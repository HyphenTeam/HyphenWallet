// Transfer module: output scanning, transaction building, and RPC submission.
//
// This module bridges the wallet's key derivation system with the blockchain's
// shielded UTXO model. It scans blocks for owned outputs, constructs ring-
// signature transactions using CLSAG + Pedersen commitments, and submits
// them to a node via the RPC protocol.

use curve25519_dalek::ristretto::{CompressedRistretto, RistrettoPoint};
use curve25519_dalek::scalar::Scalar;
use std::collections::HashSet;

use hyphen_crypto::pedersen::PedersenGens;
use hyphen_crypto::stealth::{self, EphemeralKey, SpendKey, StealthAddress, ViewKey};
use hyphen_tx::builder::{InputSpec, TransactionBuilder};
use hyphen_tx::note::{Note, OwnedNote};
use hyphen_tx::transaction::Transaction;

use crate::address::HyphenAddress;
use crate::keys::MasterKey;
use crate::rpc_client::RpcClient;

// ─── Public types exposed to FFI ────────────────────────────

/// A wallet-owned unspent output serialisable across FFI.
#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct WalletOutput {
    pub global_index: u64,
    pub value: u64,
    pub blinding_hex: String,
    pub spend_sk_hex: String,
    pub one_time_pubkey_hex: String,
    pub commitment_hex: String,
    pub block_height: u64,
}

/// Result of a transaction submission.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
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
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct BuiltTransaction {
    pub tx_hash_hex: String,
    pub tx_data: Vec<u8>,
    pub spent_indices: Vec<u64>,
    pub vre_used_adaptive: bool,
}

#[derive(Clone, Debug, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
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
    pub outputs_json: String,
}

/// Chain status info.
pub struct ChainStatus {
    pub height: u64,
    pub total_outputs: u64,
    pub tip_hash_hex: String,
}

// ─── Chain info ─────────────────────────────────────────────

pub fn get_chain_status(host: String, port: u16) -> Result<ChainStatus, String> {
    let mut client = RpcClient::connect(&host, port)?;
    let info = client.get_chain_info()?;
    Ok(ChainStatus {
        height: info.height,
        total_outputs: info.total_outputs,
        tip_hash_hex: hex::encode(&info.tip_hash),
    })
}

// ─── Output scanning ───────────────────────────────────────

/// Scan the blockchain for outputs belonging to this wallet.
///
/// Downloads blocks from `start_height` to `end_height` (inclusive),
/// parses all transaction outputs, and checks each one against the
/// wallet's view key. Returns all owned, unspent outputs.
pub fn scan_wallet_outputs(
    host: String,
    port: u16,
    seed_hex: String,
    account: u32,
    start_height: u64,
    end_height: u64,
    _is_mainnet: bool,
) -> Result<ScanResult, String> {
    let seed_bytes = hex::decode(&seed_hex).map_err(|e| format!("invalid seed hex: {e}"))?;
    if seed_bytes.len() != 64 {
        return Err(format!("seed must be 64 bytes, got {}", seed_bytes.len()));
    }
    let mut seed = [0u8; 64];
    seed.copy_from_slice(&seed_bytes);

    let mk = MasterKey::from_seed(&seed);
    let keys = mk.derive_bip44(account, 0, 0);

    let view_key = ViewKey(keys.view_secret.to_bytes());
    let spend_pub_bytes = keys.spend_public.compress().to_bytes();
    let _spend_key = SpendKey(keys.spend_secret.to_bytes());

    let mut client = RpcClient::connect(&host, port)?;
    let mut owned_outputs = Vec::new();
    let mut spent_key_images = HashSet::new();
    let mut global_index: u64 = 0;
    let mut scanned_height = start_height.saturating_sub(1);

    // Determine starting global_index by scanning from genesis if start_height > 0
    if start_height > 0 {
        // Get the cumulative output count up to start_height - 1
        // by scanning block at start_height and using its metadata
        // For efficiency, we count outputs in blocks before start_height
        for h in 0..start_height {
            let block = client.get_block_by_height(h)?;
            for tx_blob in &block.transactions {
                if let Ok(tx) = bincode::deserialize::<Transaction>(tx_blob) {
                    global_index += tx.outputs.len() as u64;
                }
            }
        }
    }

    for h in start_height..=end_height {
        let block = match client.get_block_by_height(h) {
            Ok(b) => b,
            Err(_) => break, // Past chain tip
        };
        scanned_height = h;

        for tx_blob in &block.transactions {
            let tx: Transaction = match bincode::deserialize(tx_blob) {
                Ok(tx) => tx,
                Err(_) => continue,
            };

            spent_key_images.extend(tx.inputs.iter().map(|input| input.key_image));

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
                let a_r = view_scalar * big_r;
                let encoded_idx = (out_idx as u64).to_le_bytes();
                let ss = hyphen_crypto::hash::hash_to_scalar(
                    b"Hyphen_ECDH",
                    &[a_r.compress().as_bytes().as_slice(), &encoded_idx].concat(),
                );
                let vt = stealth::compute_view_tag(&ss);
                if vt != out.view_tag {
                    global_index += 1;
                    continue;
                }

                // Full ownership check
                let spend_pub = match decompress(&spend_pub_bytes) {
                    Some(p) => p,
                    None => {
                        global_index += 1;
                        continue;
                    }
                };
                use curve25519_dalek::constants::RISTRETTO_BASEPOINT_POINT as G;
                let expected = ss * G + spend_pub;
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
                owned_outputs.push((
                    WalletOutput {
                        global_index,
                        value: amount,
                        blinding_hex: hex::encode(blinding.to_bytes()),
                        spend_sk_hex: hex::encode(one_time_sk.to_bytes()),
                        one_time_pubkey_hex: hex::encode(out.one_time_pubkey),
                        commitment_hex: hex::encode(out.commitment.as_bytes()),
                        block_height: h,
                    },
                    key_image,
                ));

                global_index += 1;
            }
        }
    }

    let owned_outputs: Vec<WalletOutput> = owned_outputs
        .into_iter()
        .filter_map(|(output, key_image)| {
            (!spent_key_images.contains(&key_image)).then_some(output)
        })
        .collect();
    let total_balance = owned_outputs.iter().try_fold(0u64, |balance, output| {
        balance
            .checked_add(output.value)
            .ok_or_else(|| "wallet balance overflow".to_string())
    })?;
    let output_count = owned_outputs.len() as u64;
    let outputs_json =
        serde_json::to_string(&owned_outputs).map_err(|e| format!("serialize outputs: {e}"))?;

    Ok(ScanResult {
        total_balance,
        output_count,
        scanned_height,
        outputs_json,
    })
}

