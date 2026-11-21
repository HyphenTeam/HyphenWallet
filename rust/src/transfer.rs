// Transfer module: output scanning, transaction building, and RPC submission.
//
// This module bridges the wallet's key derivation system with the blockchain's
// shielded UTXO model. It scans blocks for owned outputs, constructs ring-
// signature transactions using CLSAG + Pedersen commitments, and submits
// them to a node via the RPC protocol.

use curve25519_dalek::ristretto::{CompressedRistretto, RistrettoPoint};
use curve25519_dalek::scalar::Scalar;
use rand::RngExt;
use std::collections::{HashMap, hash_map::Entry};
use std::fs::File;
use std::io::{self, Read, Seek, Write};
use std::ops::RangeInclusive;
use std::path::Path;

use hyphen_crypto::pedersen::PedersenGens;
use hyphen_crypto::stealth::{self, EphemeralKey, StealthAddress, ViewKey};
use hyphen_tx::builder::{InputSpec, TransactionBuilder};
use hyphen_tx::note::{Note, OwnedNote};
use hyphen_tx::transaction::Transaction;

use crate::address::HyphenAddress;
use crate::keys::MasterKey;
use crate::rpc_client::{ChainInfoResponse, RpcClient};

/// A wallet-owned unspent output serialisable across FFI.
#[derive(Clone, serde::Serialize, serde::Deserialize, rustbinary::CompactBinary)]
pub struct WalletOutput {
    pub global_index: u64,
    #[serde(with = "json_amount")]
    pub value: u64,
    pub ephemeral_pubkey_hex: String,
    pub output_index: u64,
    pub one_time_pubkey_hex: String,
    pub commitment_hex: String,
    pub block_height: u64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub received_tx_hash: Option<String>,
}

mod json_amount {
    use serde::{Deserialize, Deserializer, Serializer};

    pub fn serialize<S: Serializer>(value: &u64, serializer: S) -> Result<S::Ok, S::Error> {
        if *value < (1 << 53) {
            serializer.serialize_u64(*value)
        } else {
            serializer.collect_str(value)
        }
    }

    pub fn deserialize<'de, D: Deserializer<'de>>(deserializer: D) -> Result<u64, D::Error> {
        #[derive(Deserialize)]
        #[serde(untagged)]
        enum Amount {
            Number(u64),
            Decimal(String),
        }
        match Amount::deserialize(deserializer)? {
            Amount::Number(value) => Ok(value),
            Amount::Decimal(text) => text.parse().map_err(serde::de::Error::custom),
        }
    }
}

impl WalletOutput {
    fn recover(&self, keys: &crate::keys::DerivedKeyPair) -> Result<OwnedNote, String> {
        let mut ephemeral = [0; 32];
        hex::decode_to_slice(&self.ephemeral_pubkey_hex, &mut ephemeral)
            .map_err(|_| "invalid cached ephemeral key")?;
        let point = decompress(&ephemeral).ok_or("invalid cached ephemeral key")?;
        let shared = output_shared_secret(keys.view_secret, point, self.output_index);
        let spend_sk = shared + keys.spend_secret;
        let pubkey = RistrettoPoint::mul_base(&spend_sk).compress().to_bytes();
        let blinding = stealth::derive_commitment_blinding(&shared);
        let commitment = hyphen_crypto::pedersen::Commitment::create(self.value, blinding);
        if hex::encode(pubkey) != self.one_time_pubkey_hex
            || hex::encode(commitment.as_bytes()) != self.commitment_hex
        {
            return Err("wallet cache does not match the unlocked keys and amount".into());
        }
        Ok(OwnedNote {
            note: Note {
                commitment,
                one_time_pubkey: pubkey,
                ephemeral_pubkey: ephemeral,
                encrypted_amount: stealth::encrypt_amount(self.value, &shared),
                global_index: self.global_index,
                block_height: self.block_height,
            },
            value: self.value,
            blinding: blinding.to_bytes(),
            spend_sk: spend_sk.to_bytes(),
        })
    }
}

fn output_shared_secret(
    view_secret: Scalar,
    ephemeral: RistrettoPoint,
    output_index: u64,
) -> Scalar {
    let point = (view_secret * ephemeral).compress();
    let mut material = [0u8; 40];
    material[..32].copy_from_slice(point.as_bytes());
    material[32..].copy_from_slice(&output_index.to_le_bytes());
    hyphen_crypto::hash::hash_to_scalar(b"Hyphen_ECDH", &material)
}

/// Result of a transaction submission.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize, rustbinary::CompactBinary)]
pub struct SendResult {
    pub tx_hash_hex: String,
    pub accepted: bool,
    pub error_message: String,
    pub spent_indices_csv: String,
    pub vre_used_adaptive: bool,
}

/// A fully signed transaction that can be persisted before network I/O.
/// Re-broadcasting these exact bytes is safe: the transaction hash and key
/// images do not change between retries.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize, rustbinary::CompactBinary)]
pub struct BuiltTransaction {
    pub tx_hash_hex: String,
    pub tx_data: Vec<u8>,
    pub spent_indices: Vec<u64>,
    pub vre_used_adaptive: bool,
}

#[derive(
    Clone, Debug, PartialEq, Eq, serde::Serialize, serde::Deserialize, rustbinary::CompactBinary,
)]
#[serde(tag = "state", rename_all = "snake_case")]
pub enum TransactionStatus {
    Unknown,
    Mempool,
    Confirmed {
        block_hash_hex: String,
        block_height: u64,
        confirmations: u64,
    },
}

/// Summary returned after a wallet scan.
pub struct ScanResult {
    pub total_balance: u64,
    pub output_count: u64,
    pub scanned_height: u64,
    pub scanned_hash_hex: String,
    pub outputs_json: String,
}

/// Chain status info.
pub struct ChainStatus {
    pub height: u64,
    pub total_outputs: u64,
    pub tip_hash_hex: String,
}

pub fn get_chain_status(host: String, port: u16) -> Result<ChainStatus, String> {
    let mut client = RpcClient::connect(&host, port)?;
    let info = verified_chain_info(&mut client)?;
    Ok(ChainStatus {
        height: info.height,
        total_outputs: info.total_outputs,
        tip_hash_hex: hex::encode(&info.tip_hash),
    })
}

