// Hyphen Wallet API — Flutter-facing interface via flutter_rust_bridge
//
// This module exposes all wallet operations to the Flutter/Dart layer.
// All functions use simple types (String, Vec<u8>, u32, bool) for
// cross-platform FFI compatibility.
//
// Wallet Features:
//   - BIP39 mnemonic generation and validation (12/15/18/21/24 words)
//   - BIP39 seed derivation (PBKDF2-HMAC-SHA512, 2048 iterations)
//   - ICD key derivation with BIP44 path structure (m/44'/868'/account'/change/index)
//   - Quantum-resistant hybrid signatures (Ed25519 + WOTS+)
//   - Hyphen address generation (hy1... format with blake3 checksum)
//   - Encrypted wallet storage (blake3-XOF stream cipher + MAC)

use crate::address::HyphenAddress;
use crate::bip39;
use crate::crypto;
use crate::keys::{MasterKey, COIN_TYPE};
use crate::wots;

// --- Data structures exposed to Flutter ---

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

/// Hybrid signature result (Ed25519 + WOTS+).
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

// --- BIP39 Mnemonic Operations ---

/// Generate a new BIP39 mnemonic phrase.
///
/// `word_count`: 12, 15, 18, 21, or 24.
/// Returns the mnemonic as a space-separated string.
pub fn generate_mnemonic(word_count: u8) -> Result<String, String> {
    bip39::generate_mnemonic(word_count as usize)
}

/// Validate a BIP39 mnemonic phrase.
///
/// Returns true if the mnemonic is valid (correct word count, valid words,
/// correct checksum).
pub fn validate_mnemonic(mnemonic: String) -> bool {
    bip39::validate_mnemonic(&mnemonic)
}

// --- Wallet Creation and Restoration ---

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

/// Create a wallet with a password that is transformed through a quantum-resistant
/// algorithm before being used as the BIP39 passphrase.
///
/// The password is NOT used directly — it is first passed through WOTS+ hash chains
/// (67 chains × 15 steps of BLAKE3) to produce a quantum-hardened passphrase.
/// This ensures the derived seed is secure even against quantum computers running
/// Grover's algorithm on the BIP39 PBKDF2.
pub fn create_wallet_with_password(password: String) -> Result<WalletCreateResult, String> {
    let mnemonic = bip39::generate_mnemonic(24)?;
    let pq_passphrase = pq_transform_password(&password);
    wallet_from_mnemonic(mnemonic, pq_passphrase)
}

/// Restore a wallet from an existing BIP39 mnemonic.
///
/// `passphrase` is the optional BIP39 passphrase (empty string if not used).
/// If a password was used during creation, it must be the same password here —
/// it will be transformed through the same quantum-resistant algorithm.
pub fn restore_wallet(mnemonic: String, passphrase: String) -> Result<WalletCreateResult, String> {
    if !bip39::validate_mnemonic(&mnemonic) {
        return Err("invalid mnemonic phrase".into());
    }
    wallet_from_mnemonic(mnemonic, passphrase)
}

/// Restore a wallet using the quantum-resistant password transformation.
///
/// The password is transformed through WOTS+ hash chains before being used
/// as the BIP39 passphrase, matching the process used during creation.
pub fn restore_wallet_with_password(
    mnemonic: String,
    password: String,
) -> Result<WalletCreateResult, String> {
    if !bip39::validate_mnemonic(&mnemonic) {
        return Err("invalid mnemonic phrase".into());
    }
    let pq_passphrase = pq_transform_password(&password);
    wallet_from_mnemonic(mnemonic, pq_passphrase)
}

/// Transform a raw password into a quantum-resistant passphrase using WOTS+ hash chains.
///
/// Process:
///   1. Derive a 32-byte seed from the password: BLAKE3("Hyphen_PQ_seed" || password)
///   2. Derive an addr_seed: BLAKE3("Hyphen_PQ_addr" || password)
///   3. Generate 67 WOTS+ chain secrets from the seed
///   4. Run each chain secret through 15 steps of BLAKE3 domain-separated hashing
///   5. Hash all 67 chain endpoints together to produce the final 32-byte passphrase
///   6. Hex-encode the result for use as BIP39 passphrase
///
/// Security: an adversary with a quantum computer would need to invert 67 × 15 = 1005
/// sequential BLAKE3 hash invocations per guess, nullifying Grover's quadratic speedup
/// on the individual hash chain structure.
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
    let seed = bip39::mnemonic_to_seed(&mnemonic, &passphrase);
    let mk = MasterKey::from_seed(&seed);
    let keys = mk.derive_default();

    let view_pub = keys.view_public.compress().to_bytes();
    let spend_pub = keys.spend_public.compress().to_bytes();

    let addr_main = HyphenAddress::new_mainnet(view_pub, spend_pub);
    let addr_test = HyphenAddress::new_testnet(view_pub, spend_pub);

    Ok(WalletCreateResult {
        mnemonic,
        seed_hex: hex::encode(seed),
        address_mainnet: addr_main.encode(),
        address_testnet: addr_test.encode(),
        view_public_hex: hex::encode(view_pub),
        spend_public_hex: hex::encode(spend_pub),
    })
}

