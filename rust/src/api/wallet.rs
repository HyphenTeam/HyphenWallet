// Hyphen Wallet API — Flutter-facing interface via flutter_rust_bridge
//
// This module exposes all wallet operations to the Flutter/Dart layer.
// All functions use simple types (String, Vec<u8>, u32, bool) for
// cross-platform FFI compatibility.
//
// Wallet Features:
//   - Versioned recovery words and historical BIP39 seed recovery
//   - ICD key derivation with BIP44 path structure (m/44'/868'/account'/change/index)
//   - Experimental Ed25519 + WOTS message-signature encoding
//   - Hyphen address generation (hy1... format with blake3 checksum)
//   - Versioned Argon2id + XChaCha20-Poly1305 wallet storage

use crate::address::HyphenAddress;
use crate::bip39;
use crate::crypto;
use crate::keys::{COIN_TYPE, MasterKey};
use crate::wots;
use rand::Rng;
use zeroize::Zeroizing;

/// Complete wallet creation result.
pub struct WalletCreateResult {
    pub mnemonic: String,
    pub seed_hex: String,
    pub address_mainnet: String,
    pub address_testnet: String,
    pub view_public_hex: String,
    pub spend_public_hex: String,
}

/// Key pair information for a derived path.
pub struct KeyPairInfo {
    pub address: String,
    pub view_public_hex: String,
    pub spend_public_hex: String,
    pub ed25519_public_hex: String,
    pub wots_public_hash_hex: String,
}

/// Experimental dual-signature result (Ed25519 + WOTS).
pub struct SignResult {
    pub ed25519_signature_hex: String,
    pub ed25519_public_hex: String,
    pub wots_signature_hex: String,
    pub wots_public_hash_hex: String,
    pub wots_addr_seed_hex: String,
}

/// Encrypted wallet file data.
pub struct EncryptedWallet {
    pub data: Vec<u8>,
}

/// Generate a marked HYN3 recovery phrase.
///
/// `word_count`: 12, 15, 18, 21, or 24.
/// Returns the mnemonic as a space-separated string.
pub fn generate_mnemonic(word_count: u8) -> Result<String, String> {
    bip39::generate_mnemonic(word_count as usize)
}

/// Validate marked HYN3 words or an unmarked historical phrase.
///
/// Returns true if the mnemonic is valid (correct word count, valid words,
/// correct checksum).
pub fn validate_mnemonic(mnemonic: String) -> bool {
    bip39::validate_mnemonic(&Zeroizing::new(mnemonic))
}

/// Create a new wallet with a fresh 24-word mnemonic.
///
/// Returns the mnemonic phrase and default account addresses.
pub fn create_wallet() -> Result<WalletCreateResult, String> {
    let mnemonic = bip39::generate_mnemonic(24)?;
    wallet_from_mnemonic(mnemonic, String::new())
}

/// Create a new wallet with a specific word count (12 or 24).
pub fn create_wallet_with_word_count(word_count: u8) -> Result<WalletCreateResult, String> {
    let mnemonic = bip39::generate_mnemonic(word_count as usize)?;
    wallet_from_mnemonic(mnemonic, String::new())
}

/// Create a wallet with a fresh HYN3 recovery phrase and a recovery password.
pub fn create_wallet_with_password(password: String) -> Result<WalletCreateResult, String> {
    let mnemonic = bip39::generate_mnemonic(24)?;
    wallet_from_mnemonic(mnemonic, password)
}

/// Restore a wallet with its derivation passphrase.
///
/// `restore_wallet_with_password` accepts the original Flutter password.
pub fn restore_wallet(mnemonic: String, passphrase: String) -> Result<WalletCreateResult, String> {
    wallet_from_mnemonic(mnemonic, passphrase)
}

/// Restore from the original password, selecting the derivation by phrase format.
pub fn restore_wallet_with_password(
    mnemonic: String,
    password: String,
) -> Result<WalletCreateResult, String> {
    if mnemonic.starts_with(bip39::PREFIX) {
        return wallet_from_mnemonic(mnemonic, password);
    }
    let password = Zeroizing::new(password);
    let pq_passphrase = pq_transform_password(&password);
    wallet_from_mnemonic(mnemonic, pq_passphrase)
}

