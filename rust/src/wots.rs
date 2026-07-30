// Experimental Winternitz one-time signature implementation.
//
// Compatible with the Hyphen chain's pq.rs implementation.
//
// Parameters:
//   w = 16 (Winternitz parameter)
//   chains = 67 (64 message + 3 checksum)
//   hash = blake3 with domain separation
//   chain max = w - 1 = 15
//
// Signature size: 67 × 32 + 32 = 2,176 bytes
// Public key: 32 bytes (hash of all chain endpoints) + 32 bytes (addr_seed) = 64 bytes
//
// Security claims require an authenticated public key and strict one-time key
// use; this module alone supplies neither lifecycle guarantee.

use serde::{Deserialize, Serialize};
use zeroize::Zeroize;

use crate::crypto::{blake3_hash, blake3_hash_many};

const WOTS_W: usize = 16;
const WOTS_LOG_W: usize = 4;
const WOTS_LEN1: usize = 64; // 256 / log2(w) = 256/4
const WOTS_LEN2: usize = 3; // checksum chains
const WOTS_LEN: usize = WOTS_LEN1 + WOTS_LEN2; // 67
const WOTS_CHAIN_MAX: u8 = (WOTS_W - 1) as u8; // 15

/// Compute one WOTS+ hash chain step: H("Hyphen_WOTS_chain" || addr_seed || chain_idx || step || value)
fn chain(value: &[u8; 32], start: u8, steps: u8, addr_seed: &[u8; 32], chain_idx: u16) -> [u8; 32] {
    let mut current = *value;
    for i in start..start.saturating_add(steps) {
        let h = blake3_hash_many(&[
            b"Hyphen_WOTS_chain",
            addr_seed,
            &chain_idx.to_le_bytes(),
            &[i],
            &current,
        ]);
        current = *h.as_bytes();
    }
    current
}

/// Convert a message hash to base-w representation with checksum.
fn msg_base_w(msg_hash: &[u8; 32]) -> Vec<u8> {
    let mut base_w = Vec::with_capacity(WOTS_LEN);

    // Split each byte into two 4-bit nibbles
    for byte in msg_hash.iter() {
        base_w.push(byte >> WOTS_LOG_W);
        base_w.push(byte & 0x0F);
    }

    // Compute checksum
    let mut checksum: u32 = 0;
    for &b in &base_w {
        checksum += (WOTS_CHAIN_MAX as u32) - (b as u32);
    }
    checksum <<= 4;

    // Append checksum digits
    let cs_bytes = checksum.to_be_bytes();
    base_w.push(cs_bytes[1] >> WOTS_LOG_W);
    base_w.push(cs_bytes[1] & 0x0F);
    base_w.push(cs_bytes[2] >> WOTS_LOG_W);

    base_w
}

/// WOTS+ public key: hash of all chain endpoints + address seed.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WotsPublicKey {
    pub key_hash: [u8; 32],
    pub addr_seed: [u8; 32],
}

/// WOTS+ secret key: master seed + address seed.
#[derive(Clone, Serialize, Deserialize, Zeroize)]
#[zeroize(drop)]
pub struct WotsSecretKey {
    pub seed: [u8; 32],
    pub addr_seed: [u8; 32],
}

/// WOTS+ signature: 67 chain values + address seed.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WotsSignature {
    pub chains: Vec<[u8; 32]>,
    pub addr_seed: [u8; 32],
}

impl WotsSecretKey {
    /// Generate a new random WOTS+ key pair.
    pub fn generate() -> Self {
        let mut seed = [0u8; 32];
        let mut addr_seed = [0u8; 32];
        rand::RngCore::fill_bytes(&mut rand::rngs::OsRng, &mut seed);
        rand::RngCore::fill_bytes(&mut rand::rngs::OsRng, &mut addr_seed);
        Self { seed, addr_seed }
    }

    /// Create from deterministic seeds.
    pub fn from_seed(seed: [u8; 32], addr_seed: [u8; 32]) -> Self {
        Self { seed, addr_seed }
    }