// ─── Transaction building + submission ──────────────────────

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
    let change = total_selected - total_needed;

    // Parse recipient address
    let dest_addr = HyphenAddress::decode(&recipient_address)?;
    let recipient_stealth = StealthAddress {
        view_public: dest_addr.view_public,
        spend_public: dest_addr.spend_public,
    };

    // Parse sender keys (for change output)
    let seed_bytes = hex::decode(&seed_hex).map_err(|e| format!("invalid seed hex: {e}"))?;
    if seed_bytes.len() != 64 {
        return Err(format!("seed must be 64 bytes, got {}", seed_bytes.len()));
    }
    let mut seed = [0u8; 64];
    seed.copy_from_slice(&seed_bytes);
    let mk = MasterKey::from_seed(&seed);
    let keys = mk.derive_bip44(account, 0, 0);
    let sender_stealth = StealthAddress {
        view_public: keys.view_public.compress().to_bytes(),
        spend_public: keys.spend_public.compress().to_bytes(),
    };

    // Connect to node
    let mut client = RpcClient::connect(&host, port)?;

    // Get chain info for total output count (needed for decoys)
    let chain_info = client.get_chain_info()?;
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

    // Real ring size (number of decoys = ring_size - 1)
    let ring_sz = (ring_size as usize).max(2);
    let num_decoys = ring_sz - 1;

    // Build transaction
    let mut builder = TransactionBuilder::new();
    builder.set_fee(fee);
    builder.set_epoch_seed(&epoch_seed);

    // Pre-flight: verify selected outputs exist on-chain with matching data
    let verify_indices: Vec<u64> = selected.iter().map(|o| o.global_index).collect();
    let chain_outputs = client.get_output_info(verify_indices)?;
    for (wo, co) in selected.iter().zip(chain_outputs.outputs.iter()) {
        if co.one_time_pubkey.is_empty() || co.commitment.is_empty() {
            return Err(format!(
                "output at global_index {} not found on chain — wallet cache may be stale, please re-scan",
                wo.global_index
            ));
        }
        let otp_bytes = hex::decode(&wo.one_time_pubkey_hex)
            .map_err(|e| format!("decode otp for verify: {e}"))?;
        let cm_bytes =
            hex::decode(&wo.commitment_hex).map_err(|e| format!("decode cm for verify: {e}"))?;
        if co.one_time_pubkey != otp_bytes || co.commitment != cm_bytes {
            return Err(format!(
                "output at global_index {} has mismatched data on chain — wallet cache is stale, please re-scan",
                wo.global_index
            ));
        }
    }

    // Add inputs with decoys
    for wo in &selected {
        let decoys = fetch_decoys(
            &mut client,
            num_decoys,
            total_outputs,
            wo.global_index,
            wo.block_height,
            &vre,
        )?;
        let real_index = rand::Rng::gen_range(&mut rand::thread_rng(), 0..=decoys.len());

        let blinding_bytes =
            hex::decode(&wo.blinding_hex).map_err(|e| format!("decode blinding: {e}"))?;
        let spend_sk_bytes =
            hex::decode(&wo.spend_sk_hex).map_err(|e| format!("decode spend_sk: {e}"))?;
        let otp_bytes =
            hex::decode(&wo.one_time_pubkey_hex).map_err(|e| format!("decode otp: {e}"))?;
        let cm_bytes =
            hex::decode(&wo.commitment_hex).map_err(|e| format!("decode commitment: {e}"))?;

        if blinding_bytes.len() != 32
            || spend_sk_bytes.len() != 32
            || otp_bytes.len() != 32
            || cm_bytes.len() != 32
        {
            return Err(format!(
                "wallet output {} contains a non-32-byte cryptographic field",
                wo.global_index
            ));
        }

        let mut blinding = [0u8; 32];
        blinding.copy_from_slice(&blinding_bytes);
        let mut spend_sk = [0u8; 32];
        spend_sk.copy_from_slice(&spend_sk_bytes);
        let mut otp = [0u8; 32];
        otp.copy_from_slice(&otp_bytes);
        let mut cm = [0u8; 32];
        cm.copy_from_slice(&cm_bytes);

        let owned_note = OwnedNote {
            note: Note {
                commitment: hyphen_crypto::pedersen::Commitment(cm),
                one_time_pubkey: otp,
                ephemeral_pubkey: [0u8; 32],
                encrypted_amount: [0u8; 32],
                global_index: wo.global_index,
                block_height: wo.block_height,
            },
            value: wo.value,
            blinding,
            spend_sk,
        };

        builder.add_input(InputSpec {
            owned: owned_note,
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
    let actual_hash = hex::encode(hyphen_crypto::blake3_hash(&built.tx_data).as_bytes());
    if actual_hash != built.tx_hash_hex {
        return Err("persisted transaction hash does not match its signed bytes".into());
    }
    let expected_hash = hex::decode(&built.tx_hash_hex)
        .map_err(|error| format!("persisted transaction hash is invalid hex: {error}"))?;
    Transaction::deserialise_limited(&built.tx_data)
        .map_err(|error| format!("persisted transaction is malformed: {error}"))?;

    let mut client = RpcClient::connect(&host, port)?;
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
    let tx_hash = hex::decode(tx_hash_hex)
        .map_err(|error| format!("invalid transaction hash hex: {error}"))?;
    if tx_hash.len() != 32 {
        return Err(format!(
            "transaction hash must be 32 bytes, got {}",
            tx_hash.len()
        ));
    }

    let mut client = RpcClient::connect(&host, port)?;
    let location = client.get_tx_location(tx_hash.clone())?;
    if location.found {
        if location.block_hash.len() != 32 {
            return Err("node returned an invalid confirmed block hash".into());
        }
        let tip = client.get_chain_info()?.height;
        if location.block_height > tip {
            return Err("node returned a transaction height above its chain tip".into());
        }
        return Ok(TransactionStatus::Confirmed {
            block_hash_hex: hex::encode(location.block_hash),
            block_height: location.block_height,
            confirmations: tip - location.block_height + 1,
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

// ─── Internal helpers ───────────────────────────────────────

fn decompress(bytes: &[u8; 32]) -> Option<RistrettoPoint> {
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
        accumulated += out.value;
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
    exclude_index: u64,
    real_height: u64,
    params: &VreParams,
) -> Result<Vec<(RistrettoPoint, RistrettoPoint, u64)>, String> {
    use rand::seq::SliceRandom;
    use std::collections::{HashMap, HashSet};

    // More retries + larger batches for early/sparse chains
    let max_retries = 16u32;

    for attempt in 0..max_retries {
        // Scale fetch aggressively — for early chains request up to all outputs
        let base = (count as u32 + 4) * (3 + attempt);
        let fetch_count = base.min(256).max(total_outputs.min(256) as u32);
        let resp = client.get_random_outputs(fetch_count, total_outputs)?;

        // Parse all valid candidates with their heights
        let mut candidates: Vec<(RistrettoPoint, RistrettoPoint, u64, u64)> = Vec::new();
        let mut seen_indices = HashSet::new();

        for out in &resp.outputs {
            if out.global_index == exclude_index {
                continue;
            }
            if seen_indices.contains(&out.global_index) {
                continue;
            }
            if out.one_time_pubkey.len() != 32 || out.commitment.len() != 32 {
                continue;
            }
            let mut pk_bytes = [0u8; 32];
            pk_bytes.copy_from_slice(&out.one_time_pubkey);
            let mut cm_bytes = [0u8; 32];
            cm_bytes.copy_from_slice(&out.commitment);

            let pk = match decompress(&pk_bytes) {
                Some(p) => p,
                None => continue,
            };
            let cm = match decompress(&cm_bytes) {
                Some(p) => p,
                None => continue,
            };

            seen_indices.insert(out.global_index);
            candidates.push((pk, cm, out.global_index, out.block_height));
        }

        if candidates.len() < count {
            continue;
        }

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
        remaining.shuffle(&mut rand::thread_rng());

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
    if ring_size < 2 {
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