/// Historical deterministic password-to-passphrase transform.
///
/// Process:
///   1. Derive a 32-byte seed from the password: BLAKE3("Hyphen_PQ_seed" || password)
///   2. Derive an addr_seed: BLAKE3("Hyphen_PQ_addr" || password)
///   3. Generate 67 WOTS+ chain secrets from the seed
///   4. Run each chain secret through 15 steps of BLAKE3 domain-separated hashing
///   5. Hash all 67 chain endpoints together to produce the final 32-byte passphrase
///   6. Hex-encode the result for use as BIP39 passphrase
///
/// This function exists for deterministic wallet recovery compatibility. It is
/// not a password KDF and does not increase the source password's entropy.
pub fn pq_transform_password(password: &str) -> String {
    let seed = crypto::blake3_hash_many(&[b"Hyphen_PQ_seed", password.as_bytes()]);
    let addr_seed = crypto::blake3_hash_many(&[b"Hyphen_PQ_addr", password.as_bytes()]);

    let wots_sk = wots::WotsSecretKey::from_seed(*seed.as_bytes(), *addr_seed.as_bytes());
    let wots_pk = wots_sk.public_key();

    let final_hash = crypto::blake3_hash_many(&[
        b"Hyphen_PQ_passphrase",
        &wots_pk.key_hash,
        &wots_pk.addr_seed,
    ]);

    hex::encode(final_hash.as_bytes())
}

fn wallet_from_mnemonic(
    mnemonic: String,
    passphrase: String,
) -> Result<WalletCreateResult, String> {
    let mut mnemonic = Zeroizing::new(mnemonic);
    let passphrase = Zeroizing::new(passphrase);
    let seed = recovery_seed(&mnemonic, &passphrase)?;
    let mk = MasterKey::from_seed(&seed);
    let keys = mk.derive_default();

    let view_pub = keys.view_public.compress().to_bytes();
    let spend_pub = keys.spend_public.compress().to_bytes();

    let addr_main = HyphenAddress::new_mainnet(view_pub, spend_pub);
    let addr_test = HyphenAddress::new_testnet(view_pub, spend_pub);

    Ok(WalletCreateResult {
        mnemonic: std::mem::take(&mut *mnemonic),
        seed_hex: hex::encode(seed.as_slice()),
        address_mainnet: addr_main.encode(),
        address_testnet: addr_test.encode(),
        view_public_hex: hex::encode(view_pub),
        spend_public_hex: hex::encode(spend_pub),
    })
}

/// Derive keys for a specific BIP44 path: m/44'/868'/account'/change/index.
///
/// `seed_hex` encodes the 64-byte wallet seed.
/// `is_mainnet` determines address format.
pub fn derive_key(
    seed_hex: String,
    account: u32,
    change: u32,
    index: u32,
    is_mainnet: bool,
) -> Result<KeyPairInfo, String> {
    let mk = MasterKey::from_hex(seed_hex)?;
    let keys = mk.derive_bip44(account, change, index);

    let view_pub = keys.view_public.compress().to_bytes();
    let spend_pub = keys.spend_public.compress().to_bytes();

    let addr = if is_mainnet {
        HyphenAddress::new_mainnet(view_pub, spend_pub)
    } else {
        HyphenAddress::new_testnet(view_pub, spend_pub)
    };

    // Derive Ed25519 key from spend secret
    let ed_seed: [u8; 32] =
        *crypto::blake3_hash_many(&[b"Hyphen_ed25519_derive", keys.spend_secret.as_bytes()])
            .as_bytes();
    let ed_sk = ed25519_dalek::SigningKey::from_bytes(&ed_seed);
    let ed_pk = ed_sk.verifying_key();

    // Derive WOTS+ key from spend secret
    let wots_seed: [u8; 32] =
        *crypto::blake3_hash_many(&[b"Hyphen_WOTS_derive_seed", keys.spend_secret.as_bytes()])
            .as_bytes();
    let wots_addr: [u8; 32] =
        *crypto::blake3_hash_many(&[b"Hyphen_WOTS_derive_addr", keys.spend_secret.as_bytes()])
            .as_bytes();
    let wots_sk = wots::WotsSecretKey::from_seed(wots_seed, wots_addr);
    let wots_pk = wots_sk.public_key();

    Ok(KeyPairInfo {
        address: addr.encode(),
        view_public_hex: hex::encode(view_pub),
        spend_public_hex: hex::encode(spend_pub),
        ed25519_public_hex: hex::encode(ed_pk.to_bytes()),
        wots_public_hash_hex: hex::encode(wots_pk.key_hash),
    })
}