/// Reads the node's chain info and refuses to continue unless the node proves
/// one of the pinned network identities.
///
/// Every RPC entry point goes through this. A wallet that skipped the check
/// could be pointed at a node replaying a different chain — a devnet mirror that
/// happens to serve familiar-looking data — and would happily sign value-bearing
/// transactions against it.
fn verified_chain_info(client: &mut RpcClient) -> Result<ChainInfoResponse, String> {
    let info = client.get_chain_info()?;
    crate::chain_identity::verify(
        &info.network,
        &info.network_magic,
        &info.consensus_params_hash,
        &info.genesis_hash,
        info.block_version,
        info.pouw_protocol_version,
    )?;
    Ok(info)
}

/// Whether a network magic addresses the value-bearing mainnet.
fn magic_is_mainnet(network_magic: &[u8]) -> bool {
    network_magic == b"HYPN"
}

/// Rejects a mismatch between the wallet's configured network and the node's.
fn require_network_class(info: &ChainInfoResponse, wallet_is_mainnet: bool) -> Result<(), String> {
    let node_is_mainnet = magic_is_mainnet(&info.network_magic);
    if node_is_mainnet != wallet_is_mainnet {
        return Err(format!(
            "wallet network setting does not match the node: the node serves {} ({}), the wallet is configured for {}",
            info.network,
            if node_is_mainnet {
                "mainnet"
            } else {
                "testnet/devnet"
            },
            if wallet_is_mainnet {
                "mainnet"
            } else {
                "testnet/devnet"
            },
        ));
    }
    Ok(())
}

// Keep one batch of public input key images in memory. A large scan spills
// full batches to an anonymous file, then intersects them with wallet keys.
// This also catches a repeated output key whose spend preceded the output.
#[derive(Default)]
struct ScanSpends<'a> {
    directory: Option<&'a Path>,
    batch: Vec<[u8; 32]>,
    file: Option<File>,
    batches_written: u64,
}

impl ScanSpends<'_> {
    const BATCH_SIZE: usize = 8192;

    fn push(&mut self, image: [u8; 32]) -> io::Result<()> {
        if self.batch.len() == Self::BATCH_SIZE {
            let file = match &mut self.file {
                Some(file) => file,
                slot @ None => slot.insert(match self.directory {
                    Some(directory) => tempfile::tempfile_in(directory)?,
                    None => tempfile::tempfile()?,
                }),
            };
            file.write_all(self.batch.as_flattened())?;
            self.batches_written += 1;
            self.batch.clear();
        }
        self.batch.push(image);
        Ok(())
    }

    fn remove_spent<T>(mut self, unspent: &mut HashMap<[u8; 32], T>) -> io::Result<()> {
        for image in &self.batch {
            unspent.remove(image);
        }
        if let Some(mut file) = self.file {
            file.rewind()?;
            self.batch.resize(Self::BATCH_SIZE, [0; 32]);
            for _ in 0..self.batches_written {
                if unspent.is_empty() {
                    break;
                }
                file.read_exact(self.batch.as_flattened_mut())?;
                for image in &self.batch {
                    unspent.remove(image);
                }
            }
        }
        Ok(())
    }
}

/// Scan the blockchain for outputs belonging to this wallet.
///
/// Reads from genesis through `end_height` (capped at the tip) to verify
/// ancestry, count global output indices and collect spends. Returns owned
/// outputs created from `start_height` onward that are unspent at the end height.
pub fn scan_wallet_outputs(
    host: String,
    port: u16,
    seed_hex: String,
    account: u32,
    start_height: u64,
    end_height: u64,
    is_mainnet: bool,
) -> Result<ScanResult, String> {
    scan_outputs_in(
        host,
        port,
        seed_hex,
        account,
        start_height..=end_height,
        ScanNetwork::AddressClass { is_mainnet },
        None,
    )
}

pub(crate) enum ScanNetwork {
    AddressClass { is_mainnet: bool },
    Exact([u8; 4]),
}

impl ScanNetwork {
    fn check(&self, info: &ChainInfoResponse) -> Result<(), String> {
        match self {
            Self::AddressClass { is_mainnet } => require_network_class(info, *is_mainnet),
            Self::Exact(magic) if info.network_magic == *magic => Ok(()),
            Self::Exact(_) => Err("wallet scan network differs from the expected chain".into()),
        }
    }
}

/// Scan account zero on the offline-payment devnet through the verified RPC connection.
pub fn scan_reserve_wallet(
    host: String,
    port: u16,
    seed_hex: String,
) -> Result<ScanResult, String> {
    scan_outputs_in(
        host,
        port,
        seed_hex,
        0,
        0..=u64::MAX,
        ScanNetwork::Exact(*b"HYN3"),
        None,
    )
}

