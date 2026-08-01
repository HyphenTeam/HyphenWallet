// Internal modules are consumed via the FFI API layer; not all symbols
// are referenced from Rust itself.
#![allow(dead_code)]

const DEFAULT_WIRE_BYTES: usize = 64 * 1024 * 1024;
const MAX_WIRE_COLLECTION_ITEMS: usize = 1_000_000;

fn wire_config(max_bytes: usize) -> rustbinary::Config {
    rustbinary::legacy_options()
        .with_little_endian()
        .with_fixint_encoding()
        .with_limit(max_bytes as u64)
        .with_collection_limit(max_bytes.min(MAX_WIRE_COLLECTION_ITEMS) as u64)
        .reject_trailing_bytes()
}

pub mod api;
mod frb_generated;

pub mod address;
mod bip39;
pub mod chain_identity;
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
        assert_eq!(
            crate::wire_config(crate::DEFAULT_WIRE_BYTES)
                .serialize(&fixture)
                .unwrap(),
            expected
        );
        assert_eq!(
            crate::wire_config(crate::DEFAULT_WIRE_BYTES)
                .deserialize::<CodecFixture>(&expected)
                .unwrap(),
            fixture
        );
        let mut trailing = expected;
        trailing.push(0);
        assert!(crate::wire_config(crate::DEFAULT_WIRE_BYTES)
            .deserialize::<CodecFixture>(&trailing)
            .is_err());
    }
}
