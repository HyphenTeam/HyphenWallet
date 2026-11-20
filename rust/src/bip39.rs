// BIP39 Mnemonic Generation and Seed Derivation
//
// Implements the BIP-0039 standard for mnemonic code generation:
//   1. Generate N bytes of entropy (16 for 12 words, 32 for 24 words)
//   2. SHA-256 hash the entropy, take first N/32 bits as checksum
//   3. Concatenate entropy + checksum, split into 11-bit groups
//   4. Map each group to a word from the standardized English word list
//
// Seed derivation: PBKDF2-HMAC-SHA512(mnemonic, "mnemonic" + passphrase, 2048)

use sha2::{Digest, Sha256};
use zeroize::Zeroizing;

/// BIP39 English word list.
const WORDLIST: &str = include_str!("bip39_english.txt");

/// Parse the embedded word list into a slice.
fn word_list() -> Vec<&'static str> {
    WORDLIST.lines().filter(|l| !l.is_empty()).collect()
}

/// Generate a BIP39 mnemonic phrase.
///
/// `word_count` must be 12, 15, 18, 21, or 24.
pub fn generate_mnemonic(word_count: usize) -> Result<String, String> {
    let entropy_bits = match word_count {
        12 => 128,
        15 => 160,
        18 => 192,
        21 => 224,
        24 => 256,
        _ => return Err("word_count must be 12, 15, 18, 21, or 24".into()),
    };
    let entropy_bytes = entropy_bits / 8;

    let mut entropy = Zeroizing::new(vec![0u8; entropy_bytes]);
    getrandom::fill(&mut entropy)
        .map_err(|error| format!("system entropy unavailable: {error}"))?;
    entropy_to_mnemonic(&entropy)
}

/// Convert raw entropy bytes to a BIP39 mnemonic phrase.
pub fn entropy_to_mnemonic(entropy: &[u8]) -> Result<String, String> {
    let ent_bits = entropy.len() * 8;
    if ![128, 160, 192, 224, 256].contains(&ent_bits) {
        return Err("entropy must be 16, 20, 24, 28, or 32 bytes".into());
    }

    let words = word_list();
    if words.len() != 2048 {
        return Err(format!(
            "word list has {} entries, expected 2048",
            words.len()
        ));
    }

    // SHA-256 checksum
    let hash = Sha256::digest(entropy);
    let cs_bits = ent_bits / 32;

    // Build combined bit string: entropy || checksum
    let total_bits = ent_bits + cs_bits;
    let mut bits = Zeroizing::new(Vec::with_capacity(total_bits));

    for byte in entropy {
        for bit in (0..8).rev() {
            bits.push((byte >> bit) & 1);
        }
    }
    for bit in (0..cs_bits).rev() {
        let byte_idx = (cs_bits - 1 - bit) / 8;
        let bit_idx = 7 - ((cs_bits - 1 - bit) % 8);
        bits.push((hash[byte_idx] >> bit_idx) & 1);
    }

    // Split into 11-bit groups
    let word_count = total_bits / 11;
    let mut phrase = Vec::with_capacity(word_count);

    for i in 0..word_count {
        let mut index: u16 = 0;
        for j in 0..11 {
            index = (index << 1) | bits[i * 11 + j] as u16;
        }
        if (index as usize) >= words.len() {
            return Err(format!("word index {index} out of range"));
        }
        phrase.push(words[index as usize]);
    }

    Ok(phrase.join(" "))
}