pub(crate) fn scan_outputs_in(
    host: String,
    port: u16,
    seed_hex: String,
    account: u32,
    heights: RangeInclusive<u64>,
    network: ScanNetwork,
    directory: Option<&Path>,
) -> Result<ScanResult, String> {
    let (start_height, end_height) = heights.into_inner();
    let mk = MasterKey::from_hex(seed_hex)?;
    let keys = mk.derive_bip44(account, 0, 0);

    let view_key = ViewKey(keys.view_secret.to_bytes());

    let mut client = RpcClient::connect(&host, port)?;
    let info = verified_chain_info(&mut client)?;
    network.check(&info)?;
    let end_height = end_height.min(info.height);
    if start_height > end_height {
        return Err(format!(
            "scan starts at {start_height} beyond the last requested block {end_height}"
        ));
    }
    // An extension of the chain is fine. A reorg through the requested range
    // invalidates the output indices and key images collected during this scan.
    let anchor = if end_height == info.height {
        info.tip_hash.clone()
    } else {
        client.get_block_by_height(end_height)?.hash
    };
    let mut owned_outputs = HashMap::<[u8; 32], WalletOutput>::new();
    let mut spends = ScanSpends {
        directory,
        ..Default::default()
    };
    let mut global_index: u64 = 0;

    let mut parent = hyphen_crypto::Hash256::ZERO;
    for h in 0..=end_height {
        let block = client.get_block_by_height(h)?;
        let header = checked_header(&block, h)?;
        let hash = header.hash();
        if header.prev_hash != parent || (h == 0 && block.hash != info.genesis_hash) {
            return Err(format!("inconsistent block header at height {h}"));
        }
        parent = hash;
        if h == end_height && block.hash != anchor {
            return Err(format!("chain changed during wallet scan at height {h}"));
        }

        let transaction_hashes = checked_transaction_hashes(&header, &block.transactions)?;
        let regular_count = transaction_hashes.len();
        for (index, tx_blob) in block.transactions.iter().enumerate() {
            // These consensus envelopes never append shielded outputs or spend key images.
            if index < regular_count
                && [b"HYPHWES1", b"HYPWASM1", b"AETHWRK1"]
                    .iter()
                    .any(|magic| tx_blob.starts_with(*magic))
            {
                continue;
            }
            let tx = Transaction::deserialise_limited(tx_blob)
                .map_err(|error| format!("decode transaction {index} at height {h}: {error}"))?;
            if index == regular_count {
                verify_reward_output(&header, &info, &block.block_authorization, &tx)
                    .map_err(|e| format!("invalid coinbase at height {h}: {e}"))?;
            }
            // A repeated output key can already have been spent before the
            // requested output range. Key images apply to the entire prefix.
            let incoming = start_height == 0
                && index < regular_count
                && !tx
                    .inputs
                    .iter()
                    .any(|input| owned_outputs.contains_key(&input.key_image));
            for input in &tx.inputs {
                spends
                    .push(input.key_image)
                    .map_err(|e| format!("buffer scan key images: {e}"))?;
            }

            if h < start_height {
                global_index += tx.outputs.len() as u64;
                continue;
            }

            for (out_idx, out) in tx.outputs.iter().enumerate() {
                let eph = EphemeralKey(out.ephemeral_pubkey);
                let otp = match decompress(&out.one_time_pubkey) {
                    Some(p) => p,
                    None => {
                        global_index += 1;
                        continue;
                    }
                };

                // Fast view tag check
                let view_scalar = view_key.as_scalar();
                let big_r = match decompress(&eph.0) {
                    Some(p) => p,
                    None => {
                        global_index += 1;
                        continue;
                    }
                };
                let ss = output_shared_secret(view_scalar, big_r, out_idx as u64);
                let vt = stealth::compute_view_tag(&ss);
                if vt != out.view_tag {
                    global_index += 1;
                    continue;
                }

                // Full ownership check
                use curve25519_dalek::constants::RISTRETTO_BASEPOINT_POINT as G;
                let expected = ss * G + keys.spend_public;
                if expected != otp {
                    global_index += 1;
                    continue;
                }

                // Output is ours! Recover the one-time spend key
                let one_time_sk = ss + keys.spend_secret;
                let amount = stealth::decrypt_amount(&out.encrypted_amount, &ss);
                let blinding = stealth::derive_commitment_blinding(&ss);

                // Verify the commitment matches
                let gens = PedersenGens::default();
                let computed_commit = gens.commit(Scalar::from(amount), blinding);
                let stored_commit = match out.commitment.to_point() {
                    Ok(p) => p,
                    Err(_) => {
                        global_index += 1;
                        continue;
                    }
                };
                if computed_commit != stored_commit {
                    // Commitment mismatch — corrupted or not actually ours
                    global_index += 1;
                    continue;
                }

                let key_image = hyphen_tx::nullifier::compute_nullifier(&one_time_sk, &otp)
                    .compress()
                    .to_bytes();
                let output = WalletOutput {
                    global_index,
                    value: amount,
                    ephemeral_pubkey_hex: hex::encode(eph.0),
                    output_index: out_idx as u64,
                    one_time_pubkey_hex: hex::encode(out.one_time_pubkey),
                    commitment_hex: hex::encode(out.commitment.as_bytes()),
                    block_height: h,
                    received_tx_hash: incoming.then(|| transaction_hashes[index].to_string()),
                };
                keep_spendable_output(owned_outputs.entry(key_image), output);

                global_index += 1;
            }
        }
    }

    spends
        .remove_spent(&mut owned_outputs)
        .map_err(|e| format!("read scan key images: {e}"))?;
    let mut owned_outputs: Vec<_> = owned_outputs.into_values().collect();
    owned_outputs.sort_unstable_by_key(|output| output.global_index);
    let total_balance = owned_outputs.iter().try_fold(0u64, |balance, output| {
        balance
            .checked_add(output.value)
            .ok_or_else(|| "wallet balance overflow".to_string())
    })?;
    let output_count = owned_outputs.len() as u64;
    let outputs_json =
        serde_json::to_string(&owned_outputs).map_err(|e| format!("serialize outputs: {e}"))?;

    // A reorganization may have removed the scanned anchor while processing its outputs.
    if client.get_block_by_height(end_height)?.hash != anchor {
        return Err(format!(
            "chain changed during wallet scan at height {end_height}"
        ));
    }

    Ok(ScanResult {
        total_balance,
        output_count,
        scanned_height: end_height,
        scanned_hash_hex: hex::encode(anchor),
        outputs_json,
    })
}

fn keep_spendable_output(entry: Entry<'_, [u8; 32], WalletOutput>, output: WalletOutput) {
    match entry {
        Entry::Vacant(slot) => {
            slot.insert(output);
        }
        Entry::Occupied(mut slot) if output.value > slot.get().value => {
            slot.insert(output);
        }
        Entry::Occupied(_) => {}
    }
}

fn checked_header(
    block: &crate::rpc_client::BlockResponse,
    height: u64,
) -> Result<hyphen_core::BlockHeader, String> {
    let header: hyphen_core::BlockHeader = crate::wire_config(4096)
        .deserialize(&block.header_data)
        .map_err(|e| format!("decode header at height {height}: {e}"))?;
    if header.height != height || header.hash().as_bytes().as_slice() != block.hash {
        return Err(format!("inconsistent block header at height {height}"));
    }
    Ok(header)
}