// --- Key Derivation (BIP44 Paths) ---

/// Derive keys for a specific BIP44 path: m/44'/868'/account'/change/index.
///
/// `seed_hex` is the hex-encoded 64-byte BIP39 seed.
/// `is_mainnet` determines address format.
pub fn derive_key(
    seed_hex: String,
    account: u32,
    change: u32,
    index: u32,
    is_mainnet: bool,
) -> Result<KeyPairInfo, String> {
    let seed_bytes = hex::decode(&seed_hex).map_err(|e| format!("invalid seed hex: {e}"))?;
    if seed_bytes.len() != 64 {
        return Err(format!("seed must be 64 bytes, got {}", seed_bytes.len()));
    }
    let mut seed = [0u8; 64];
    seed.copy_from_slice(&seed_bytes);

    let mk = MasterKey::from_seed(&seed);
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
    if !bip39::validate_mnemonic(&mnemonic) {
        return Err("invalid mnemonic phrase".into());
    }
    let seed = bip39::mnemonic_to_seed(&mnemonic, &passphrase);
    Ok(hex::encode(seed))
}

// --- Signing Operations (Hybrid Ed25519 + WOTS+) ---

/// Sign a message with hybrid quantum-resistant signature.
///
/// Uses both Ed25519 and WOTS+ to create a dual signature.
/// Even if elliptic curves are broken by quantum computers,
/// the WOTS+ signature remains secure.
pub fn sign_message(
    seed_hex: String,
    account: u32,
    change: u32,
    index: u32,
    message: Vec<u8>,
) -> Result<SignResult, String> {
    let seed_bytes = hex::decode(&seed_hex).map_err(|e| format!("invalid seed hex: {e}"))?;
    if seed_bytes.len() != 64 {
        return Err(format!("seed must be 64 bytes, got {}", seed_bytes.len()));
    }
    let mut seed = [0u8; 64];
    seed.copy_from_slice(&seed_bytes);

    let mk = MasterKey::from_seed(&seed);
    let keys = mk.derive_bip44(account, change, index);

    // Derive Ed25519 signing key
    let ed_seed: [u8; 32] =
        *crypto::blake3_hash_many(&[b"Hyphen_ed25519_derive", keys.spend_secret.as_bytes()])
            .as_bytes();
    let ed_sk = ed25519_dalek::SigningKey::from_bytes(&ed_seed);

    // Derive WOTS+ signing key
    let wots_seed: [u8; 32] =
        *crypto::blake3_hash_many(&[b"Hyphen_WOTS_derive_seed", keys.spend_secret.as_bytes()])
            .as_bytes();
    let wots_addr: [u8; 32] =
        *crypto::blake3_hash_many(&[b"Hyphen_WOTS_derive_addr", keys.spend_secret.as_bytes()])
            .as_bytes();
    let wots_sk = wots::WotsSecretKey::from_seed(wots_seed, wots_addr);

    // Create hybrid signature
    let hybrid = wots::HybridSignature::sign(&message, &ed_sk, &wots_sk);

    Ok(SignResult {
        ed25519_signature_hex: hex::encode(hybrid.ed25519_sig),
        ed25519_public_hex: hex::encode(hybrid.ed25519_pubkey),
        wots_signature_hex: hex::encode(hybrid.wots_sig.to_bytes()),
        wots_public_hash_hex: hex::encode(hybrid.wots_pubkey.key_hash),
        wots_addr_seed_hex: hex::encode(hybrid.wots_pubkey.addr_seed),
    })
}

/// Verify a hybrid signature.
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

// --- Address Validation ---

/// Validate a Hyphen address string.
pub fn validate_address(address: String) -> bool {
    HyphenAddress::decode(&address).is_ok()
}

/// Check if an address is mainnet.
pub fn is_mainnet_address(address: String) -> Result<bool, String> {
    let addr = HyphenAddress::decode(&address)?;
    Ok(addr.is_mainnet())
}

// --- Encrypted Wallet Storage ---