/// Validate a BIP39 mnemonic phrase.
pub fn validate_mnemonic(phrase: &str) -> bool {
    let words = word_list();
    let mnemonic_words: Vec<&str> = phrase.split_whitespace().collect();

    let word_count = mnemonic_words.len();
    if ![12, 15, 18, 21, 24].contains(&word_count) {
        return false;
    }

    // Look up each word's index
    let mut indices = Zeroizing::new(Vec::with_capacity(word_count));
    for w in &mnemonic_words {
        match words.iter().position(|&wl| wl == *w) {
            Some(idx) => indices.push(idx as u16),
            None => return false,
        }
    }

    // Convert indices to bits
    let total_bits = word_count * 11;
    let mut bits = Zeroizing::new(Vec::with_capacity(total_bits));
    for &idx in indices.iter() {
        for bit in (0..11).rev() {
            bits.push(((idx >> bit) & 1) as u8);
        }
    }

    let ent_bits = total_bits * 32 / 33;
    let cs_bits = total_bits - ent_bits;

    // Extract entropy bytes
    let mut entropy = Zeroizing::new(vec![0u8; ent_bits / 8]);
    for i in 0..ent_bits {
        entropy[i / 8] |= bits[i] << (7 - (i % 8));
    }

    // Compute checksum
    let hash = Sha256::digest(entropy.as_slice());

    // Verify checksum bits
    for i in 0..cs_bits {
        let expected = (hash[i / 8] >> (7 - (i % 8))) & 1;
        if bits[ent_bits + i] != expected {
            return false;
        }
    }

    true
}

/// Historical Hyphen seed derivation. PBKDF2 receives the exact UTF-8 bytes,
/// including internal whitespace and the original Unicode normalization form.
pub fn mnemonic_to_seed(mnemonic: &str, passphrase: &str) -> [u8; 64] {
    let salt = Zeroizing::new(format!("mnemonic{}", passphrase));
    let mut seed = [0u8; 64];
    pbkdf2::pbkdf2_hmac::<sha2::Sha512>(mnemonic.as_bytes(), salt.as_bytes(), 2048, &mut seed);
    seed
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wordlist_has_2048_words() {
        let wl = word_list();
        assert_eq!(wl.len(), 2048);
    }

    #[test]
    fn generate_12_words() {
        let m = generate_mnemonic(12).unwrap();
        assert_eq!(m.split_whitespace().count(), 12);
        assert!(validate_mnemonic(&m));
    }

    #[test]
    fn generate_24_words() {
        let m = generate_mnemonic(24).unwrap();
        assert_eq!(m.split_whitespace().count(), 24);
        assert!(validate_mnemonic(&m));
    }

    #[test]
    fn invalid_word_count() {
        assert!(generate_mnemonic(13).is_err());
    }

    #[test]
    fn invalid_mnemonic_fails_validation() {
        assert!(!validate_mnemonic("not a valid mnemonic phrase at all"));
    }

    #[test]
    fn bip39_english_reference_vector() {
        let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        assert_eq!(entropy_to_mnemonic(&[0; 16]).unwrap(), phrase);
        assert!(validate_mnemonic(phrase));
        assert_eq!(
            hex::encode(mnemonic_to_seed(phrase, "TREZOR")),
            "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04"
        );
    }

    #[test]
    fn historical_seed_preserves_whitespace_and_unicode_bytes() {
        let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let spaced = phrase.replacen(' ', "  ", 1);
        assert!(validate_mnemonic(&spaced));
        assert_eq!(
            hex::encode(mnemonic_to_seed(&spaced, "\u{e9}")),
            "6b4cd956d415797eba1e6f2800813ec09e545c227c78374acf761f1ca0cb336d48f647d202fe594696ef2129592da4d9150b1fcb0dde7af558a284e9853e91de"
        );
        assert_eq!(
            hex::encode(mnemonic_to_seed(phrase, "e\u{301}")),
            "f37f8652bf7004d4bd4ba7702e70e647f54965758656423dde58d64fa725c1e8be1b0416864e10f714c0730e46f9676079b4fd4f72fcf0c09a120ae65589c091"
        );
        assert_ne!(
            mnemonic_to_seed(phrase, "\u{e9}"),
            mnemonic_to_seed(phrase, "e\u{301}")
        );
    }

    #[test]
    fn different_passphrase_different_seed() {
        let m = generate_mnemonic(12).unwrap();
        let s1 = mnemonic_to_seed(&m, "");
        let s2 = mnemonic_to_seed(&m, "password");
        assert_ne!(s1, s2);
    }
}
