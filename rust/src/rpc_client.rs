// Blocking RPC client for communicating with a Hyphen node.
//
// Wire protocol: [u32 big-endian length][protobuf-encoded message]
// The client sends RpcRequest and receives RpcResponse over a single
// persistent TCP connection.

use prost::Message;
use std::io::{Read, Write};
use std::net::{TcpStream, ToSocketAddrs};
use std::time::Duration;

// ─── Protobuf message types (mirrors hyphen-rpc/src/messages.rs) ────

#[derive(Clone, prost::Message)]
pub struct RpcRequest {
    #[prost(uint32, tag = "1")]
    pub id: u32,
    #[prost(uint32, tag = "2")]
    pub method: u32,
    #[prost(bytes = "vec", tag = "3")]
    pub payload: Vec<u8>,
}

#[derive(Clone, prost::Message)]
pub struct RpcResponse {
    #[prost(uint32, tag = "1")]
    pub id: u32,
    #[prost(bool, tag = "2")]
    pub success: bool,
    #[prost(bytes = "vec", tag = "3")]
    pub payload: Vec<u8>,
    #[prost(string, tag = "4")]
    pub error: String,
}

// ─── Request / Response sub-messages ────

pub const METHOD_GET_CHAIN_INFO: u32 = 3;
pub const METHOD_SUBMIT_TX: u32 = 4;
pub const METHOD_GET_MEMPOOL: u32 = 5;
pub const METHOD_GET_TX_LOCATION: u32 = 6;
pub const METHOD_GET_BLOCK_BY_HEIGHT: u32 = 2;
pub const METHOD_GET_RANDOM_OUTPUTS: u32 = 7;
pub const METHOD_GET_OUTPUT_INFO: u32 = 8;

#[derive(Clone, prost::Message)]
pub struct GetOutputInfoRequest {
    #[prost(uint64, repeated, tag = "1")]
    pub global_indices: Vec<u64>,
}

#[derive(Clone, prost::Message)]
pub struct GetOutputInfoResponse {
    #[prost(message, repeated, tag = "1")]
    pub outputs: Vec<OutputInfoMsg>,
}

#[derive(Clone, prost::Message)]
pub struct GetChainInfoRequest {}

#[derive(Clone, prost::Message)]
pub struct ChainInfoResponse {
    #[prost(uint64, tag = "1")]
    pub height: u64,
    #[prost(bytes = "vec", tag = "2")]
    pub tip_hash: Vec<u8>,
    #[prost(uint64, tag = "3")]
    pub difficulty: u64,
    #[prost(bytes = "vec", tag = "4")]
    pub cumulative_difficulty: Vec<u8>,
    #[prost(uint64, tag = "5")]
    pub total_outputs: u64,
    #[prost(string, tag = "6")]
    pub network: String,
    #[prost(bytes = "vec", tag = "7")]
    pub epoch_seed: Vec<u8>,
}

#[derive(Clone, prost::Message)]
pub struct GetBlockByHeightRequest {
    #[prost(uint64, tag = "1")]
    pub height: u64,
}

#[derive(Clone, prost::Message)]
pub struct BlockResponse {
    #[prost(bytes = "vec", tag = "1")]
    pub header_data: Vec<u8>,
    #[prost(bytes = "vec", repeated, tag = "2")]
    pub transactions: Vec<Vec<u8>>,
    #[prost(bytes = "vec", tag = "3")]
    pub hash: Vec<u8>,
    #[prost(uint64, tag = "4")]
    pub height: u64,
    #[prost(uint64, tag = "5")]
    pub timestamp: u64,
}

#[derive(Clone, prost::Message)]
pub struct SubmitTransactionRequest {
    #[prost(bytes = "vec", tag = "1")]
    pub tx_data: Vec<u8>,
}

#[derive(Clone, prost::Message)]
pub struct SubmitTransactionResponse {
    #[prost(bool, tag = "1")]
    pub accepted: bool,
    #[prost(bytes = "vec", tag = "2")]
    pub tx_hash: Vec<u8>,
    #[prost(string, tag = "3")]
    pub error: String,
}

