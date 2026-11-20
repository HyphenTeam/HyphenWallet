use prost::Message;
use rust_lib_hyphen_wallet::chain_identity::{CHAIN_IDENTITIES, IDENTITY_VECTOR};
use rust_lib_hyphen_wallet::rpc_client::{
    BlockResponse, ChainInfoResponse, METHOD_GET_BLOCK_BY_HEIGHT, METHOD_GET_CHAIN_INFO,
    RpcRequest, RpcResponse,
};
use rust_lib_hyphen_wallet::{api::wallet::get_default_address, transfer::scan_wallet_outputs};
use std::io::{Read, Write};

fn reply(stream: &mut std::net::TcpStream, method: u32, payload: Vec<u8>, wrong_id: bool) {
    let mut prefix = [0; 4];
    stream.read_exact(&mut prefix).unwrap();
    let mut bytes = vec![0; u32::from_be_bytes(prefix) as usize];
    stream.read_exact(&mut bytes).unwrap();
    let request = RpcRequest::decode(bytes.as_slice()).unwrap();
    assert_eq!(request.method, method);
    let response = RpcResponse {
        id: request.id + u32::from(wrong_id),
        success: true,
        payload,
        error: String::new(),
    }
    .encode_to_vec();
    stream
        .write_all(&(response.len() as u32).to_be_bytes())
        .unwrap();
    stream.write_all(&response).unwrap();
}

#[test]
fn an_interrupted_scan_or_mismatched_response_fails_the_whole_scan() {
    let identity = &CHAIN_IDENTITIES[0];
    let genesis = hyphen_core::genesis::build_genesis_block(&hyphen_core::ChainConfig::devnet());
    let genesis_response = BlockResponse {
        header_data: hyphen_wire::wire_config(4096)
            .serialize(&genesis.header)
            .unwrap(),
        hash: genesis.hash().to_vec(),
        ..Default::default()
    };
    let info = ChainInfoResponse {
        height: 1,
        tip_hash: vec![1; 32],
        network: identity.network.into(),
        network_magic: identity.network_magic.to_vec(),
        consensus_params_hash: hex::decode(identity.consensus_params_hash).unwrap(),
        genesis_hash: hex::decode(identity.genesis_hash).unwrap(),
        block_version: 5,
        pouw_protocol_version: 3,
        ..Default::default()
    };
    for (mismatch, final_fragment, expected_error) in [
        (true, &[][..], "does not match request"),
        (false, &[0, 0], "read response length"),
        (false, &[0, 0, 0, 4, 8, 1], "read response body"),
    ] {
        let listener = std::net::TcpListener::bind(("127.0.0.1", 0)).unwrap();
        let port = listener.local_addr().unwrap().port();
        let responses = [
            (METHOD_GET_CHAIN_INFO, info.encode_to_vec()),
            (METHOD_GET_CHAIN_INFO, info.encode_to_vec()),
            (METHOD_GET_BLOCK_BY_HEIGHT, genesis_response.encode_to_vec()),
        ];
        let server = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            for (method, payload) in responses {
                reply(
                    &mut stream,
                    method,
                    payload,
                    mismatch && method == METHOD_GET_BLOCK_BY_HEIGHT,
                );
            }
            if !mismatch {
                let mut prefix = [0; 4];
                stream.read_exact(&mut prefix).unwrap();
                let mut body = vec![0; u32::from_be_bytes(prefix) as usize];
                stream.read_exact(&mut body).unwrap();
                stream.write_all(final_fragment).unwrap();
            }
        });
        let result = scan_wallet_outputs(
            "127.0.0.1".into(),
            port,
            hex::encode([0x42; 64]),
            0,
            0,
            1,
            false,
        );
        server.join().unwrap();
        let error = result.err().expect("partial scan must fail");
        assert!(error.contains(expected_error), "{error}");
    }
}