fn checked_transaction_hashes(
    header: &hyphen_core::BlockHeader,
    transactions: &[Vec<u8>],
) -> Result<Vec<hyphen_crypto::Hash256>, String> {
    let reward_count = usize::from(header.height > 0 && header.reward > 0);
    let count = transactions
        .len()
        .checked_sub(reward_count)
        .ok_or_else(|| format!("missing coinbase at height {}", header.height))?;
    let hashes: Vec<_> = transactions[..count]
        .iter()
        .map(|tx| hyphen_crypto::blake3_hash(tx))
        .collect();
    if hyphen_core::block::merkle_root(&hashes) != header.tx_root {
        return Err(format!(
            "transaction root mismatch at height {}",
            header.height
        ));
    }
    Ok(hashes)
}

fn verify_reward_output(
    header: &hyphen_core::BlockHeader,
    info: &ChainInfoResponse,
    authorization: &[u8],
    tx: &Transaction,
) -> Result<(), String> {
    if authorization.is_empty() {
        return Err("RPC node did not provide the miner authorization; upgrade the node".into());
    }
    let auth: hyphen_core::BlockAuthorization = crate::wire_config(256)
        .deserialize(authorization)
        .map_err(|e| format!("invalid authorization: {e}"))?;
    let [output] = tx.outputs.as_slice() else {
        return Err("expected one reward output".into());
    };
    if !tx.is_coinbase()
        || tx.fee != 0
        || tx.extra != header.height.to_le_bytes()
        || !tx.prunable.clsag_signatures.is_empty()
    {
        return Err("invalid reward metadata".into());
    }
    if info.network_magic.as_slice() == b"HYN3"
        && header.extra_nonce
            != hyphen_core::authorization::reward_commitment(
                &auth.reward_view_public,
                &auth.reward_spend_public,
            )
    {
        return Err("reward keys differ from the block header commitment".into());
    }
    auth.verify(
        header,
        info.network_magic
            .as_slice()
            .try_into()
            .map_err(|_| "invalid network magic")?,
        info.consensus_params_hash
            .as_slice()
            .try_into()
            .map_err(|_| "invalid consensus hash")?,
        hyphen_crypto::Hash256::from_bytes(
            info.genesis_hash
                .as_slice()
                .try_into()
                .map_err(|_| "invalid genesis hash")?,
        ),
    )
    .map_err(|error| format!("invalid miner authorization: {error}"))?;
    let recipient = StealthAddress {
        view_public: auth.reward_view_public,
        spend_public: auth.reward_spend_public,
    };
    let (ephemeral, pk, shared) =
        stealth::derive_consensus_one_time_key(&recipient, 0, header.hash().as_bytes())
            .map_err(|e| e.to_string())?;
    if output.ephemeral_pubkey != ephemeral.0
        || output.one_time_pubkey != pk.compress().to_bytes()
        || output.view_tag != stealth::compute_view_tag(&shared)
        || output.encrypted_amount != stealth::encrypt_amount(header.reward, &shared)
        || output.commitment
            != hyphen_crypto::pedersen::Commitment::create(
                header.reward,
                stealth::derive_commitment_blinding(&shared),
            )
    {
        return Err("reward output differs from the miner authorization and header amount".into());
    }
    Ok(())
}

pub struct TransactionRequest {
    pub host: String,
    pub port: u16,
    pub seed_hex: String,
    pub account: u32,
    pub recipient_address: String,
    pub amount: u64,
    pub fee: u64,
    pub owned_outputs_json: String,
    pub ring_size: u32,
}

/// Build a shielded transaction and submit it to the node.
///
/// This function:
/// 1. Selects inputs from owned outputs to cover the amount + fee
/// 2. Fetches random decoy outputs from the node for ring signatures
/// 3. Constructs the transaction with CLSAG signatures and range proofs
/// 4. Serializes and submits via RPC
pub fn build_and_send_transaction(request: TransactionRequest) -> Result<SendResult, String> {
    let host = request.host.clone();
    let port = request.port;
    let built = build_transaction(request)?;
    submit_built_transaction(host, port, built)
}

/// Build and sign a transaction without broadcasting it.
///
/// Callers that need crash-safe delivery must persist the returned value
/// before calling [`submit_built_transaction`].
pub fn build_transaction(request: TransactionRequest) -> Result<BuiltTransaction, String> {
    build_transaction_for_network(request, None)
}

