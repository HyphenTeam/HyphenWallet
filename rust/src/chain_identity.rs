/// Block wire format. Must equal `hyphen_core::FROZEN_BLOCK_VERSION`.
pub const BLOCK_VERSION: u32 = 5;

/// PoUW protocol version. Must equal `hyphen_pow::POUW_PROTOCOL_VERSION`.
pub const POUW_PROTOCOL_VERSION: u32 = 3;

/// Published genesis and parameters for the active network.
pub const IDENTITY_VECTOR: &str = "chain-identity-neural-v3";

pub struct ChainIdentity {
    pub network: &'static str,
    pub network_magic: [u8; 4],
    pub consensus_params_hash: &'static str,
    pub genesis_hash: &'static str,
}

pub const CHAIN_IDENTITIES: [ChainIdentity; 1] = [ChainIdentity {
    network: "hyphen-neural-devnet-v3",
    network_magic: *b"HYN3",
    consensus_params_hash: "4f3b68f56eb14d9d022d2f6b970811b3d8d53f5a3f6db07f70763cd7e5c17d49",
    genesis_hash: "710ad7eb105d56901495cf9c31f07f749cb812ddf3848f978e2bd133b7ebc926",
}];

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