/// Encrypt wallet data (mnemonic) with a password.
///
/// Format: [salt:32] [mac:32] [ciphertext:N]
/// KDF: 100,000 iterations of blake3
/// Cipher: blake3-XOF stream cipher
/// MAC: blake3 keyed hash (encrypt-then-MAC)
pub fn encrypt_wallet(mnemonic: String, password: String) -> Vec<u8> {
    let data = mnemonic.as_bytes();

    // Generate random salt
    let mut salt = [0u8; 32];
    rand::RngCore::fill_bytes(&mut rand::rngs::OsRng, &mut salt);

    // Derive encryption key
    let key = derive_wallet_key(password.as_bytes(), &salt);

    // Encrypt
    let ciphertext = xof_encrypt(&key, data);

    // Compute MAC over ciphertext
    let mac = crypto::blake3_keyed(&key, &ciphertext);

    // Assemble output: salt || mac || ciphertext
    let mut out = Vec::with_capacity(32 + 32 + ciphertext.len());
    out.extend_from_slice(&salt);
    out.extend_from_slice(mac.as_bytes());
    out.extend_from_slice(&ciphertext);
    out
}

/// Decrypt wallet data with a password.
///
/// Returns the mnemonic string if the password is correct.
pub fn decrypt_wallet(encrypted_data: Vec<u8>, password: String) -> Result<String, String> {
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

    // Derive key
    let key = derive_wallet_key(password.as_bytes(), &salt);

    // Verify MAC before decryption
    let computed_mac = crypto::blake3_keyed(&key, ciphertext);
    if computed_mac.as_bytes() != &stored_mac {
        return Err("wrong password or corrupted data".into());
    }

    // Decrypt
    let plaintext = xof_encrypt(&key, ciphertext);
    String::from_utf8(plaintext).map_err(|e| format!("invalid utf8: {e}"))
}

/// Derive encryption key from password and salt using iterated blake3.
fn derive_wallet_key(password: &[u8], salt: &[u8; 32]) -> [u8; 32] {
    let mut state = crypto::blake3_hash(&[salt.as_slice(), password].concat());
    for _ in 0..100_000 {
        state = crypto::blake3_hash(state.as_bytes());
    }
    *state.as_bytes()
}

/// Symmetric encryption/decryption using blake3 XOF as a stream cipher.
fn xof_encrypt(key: &[u8; 32], data: &[u8]) -> Vec<u8> {
    let mut h = blake3::Hasher::new_keyed(key);
    h.update(b"Hyphen_wallet_stream");
    let mut stream = h.finalize_xof();
    let mut keystream = vec![0u8; data.len()];
    stream.fill(&mut keystream);
    let mut out = vec![0u8; data.len()];
    for (i, b) in data.iter().enumerate() {
        out[i] = b ^ keystream[i];
    }
    out
}

// --- Utility Functions ---

/// Get wallet version info.
pub fn wallet_version() -> String {
    "Hyphen Wallet v0.1.0 (BIP39/BIP44/ICD/WOTS+)".to_string()
}

/// Get the coin type used for BIP44 derivation.
pub fn get_coin_type() -> u32 {
    COIN_TYPE
}

/// Hash arbitrary data with blake3 (utility).
pub fn blake3_hash(data: Vec<u8>) -> String {
    hex::encode(crypto::blake3_hash(&data).as_bytes())
}

// --- Transfer Operations ---

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
pub fn scan_wallet_outputs(
    host: String,
    port: u16,
    seed_hex: String,
    account: u32,
    start_height: u64,
    end_height: u64,
    is_mainnet: bool,
) -> Result<WalletScanResult, String> {
    let result = crate::transfer::scan_wallet_outputs(
        host,
        port,
        seed_hex,
        account,
        start_height,
        end_height,
        is_mainnet,
    )?;
    Ok(WalletScanResult {
        total_balance: result.total_balance,
        output_count: result.output_count,
        scanned_height: result.scanned_height,
        outputs_json: result.outputs_json,
    })
}

/// Build and send a shielded transaction.
///
/// Selects inputs from owned outputs, fetches decoys for ring signatures,
/// constructs a CLSAG-signed transaction with range proofs, and submits
/// it to the node.
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
    let result = crate::transfer::build_and_send_transaction(
        host,
        port,
        seed_hex,
        account,
        recipient_address,
        amount,
        fee,
        owned_outputs_json,
        ring_size,
    )?;
    Ok(TransactionSendResult {
        tx_hash_hex: result.tx_hash_hex,
        accepted: result.accepted,
        error_message: result.error_message,
        spent_indices_csv: result.spent_indices_csv,
        vre_used_adaptive: result.vre_used_adaptive,
    })
}