/// Get the default address (account=0, change=0, index=0).
pub fn get_default_address(seed_hex: String, is_mainnet: bool) -> Result<String, String> {
    let info = derive_key(seed_hex, 0, 0, 0, is_mainnet)?;
    Ok(info.address)
}

/// Get the BIP44 derivation path string for display.
pub fn get_derivation_path(account: u32, change: u32, index: u32) -> String {
    format!("m/44'/{COIN_TYPE}'/{account}'/{change}/{index}")
}

/// Derive a seed from mnemonic (returns hex-encoded 64-byte seed).
pub fn mnemonic_to_seed_hex(mnemonic: String, passphrase: String) -> Result<String, String> {
    let mnemonic = zeroize::Zeroizing::new(mnemonic);
    let passphrase = zeroize::Zeroizing::new(passphrase);
    let seed = recovery_seed(&mnemonic, &passphrase)?;
    Ok(hex::encode(seed.as_slice()))
}

fn recovery_seed(phrase: &str, passphrase: &str) -> Result<Zeroizing<[u8; 64]>, String> {
    if !bip39::validate_mnemonic(phrase) {
        return Err("invalid mnemonic phrase".into());
    }
    if !phrase.starts_with(bip39::PREFIX) {
        return Ok(Zeroizing::new(bip39::mnemonic_to_seed(phrase, passphrase)));
    }
    let salt = Zeroizing::new(blake3::derive_key(
        "Hyphen recovery salt v3",
        phrase.as_bytes(),
    ));
    let key = derive_argon2id_key(passphrase.as_bytes(), salt[..16].try_into().unwrap())?;
    let mut expand = blake3::Hasher::new_keyed(&key);
    expand.update(b"Hyphen recovery seed v3\0");
    expand.update(phrase.as_bytes());
    let mut seed = Zeroizing::new([0; 64]);
    expand.finalize_xof().fill(seed.as_mut_slice());
    Ok(seed)
}

/// Retained for bridge compatibility. The stateless WOTS signer is disabled.
pub fn sign_message(
    seed_hex: String,
    account: u32,
    change: u32,
    index: u32,
    message: Vec<u8>,
) -> Result<SignResult, String> {
    drop((seed_hex, account, change, index, message));
    Err("WOTS message signing requires persistent one-time key management".into())
}

/// Verify the syntax and equations of an experimental dual signature.
pub fn verify_signature(
    message: Vec<u8>,
    ed25519_signature_hex: String,
    ed25519_public_hex: String,
    wots_signature_hex: String,
    wots_public_hash_hex: String,
    wots_addr_seed_hex: String,
) -> Result<bool, String> {
    let ed_sig_bytes =
        hex::decode(&ed25519_signature_hex).map_err(|e| format!("invalid ed25519 sig hex: {e}"))?;
    let ed_pub_bytes =
        hex::decode(&ed25519_public_hex).map_err(|e| format!("invalid ed25519 pub hex: {e}"))?;
    let wots_sig_bytes =
        hex::decode(&wots_signature_hex).map_err(|e| format!("invalid wots sig hex: {e}"))?;
    let wots_hash_bytes =
        hex::decode(&wots_public_hash_hex).map_err(|e| format!("invalid wots hash hex: {e}"))?;
    let wots_addr_bytes =
        hex::decode(&wots_addr_seed_hex).map_err(|e| format!("invalid wots addr hex: {e}"))?;

    if ed_sig_bytes.len() != 64 {
        return Err("ed25519 signature must be 64 bytes".into());
    }
    if ed_pub_bytes.len() != 32 {
        return Err("ed25519 public key must be 32 bytes".into());
    }
    if wots_hash_bytes.len() != 32 {
        return Err("wots public key hash must be 32 bytes".into());
    }
    if wots_addr_bytes.len() != 32 {
        return Err("wots addr seed must be 32 bytes".into());
    }

    let mut ed_sig = [0u8; 64];
    ed_sig.copy_from_slice(&ed_sig_bytes);
    let mut ed_pub = [0u8; 32];
    ed_pub.copy_from_slice(&ed_pub_bytes);
    let mut wots_hash = [0u8; 32];
    wots_hash.copy_from_slice(&wots_hash_bytes);
    let mut wots_addr = [0u8; 32];
    wots_addr.copy_from_slice(&wots_addr_bytes);

    let hybrid = wots::HybridSignature {
        ed25519_sig: ed_sig,
        ed25519_pubkey: ed_pub,
        wots_sig: wots::WotsSignature::from_bytes(&wots_sig_bytes)?,
        wots_pubkey: wots::WotsPublicKey {
            key_hash: wots_hash,
            addr_seed: wots_addr,
        },
    };

    match hybrid.verify(&message) {
        Ok(()) => Ok(true),
        Err(_) => Ok(false),
    }
}

