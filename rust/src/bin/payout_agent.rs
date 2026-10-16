use std::collections::BTreeMap;
use std::io::Write;
use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, PoisonError};
use std::time::Duration;

use courierust::courierust_body::Body;
use courierust::courierust_http::header::HeaderMap;
use courierust::courierust_http::request::Request;
use courierust::courierust_http::response::Response;
use courierust::courierust_http::{Method, StatusCode};
use courierust::courierust_server::{Server, ServerConfig};
use rust_lib_hyphen_wallet::address::HyphenAddress;
use rust_lib_hyphen_wallet::api::wallet::get_default_address;
use rust_lib_hyphen_wallet::transfer::{
    build_transaction, scan_wallet_outputs, submit_built_transaction, transaction_status,
    BuiltTransaction, TransactionRequest, TransactionStatus,
};
use serde::{Deserialize, Serialize};
use zeroize::Zeroizing;

const PROTOCOL_VERSION: u32 = 2;
const MAX_REQUEST_BYTES: usize = 64 * 1024;
const MAX_HEADER_LIST: usize = 16 * 1024;
const READER_TIMEOUT: Duration = Duration::from_secs(30);
const REQUEST_HEAD_TIMEOUT: Duration = Duration::from_secs(10);
const IDLE_TIMEOUT: Duration = Duration::from_secs(60);
const MAX_CONNECTIONS: usize = 64;
const STATE_VERSION: u32 = 1;
const MAX_WIRE_COLLECTION_ITEMS: usize = 1_000_000;

const HEALTH_PATH: &str = "/v1/health";
const SUBMIT_PATH: &str = "/v1/submit";
const STATUS_PATH: &str = "/v1/status";

fn wire_config(max_bytes: usize) -> rustbinary::CompactConfig {
    rustbinary::options()
        .with_limit(max_bytes as u64)
        .with_collection_limit(max_bytes.min(MAX_WIRE_COLLECTION_ITEMS) as u64)
        .reject_trailing_bytes()
        .with_compact_format()
}

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

/// A payout request, decoded per route.
///
/// The method used to be a field inside the envelope; now it is the path, which
/// is what lets a status code carry the outcome instead of a JSON flag.
#[derive(Debug, Deserialize)]
struct HealthRequest {
    version: u32,
}

#[derive(Debug, Deserialize)]
struct SubmitRequest {
    version: u32,
    intent_id: String,
    recipient_address: String,
    amount_atomic: u64,
}

#[derive(Debug, Deserialize)]
struct StatusRequest {
    version: u32,
    intent_id: String,
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

#[derive(Clone, Debug, Serialize, Deserialize, rustbinary::CompactBinary)]
struct AgentRecord {
    recipient_address: String,
    amount_atomic: u64,
    built: BuiltTransaction,
}

#[derive(Clone, Debug, Serialize, Deserialize, rustbinary::CompactBinary)]
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

    /// Serves the pool link until the process is stopped.
    ///
    /// Courierust's server owns the accept loop and its workers; one mutex
    /// serialises the agent itself, which is what keeps "reserve then sign then
    /// submit" single-file: two concurrent requests must never both decide the
    /// same payout is unpaid.
    fn serve(self) -> Result<(), String> {
        let bind = self.config.bind;
        let wallet_address = self.wallet_address.clone();
        let config = ServerConfig {
            http2: false,
            max_body: MAX_REQUEST_BYTES,
            max_header_list: MAX_HEADER_LIST,
            request_header_timeout: Some(REQUEST_HEAD_TIMEOUT),
            read_timeout: Some(READER_TIMEOUT),
            idle_timeout: Some(IDLE_TIMEOUT),
            max_connections: MAX_CONNECTIONS,
            threads: 2,
            ..ServerConfig::default()
        };
        let server = Server::bind_with_config(bind, config)
            .map_err(|error| format!("bind payout agent: {error}"))?;
        let local_addr = server
            .local_addr()
            .map_err(|error| format!("payout agent address: {error}"))?;
        eprintln!(
            "hyphen-payout-agent listening on http://{local_addr} for wallet {wallet_address}"
        );

        let agent = Arc::new(Mutex::new(self));
        server
            .serve(move |request: Request<Body>| AgentService::respond(&agent, request))
            .map_err(|error| format!("serve payout agent: {error}"))
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

/// The routes the pool link exposes.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Route {
    Health,
    Submit,
    Status,
}

impl Route {
    fn of(path: &str) -> Option<Self> {
        match path {
            HEALTH_PATH => Some(Route::Health),
            SUBMIT_PATH => Some(Route::Submit),
            STATUS_PATH => Some(Route::Status),
            _ => None,
        }
    }
}

/// Why a payout request was refused before the agent looked at it.
struct Rejection {
    status: StatusCode,
    message: String,
}

impl Rejection {
    fn bad_request(message: impl Into<String>) -> Self {
        Self {
            status: StatusCode::BAD_REQUEST,
            message: message.into(),
        }
    }