    /// Derive the i-th chain's secret value.
    fn chain_secret(&self, idx: u16) -> [u8; 32] {
        let h = blake3_hash_many(&[b"Hyphen_WOTS_sk", &self.seed, &idx.to_le_bytes()]);
        *h.as_bytes()
    }

    /// Compute the corresponding public key.
    pub fn public_key(&self) -> WotsPublicKey {
        let mut concat = Vec::with_capacity(WOTS_LEN * 32);
        for i in 0..WOTS_LEN as u16 {
            let sk_i = self.chain_secret(i);
            let pk_i = chain(&sk_i, 0, WOTS_CHAIN_MAX, &self.addr_seed, i);
            concat.extend_from_slice(&pk_i);
        }
        let key_hash = blake3_hash(&concat);
        WotsPublicKey {
            key_hash: *key_hash.as_bytes(),
            addr_seed: self.addr_seed,
        }
    }

    /// Sign a message.
    pub fn sign(&self, msg: &[u8]) -> WotsSignature {
        let msg_hash = blake3_hash(msg);
        let base_w = msg_base_w(msg_hash.as_bytes());

        let mut chains = Vec::with_capacity(WOTS_LEN);
        for (i, &b) in base_w.iter().enumerate() {
            let sk_i = self.chain_secret(i as u16);
            let sig_i = chain(&sk_i, 0, b, &self.addr_seed, i as u16);
            chains.push(sig_i);
        }

        WotsSignature {
            chains,
            addr_seed: self.addr_seed,
        }
    }
}

impl std::fmt::Debug for WotsSecretKey {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "WotsSecretKey(**redacted**)")
    }
}

impl WotsSignature {
    /// Verify a WOTS+ signature against a public key.
    pub fn verify(&self, msg: &[u8], pk: &WotsPublicKey) -> Result<(), String> {
        if self.chains.len() != WOTS_LEN {
            return Err(format!(
                "invalid signature length: {} chains, expected {}",
                self.chains.len(),
                WOTS_LEN
            ));
        }
        if self.addr_seed != pk.addr_seed {
            return Err("address seed mismatch".into());
        }

        let msg_hash = blake3_hash(msg);
        let base_w = msg_base_w(msg_hash.as_bytes());

        let mut concat = Vec::with_capacity(WOTS_LEN * 32);
        for (i, (&sig_i, &b)) in self.chains.iter().zip(base_w.iter()).enumerate() {
            let remaining = WOTS_CHAIN_MAX - b;
            let pk_i = chain(&sig_i, b, remaining, &self.addr_seed, i as u16);
            concat.extend_from_slice(&pk_i);
        }

        let key_hash = blake3_hash(&concat);
        if key_hash.as_bytes() != &pk.key_hash {
            return Err("signature verification failed".into());
        }

        Ok(())
    }

    /// Serialize the signature to bytes.
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(32 + WOTS_LEN * 32);
        out.extend_from_slice(&self.addr_seed);
        for c in &self.chains {
            out.extend_from_slice(c);
        }
        out
    }

    /// Deserialize a signature from bytes.
    pub fn from_bytes(data: &[u8]) -> Result<Self, String> {
        let expected = 32 + WOTS_LEN * 32;
        if data.len() != expected {
            return Err(format!(
                "invalid signature data length: got {}, expected {expected}",
                data.len()
            ));
        }
        let mut addr_seed = [0u8; 32];
        addr_seed.copy_from_slice(&data[..32]);
        let mut chains = Vec::with_capacity(WOTS_LEN);
        for i in 0..WOTS_LEN {
            let start = 32 + i * 32;
            let mut c = [0u8; 32];
            c.copy_from_slice(&data[start..start + 32]);
            chains.push(c);
        }
        Ok(Self { chains, addr_seed })
    }
}