/// Validate a Hyphen address string.
pub fn validate_address(address: String) -> bool {
    HyphenAddress::decode(&address).is_ok()
}

/// Check if an address is mainnet.
pub fn is_mainnet_address(address: String) -> Result<bool, String> {
    let addr = HyphenAddress::decode(&address)?;
    Ok(addr.is_mainnet())
}

const WALLET_MAGIC: &[u8; 8] = b"HYWLT001";
const WALLET_HEADER_LEN: usize = 64;
const WALLET_SALT_LEN: usize = 16;
const WALLET_NONCE_LEN: usize = 24;
const WALLET_ARGON2_MEMORY_KIB: u32 = 65_536;
const WALLET_ARGON2_ITERATIONS: u32 = 3;
const WALLET_ARGON2_LANES: u32 = 1;

/// Encrypt a mnemonic using a versioned Argon2id + XChaCha20-Poly1305 envelope.
pub fn encrypt_wallet(mnemonic: String, password: String) -> Result<Vec<u8>, String> {
    use chacha20poly1305::aead::{Aead, KeyInit, Payload};
    use chacha20poly1305::{XChaCha20Poly1305, XNonce};

    let password = Zeroizing::new(password);
    let mnemonic = Zeroizing::new(mnemonic);
    let mut salt = [0u8; WALLET_SALT_LEN];
    let mut nonce = [0u8; WALLET_NONCE_LEN];
    rand::rng().fill_bytes(&mut salt);
    rand::rng().fill_bytes(&mut nonce);

    let mut header = Vec::with_capacity(WALLET_HEADER_LEN);
    header.extend_from_slice(WALLET_MAGIC);
    header.extend_from_slice(&[1, 1, 1, 0]);
    header.extend_from_slice(&WALLET_ARGON2_MEMORY_KIB.to_be_bytes());
    header.extend_from_slice(&WALLET_ARGON2_ITERATIONS.to_be_bytes());
    header.extend_from_slice(&WALLET_ARGON2_LANES.to_be_bytes());
    header.extend_from_slice(&salt);
    header.extend_from_slice(&nonce);
    debug_assert_eq!(header.len(), WALLET_HEADER_LEN);

    let key = derive_argon2id_key(password.as_bytes(), &salt)?;
    let cipher = XChaCha20Poly1305::new((&*key).into());
    let nonce = XNonce::from(nonce);
    let ciphertext = cipher
        .encrypt(
            &nonce,
            Payload {
                msg: mnemonic.as_bytes(),
                aad: &header,
            },
        )
        .map_err(|_| "wallet encryption failed".to_string())?;
    header.extend_from_slice(&ciphertext);
    Ok(header)
}

/// Decrypt the current wallet format or the historical read-only format.
pub fn decrypt_wallet(encrypted_data: Vec<u8>, password: String) -> Result<String, String> {
    let password = Zeroizing::new(password);
    if encrypted_data.starts_with(WALLET_MAGIC) {
        decrypt_current_wallet(&encrypted_data, password.as_bytes())
    } else {
        decrypt_legacy_wallet(&encrypted_data, password.as_bytes())
    }
}