pub fn build_transaction_for_network(
    request: TransactionRequest,
    expected_magic: Option<[u8; 4]>,
) -> Result<BuiltTransaction, String> {
    let TransactionRequest {
        host,
        port,
        seed_hex,
        account,
        recipient_address,
        amount,
        fee,
        owned_outputs_json,
        ring_size,
    } = request;
    if amount == 0 {
        return Err("amount must be greater than 0".into());
    }
    if fee == 0 {
        return Err("fee must be greater than 0".into());
    }

    // Parse owned outputs
    let all_outputs: Vec<WalletOutput> = serde_json::from_str(&owned_outputs_json)
        .map_err(|e| format!("parse owned outputs: {e}"))?;

    // Select inputs to cover amount + fee
    let total_needed = amount.checked_add(fee).ok_or("amount + fee overflow")?;

    let selected = select_inputs(&all_outputs, total_needed)?;
    let total_selected = selected.iter().try_fold(0u64, |total, output| {
        total
            .checked_add(output.value)
            .ok_or_else(|| "selected input value overflow".to_string())
    })?;
    let change = total_selected
        .checked_sub(total_needed)
        .ok_or_else(|| "input selection returned an insufficient set".to_string())?;

    // Parse recipient address
    let dest_addr = HyphenAddress::decode(&recipient_address)?;
    let recipient_stealth = StealthAddress {
        view_public: dest_addr.view_public,
        spend_public: dest_addr.spend_public,
    };

    // Parse sender keys (for change output)
    let mk = MasterKey::from_hex(seed_hex)?;
    let keys = mk.derive_bip44(account, 0, 0);
    let sender_stealth = StealthAddress {
        view_public: keys.view_public.compress().to_bytes(),
        spend_public: keys.spend_public.compress().to_bytes(),
    };

    // Connect to node
    let mut client = RpcClient::connect(&host, port)?;

    // Get chain info for total output count (needed for decoys); this also
    // pins the node to a known chain and rejects a cross-network recipient.
    let chain_info = verified_chain_info(&mut client)?;
    if expected_magic.is_some_and(|magic| chain_info.network_magic != magic) {
        return Err("funding network differs from the expected chain".into());
    }
    let node_is_mainnet = magic_is_mainnet(&chain_info.network_magic);
    if dest_addr.is_mainnet() != node_is_mainnet {
        return Err(format!(
            "recipient address version does not match the node's network {}",
            chain_info.network
        ));
    }
    let total_outputs = chain_info.total_outputs;

    // Extract epoch seed for TERA binding
    if chain_info.epoch_seed.len() != 32 {
        return Err(format!(
            "node returned invalid epoch_seed length: {}",
            chain_info.epoch_seed.len()
        ));
    }
    let mut epoch_seed = [0u8; 32];
    epoch_seed.copy_from_slice(&chain_info.epoch_seed);

    // Determine VRE parameters from network name, adapted to current height
    let vre = vre_params_for_network(&chain_info.network, chain_info.height, total_outputs);

    // Pre-flight: ensure chain is mature enough for transactions
    if chain_info.height < vre.min_chain_height {
        return Err(format!(
            "chain height {} is too low for transactions on {}: minimum required height is {}",
            chain_info.height, chain_info.network, vre.min_chain_height
        ));
    }

    let expected_ring = if node_is_mainnet { 16 } else { 4 };
    if ring_size != expected_ring {
        return Err(format!("network requires ring size {expected_ring}"));
    }
    let num_decoys = ring_size as usize - 1;

    // Build transaction
    let mut builder = TransactionBuilder::new();
    builder.set_fee(fee);
    builder.set_epoch_seed(&epoch_seed);

    // Add inputs with decoys
    for wo in &selected {
        let decoys = fetch_decoys(&mut client, num_decoys, total_outputs, wo, &vre)?;
        let real_index = rand::rng().random_range(0..=decoys.len());

        builder.add_input(InputSpec {
            owned: wo.recover(&keys)?,
            decoys,
            real_index,
        });
    }

    // Add recipient output
    builder.add_output(recipient_stealth, amount);

    // Add change output back to self (if any)
    if change > 0 {
        builder.add_output(sender_stealth, change);
    }

    // Build the transaction (creates CLSAG signatures + range proofs)
    // The builder now self-verifies each CLSAG signature
    let tx = builder
        .build()
        .map_err(|e| format!("build transaction: {e}"))?;

    // Serialize, but do not perform network I/O. The caller can now persist
    // these exact signed bytes before the first broadcast attempt.
    let tx_data = tx.serialise();
    let tx_hash_hex = hex::encode(hyphen_crypto::blake3_hash(&tx_data).as_bytes());
    let spent_indices: Vec<u64> = selected.iter().map(|o| o.global_index).collect();

    Ok(BuiltTransaction {
        tx_hash_hex,
        tx_data,
        spent_indices,
        vre_used_adaptive: vre.used_adaptive,
    })
}

/// Broadcast a previously persisted signed transaction.
pub fn submit_built_transaction(
    host: String,
    port: u16,
    built: BuiltTransaction,
) -> Result<SendResult, String> {
    submit_transaction_for_network(host, port, built, None)
}

pub fn submit_transaction_for_network(
    host: String,
    port: u16,
    built: BuiltTransaction,
    expected_magic: Option<[u8; 4]>,
) -> Result<SendResult, String> {
    let actual_hash = hex::encode(hyphen_crypto::blake3_hash(&built.tx_data).as_bytes());
    if actual_hash != built.tx_hash_hex {
        return Err("persisted transaction hash does not match its signed bytes".into());
    }
    let expected_hash = hex::decode(&built.tx_hash_hex)
        .map_err(|error| format!("persisted transaction hash is invalid hex: {error}"))?;
    Transaction::deserialise_limited(&built.tx_data)
        .map_err(|error| format!("persisted transaction is malformed: {error}"))?;

    let mut client = RpcClient::connect(&host, port)?;
    if let Some(magic) = expected_magic
        && verified_chain_info(&mut client)?.network_magic != magic
    {
        return Err("submission network differs from the expected chain".into());
    }
    let resp = client.submit_transaction(built.tx_data)?;
    if resp.accepted && resp.tx_hash.as_slice() != expected_hash.as_slice() {
        return Err("node accepted transaction under an unexpected hash".into());
    }

    Ok(SendResult {
        tx_hash_hex: built.tx_hash_hex,
        accepted: resp.accepted,
        error_message: resp.error,
        spent_indices_csv: if resp.accepted {
            built
                .spent_indices
                .iter()
                .map(u64::to_string)
                .collect::<Vec<_>>()
                .join(",")
        } else {
            String::new()
        },
        vre_used_adaptive: built.vre_used_adaptive,
    })
}

/// Query canonical-chain or mempool presence for a transaction hash.
pub fn transaction_status(
    host: String,
    port: u16,
    tx_hash_hex: &str,
) -> Result<TransactionStatus, String> {
    transaction_status_for_network(host, port, tx_hash_hex, None)
}