/// Ed25519 + WOTS dual-signature container.
///
/// This type is not a post-quantum identity scheme by itself: the WOTS public
/// key must be authenticated before use and each WOTS key may sign only once.
#[derive(Clone, Debug)]
pub struct HybridSignature {
    pub ed25519_sig: [u8; 64],
    pub ed25519_pubkey: [u8; 32],
    pub wots_sig: WotsSignature,
    pub wots_pubkey: WotsPublicKey,
}

impl HybridSignature {
    /// Create an experimental dual signature over a message.
    pub fn sign(
        msg: &[u8],
        ed_signing_key: &ed25519_dalek::SigningKey,
        wots_sk: &WotsSecretKey,
    ) -> Self {
        use ed25519_dalek::Signer;
        let ed_sig = ed_signing_key.sign(msg);
        let wots_sig = wots_sk.sign(msg);
        Self {
            ed25519_sig: ed_sig.to_bytes(),
            ed25519_pubkey: ed_signing_key.verifying_key().to_bytes(),
            wots_sig,
            wots_pubkey: wots_sk.public_key(),
        }
    }

    /// Verify a hybrid signature. Both Ed25519 and WOTS+ must pass.
    pub fn verify(&self, msg: &[u8]) -> Result<(), String> {
        // Verify Ed25519
        let vk = ed25519_dalek::VerifyingKey::from_bytes(&self.ed25519_pubkey)
            .map_err(|e| format!("invalid ed25519 public key: {e}"))?;
        let sig = ed25519_dalek::Signature::from_bytes(&self.ed25519_sig);
        use ed25519_dalek::Verifier;
        vk.verify(msg, &sig)
            .map_err(|e| format!("ed25519 verification failed: {e}"))?;

        // Verify WOTS+
        self.wots_sig.verify(msg, &self.wots_pubkey)?;

        Ok(())
    }

    /// Serialize to bytes.
    pub fn to_bytes(&self) -> Vec<u8> {
        let wots_bytes = self.wots_sig.to_bytes();
        let mut out = Vec::with_capacity(64 + 32 + 64 + wots_bytes.len());
        out.extend_from_slice(&self.ed25519_sig);
        out.extend_from_slice(&self.ed25519_pubkey);
        out.extend_from_slice(&self.wots_pubkey.key_hash);
        out.extend_from_slice(&self.wots_pubkey.addr_seed);
        out.extend_from_slice(&wots_bytes);
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wots_sign_verify() {
        let sk = WotsSecretKey::generate();
        let pk = sk.public_key();
        let msg = b"test message for WOTS+";
        let sig = sk.sign(msg);
        sig.verify(msg, &pk).unwrap();
    }

    #[test]
    fn wots_wrong_message_fails() {
        let sk = WotsSecretKey::generate();
        let pk = sk.public_key();
        let sig = sk.sign(b"correct");
        assert!(sig.verify(b"wrong", &pk).is_err());
    }

    #[test]
    fn wots_serialisation_roundtrip() {
        let sk = WotsSecretKey::generate();
        let sig = sk.sign(b"roundtrip test");
        let bytes = sig.to_bytes();
        let recovered = WotsSignature::from_bytes(&bytes).unwrap();
        let pk = sk.public_key();
        recovered.verify(b"roundtrip test", &pk).unwrap();
    }

    #[test]
    fn hybrid_sign_verify() {
        let ed_sk = ed25519_dalek::SigningKey::generate(&mut rand::rngs::OsRng);
        let wots_sk = WotsSecretKey::generate();
        let msg = b"hybrid PQ test";
        let sig = HybridSignature::sign(msg, &ed_sk, &wots_sk);
        sig.verify(msg).unwrap();
    }

    #[test]
    fn hybrid_wrong_message_fails() {
        let ed_sk = ed25519_dalek::SigningKey::generate(&mut rand::rngs::OsRng);
        let wots_sk = WotsSecretKey::generate();
        let sig = HybridSignature::sign(b"correct", &ed_sk, &wots_sk);
        assert!(sig.verify(b"wrong").is_err());
    }
}