#[test]
fn scans_reject_the_wrong_reserve_network_and_a_replaced_anchor() {
    use rust_lib_hyphen_wallet::transfer::scan_reserve_wallet;
    let identity = CHAIN_IDENTITIES
        .iter()
        .find(|i| i.network_magic == *b"HYDV")
        .unwrap();
    for reserve_scan in [true, false] {
        let info = ChainInfoResponse {
            network: identity.network.into(),
            network_magic: identity.network_magic.to_vec(),
            genesis_hash: hex::decode(identity.genesis_hash).unwrap(),
            tip_hash: hex::decode(identity.genesis_hash).unwrap(),
            consensus_params_hash: hex::decode(identity.consensus_params_hash).unwrap(),
            block_version: 5,
            pouw_protocol_version: 3,
            ..Default::default()
        };
        let listener = std::net::TcpListener::bind(("127.0.0.1", 0)).unwrap();
        let port = listener.local_addr().unwrap().port();
        let server = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            reply(
                &mut stream,
                METHOD_GET_CHAIN_INFO,
                info.encode_to_vec(),
                false,
            );
            reply(
                &mut stream,
                METHOD_GET_CHAIN_INFO,
                info.encode_to_vec(),
                false,
            );
            if !reserve_scan {
                let genesis = hyphen_core::build_genesis_block(&hyphen_core::ChainConfig::devnet());
                let mut block = BlockResponse {
                    header_data: hyphen_wire::wire_config(4096)
                        .serialize(&genesis.header)
                        .unwrap(),
                    hash: genesis.hash().to_vec(),
                    ..Default::default()
                };
                assert_eq!(block.hash, info.genesis_hash);
                reply(
                    &mut stream,
                    METHOD_GET_BLOCK_BY_HEIGHT,
                    block.encode_to_vec(),
                    false,
                );
                block.hash = vec![2; 32];
                reply(
                    &mut stream,
                    METHOD_GET_BLOCK_BY_HEIGHT,
                    block.encode_to_vec(),
                    false,
                );
            }
        });
        let host = "127.0.0.1".into();
        let seed = hex::encode([42; 64]);
        let result = if reserve_scan {
            scan_reserve_wallet(host, port, seed)
        } else {
            scan_wallet_outputs(host, port, seed, 0, 0, u64::MAX, false)
        };
        let error = result.err().unwrap();
        server.join().unwrap();
        let expected = if reserve_scan {
            "differs from the expected chain"
        } else {
            "chain changed during wallet scan"
        };
        assert!(error.contains(expected), "{error}");
    }
}

#[test]
#[ignore = "requires the base-chain compatibility checkout"]
fn pins_every_published_identity() {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join(format!("../../test-vectors/{IDENTITY_VECTOR}.json"));
    let vectors: Vec<serde_json::Value> =
        serde_json::from_slice(&std::fs::read(path).unwrap()).unwrap();
    assert_eq!(vectors.len(), CHAIN_IDENTITIES.len());
    for chain in CHAIN_IDENTITIES {
        let magic = hex::encode(chain.network_magic);
        let vector = vectors
            .iter()
            .find(|v| v["network_magic"] == magic)
            .unwrap();
        assert_eq!(vector["consensus_params_hash"], chain.consensus_params_hash);
        assert_eq!(vector["genesis_hash"], chain.genesis_hash);
    }
}

/// Run against the private node created by the base-chain compatibility script.
#[test]
#[ignore = "requires a fresh local devnet mined to the compatibility wallet"]
fn scans_the_first_solo_reward() {
    let mut rpc =
        rust_lib_hyphen_wallet::rpc_client::RpcClient::connect("127.0.0.1", 49633).unwrap();
    let block = rpc.get_block_by_height(1).unwrap();
    assert_eq!(
        hex::encode(block.hash),
        std::env::var("HYPHEN_SMOKE_BLOCK_HASH").unwrap()
    );
    let seed = hex::encode([0x42; 64]);
    let address = get_default_address(seed.clone(), false).unwrap();
    let scanned = scan_wallet_outputs("127.0.0.1".into(), 49633, seed.clone(), 0, 0, 1, false)
        .unwrap_or_else(|error| panic!("scan for {address}: {error}"));
    assert_eq!(scanned.scanned_height, 1);
    assert_eq!(scanned.output_count, 1, "expected a reward for {address}");
    assert!(scanned.total_balance > 0);
    assert_eq!(
        scanned.total_balance.to_string(),
        std::env::var("HYPHEN_SMOKE_REWARD_ATOMIC").unwrap()
    );
    let tip = rpc.get_chain_info().unwrap().height;
    if tip > 1 {
        let mut expected = scanned.total_balance;
        for height in 2..=tip {
            let block = rpc.get_block_by_height(height).unwrap();
            let header: hyphen_core::BlockHeader = hyphen_wire::wire_config(4096)
                .deserialize(&block.header_data)
                .unwrap();
            expected = expected.checked_add(header.reward).unwrap();
        }
        let all = scan_wallet_outputs("127.0.0.1".into(), 49633, seed, 0, 0, tip, false).unwrap();
        assert_eq!(all.scanned_height, tip);
        assert_eq!(all.output_count, tip);
        assert_eq!(all.total_balance, expected);
    }
}