pub fn transaction_status_for_network(
    host: String,
    port: u16,
    tx_hash_hex: &str,
    expected_magic: Option<[u8; 4]>,
) -> Result<TransactionStatus, String> {
    let tx_hash = hex::decode(tx_hash_hex)
        .map_err(|error| format!("invalid transaction hash hex: {error}"))?;
    if tx_hash.len() != 32 {
        return Err(format!(
            "transaction hash must be 32 bytes, got {}",
            tx_hash.len()
        ));
    }

    let mut client = RpcClient::connect(&host, port)?;
    if let Some(magic) = expected_magic {
        ScanNetwork::Exact(magic).check(&verified_chain_info(&mut client)?)?;
    }
    let location = client.get_tx_location(tx_hash.clone())?;
    if location.found {
        if location.block_hash.len() != 32 {
            return Err("node returned an invalid confirmed block hash".into());
        }
        let block = client.get_block_by_height(location.block_height)?;
        let header = checked_header(&block, location.block_height)?;
        let hashes = checked_transaction_hashes(&header, &block.transactions)?;
        if block.hash != location.block_hash
            || hashes
                .get(location.tx_index as usize)
                .is_none_or(|hash| hash.as_bytes().as_slice() != tx_hash)
        {
            return Err("transaction location differs from the block at that height".into());
        }
        let tip = verified_chain_info(&mut client)?;
        if location.block_height > tip.height
            || (location.block_height == tip.height && block.hash != tip.tip_hash)
        {
            return Err("transaction location differs from the reported tip".into());
        }
        return Ok(TransactionStatus::Confirmed {
            block_hash_hex: hex::encode(location.block_hash),
            block_height: location.block_height,
            confirmations: (tip.height - location.block_height)
                .checked_add(1)
                .ok_or("confirmation count overflow")?,
        });
    }

    let mempool = client.get_mempool()?;
    if mempool
        .tx_hashes
        .iter()
        .any(|candidate| candidate.as_slice() == tx_hash.as_slice())
    {
        Ok(TransactionStatus::Mempool)
    } else {
        Ok(TransactionStatus::Unknown)
    }
}

fn decompress(bytes: &[u8]) -> Option<RistrettoPoint> {
    CompressedRistretto::from_slice(bytes).ok()?.decompress()
}

/// Select inputs to cover the required amount using a simple greedy algorithm.
/// Prefers larger outputs first to minimize the number of inputs.
fn select_inputs(outputs: &[WalletOutput], total_needed: u64) -> Result<Vec<WalletOutput>, String> {
    if outputs.is_empty() {
        return Err("no spendable outputs available".into());
    }

    let mut sorted: Vec<&WalletOutput> = outputs.iter().collect();
    sorted.sort_by_key(|output| std::cmp::Reverse(output.value));

    let mut selected = Vec::new();
    let mut accumulated = 0u64;

    for out in sorted {
        if accumulated >= total_needed {
            break;
        }
        accumulated = accumulated
            .checked_add(out.value)
            .ok_or_else(|| "wallet output value total overflowed u64".to_string())?;
        selected.push(out.clone());
    }

    if accumulated < total_needed {
        return Err(format!(
            "insufficient balance: have {accumulated}, need {total_needed}"
        ));
    }

    Ok(selected)
}

/// Fetch random decoy outputs from the node, excluding the real output.
/// Performs age-band-stratified selection to satisfy all VRE consensus rules:
///   VRE-1: min height span
///   VRE-2: distinct height fraction (≥ 3/4)
///   MD-VRE-3: age band diversity
///   MD-VRE-4: global index span
fn fetch_decoys(
    client: &mut RpcClient,
    count: usize,
    total_outputs: u64,
    owned: &WalletOutput,
    params: &VreParams,
) -> Result<Vec<(RistrettoPoint, RistrettoPoint, u64)>, String> {
    use rand::seq::SliceRandom;
    use std::collections::{HashMap, HashSet};

    let exclude_index = owned.global_index;
    let real_height = owned.block_height;
    if exclude_index >= total_outputs || total_outputs <= count as u64 {
        return Err("output set is too small or wallet cache is stale".into());
    }
    // Query the owned output and locally sampled candidates together only once.
    let sample_size = total_outputs.min(256) as usize;
    let mut indices = HashSet::from([exclude_index]);
    if sample_size as u64 == total_outputs {
        indices.extend(0..total_outputs);
    } else {
        while indices.len() < sample_size {
            indices.insert(rand::rng().random_range(0..total_outputs));
        }
    }
    let mut indices: Vec<_> = indices.into_iter().collect();
    indices.sort_unstable();
    let resp = client.get_output_info(indices.clone())?;
    if resp.outputs.len() != indices.len() {
        return Err("incomplete output lookup".into());
    }
    let mut candidates = Vec::with_capacity(sample_size - 1);
    for (expected, out) in indices.into_iter().zip(resp.outputs) {
        if out.global_index != expected
            || out.one_time_pubkey.len() != 32
            || out.commitment.len() != 32
        {
            return Err("inconsistent output lookup".into());
        }
        let pk = decompress(&out.one_time_pubkey).ok_or("invalid output public key")?;
        let cm = decompress(&out.commitment).ok_or("invalid output commitment")?;
        if expected == exclude_index {
            if real_height != out.block_height
                || hex::encode(&out.one_time_pubkey) != owned.one_time_pubkey_hex
                || hex::encode(&out.commitment) != owned.commitment_hex
            {
                return Err("wallet output changed on chain, please re-scan".into());
            }
        } else {
            candidates.push((pk, cm, expected, out.block_height));
        }
    }

    let max_retries = 16u32;
    for _ in 0..max_retries {
        candidates.shuffle(&mut rand::rng());

        // Compute the tentative max height across real + all candidates
        let tentative_max_h = std::iter::once(real_height)
            .chain(candidates.iter().map(|c| c.3))
            .max()
            .unwrap_or(0);
        let band_width = params.vre_age_band_width.max(1);

        // Group candidates by age band (relative to tentative max)
        let mut by_band: HashMap<u64, Vec<usize>> = HashMap::new();
        for (i, c) in candidates.iter().enumerate() {
            let band = tentative_max_h.saturating_sub(c.3) / band_width;
            by_band.entry(band).or_default().push(i);
        }

        // Real output's band
        let real_band = tentative_max_h.saturating_sub(real_height) / band_width;

        // Count total distinct bands (including real)
        let available_bands: HashSet<u64> = by_band
            .keys()
            .copied()
            .chain(std::iter::once(real_band))
            .collect();

        if available_bands.len() < params.vre_min_age_bands {
            continue;
        }

        // Stratified selection: pick one from each band != real_band first
        let mut selected_indices: Vec<usize> = Vec::with_capacity(count);
        let mut used: HashSet<usize> = HashSet::new();

        let mut other_bands: Vec<u64> = by_band
            .keys()
            .copied()
            .filter(|&b| b != real_band)
            .collect();
        other_bands.sort_unstable();

        let bands_needed = params.vre_min_age_bands.saturating_sub(1);
        for &band in other_bands.iter().take(bands_needed) {
            if let Some(indices_in_band) = by_band.get(&band) {
                for &ci in indices_in_band {
                    if !used.contains(&ci) {
                        selected_indices.push(ci);
                        used.insert(ci);
                        break;
                    }
                }
            }
        }

        // Fill remaining slots from all unused candidates (shuffled for privacy)
        let mut remaining: Vec<usize> = (0..candidates.len())
            .filter(|i| !used.contains(i))
            .collect();
        remaining.shuffle(&mut rand::rng());

        for ci in remaining {
            if selected_indices.len() >= count {
                break;
            }
            selected_indices.push(ci);
            used.insert(ci);
        }

        if selected_indices.len() < count {
            continue;
        }

        let selected: Vec<(RistrettoPoint, RistrettoPoint, u64, u64)> =
            selected_indices.iter().map(|&i| candidates[i]).collect();

        // Verify all VRE constraints on the final ring
        if check_ring_vre(real_height, exclude_index, &selected, total_outputs, params) {
            // Audit decoy distribution for malicious-node detection
            let decoy_idxs: Vec<u64> = selected.iter().map(|s| s.2).collect();
            audit_decoy_distribution(&decoy_idxs, total_outputs)?;

            return Ok(selected
                .into_iter()
                .map(|(pk, cm, idx, _)| (pk, cm, idx))
                .collect());
        }
    }

    Err(format!(
        "failed to select decoys satisfying VRE after {max_retries} attempts \
         (chain height may be insufficient or output diversity too low)"
    ))
}