    /// The agent reached a decision and refused. The status stays `200`: the
    /// exchange itself worked, and the reason is in the body where the pool
    /// reads it.
    fn from_agent(message: String) -> Self {
        Self {
            status: StatusCode::OK,
            message,
        }
    }
}

/// Serves one request against the single agent behind the mutex.
///
/// Status codes are used where they say something the body cannot — the route
/// is unknown, the method is not `POST`, the token is wrong, the payload is not
/// JSON of this version. Everything the agent itself decides comes back as
/// `200` with `ok` and `error` in the body, so a pool that was upgraded
/// independently still reads the reason rather than only a code.
struct AgentService;

impl AgentService {
    fn respond(agent: &Arc<Mutex<Agent>>, request: Request<Body>) -> Response<Body> {
        if request.method != Method::POST {
            let mut response = write_json(
                StatusCode::METHOD_NOT_ALLOWED,
                &AgentResponse::error("payout requests are POST"),
            );
            response.headers.insert("allow".into(), "POST".into());
            return response;
        }
        let Some(route) = Route::of(request.uri.path()) else {
            return write_json(
                StatusCode::NOT_FOUND,
                &AgentResponse::error("no such payout endpoint"),
            );
        };

        // Authorization is checked before the body is read: an unauthenticated
        // peer gets no work out of this process, not even JSON parsing.
        let Some(token) = bearer_token(&request.headers) else {
            return write_json(
                StatusCode::UNAUTHORIZED,
                &AgentResponse::error("authentication failed"),
            );
        };
        let body = match request.body.collect() {
            Ok(body) => body,
            Err(error) => {
                return write_json(
                    StatusCode::BAD_REQUEST,
                    &AgentResponse::error(format!("read payout request: {error}")),
                )
            }
        };

        let outcome = {
            // One lock per request, held across the whole exchange: a payout is
            // reserved, signed and submitted as one step, so two requests must
            // never interleave inside it.
            let mut agent = agent.lock().unwrap_or_else(PoisonError::into_inner);
            if !constant_time_eq(token.as_bytes(), agent.token.as_bytes()) {
                return write_json(
                    StatusCode::UNAUTHORIZED,
                    &AgentResponse::error("authentication failed"),
                );
            }

            match route {
                Route::Health => decode::<HealthRequest>(&body)
                    .and_then(|request| check_version(request.version))
                    .and_then(|()| agent.health().map_err(Rejection::from_agent)),
                Route::Submit => decode::<SubmitRequest>(&body)
                    .and_then(|request| check_version(request.version).map(|()| request))
                    .and_then(|request| {
                        agent
                            .submit(
                                request.intent_id,
                                request.recipient_address,
                                request.amount_atomic,
                            )
                            .map_err(Rejection::from_agent)
                    }),
                Route::Status => decode::<StatusRequest>(&body)
                    .and_then(|request| check_version(request.version).map(|()| request))
                    .and_then(|request| {
                        agent
                            .status(request.intent_id)
                            .map_err(Rejection::from_agent)
                    }),
            }
        };

        match outcome {
            Ok(response) => write_json(StatusCode::OK, &response),
            Err(rejection) => {
                write_json(rejection.status, &AgentResponse::error(rejection.message))
            }
        }
    }
}

/// The token from an `authorization: Bearer …` field.
///
/// The scheme is compared case-insensitively, as RFC 9110 §11.1 requires; the
/// token is compared byte for byte elsewhere, in constant time.
fn bearer_token(headers: &HeaderMap) -> Option<&str> {
    let value = headers.get("authorization")?.to_str().ok()?;
    let (scheme, token) = value.split_once(' ')?;
    if !scheme.eq_ignore_ascii_case("bearer") || token.is_empty() {
        return None;
    }
    Some(token)
}

fn decode<T: serde::de::DeserializeOwned>(body: &[u8]) -> Result<T, Rejection> {
    serde_json::from_slice(body)
        .map_err(|error| Rejection::bad_request(format!("malformed payout request: {error}")))
}

fn check_version(version: u32) -> Result<(), Rejection> {
    if version != PROTOCOL_VERSION {
        return Err(Rejection::bad_request(format!(
            "payout protocol version {version} is not supported; this agent speaks {PROTOCOL_VERSION}"
        )));
    }
    Ok(())
}

fn write_json(status: StatusCode, payload: &AgentResponse) -> Response<Body> {
    match serde_json::to_vec(payload) {
        Ok(bytes) => Response::<Body>::with_status(status)
            .header("content-type", "application/json")
            .header("cache-control", "no-store")
            .with_body(Body::from(bytes)),
        // `AgentResponse` is plain owned data, so this arm is unreachable unless
        // the type grows something fallible. An empty body is still a truthful
        // answer; a second failure is not worth inventing.
        Err(error) => {
            eprintln!("payout response encoding failed: {error}");
            Response::<Body>::with_status(StatusCode::INTERNAL_SERVER_ERROR).with_body(Body::Empty)
        }
    }
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
    wire_config(64 * 1024 * 1024)
        .deserialize(&bytes)
        .map_err(|error| error.to_string())
}

fn persist_state(path: &Path, state: &AgentState) -> Result<(), String> {
    let bytes = wire_config(64 * 1024 * 1024)
        .serialize(state)
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
    use courierust::courierust_http::header::{HeaderName, HeaderValue};

    #[test]
    fn routes_come_from_the_path_and_only_the_three_are_served() {
        assert_eq!(Route::of(HEALTH_PATH), Some(Route::Health));
        assert_eq!(Route::of(SUBMIT_PATH), Some(Route::Submit));
        assert_eq!(Route::of(STATUS_PATH), Some(Route::Status));
        assert_eq!(Route::of("/v1/pay"), None);
        assert_eq!(Route::of("/healthz"), None);
        assert_eq!(Route::of(""), None);
    }

    #[test]
    fn the_bearer_scheme_is_matched_case_insensitively() {
        let with = |value: &'static str| {
            let mut headers = HeaderMap::new();
            headers.insert(
                HeaderName::from_lowercase("authorization"),
                HeaderValue::from_static(value),
            );
            headers
        };

        assert_eq!(bearer_token(&with("Bearer abc")), Some("abc"));
        assert_eq!(bearer_token(&with("bearer abc")), Some("abc"));
        assert_eq!(bearer_token(&with("BEARER abc")), Some("abc"));
        assert_eq!(bearer_token(&with("Basic abc")), None);
        assert_eq!(bearer_token(&with("Bearer")), None);
        assert_eq!(bearer_token(&with("Bearer ")), None);
        assert_eq!(bearer_token(&HeaderMap::new()), None);
    }

    #[test]
    fn version_mismatch_is_a_bad_request_that_names_both_versions() {
        assert!(check_version(PROTOCOL_VERSION).is_ok());
        let rejection = check_version(PROTOCOL_VERSION - 1).unwrap_err();
        assert_eq!(rejection.status, StatusCode::BAD_REQUEST);
        assert!(rejection.message.contains(&PROTOCOL_VERSION.to_string()));
    }

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