fn decrypt_current_wallet(encrypted_data: &[u8], password: &[u8]) -> Result<String, String> {
    use chacha20poly1305::aead::{Aead, KeyInit, Payload};
    use chacha20poly1305::{XChaCha20Poly1305, XNonce};

    if encrypted_data.len() < WALLET_HEADER_LEN + 16 {
        return Err("encrypted wallet is truncated".into());
    }
    if encrypted_data[8..12] != [1, 1, 1, 0] {
        return Err("unsupported encrypted-wallet format".into());
    }
    let memory_kib = u32::from_be_bytes(encrypted_data[12..16].try_into().unwrap());
    let iterations = u32::from_be_bytes(encrypted_data[16..20].try_into().unwrap());
    let lanes = u32::from_be_bytes(encrypted_data[20..24].try_into().unwrap());
    if memory_kib != WALLET_ARGON2_MEMORY_KIB
        || iterations != WALLET_ARGON2_ITERATIONS
        || lanes != WALLET_ARGON2_LANES
    {
        return Err("unsupported encrypted-wallet KDF parameters".into());
    }
    let salt: [u8; WALLET_SALT_LEN] = encrypted_data[24..40].try_into().unwrap();
    let nonce: [u8; WALLET_NONCE_LEN] = encrypted_data[40..64].try_into().unwrap();
    let key = derive_argon2id_key(password, &salt)?;
    let cipher = XChaCha20Poly1305::new((&*key).into());
    let nonce = XNonce::from(nonce);
    let plaintext = cipher
        .decrypt(
            &nonce,
            Payload {
                msg: &encrypted_data[WALLET_HEADER_LEN..],
                aad: &encrypted_data[..WALLET_HEADER_LEN],
            },
        )
        .map_err(|_| "wrong password or corrupted data".to_string());
    wallet_text(plaintext?)
}

fn derive_argon2id_key(
    password: &[u8],
    salt: &[u8; WALLET_SALT_LEN],
) -> Result<Zeroizing<[u8; 32]>, String> {
    use argon2::{Algorithm, Argon2, Params, Version};

    let params = Params::new(
        WALLET_ARGON2_MEMORY_KIB,
        WALLET_ARGON2_ITERATIONS,
        WALLET_ARGON2_LANES,
        Some(32),
    )
    .map_err(|error| format!("invalid wallet KDF parameters: {error}"))?;
    let password_digest = Zeroizing::new(blake3::derive_key(
        "Hyphen wallet password prehash v1",
        password,
    ));
    let mut key = Zeroizing::new([0u8; 32]);
    Argon2::new(Algorithm::Argon2id, Version::V0x13, params)
        .hash_password_into(password_digest.as_slice(), salt, key.as_mut_slice())
        .map_err(|error| format!("wallet KDF failed: {error}"))?;
    Ok(key)
}

fn decrypt_legacy_wallet(encrypted_data: &[u8], password: &[u8]) -> Result<String, String> {
    use subtle::ConstantTimeEq;

    if encrypted_data.len() < 64 {
        return Err("encrypted data too short".into());
    }
    let salt: [u8; 32] = encrypted_data[..32]
        .try_into()
        .map_err(|_| "invalid salt")?;
    let stored_mac: [u8; 32] = encrypted_data[32..64]
        .try_into()
        .map_err(|_| "invalid mac")?;
    let ciphertext = &encrypted_data[64..];
    let key = Zeroizing::new(derive_legacy_wallet_key(password, &salt));
    let computed_mac = crypto::blake3_keyed(&key, ciphertext);
    if computed_mac.as_bytes().ct_eq(&stored_mac).unwrap_u8() != 1 {
        return Err("wrong password or corrupted data".into());
    }
    let plaintext = legacy_xof_encrypt(&key, ciphertext);
    wallet_text(plaintext)
}

fn wallet_text(bytes: Vec<u8>) -> Result<String, String> {
    String::from_utf8(bytes).map_err(|error| {
        use zeroize::Zeroize;
        error.into_bytes().zeroize();
        "wallet plaintext is not valid UTF-8".into()
    })
}

fn derive_legacy_wallet_key(password: &[u8], salt: &[u8; 32]) -> [u8; 32] {
    let mut state = crypto::blake3_hash_many(&[salt, password]);
    for _ in 0..100_000 {
        state = crypto::blake3_hash(state.as_bytes());
    }
    *state.as_bytes()
}

/// Symmetric encryption/decryption using blake3 XOF as a stream cipher.
fn legacy_xof_encrypt(key: &[u8; 32], data: &[u8]) -> Vec<u8> {
    let mut h = blake3::Hasher::new_keyed(key);
    h.update(b"Hyphen_wallet_stream");
    let mut stream = h.finalize_xof();
    let mut out = vec![0u8; data.len()];
    stream.fill(&mut out);
    for (byte, input) in out.iter_mut().zip(data) {
        *byte ^= input;
    }
    out
}