/// VRE consensus parameters for decoy selection.
///
/// Values mirror the paper specification with adaptive scaling so that
/// the wallet-side constraints match what the consensus layer will
/// actually enforce at the current chain height.
struct VreParams {
    min_ring_span: u64,
    vre_min_age_bands: usize,
    vre_age_band_width: u64,
    vre_min_index_span_bps: u64,
    min_chain_height: u64,
    used_adaptive: bool,
}

fn vre_params_for_network(network: &str, chain_height: u64, total_outputs: u64) -> VreParams {
    if network == "hyphen-neural-devnet-v3" {
        return VreParams {
            min_ring_span: 0,
            vre_min_age_bands: 0,
            vre_age_band_width: 1,
            vre_min_index_span_bps: 0,
            min_chain_height: 0,
            used_adaptive: false,
        };
    }
    let (target_span, target_bands, target_bw, target_bps, activation, ring_size) =
        if network.contains("mainnet") {
            (100u64, 3usize, 2048u64, 500u64, 128u64, 16u64)
        } else {
            (20u64, 2usize, 128u64, 300u64, 32u64, 4u64)
        };

    // Adaptive age-band width: shrink so that `target_bands` distinct bands
    // fit within the available height range.
    let eff_bw = if chain_height > 0 && target_bands > 0 {
        let max_feasible = chain_height / (target_bands as u64);
        target_bw.min(max_feasible.max(1))
    } else {
        target_bw
    };

    // Adaptive min ring span: cap at what the chain can actually provide.
    let eff_span = target_span.min(chain_height.saturating_sub(1));

    // Progressive logistic index span: target_bps × n²/(n²+k²) where k = ring_size×64
    let eff_bps = if total_outputs > 1 {
        let max_bps = (total_outputs - 1).saturating_mul(10_000) / total_outputs;
        let k = (ring_size as u128).saturating_mul(64);
        let n = total_outputs as u128;
        let n2 = n.saturating_mul(n);
        let k2 = k.saturating_mul(k);
        let denom = n2.saturating_add(k2).max(1);
        let progressive = ((target_bps as u128).saturating_mul(n2) / denom) as u64;
        progressive.min(max_bps)
    } else {
        0
    };

    let used_adaptive = eff_bw != target_bw || eff_span != target_span || eff_bps != target_bps;

    VreParams {
        min_ring_span: eff_span,
        vre_min_age_bands: target_bands,
        vre_age_band_width: eff_bw,
        vre_min_index_span_bps: eff_bps,
        min_chain_height: activation,
        used_adaptive,
    }
}

/// Pre-validate that the ring (real output + decoys) satisfies all VRE rules
/// using the same adaptive parameters the consensus layer will apply.
fn check_ring_vre(
    real_height: u64,
    real_index: u64,
    decoys: &[(RistrettoPoint, RistrettoPoint, u64, u64)],
    total_outputs: u64,
    params: &VreParams,
) -> bool {
    let ring_size = 1 + decoys.len();
    if ring_size < 2 || params.vre_min_age_bands == 0 {
        return true;
    }

    let mut heights: Vec<u64> = Vec::with_capacity(ring_size);
    let mut indices: Vec<u64> = Vec::with_capacity(ring_size);
    heights.push(real_height);
    indices.push(real_index);
    for d in decoys {
        heights.push(d.3);
        indices.push(d.2);
    }

    // VRE-1: min height span
    let min_h = *heights.iter().min().unwrap();
    let max_h = *heights.iter().max().unwrap();
    if max_h - min_h < params.min_ring_span {
        return false;
    }

    // VRE-2: distinct height fraction (≥ 3/4)
    let mut unique_h = heights.clone();
    unique_h.sort_unstable();
    unique_h.dedup();
    let min_distinct = (ring_size * 3).div_ceil(4);
    if unique_h.len() < min_distinct {
        return false;
    }

    // MD-VRE-3: age band diversity
    let band_width = params.vre_age_band_width.max(1);
    let mut bands: Vec<u64> = heights
        .iter()
        .map(|&h| max_h.saturating_sub(h) / band_width)
        .collect();
    bands.sort_unstable();
    bands.dedup();
    if bands.len() < params.vre_min_age_bands {
        return false;
    }

    // MD-VRE-4: global index span
    let min_idx = *indices.iter().min().unwrap();
    let max_idx = *indices.iter().max().unwrap();
    let idx_span = max_idx.saturating_sub(min_idx);
    let span_bps = idx_span.saturating_mul(10_000) / total_outputs.max(1);
    if span_bps < params.vre_min_index_span_bps {
        return false;
    }

    true
}

