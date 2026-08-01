pub const BLOCK_VERSION: u32 = 3;
pub const POUW_PROTOCOL_VERSION: u32 = 1;

pub struct ChainIdentity {
    pub network: &'static str,
    pub network_magic: [u8; 4],
    pub consensus_params_hash: &'static str,
    pub genesis_hash: &'static str,
}

pub const CHAIN_IDENTITIES: [ChainIdentity; 3] = [
    ChainIdentity {
        network: "hyphen-devnet-v2",
        network_magic: *b"HYDV",
        consensus_params_hash: "54bf97e4e28d4fcf963d884a555a8425bbfe7c84d2753001bcabbaf116232fda",
        genesis_hash: "47d530160cfef9141fe3b37b886e09b9f96ec4dc93d6c05005b9c6dbf35b1972",
    },
    ChainIdentity {
        network: "hyphen-testnet",
        network_magic: *b"HYTS",
        consensus_params_hash: "cfb4d633a7a2326670ed970335a26454e52ad166e97f304d3ef96dbe4e269358",
        genesis_hash: "366d32b3ef3fb206366f1d0e54693340689d49f3f9a4d1bad2cf353b0539a643",
    },
    ChainIdentity {
        network: "hyphen-mainnet",
        network_magic: *b"HYPN",
        consensus_params_hash: "9231dcb5fa6eaf9dc2e06fe95c026141d86eedc4fd7119a404eda0c346dd88dc",
        genesis_hash: "6b311cb4f6587ff7aaf632c1c4c006a23c5bbc41679a66e1c1604ab80562c8d1",
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
    fn accepts_pinned_scientific_pouw_identity_and_rejects_legacy() {
        let chain = &CHAIN_IDENTITIES[0];
        verify(
            chain.network,
            &chain.network_magic,
            &hex::decode(chain.consensus_params_hash).unwrap(),
            &hex::decode(chain.genesis_hash).unwrap(),
            BLOCK_VERSION,
            POUW_PROTOCOL_VERSION,
        )
        .unwrap();
        assert!(verify(
            chain.network,
            &chain.network_magic,
            &hex::decode(chain.consensus_params_hash).unwrap(),
            &hex::decode(chain.genesis_hash).unwrap(),
            2,
            0,
        )
        .is_err());
    }
}