/// Get wallet version info.
pub fn wallet_version() -> String {
    "Hyphen Wallet v0.1.0 (experimental)".to_string()
}

/// Get the coin type used for BIP44 derivation.
pub fn get_coin_type() -> u32 {
    COIN_TYPE
}

/// Hash arbitrary data with blake3 (utility).
pub fn blake3_hash(data: Vec<u8>) -> String {
    hex::encode(crypto::blake3_hash(&data).as_bytes())
}

/// Result of a chain status query.
pub struct ChainStatusResult {
    pub height: u64,
    pub total_outputs: u64,
    pub tip_hash_hex: String,
}

/// Result of a wallet scan.
pub struct WalletScanResult {
    pub total_balance: u64,
    pub output_count: u64,
    pub scanned_height: u64,
    pub scanned_hash_hex: String,
    pub outputs_json: String,
}

/// Result of a transaction send.
pub struct TransactionSendResult {
    pub tx_hash_hex: String,
    pub accepted: bool,
    pub error_message: String,
    pub spent_indices_csv: String,
    pub vre_used_adaptive: bool,
}

/// Query the chain status from a node.
pub fn get_chain_status(host: String, port: u16) -> Result<ChainStatusResult, String> {
    let status = crate::transfer::get_chain_status(host, port)?;
    Ok(ChainStatusResult {
        height: status.height,
        total_outputs: status.total_outputs,
        tip_hash_hex: status.tip_hash_hex,
    })
}

/// Scan the blockchain for wallet-owned outputs.
///
/// Downloads blocks from `start_height` to `end_height`, checking each
/// output against the wallet's view key. Returns owned outputs as JSON.
#[allow(clippy::too_many_arguments)]
pub fn scan_wallet_outputs(
    host: String,
    port: u16,
    seed_hex: String,
    account: u32,
    start_height: u64,
    end_height: u64,
    is_mainnet: bool,
    cache_directory: Option<String>,
) -> Result<WalletScanResult, String> {
    let result = crate::transfer::scan_outputs_in(
        host,
        port,
        seed_hex,
        account,
        start_height..=end_height,
        crate::transfer::ScanNetwork::AddressClass { is_mainnet },
        cache_directory.as_deref().map(std::path::Path::new),
    )?;
    Ok(WalletScanResult {
        total_balance: result.total_balance,
        output_count: result.output_count,
        scanned_height: result.scanned_height,
        scanned_hash_hex: result.scanned_hash_hex,
        outputs_json: result.outputs_json,
    })
}

/// Build and send a shielded transaction.
///
/// Selects inputs from owned outputs, fetches decoys for ring signatures,
/// constructs a CLSAG-signed transaction with range proofs, and submits
/// it to the node.
#[allow(clippy::too_many_arguments)]
pub fn send_transaction(
    host: String,
    port: u16,
    seed_hex: String,
    account: u32,
    recipient_address: String,
    amount: u64,
    fee: u64,
    owned_outputs_json: String,
    ring_size: u32,
) -> Result<TransactionSendResult, String> {
    let result =
        crate::transfer::build_and_send_transaction(crate::transfer::TransactionRequest {
            host,
            port,
            seed_hex,
            account,
            recipient_address,
            amount,
            fee,
            owned_outputs_json,
            ring_size,
        })?;
    Ok(TransactionSendResult {
        tx_hash_hex: result.tx_hash_hex,
        accepted: result.accepted,
        error_message: result.error_message,
        spent_indices_csv: result.spent_indices_csv,
        vre_used_adaptive: result.vre_used_adaptive,
    })
}

#[cfg(test)]
mod encrypted_wallet_tests {
    use super::*;

    const MNEMONIC: &str = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    #[test]
    fn stateless_message_signing_refuses_a_valid_derivation_path() {
        let result = sign_message(hex::encode([42; 64]), 0, 0, 0, b"fixture".to_vec());
        assert!(matches!(result, Err(reason) if reason.contains("one-time key management")));
    }

