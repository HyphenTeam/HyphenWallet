use std::collections::BTreeMap;
use std::io::{Read, Write};
use std::net::{SocketAddr, TcpListener, TcpStream};
use std::path::{Path, PathBuf};
use std::time::Duration;

use rust_lib_hyphen_wallet::address::HyphenAddress;
use rust_lib_hyphen_wallet::api::wallet::get_default_address;
use rust_lib_hyphen_wallet::transfer::{
    build_transaction, scan_wallet_outputs, submit_built_transaction, transaction_status,
    BuiltTransaction, TransactionRequest, TransactionStatus,
};
use serde::{Deserialize, Serialize};
use zeroize::Zeroizing;

const PROTOCOL_VERSION: u32 = 1;
const MAX_REQUEST_BYTES: usize = 64 * 1024;
const STATE_VERSION: u32 = 1;

#[derive(Clone, Debug)]
struct Config {
    bind: SocketAddr,
    node_host: String,
    node_port: u16,
    seed_file: PathBuf,
    token_file: PathBuf,
    state_dir: PathBuf,
    account: u32,
    network: String,
    ring_size: u32,
    fee: u64,
}

#[derive(Debug, Deserialize)]
struct AgentRequest {
    version: u32,
    token: String,
    #[serde(flatten)]
    method: AgentMethod,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "method", rename_all = "snake_case")]
enum AgentMethod {
    Health,
    Submit {
        intent_id: String,
        recipient_address: String,
        amount_atomic: u64,
    },
    Status {
        intent_id: String,
    },
}

#[derive(Debug, Serialize)]
struct AgentResponse {
    version: u32,
    ok: bool,
    error: String,
    wallet_address: String,
    fee_atomic: u64,
    intent_id: String,
    tx_hash: String,
    status: Option<TransactionStatus>,
}

