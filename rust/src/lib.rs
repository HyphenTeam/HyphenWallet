// Internal modules are consumed via the FFI API layer; not all symbols
// are referenced from Rust itself.
#![allow(dead_code)]

const DEFAULT_WIRE_BYTES: usize = 64 * 1024 * 1024;
const MAX_WIRE_COLLECTION_ITEMS: usize = 1_000_000;

fn wire_config(max_bytes: usize) -> rustbinary::CompactConfig {
    rustbinary::options()
        .with_limit(max_bytes as u64)
        .with_collection_limit(max_bytes.min(MAX_WIRE_COLLECTION_ITEMS) as u64)
        .reject_trailing_bytes()
        .with_compact_format()
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

    #[derive(Debug, PartialEq, Serialize, Deserialize, rustbinary::CompactBinary)]
    struct CodecFixture {
        tag: u8,
        count: u64,
        bytes: Vec<u8>,
        optional: Option<u32>,
    }

    /// The wallet must speak exactly the profile the base chain freezes: a drift
    /// here is a rejected handshake or an unreadable node payload, so the expected
    /// bytes are pinned rather than round-tripped.
    #[test]
    fn canonical_codec_matches_the_chain_wire_vector() {
        let fixture = CodecFixture {
            tag: 7,
            count: 0x0102,
            bytes: vec![3, 4],
            optional: Some(9),
        };
        let expected = vec![7, 251, 2, 1, 2, 3, 4, 1, 9];
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