#[derive(Clone, prost::Message)]
pub struct GetMempoolRequest {}

#[derive(Clone, prost::Message)]
pub struct MempoolResponse {
    #[prost(uint64, tag = "1")]
    pub tx_count: u64,
    #[prost(uint64, tag = "2")]
    pub total_size: u64,
    #[prost(bytes = "vec", repeated, tag = "3")]
    pub tx_hashes: Vec<Vec<u8>>,
}

#[derive(Clone, prost::Message)]
pub struct GetTxLocationRequest {
    #[prost(bytes = "vec", tag = "1")]
    pub tx_hash: Vec<u8>,
}

#[derive(Clone, prost::Message)]
pub struct TxLocationResponse {
    #[prost(bytes = "vec", tag = "1")]
    pub block_hash: Vec<u8>,
    #[prost(uint32, tag = "2")]
    pub tx_index: u32,
    #[prost(bool, tag = "3")]
    pub found: bool,
    #[prost(uint64, tag = "4")]
    pub block_height: u64,
}

#[derive(Clone, prost::Message)]
pub struct GetRandomOutputsRequest {
    #[prost(uint32, tag = "1")]
    pub count: u32,
    #[prost(uint64, tag = "2")]
    pub below_index: u64,
}

#[derive(Clone, prost::Message)]
pub struct OutputInfoMsg {
    #[prost(bytes = "vec", tag = "1")]
    pub one_time_pubkey: Vec<u8>,
    #[prost(bytes = "vec", tag = "2")]
    pub commitment: Vec<u8>,
    #[prost(uint64, tag = "3")]
    pub global_index: u64,
    #[prost(uint64, tag = "4")]
    pub block_height: u64,
}

#[derive(Clone, prost::Message)]
pub struct RandomOutputsResponse {
    #[prost(message, repeated, tag = "1")]
    pub outputs: Vec<OutputInfoMsg>,
}

// ─── RPC Client ─────────────────────────────────────────────

const MAX_FRAME_SIZE: u32 = 64 * 1024 * 1024;

pub struct RpcClient {
    stream: TcpStream,
    next_id: u32,
}

impl RpcClient {
    pub fn connect(host: &str, port: u16) -> Result<Self, String> {
        let addr = format!("{host}:{port}");
        let sock_addr = addr
            .to_socket_addrs()
            .map_err(|e| format!("failed to resolve '{addr}': {e}"))?
            .next()
            .ok_or_else(|| format!("DNS resolution returned no addresses for '{addr}'"))?;
        let stream = TcpStream::connect_timeout(&sock_addr, Duration::from_secs(10))
            .map_err(|e| format!("failed to connect to {addr}: {e}"))?;
        stream
            .set_read_timeout(Some(Duration::from_secs(60)))
            .map_err(|e| format!("set read timeout: {e}"))?;
        stream
            .set_write_timeout(Some(Duration::from_secs(30)))
            .map_err(|e| format!("set write timeout: {e}"))?;
        Ok(Self { stream, next_id: 1 })
    }

    fn call(&mut self, method: u32, payload: Vec<u8>) -> Result<RpcResponse, String> {
        let id = self.next_id;
        self.next_id = self.next_id.wrapping_add(1);

        let request = RpcRequest {
            id,
            method,
            payload,
        };
        let encoded = request.encode_to_vec();
        let len = encoded.len() as u32;

        self.stream
            .write_all(&len.to_be_bytes())
            .map_err(|e| format!("write frame length: {e}"))?;
        self.stream
            .write_all(&encoded)
            .map_err(|e| format!("write frame body: {e}"))?;
        self.stream.flush().map_err(|e| format!("flush: {e}"))?;

        // Read response
        let mut len_buf = [0u8; 4];
        self.stream
            .read_exact(&mut len_buf)
            .map_err(|e| format!("read response length: {e}"))?;
        let resp_len = u32::from_be_bytes(len_buf);
        if resp_len > MAX_FRAME_SIZE {
            return Err(format!("response too large: {resp_len}"));
        }
        let mut resp_buf = vec![0u8; resp_len as usize];
        self.stream
            .read_exact(&mut resp_buf)
            .map_err(|e| format!("read response body: {e}"))?;

        RpcResponse::decode(&resp_buf[..]).map_err(|e| format!("decode response: {e}"))
    }

