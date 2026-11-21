//! HYN3 recovery words and the historical BIP39 decoder.

use sha2::{Digest, Sha256};
use zeroize::Zeroizing;

/// BIP39 English word list.
const WORDLIST: &str = include_str!("bip39_english.txt");
pub const PREFIX: &str = "hy3-";
const SUFFIX: &str = "-hy3";

fn checksum(entropy: &[u8], versioned: bool) -> u8 {
    if versioned {
        blake3::derive_key("Hyphen recovery checksum v3", entropy)[0]
    } else {
        Sha256::digest(entropy)[0]
    }
}

/// Parse the embedded word list into a slice.
fn word_list() -> Vec<&'static str> {
    WORDLIST.lines().filter(|l| !l.is_empty()).collect()
}

/// Generate HYN3 recovery words with both version markers.
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
    encode_words(&entropy, true)
}

/// Append checksum bits and encode eleven bits per dictionary word.
fn encode_words(entropy: &[u8], versioned: bool) -> Result<String, String> {
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

    let check = checksum(entropy, versioned);
    let cs_bits = ent_bits / 32;

    // Build combined bit string: entropy || checksum
    let total_bits = ent_bits + cs_bits;
    let mut bits = Zeroizing::new(Vec::with_capacity(total_bits));

    for byte in entropy {
        for bit in (0..8).rev() {
            bits.push((byte >> bit) & 1);
        }
    }
    for bit in 0..cs_bits {
        bits.push((check >> (7 - bit)) & 1);
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

    let mut phrase = phrase.join(" ");
    if versioned {
        phrase.insert_str(0, PREFIX);
        phrase.push_str(SUFFIX);
    }
    Ok(phrase)
}

/// Validate the checksum and framing of the selected recovery format.
pub fn validate_mnemonic(phrase: &str) -> bool {
    let versioned = phrase.starts_with(PREFIX);
    let phrase = if let Some(words) = phrase.strip_prefix(PREFIX) {
        let Some(words) = words.strip_suffix(SUFFIX) else {
            return false;
        };
        words
    } else {
        phrase
    };
    let words = word_list();
    let mnemonic_words: Vec<&str> = phrase.split_whitespace().collect();
    if versioned
        && (phrase.starts_with(' ')
            || phrase.ends_with(' ')
            || phrase.contains("  ")
            || !phrase.bytes().all(|c| c.is_ascii_lowercase() || c == b' '))
    {
        return false;
    }

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
    let check = checksum(&entropy, versioned);

    // Verify checksum bits
    for i in 0..cs_bits {
        let expected = (check >> (7 - i)) & 1;
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
        assert_eq!(encode_words(&[0; 16], false).unwrap(), phrase);
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
    fn version_markers_are_required_as_a_pair() {
        let phrase = encode_words(&[0; 16], true).unwrap();
        assert_eq!(
            phrase,
            "hy3-abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon able-hy3"
        );
        for invalid in [
            phrase.trim_start_matches(PREFIX),
            phrase.trim_end_matches(SUFFIX),
            &phrase.replacen(' ', "  ", 1),
            &phrase.replace("able-hy3", "about-hy3"),
        ] {
            assert!(!validate_mnemonic(invalid));
        }
    }
}