/// Verify that node-returned decoy outputs are not suspiciously clustered.
///
/// A malicious node may return outputs concentrated in a narrow index band
/// to reduce the effective anonymity set. This audit divides the output
/// space into 10 equal bands and rejects if more than half the decoys
/// fall in the same band — a distribution incompatible with honest
/// random sampling.
fn audit_decoy_distribution(decoy_indices: &[u64], total_outputs: u64) -> Result<(), String> {
    if decoy_indices.len() < 3 || total_outputs < 10 {
        return Ok(());
    }

    let band_size = total_outputs / 10;
    if band_size == 0 {
        return Ok(());
    }

    let mut band_counts = std::collections::HashMap::<u64, u32>::new();
    for &idx in decoy_indices {
        *band_counts.entry(idx / band_size).or_insert(0) += 1;
    }

    let max_in_band = *band_counts.values().max().unwrap_or(&0);
    let threshold = (decoy_indices.len() as u32).div_ceil(2);
    if max_in_band > threshold {
        return Err(format!(
            "suspicious decoy clustering: {} of {} decoys in same index band — \
             the connected node may be attempting output tracing",
            max_in_band,
            decoy_indices.len()
        ));
    }

    Ok(())
}

#[cfg(test)]
mod scan_spends_tests {
    use super::*;

    #[test]
    fn scan_authenticates_the_reward_recipient_and_value() {
        let cfg = hyphen_core::ChainConfig::neural_devnet();
        let genesis = hyphen_core::genesis::build_genesis_block(&cfg);
        let info = ChainInfoResponse {
            network_magic: cfg.network_magic.to_vec(),
            consensus_params_hash: cfg.consensus_params_hash().to_vec(),
            genesis_hash: genesis.hash().to_vec(),
            ..Default::default()
        };
        let miner = hyphen_crypto::SecretKey([39; 32]);
        let mut header = genesis.header.clone();
        header.height = 1;
        header.reward = 57;
        header.miner_pubkey = *miner.public_key().as_bytes();
        let (_, _, recipient) = stealth::generate_keys();
        header.extra_nonce = hyphen_core::authorization::reward_commitment(
            &recipient.view_public,
            &recipient.spend_public,
        );
        let auth = hyphen_core::BlockAuthorization::sign(
            &header,
            cfg.network_magic,
            cfg.consensus_params_hash(),
            genesis.hash(),
            recipient.view_public,
            recipient.spend_public,
            &miner,
        )
        .unwrap();
        let bytes = crate::wire_config(256).serialize(&auth).unwrap();
        let mut tx = hyphen_tx::builder::build_coinbase_tx(
            recipient.view_public,
            recipient.spend_public,
            header.reward,
            1,
            header.hash(),
        )
        .unwrap();
        verify_reward_output(&header, &info, &bytes, &tx).unwrap();
        assert!(verify_reward_output(&header, &info, &[], &tx).is_err());
        tx.outputs[0].encrypted_amount[0] ^= 1;
        assert!(verify_reward_output(&header, &info, &bytes, &tx).is_err());
    }

    #[test]
    fn cached_output_recovers_only_with_its_wallet_and_amount() {
        let keys = MasterKey::from_seed(&[61; 64]).derive_default();
        let recipient = StealthAddress {
            view_public: keys.view_public.compress().to_bytes(),
            spend_public: keys.spend_public.compress().to_bytes(),
        };
        let (ephemeral, pk, shared) = stealth::derive_one_time_key(&recipient, 1).unwrap();
        let commitment = hyphen_crypto::pedersen::Commitment::create(
            71,
            stealth::derive_commitment_blinding(&shared),
        );
        let mut item = WalletOutput {
            global_index: 18,
            value: 71,
            ephemeral_pubkey_hex: hex::encode(ephemeral.0),
            output_index: 1,
            one_time_pubkey_hex: hex::encode(pk.compress().to_bytes()),
            commitment_hex: hex::encode(commitment.0),
            block_height: 5,
            received_tx_hash: None,
        };
        assert_eq!(
            item.recover(&keys).unwrap().spend_sk,
            (keys.spend_secret + shared).to_bytes()
        );
        assert!(
            item.recover(&MasterKey::from_seed(&[62; 64]).derive_default())
                .is_err()
        );
        item.value += 1;
        assert!(item.recover(&keys).is_err());
        item.value = u64::MAX;
        let mut json = serde_json::to_value(&item).unwrap();
        assert_eq!(json["value"], u64::MAX.to_string());
        assert_eq!(
            serde_json::from_str::<WalletOutput>(&json.to_string())
                .unwrap()
                .value,
            u64::MAX
        );
        json["value"] = u64::MAX.into();
        assert_eq!(
            serde_json::from_value::<WalletOutput>(json).unwrap().value,
            u64::MAX
        );
    }

    #[test]
    fn repeated_output_keys_contribute_only_the_largest_spendable_value() {
        let mut owned = HashMap::new();
        let image = [12; 32];
        for (global_index, value) in [(0, 3), (1, 5), (2, 5), (3, 2)] {
            let output = WalletOutput {
                global_index,
                value,
                ephemeral_pubkey_hex: String::new(),
                output_index: 0,
                one_time_pubkey_hex: String::new(),
                commitment_hex: String::new(),
                block_height: 1,
                received_tx_hash: None,
            };
            keep_spendable_output(owned.entry(image), output);
        }
        assert_eq!(owned.len(), 1);
        assert_eq!((owned[&image].global_index, owned[&image].value), (1, 5));
    }

    #[test]
    fn spending_in_any_batch_removes_the_owned_image() {
        let cache = tempfile::tempdir().unwrap();
        let mut spends = ScanSpends {
            directory: Some(cache.path()),
            ..Default::default()
        };
        for byte in [1, 2, 3] {
            for _ in 0..ScanSpends::BATCH_SIZE {
                spends.push([byte; 32]).unwrap();
            }
        }
        assert_eq!(spends.batches_written, 2);
        assert_eq!(spends.batch.len(), ScanSpends::BATCH_SIZE);
        let mut unspent =
            HashMap::from([([1; 32], ()), ([2; 32], ()), ([3; 32], ()), ([4; 32], ())]);
        spends.remove_spent(&mut unspent).unwrap();
        assert_eq!(unspent, HashMap::from([([4; 32], ())]));
    }
}