impl AgentResponse {
    fn error(error: impl Into<String>) -> Self {
        Self {
            version: PROTOCOL_VERSION,
            ok: false,
            error: error.into(),
            wallet_address: String::new(),
            fee_atomic: 0,
            intent_id: String::new(),
            tx_hash: String::new(),
            status: None,
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct AgentRecord {
    recipient_address: String,
    amount_atomic: u64,
    built: BuiltTransaction,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct AgentState {
    version: u32,
    records: BTreeMap<String, AgentRecord>,
}

impl Default for AgentState {
    fn default() -> Self {
        Self {
            version: STATE_VERSION,
            records: BTreeMap::new(),
        }
    }
}

struct Agent {
    config: Config,
    seed_hex: Zeroizing<String>,
    token: Zeroizing<String>,
    wallet_address: String,
    state_path: PathBuf,
    state: AgentState,
}

impl Agent {
    fn open(config: Config) -> Result<Self, String> {
        if !config.bind.ip().is_loopback() {
            return Err("payout agent must bind to a loopback address".into());
        }
        if config.fee == 0 {
            return Err("payout fee must be greater than zero".into());
        }
        if config.ring_size < 2 {
            return Err("ring size must be at least 2".into());
        }
        if !matches!(config.network.as_str(), "mainnet" | "testnet" | "devnet") {
            return Err("network must be mainnet, testnet, or devnet".into());
        }

        let seed_hex = Zeroizing::new(load_seed(&config.seed_file)?);
        let token = Zeroizing::new(load_token(&config.token_file)?);
        let wallet_address =
            get_default_address(seed_hex.to_string(), config.network.as_str() == "mainnet")?;
        std::fs::create_dir_all(&config.state_dir)
            .map_err(|error| format!("create payout state directory: {error}"))?;
        let state_path = config.state_dir.join("payout_agent.bin");
        let state = load_state_with_backup(&state_path)?;
        if state.version != STATE_VERSION {
            return Err(format!(
                "unsupported payout state version {}",
                state.version
            ));
        }

        Ok(Self {
            config,
            seed_hex,
            token,
            wallet_address,
            state_path,
            state,
        })
    }

    fn serve(mut self) -> Result<(), String> {
        let listener = TcpListener::bind(self.config.bind)
            .map_err(|error| format!("bind payout agent: {error}"))?;
        eprintln!(
            "hyphen-payout-agent listening on {} for wallet {}",
            self.config.bind, self.wallet_address
        );
        for incoming in listener.incoming() {
            match incoming {
                Ok(mut stream) => {
                    let response = match read_request(&mut stream) {
                        Ok(request) => self.handle(request),
                        Err(error) => AgentResponse::error(error),
                    };
                    if let Err(error) = write_response(&mut stream, &response) {
                        eprintln!("payout response write failed: {error}");
                    }
                }
                Err(error) => eprintln!("payout connection failed: {error}"),
            }
        }
        Ok(())
    }

    fn handle(&mut self, request: AgentRequest) -> AgentResponse {
        if request.version != PROTOCOL_VERSION {
            return AgentResponse::error("unsupported payout-agent protocol version");
        }
        if !constant_time_eq(request.token.as_bytes(), self.token.as_bytes()) {
            return AgentResponse::error("authentication failed");
        }

        let result = match request.method {
            AgentMethod::Health => self.health(),
            AgentMethod::Submit {
                intent_id,
                recipient_address,
                amount_atomic,
            } => self.submit(intent_id, recipient_address, amount_atomic),
            AgentMethod::Status { intent_id } => self.status(intent_id),
        };
        result.unwrap_or_else(AgentResponse::error)
    }

    fn health(&mut self) -> Result<AgentResponse, String> {
        rust_lib_hyphen_wallet::transfer::get_chain_status(
            self.config.node_host.clone(),
            self.config.node_port,
        )?;
        Ok(AgentResponse {
            version: PROTOCOL_VERSION,
            ok: true,
            error: String::new(),
            wallet_address: self.wallet_address.clone(),
            fee_atomic: self.config.fee,
            intent_id: String::new(),
            tx_hash: String::new(),
            status: None,
        })
    }

    fn submit(
        &mut self,
        intent_id: String,
        recipient_address: String,
        amount_atomic: u64,
    ) -> Result<AgentResponse, String> {
        validate_intent_id(&intent_id)?;
        validate_recipient(&recipient_address, &self.config.network)?;
        if amount_atomic == 0 {
            return Err("payout amount must be greater than zero".into());
        }

        if let Some(record) = self.state.records.get(&intent_id) {
            if record.recipient_address != recipient_address
                || record.amount_atomic != amount_atomic
            {
                return Err("intent id is already bound to different payout data".into());
            }
        } else {
            self.ensure_no_unconfirmed_intent()?;
            let chain = rust_lib_hyphen_wallet::transfer::get_chain_status(
                self.config.node_host.clone(),
                self.config.node_port,
            )?;
            let scan = scan_wallet_outputs(
                self.config.node_host.clone(),
                self.config.node_port,
                self.seed_hex.to_string(),
                self.config.account,
                0,
                chain.height,
                self.config.network.as_str() == "mainnet",
            )?;
            let built = build_transaction(TransactionRequest {
                host: self.config.node_host.clone(),
                port: self.config.node_port,
                seed_hex: self.seed_hex.to_string(),
                account: self.config.account,
                recipient_address: recipient_address.clone(),
                amount: amount_atomic,
                fee: self.config.fee,
                owned_outputs_json: scan.outputs_json,
                ring_size: self.config.ring_size,
            })?;
            self.state.records.insert(
                intent_id.clone(),
                AgentRecord {
                    recipient_address,
                    amount_atomic,
                    built,
                },
            );
            persist_state(&self.state_path, &self.state)?;
        }

        let record = self
            .state
            .records
            .get(&intent_id)
            .cloned()
            .ok_or("payout intent disappeared")?;
        let mut status = transaction_status(
            self.config.node_host.clone(),
            self.config.node_port,
            &record.built.tx_hash_hex,
        )?;
        if status == TransactionStatus::Unknown {
            let send = submit_built_transaction(
                self.config.node_host.clone(),
                self.config.node_port,
                record.built.clone(),
            )?;
            if !send.accepted {
                let after = transaction_status(
                    self.config.node_host.clone(),
                    self.config.node_port,
                    &record.built.tx_hash_hex,
                )?;
                if after == TransactionStatus::Unknown {
                    return Err(format!("node rejected payout: {}", send.error_message));
                }
                status = after;
            } else {
                status = transaction_status(
                    self.config.node_host.clone(),
                    self.config.node_port,
                    &record.built.tx_hash_hex,
                )?;
            }
        }

        Ok(self.record_response(intent_id, &record, status))
    }

    fn status(&mut self, intent_id: String) -> Result<AgentResponse, String> {
        validate_intent_id(&intent_id)?;
        let record = self
            .state
            .records
            .get(&intent_id)
            .ok_or("unknown payout intent")?;
        let status = transaction_status(
            self.config.node_host.clone(),
            self.config.node_port,
            &record.built.tx_hash_hex,
        )?;
        Ok(self.record_response(intent_id, record, status))
    }

    fn ensure_no_unconfirmed_intent(&mut self) -> Result<(), String> {
        for (intent_id, record) in &self.state.records {
            let status = transaction_status(
                self.config.node_host.clone(),
                self.config.node_port,
                &record.built.tx_hash_hex,
            )?;
            if !matches!(status, TransactionStatus::Confirmed { .. }) {
                return Err(format!(
                    "payout intent {intent_id} is not confirmed; refusing to select overlapping inputs"
                ));
            }
        }
        Ok(())
    }

    fn record_response(
        &self,
        intent_id: String,
        record: &AgentRecord,
        status: TransactionStatus,
    ) -> AgentResponse {
        AgentResponse {
            version: PROTOCOL_VERSION,
            ok: true,
            error: String::new(),
            wallet_address: self.wallet_address.clone(),
            fee_atomic: self.config.fee,
            intent_id,
            tx_hash: record.built.tx_hash_hex.clone(),
            status: Some(status),
        }
    }
}

fn read_request(stream: &mut TcpStream) -> Result<AgentRequest, String> {
    stream
        .set_read_timeout(Some(Duration::from_secs(10)))
        .map_err(|error| format!("set request timeout: {error}"))?;
    let mut bytes = Vec::new();
    stream
        .take((MAX_REQUEST_BYTES + 1) as u64)
        .read_to_end(&mut bytes)
        .map_err(|error| format!("read payout request: {error}"))?;
    if bytes.len() > MAX_REQUEST_BYTES {
        return Err("payout request exceeds 64 KiB".into());
    }
    serde_json::from_slice(&bytes).map_err(|error| format!("decode payout request: {error}"))
}

fn write_response(stream: &mut TcpStream, response: &AgentResponse) -> Result<(), String> {
    let bytes =
        serde_json::to_vec(response).map_err(|error| format!("encode payout response: {error}"))?;
    stream
        .write_all(&bytes)
        .map_err(|error| format!("write payout response: {error}"))?;
    stream
        .flush()
        .map_err(|error| format!("flush payout response: {error}"))
}

fn load_seed(path: &Path) -> Result<String, String> {
    let raw =
        Zeroizing::new(std::fs::read(path).map_err(|error| format!("read seed file: {error}"))?);
    if raw.len() == 64 {
        return Ok(hex::encode(raw.as_slice()));
    }
    let text = std::str::from_utf8(raw.as_slice())
        .map_err(|_| "seed file must contain 64 raw bytes or 128 hex characters")?
        .trim();
    let decoded = Zeroizing::new(
        hex::decode(text).map_err(|error| format!("decode seed file hex: {error}"))?,
    );
    if decoded.len() != 64 {
        return Err(format!(
            "seed file must decode to 64 bytes, got {}",
            decoded.len()
        ));
    }
    Ok(text.to_owned())
}

fn load_token(path: &Path) -> Result<String, String> {
    let token = std::fs::read_to_string(path)
        .map_err(|error| format!("read token file: {error}"))?
        .trim()
        .to_owned();
    if token.len() < 32 || token.len() > 256 {
        return Err("token must contain between 32 and 256 characters".into());
    }
    Ok(token)
}

fn load_state_with_backup(path: &Path) -> Result<AgentState, String> {
    match load_state(path) {
        Ok(state) => Ok(state),
        Err(primary_error) if path.exists() => {
            let backup = sidecar(path, "bak");
            load_state(&backup).map_err(|backup_error| {
                format!(
                    "load payout state failed ({primary_error}); backup failed ({backup_error})"
                )
            })
        }
        Err(_) => Ok(AgentState::default()),
    }
}

fn load_state(path: &Path) -> Result<AgentState, String> {
    let bytes = std::fs::read(path).map_err(|error| error.to_string())?;
    hyphen_codec::deserialize_with_limit(&bytes, 64 * 1024 * 1024)
        .map_err(|error| error.to_string())
}

fn persist_state(path: &Path, state: &AgentState) -> Result<(), String> {
    let bytes = hyphen_codec::serialize_with_limit(state, 64 * 1024 * 1024)
        .map_err(|error| error.to_string())?;
    let temporary = sidecar(path, "next");
    let backup = sidecar(path, "bak");
    let mut file = std::fs::OpenOptions::new()
        .create(true)
        .truncate(true)
        .write(true)
        .open(&temporary)
        .map_err(|error| error.to_string())?;
    file.write_all(&bytes).map_err(|error| error.to_string())?;
    file.sync_all().map_err(|error| error.to_string())?;
    drop(file);

    if path.exists() {
        if backup.exists() {
            std::fs::remove_file(&backup).map_err(|error| error.to_string())?;
        }
        std::fs::rename(path, &backup).map_err(|error| error.to_string())?;
    }
    if let Err(error) = std::fs::rename(&temporary, path) {
        if !path.exists() && backup.exists() {
            let _ = std::fs::rename(&backup, path);
        }
        return Err(error.to_string());
    }
    Ok(())
}

fn sidecar(path: &Path, suffix: &str) -> PathBuf {
    let name = path
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("payout_agent.bin");
    path.with_file_name(format!("{name}.{suffix}"))
}

fn validate_intent_id(intent_id: &str) -> Result<(), String> {
    let bytes = hex::decode(intent_id).map_err(|_| "intent id must be hex")?;
    if bytes.len() != 32 {
        return Err("intent id must be exactly 32 bytes".into());
    }
    Ok(())
}

fn validate_recipient(address: &str, network: &str) -> Result<(), String> {
    let decoded = HyphenAddress::decode(address)?;
    if decoded.is_mainnet() != (network == "mainnet") {
        return Err("recipient belongs to a different network".into());
    }
    Ok(())
}

fn constant_time_eq(left: &[u8], right: &[u8]) -> bool {
    let mut difference = left.len() ^ right.len();
    let max_len = left.len().max(right.len());
    for index in 0..max_len {
        let l = left.get(index).copied().unwrap_or(0);
        let r = right.get(index).copied().unwrap_or(0);
        difference |= (l ^ r) as usize;
    }
    difference == 0
}

fn parse_args() -> Result<Config, String> {
    let mut values = BTreeMap::new();
    let mut args = std::env::args().skip(1);
    while let Some(name) = args.next() {
        if !name.starts_with("--") {
            return Err(format!("unexpected argument: {name}"));
        }
        let value = args
            .next()
            .ok_or_else(|| format!("missing value for {name}"))?;
        if values.insert(name.clone(), value).is_some() {
            return Err(format!("duplicate argument: {name}"));
        }
    }
    let required = |name: &str| {
        values
            .get(name)
            .cloned()
            .ok_or_else(|| format!("missing required argument {name}"))
    };
    let optional = |name: &str, default: &str| {
        values
            .get(name)
            .cloned()
            .unwrap_or_else(|| default.to_owned())
    };

    Ok(Config {
        bind: optional("--bind", "127.0.0.1:38401")
            .parse()
            .map_err(|error| format!("invalid --bind: {error}"))?,
        node_host: optional("--node-host", "127.0.0.1"),
        node_port: optional("--node-port", "48333")
            .parse()
            .map_err(|error| format!("invalid --node-port: {error}"))?,
        seed_file: PathBuf::from(required("--seed-file")?),
        token_file: PathBuf::from(required("--token-file")?),
        state_dir: PathBuf::from(optional("--state-dir", "payout_agent_state")),
        account: optional("--account", "0")
            .parse()
            .map_err(|error| format!("invalid --account: {error}"))?,
        network: optional("--network", "devnet"),
        ring_size: optional("--ring-size", "4")
            .parse()
            .map_err(|error| format!("invalid --ring-size: {error}"))?,
        fee: optional("--fee", "1000")
            .parse()
            .map_err(|error| format!("invalid --fee: {error}"))?,
    })
}

fn main() -> Result<(), String> {
    Agent::open(parse_args()?)?.serve()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn token_comparison_checks_length_and_content() {
        assert!(constant_time_eq(b"same", b"same"));
        assert!(!constant_time_eq(b"same", b"samf"));
        assert!(!constant_time_eq(b"same", b"same-longer"));
    }

    #[test]
    fn intent_id_is_exactly_32_bytes() {
        assert!(validate_intent_id(&"ab".repeat(32)).is_ok());
        assert!(validate_intent_id(&"ab".repeat(31)).is_err());
        assert!(validate_intent_id("not-hex").is_err());
    }

    #[test]
    fn state_round_trip_preserves_signed_transaction() {
        let directory = std::env::temp_dir().join(format!(
            "hyphen_payout_agent_test_{}_{}",
            std::process::id(),
            rand::random::<u64>()
        ));
        std::fs::create_dir_all(&directory).unwrap();
        let path = directory.join("state.bin");
        let mut state = AgentState::default();
        state.records.insert(
            "11".repeat(32),
            AgentRecord {
                recipient_address: "hy1test".into(),
                amount_atomic: 7,
                built: BuiltTransaction {
                    tx_hash_hex: "22".repeat(32),
                    tx_data: vec![1, 2, 3],
                    spent_indices: vec![4],
                    vre_used_adaptive: false,
                },
            },
        );
        persist_state(&path, &state).unwrap();
        assert_eq!(
            load_state(&path).unwrap().records[&"11".repeat(32)]
                .built
                .tx_data,
            vec![1, 2, 3]
        );
        let _ = std::fs::remove_dir_all(directory);
    }
}