    #[test]
    fn flutter_password_restores_the_historical_receiving_address() {
        let wallet =
            restore_wallet(MNEMONIC.into(), pq_transform_password("public-fixture")).unwrap();
        assert_eq!(
            wallet.seed_hex,
            "06cf316d51866398b413ce1635c8cf3ee0dc5956ee9feaceb4ad00f83085adddb8725f92df511a50cb8b10641557ed2ded2620348a493ac2679a245d7283eb79"
        );
        assert_eq!(
            wallet.address_testnet,
            "hy12LqVc3VPiSoMTgxpVubj4yusXPYoFKERshuLsEWD88ZXRKwPEeLcgBXoJck7CQ1FTBhjdtVttHmTFBewYeR7VDtxSvKkeE"
        );
        let different =
            restore_wallet_with_password(MNEMONIC.into(), "different-fixture".into()).unwrap();
        assert_ne!(wallet.address_testnet, different.address_testnet);
    }

    #[test]
    fn marked_recovery_matches_independent_kdf_and_survives_encrypted_migration() {
        let phrase = "hy3-abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon able-hy3";
        let pass = "TREZOR";
        let restored = restore_wallet_with_password(phrase.into(), pass.into()).unwrap();
        assert_eq!(
            restored.seed_hex,
            "4d843009d9de540b8cdbaf0b879a8f2a25547c6785f089bca003b5c0fec683f7b0f30d76167c721aa1d27cce1b7830dc718510c0e6d902dbce0fae31a6d6f87d"
        );
        let envelope = encrypt_wallet(phrase.into(), pass.into()).unwrap();
        let decoded = decrypt_wallet(envelope, pass.into()).unwrap();
        let reopened = restore_wallet_with_password(decoded, pass.into()).unwrap();
        assert_eq!(restored.address_testnet, reopened.address_testnet);
        assert_ne!(
            restored.address_testnet,
            restore_wallet_with_password(phrase.into(), "other".into())
                .unwrap()
                .address_testnet
        );
    }

    #[test]
    fn current_envelope_roundtrips_and_authenticates_every_byte() {
        let encrypted = encrypt_wallet(MNEMONIC.into(), "correct horse".into()).unwrap();
        assert!(encrypted.starts_with(WALLET_MAGIC));
        assert_eq!(
            decrypt_wallet(encrypted.clone(), "correct horse".into()).unwrap(),
            MNEMONIC
        );
        assert!(decrypt_wallet(encrypted.clone(), "wrong password".into()).is_err());

        let mut tampered_header = encrypted.clone();
        tampered_header[40] ^= 1;
        assert!(decrypt_wallet(tampered_header, "correct horse".into()).is_err());

        let mut tampered_ciphertext = encrypted;
        *tampered_ciphertext.last_mut().unwrap() ^= 1;
        assert!(decrypt_wallet(tampered_ciphertext, "correct horse".into()).is_err());
    }

    #[test]
    fn encryption_uses_fresh_salt_and_nonce() {
        let first = encrypt_wallet(MNEMONIC.into(), "password".into()).unwrap();
        let second = encrypt_wallet(MNEMONIC.into(), "password".into()).unwrap();
        assert_ne!(first, second);
    }

    #[test]
    fn historical_envelope_remains_readable_for_migration() {
        let password = b"legacy password";
        let salt = [7u8; 32];
        let key = derive_legacy_wallet_key(password, &salt);
        let ciphertext = legacy_xof_encrypt(&key, MNEMONIC.as_bytes());
        let mac = crypto::blake3_keyed(&key, &ciphertext);
        let mut envelope = Vec::new();
        envelope.extend_from_slice(&salt);
        envelope.extend_from_slice(mac.as_bytes());
        envelope.extend_from_slice(&ciphertext);

        let password = String::from_utf8(password.to_vec()).unwrap();
        let decoded = decrypt_wallet(envelope, password.clone()).unwrap();
        assert_eq!(decoded, MNEMONIC);
        let original = restore_wallet_with_password(decoded.clone(), password.clone()).unwrap();
        let current = encrypt_wallet(decoded, password.clone()).unwrap();
        assert!(current.starts_with(WALLET_MAGIC));
        let reopened = decrypt_wallet(current, password.clone()).unwrap();
        assert_eq!(
            restore_wallet_with_password(reopened, password)
                .unwrap()
                .address_testnet,
            original.address_testnet
        );
    }
}