    pub fn get_chain_info(&mut self) -> Result<ChainInfoResponse, String> {
        let req = GetChainInfoRequest {};
        let resp = self.call(METHOD_GET_CHAIN_INFO, req.encode_to_vec())?;
        if !resp.success {
            return Err(format!("get_chain_info failed: {}", resp.error));
        }
        ChainInfoResponse::decode(&resp.payload[..]).map_err(|e| format!("decode chain info: {e}"))
    }

    pub fn get_block_by_height(&mut self, height: u64) -> Result<BlockResponse, String> {
        let req = GetBlockByHeightRequest { height };
        let resp = self.call(METHOD_GET_BLOCK_BY_HEIGHT, req.encode_to_vec())?;
        if !resp.success {
            return Err(format!("get_block_by_height failed: {}", resp.error));
        }
        BlockResponse::decode(&resp.payload[..]).map_err(|e| format!("decode block: {e}"))
    }

    pub fn submit_transaction(
        &mut self,
        tx_data: Vec<u8>,
    ) -> Result<SubmitTransactionResponse, String> {
        let req = SubmitTransactionRequest { tx_data };
        let resp = self.call(METHOD_SUBMIT_TX, req.encode_to_vec())?;
        if !resp.success {
            return Err(format!("submit_tx failed: {}", resp.error));
        }
        SubmitTransactionResponse::decode(&resp.payload[..])
            .map_err(|e| format!("decode submit response: {e}"))
    }

    pub fn get_mempool(&mut self) -> Result<MempoolResponse, String> {
        let resp = self.call(METHOD_GET_MEMPOOL, GetMempoolRequest {}.encode_to_vec())?;
        if !resp.success {
            return Err(format!("get_mempool failed: {}", resp.error));
        }
        MempoolResponse::decode(&resp.payload[..])
            .map_err(|error| format!("decode mempool response: {error}"))
    }

    pub fn get_tx_location(&mut self, tx_hash: Vec<u8>) -> Result<TxLocationResponse, String> {
        let request = GetTxLocationRequest { tx_hash };
        let resp = self.call(METHOD_GET_TX_LOCATION, request.encode_to_vec())?;
        if !resp.success {
            return Err(format!("get_tx_location failed: {}", resp.error));
        }
        TxLocationResponse::decode(&resp.payload[..])
            .map_err(|error| format!("decode transaction location: {error}"))
    }

    pub fn get_random_outputs(
        &mut self,
        count: u32,
        below_index: u64,
    ) -> Result<RandomOutputsResponse, String> {
        let req = GetRandomOutputsRequest { count, below_index };
        let resp = self.call(METHOD_GET_RANDOM_OUTPUTS, req.encode_to_vec())?;
        if !resp.success {
            return Err(format!("get_random_outputs failed: {}", resp.error));
        }
        RandomOutputsResponse::decode(&resp.payload[..])
            .map_err(|e| format!("decode random outputs: {e}"))
    }

    pub fn get_output_info(
        &mut self,
        global_indices: Vec<u64>,
    ) -> Result<GetOutputInfoResponse, String> {
        let req = GetOutputInfoRequest { global_indices };
        let resp = self.call(METHOD_GET_OUTPUT_INFO, req.encode_to_vec())?;
        if !resp.success {
            return Err(format!("get_output_info failed: {}", resp.error));
        }
        GetOutputInfoResponse::decode(&resp.payload[..])
            .map_err(|e| format!("decode output info: {e}"))
    }
}
