/// Block wire format. Must equal `hyphen_core::FROZEN_BLOCK_VERSION`.
pub const BLOCK_VERSION: u32 = 5;

/// PoUW protocol version. Must equal `hyphen_pow::POUW_PROTOCOL_VERSION`.
pub const POUW_PROTOCOL_VERSION: u32 = 3;

/// Canonical anchor of the pinned identities: `test-vectors/chain-identity-v6.json`.
///
/// The genesis hashes are the identity-v6 values: they moved when the chain
/// switched from the fixed-width profile to RustBinary's schema-guided compact
/// profile, because a genesis hash is the hash of the encoded genesis block.
pub const IDENTITY_VECTOR: &str = "chain-identity-v6";

pub struct ChainIdentity {
    pub network: &'static str,
    pub network_magic: [u8; 4],
    pub consensus_params_hash: &'static str,
    pub genesis_hash: &'static str,
}

pub const CHAIN_IDENTITIES: [ChainIdentity; 7] = [
    ChainIdentity {
        network: "hyphen-devnet-v2",
        network_magic: *b"HYDV",
        consensus_params_hash: "521f6cdc47f4424c1ea7b9f4d6770cf114f620cdff62958060f8c6953cb69de8",
        genesis_hash: "5f7c144f0ef27880259b2429e46ef175685da679916fcc6b80c45f457465e32d",
    },
    ChainIdentity {
        network: "hyphen-neural-devnet-v1",
        network_magic: *b"HYNN",
        consensus_params_hash: "451ca637dafb07604b8dcabebc86c54d72efe590ac5912bb2a2f35ea6d41b6a9",
        genesis_hash: "6d3c028ecd7380ba143a62c8b82fa706155da56fb42ec8cf8b30ec4dc989d058",
    },
    ChainIdentity {
        network: "hyphen-contract-devnet-v1",
        network_magic: *b"HYCD",
        consensus_params_hash: "3ad32be8f0c772331740a74ebcd56266ad97da58bdda076e9e139d31499910b2",
        genesis_hash: "422475c11a829f198cc502ca4f5cd4489336569997c3cdf048dddaf1d71f1b33",
    },
    ChainIdentity {
        network: "hyphen-offline-devnet-v1",
        network_magic: *b"HYOF",
        consensus_params_hash: "abcc133c433575b338b6a38f3522cd2602f2b08c28f970c7c4fbd08280e28bae",
        genesis_hash: "2c80d0881102a4e2d4a080bca8b08d2726b303f5877a8c585eb315eae49f9aa5",
    },
    ChainIdentity {
        network: "hyphen-compute-devnet-v1",
        network_magic: *b"HYAC",
        consensus_params_hash: "8cb229414e48614e7c1e5c47bb819de2974af9735747e0f2d7728b91ededa2e9",
        genesis_hash: "381fa56cec297fad0d25563a8c0a14fa1fd226b143f3d1ec198b897aeac339bb",
    },
    ChainIdentity {
        network: "hyphen-testnet",
        network_magic: *b"HYTS",
        consensus_params_hash: "dacfd24354a308d149ee8676444d92bc9e48a54b5c6f191272b40b16653dffa9",
        genesis_hash: "944514b7c52d93ce03f0bfac1d436cf1607fab1b78d73010ff59301f913dba42",
    },
    ChainIdentity {
        network: "hyphen-mainnet",
        network_magic: *b"HYPN",
        consensus_params_hash: "d42031b0c51640621ce6c6cb7bc97847db53bd636842c5b2b4f07c2be6a4e15b",
        genesis_hash: "5896c90005ca4e85e19876dac81867920dfa4315744d757ecbf13c16c24669e6",
    },
];

pub fn verify(
    network: &str,
    network_magic: &[u8],
    consensus_params_hash: &[u8],
    genesis_hash: &[u8],
    block_version: u32,
    pouw_protocol_version: u32,
) -> Result<(), String> {
    if block_version != BLOCK_VERSION || pouw_protocol_version != POUW_PROTOCOL_VERSION {
        return Err(format!(
            "unsupported chain protocol: block v{block_version}, PoUW v{pouw_protocol_version}"
        ));
    }
    let identity = CHAIN_IDENTITIES
        .iter()
        .find(|identity| identity.network == network)
        .ok_or_else(|| format!("unsupported Hyphen network identity '{network}'"))?;
    if network_magic != identity.network_magic
        || hex::encode(consensus_params_hash) != identity.consensus_params_hash
        || hex::encode(genesis_hash) != identity.genesis_hash
    {
        return Err("node chain identity does not match the pinned scientific-PoUW network".into());
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_pinned_identity_on_every_network() {
        for chain in &CHAIN_IDENTITIES {
            verify(
                chain.network,
                &chain.network_magic,
                &hex::decode(chain.consensus_params_hash).unwrap(),
                &hex::decode(chain.genesis_hash).unwrap(),
                BLOCK_VERSION,
                POUW_PROTOCOL_VERSION,
            )
            .unwrap();
        }
    }

    #[test]
    fn rejects_legacy_identities_and_versions() {
        let chain = &CHAIN_IDENTITIES[0];
        let params = hex::decode(chain.consensus_params_hash).unwrap();
        let genesis = hex::decode(chain.genesis_hash).unwrap();
        // Pre-PoUW-v3 devnet identity: block v3, PoUW v1, superseded hashes.
        assert!(verify(chain.network, &chain.network_magic, &params, &genesis, 3, 1).is_err());
        assert!(verify(chain.network, &chain.network_magic, &params, &genesis, 4, 2).is_err());
        assert!(
            verify(
                chain.network,
                &chain.network_magic,
                &hex::decode("54bf97e4e28d4fcf963d884a555a8425bbfe7c84d2753001bcabbaf116232fda")
                    .unwrap(),
                &genesis,
                BLOCK_VERSION,
                POUW_PROTOCOL_VERSION,
            )
            .is_err()
        );
        assert!(
            verify(
                chain.network,
                &chain.network_magic,
                &params,
                &hex::decode("47d530160cfef9141fe3b37b886e09b9f96ec4dc93d6c05005b9c6dbf35b1972")
                    .unwrap(),
                BLOCK_VERSION,
                POUW_PROTOCOL_VERSION,
            )
            .is_err()
        );
        assert!(
            verify(
                chain.network,
                b"XXXX",
                &params,
                &genesis,
                BLOCK_VERSION,
                POUW_PROTOCOL_VERSION,
            )
            .is_err()
        );
        assert!(
            verify(
                "hyphen-devnet-v1",
                &chain.network_magic,
                &params,
                &genesis,
                BLOCK_VERSION,
                POUW_PROTOCOL_VERSION,
            )
            .is_err()
        );
        assert!(
            verify(
                chain.network,
                &chain.network_magic,
                &params[..31],
                &genesis,
                BLOCK_VERSION,
                POUW_PROTOCOL_VERSION,
            )
            .is_err()
        );
    }
}
