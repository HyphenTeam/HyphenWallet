// Internal modules are consumed via the FFI API layer; not all symbols
// are referenced from Rust itself.
#![allow(dead_code)]

pub mod api;
mod frb_generated;

pub mod address;
mod bip39;
mod crypto;
pub mod keys;
pub mod rpc_client;
pub mod transfer;
mod wots;

#[cfg(test)]
mod codec_compatibility_tests {
    use serde::{Deserialize, Serialize};

    #[derive(Debug, PartialEq, Serialize, Deserialize)]
    struct CodecFixture {
        tag: u8,
        count: u64,
        bytes: Vec<u8>,
        optional: Option<u32>,
    }

    #[test]
    fn canonical_codec_matches_main_chain_fixed_vector() {
        let fixture = CodecFixture {
            tag: 7,
            count: 0x0102,
            bytes: vec![3, 4],
            optional: Some(9),
        };
        let expected = vec![
            7, 2, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 9, 0, 0, 0,
        ];
        assert_eq!(hyphen_codec::serialize(&fixture).unwrap(), expected);
        assert_eq!(
            hyphen_codec::deserialize::<CodecFixture>(&expected).unwrap(),
            fixture
        );
        let mut trailing = expected;
        trailing.push(0);
        assert!(hyphen_codec::deserialize::<CodecFixture>(&trailing).is_err());
    }
}
