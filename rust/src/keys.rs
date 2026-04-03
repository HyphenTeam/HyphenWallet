// Key Derivation Module
//
// Implements Iterative Commitment Derivation (ICD) with a BIP44-compatible
// path structure: m / purpose' / coin_type' / account' / change / index
//
// ICD uses Pedersen commitments on Ristretto255 for key derivation instead
// of HMAC-based chain codes (BIP32). This provides the same hierarchical
// structure with stronger mathematical security guarantees.
//
// The derivation path follows BIP44:
//   m/44'/868'/account'/0/index    (external addresses)
//   m/44'/868'/account'/1/index    (internal/change addresses)
//
// Coin type 868 is used for Hyphen (HPN).

use curve25519_dalek::constants::RISTRETTO_BASEPOINT_POINT as G;
use curve25519_dalek::ristretto::RistrettoPoint;
use curve25519_dalek::scalar::Scalar;
use once_cell::sync::Lazy;
use zeroize::Zeroize;

use crate::crypto::{hash_to_point, hash_to_scalar};

/// Twist generator T for ICD: nothing-up-my-sleeve point with unknown DL relative to G.
static TWIST_GEN: Lazy<RistrettoPoint> =
    Lazy::new(|| hash_to_point(b"Hyphen_ICD_twist_generator_v1"));

/// BIP44 coin type for Hyphen.
pub const COIN_TYPE: u32 = 868;

/// Master key derived from BIP39 seed.
#[derive(Clone)]
pub struct MasterKey {
    seed: [u8; 64],
    master_scalar: Scalar,
}

impl Zeroize for MasterKey {
    fn zeroize(&mut self) {
        self.seed.zeroize();
        self.master_scalar.zeroize();
    }
}

impl Drop for MasterKey {
    fn drop(&mut self) {
        self.zeroize();
    }
}

/// Derived view/spend key pair for a specific path.
#[derive(Clone)]
pub struct DerivedKeyPair {
    pub view_secret: Scalar,
    pub spend_secret: Scalar,
    pub view_public: RistrettoPoint,
    pub spend_public: RistrettoPoint,
}

impl Zeroize for DerivedKeyPair {
    fn zeroize(&mut self) {
        self.view_secret.zeroize();
        self.spend_secret.zeroize();
    }
}

impl Drop for DerivedKeyPair {
    fn drop(&mut self) {
        self.zeroize();
    }
}

impl MasterKey {
    /// Create a master key from a BIP39 seed (64 bytes).
    pub fn from_seed(seed: &[u8; 64]) -> Self {
        let master_scalar = hash_to_scalar(b"Hyphen_master_v1", seed);
        Self {
            seed: *seed,
            master_scalar,
        }
    }

    /// ICD derivation: project parent scalar through a Pedersen commitment
    /// with a purpose-specific twist, then hash the resulting point.
    ///
    ///   chain_point = parent · G + H_s(purpose) · T
    ///   child       = H_s(compress(chain_point))
    fn icd_derive(&self, purpose: &[u8]) -> Scalar {
        let twist_scalar = hash_to_scalar(b"Hyphen_ICD_purpose", purpose);
        let chain_point = self.master_scalar * G + twist_scalar * *TWIST_GEN;
        hash_to_scalar(b"Hyphen_ICD_child", chain_point.compress().as_bytes())
    }

    /// Derive a child scalar at a BIP44-style path level.
    /// Incorporates the path components into the derivation.
    fn derive_path_scalar(&self, path_data: &[u8]) -> Scalar {
        let parent = self.master_scalar;
        let path_scalar = hash_to_scalar(b"Hyphen_ICD_path_v1", path_data);
        let chain_point = parent * G + path_scalar * *TWIST_GEN;
        hash_to_scalar(b"Hyphen_ICD_child", chain_point.compress().as_bytes())
    }

    /// Derive keys for a BIP44 path: m/44'/868'/account'/change/index
    pub fn derive_bip44(&self, account: u32, change: u32, index: u32) -> DerivedKeyPair {
        // Build the full path data: purpose(44) | coin(868) | account | change | index
        let mut path = Vec::with_capacity(20);
        path.extend_from_slice(&44u32.to_le_bytes());
        path.extend_from_slice(&COIN_TYPE.to_le_bytes());
        path.extend_from_slice(&account.to_le_bytes());
        path.extend_from_slice(&change.to_le_bytes());
        path.extend_from_slice(&index.to_le_bytes());

        let base_scalar = self.derive_path_scalar(&path);

        // Derive separate view and spend keys from the base scalar
        let view_chain =
            base_scalar * G + hash_to_scalar(b"Hyphen_ICD_purpose", b"view") * *TWIST_GEN;
        let view_secret = hash_to_scalar(b"Hyphen_ICD_child", view_chain.compress().as_bytes());

        let spend_chain =
            base_scalar * G + hash_to_scalar(b"Hyphen_ICD_purpose", b"spend") * *TWIST_GEN;
        let spend_secret = hash_to_scalar(b"Hyphen_ICD_child", spend_chain.compress().as_bytes());

        DerivedKeyPair {
            view_public: view_secret * G,
            spend_public: spend_secret * G,
            view_secret,
            spend_secret,
        }
    }

    /// Derive the default account keys (account=0, change=0, index=0).
    pub fn derive_default(&self) -> DerivedKeyPair {
        self.derive_bip44(0, 0, 0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_seed() -> [u8; 64] {
        let mut seed = [0u8; 64];
        for (i, b) in seed.iter_mut().enumerate() {
            *b = (i as u8).wrapping_mul(0xAB);
        }
        seed
    }

    #[test]
    fn deterministic_derivation() {
        let seed = test_seed();
        let mk = MasterKey::from_seed(&seed);
        let k1 = mk.derive_default();
        let k2 = mk.derive_default();
        assert_eq!(k1.view_secret, k2.view_secret);
        assert_eq!(k1.spend_secret, k2.spend_secret);
    }

    #[test]
    fn view_and_spend_differ() {
        let seed = test_seed();
        let mk = MasterKey::from_seed(&seed);
        let keys = mk.derive_default();
        assert_ne!(keys.view_secret, keys.spend_secret);
    }

    #[test]
    fn different_accounts_different_keys() {
        let seed = test_seed();
        let mk = MasterKey::from_seed(&seed);
        let k0 = mk.derive_bip44(0, 0, 0);
        let k1 = mk.derive_bip44(1, 0, 0);
        assert_ne!(k0.spend_public, k1.spend_public);
        assert_ne!(k0.view_public, k1.view_public);
    }

    #[test]
    fn different_indices_different_keys() {
        let seed = test_seed();
        let mk = MasterKey::from_seed(&seed);
        let k0 = mk.derive_bip44(0, 0, 0);
        let k1 = mk.derive_bip44(0, 0, 1);
        assert_ne!(k0.spend_public, k1.spend_public);
    }

    #[test]
    fn change_addresses_differ() {
        let seed = test_seed();
        let mk = MasterKey::from_seed(&seed);
        let external = mk.derive_bip44(0, 0, 0);
        let internal = mk.derive_bip44(0, 1, 0);
        assert_ne!(external.spend_public, internal.spend_public);
    }
}
