//! Online funding and receipt scanning for the offline-payment devnet.
use rust_lib_hyphen_wallet::{
    address::HyphenAddress,
    keys::MasterKey,
    transfer::{
        BuiltTransaction, TransactionRequest, TransactionStatus, build_transaction_for_network,
        scan_reserve_wallet, submit_transaction_for_network, transaction_status_for_network,
    },
};
use std::{
    error::Error,
    io::{IsTerminal, Read, Write},
    net::SocketAddr,
    path::Path,
};
use zeroize::Zeroizing;

const USAGE: &str = "hyphen-reserve-wallet address | balance RPC | prepare RPC ADDRESS AMOUNT_ATOMIC FEE_ATOMIC SIGNED_FILE | submit RPC SIGNED_FILE\nFor address, balance and prepare, pipe the raw 64-byte BIP39 seed to stdin. Uses account 0 on neural-devnet.";

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    if args == ["--help"] {
        println!("{USAGE}");
        return Ok(());
    }
    if let [cmd, rpc, path] = args.as_slice()
        && cmd == "submit"
    {
        let rpc: SocketAddr = rpc.parse()?;
        let mut bytes = Vec::new();
        let max = hyphen_tx::transaction::MAX_TRANSACTION_SIZE;
        std::fs::File::open(path)?
            .take(max as u64 + 1)
            .read_to_end(&mut bytes)?;
        if bytes.len() > max || hyphen_tx::Transaction::deserialise_limited(&bytes)?.version != 1 {
            return Err("expected a signed regular payment".into());
        }
        let hash = hyphen_crypto::blake3_hash(&bytes).to_string();
        let host = rpc.ip().to_string();
        let signed = BuiltTransaction {
            tx_hash_hex: hash.clone(),
            tx_data: bytes,
            spent_indices: vec![],
            vre_used_adaptive: false,
        };
        let result =
            submit_transaction_for_network(host.clone(), rpc.port(), signed, Some(*b"HYN3"))?;
        if !result.accepted
            && matches!(
                transaction_status_for_network(host, rpc.port(), &hash, Some(*b"HYN3"))?,
                TransactionStatus::Unknown
            )
        {
            return Err(result.error_message.into());
        }
        println!("{hash}");
        return Ok(());
    }
    let stdin = std::io::stdin();
    if stdin.is_terminal() {
        return Err(USAGE.into());
    }
    let mut seed = Zeroizing::new([0u8; 64]);
    let mut input = stdin.lock();
    input.read_exact(&mut *seed)?;
    if input.read(&mut [0])? != 0 {
        return Err("expected exactly 64 seed bytes".into());
    }
    if args == ["address"] {
        let keys = MasterKey::from_seed(&seed).derive_bip44(0, 0, 0);
        println!(
            "{}",
            HyphenAddress::new_testnet(
                keys.view_public.compress().to_bytes(),
                keys.spend_public.compress().to_bytes()
            )
            .encode()
        );
        return Ok(());
    }
    let (rpc, payment) = match args.as_slice() {
        [cmd, rpc] if cmd == "balance" => (rpc, None),
        [cmd, rpc, address, amount, fee, out] if cmd == "prepare" => (
            rpc,
            Some((
                address,
                amount.parse::<u64>()?,
                fee.parse::<u64>()?,
                Path::new(out),
            )),
        ),
        _ => return Err(USAGE.into()),
    };
    let endpoint: SocketAddr = rpc.parse()?;
    let host = endpoint.ip().to_string();
    let port = endpoint.port();
    let scan = scan_reserve_wallet(host.clone(), port, hex::encode(seed.as_slice()))?;
    if let Some((address, amount, fee, out)) = payment {
        let signed = build_transaction_for_network(
            TransactionRequest {
                host: host.clone(),
                port,
                seed_hex: hex::encode(seed.as_slice()),
                account: 0,
                recipient_address: address.clone(),
                amount,
                fee,
                owned_outputs_json: scan.outputs_json,
                ring_size: 4,
            },
            Some(*b"HYN3"),
        )?;
        let dir = out
            .parent()
            .filter(|dir| !dir.as_os_str().is_empty())
            .unwrap_or(Path::new("."));
        let mut staged = tempfile::NamedTempFile::new_in(dir)?;
        staged.write_all(&signed.tx_data)?;
        staged.as_file().sync_all()?;
        staged.persist_noclobber(out)?;
        #[cfg(unix)]
        std::fs::File::open(dir)?.sync_all()?;
        println!("{}", signed.tx_hash_hex);
    } else {
        println!(
            "{{\"balance\":{},\"height\":{},\"outputs\":{}}}",
            scan.total_balance, scan.scanned_height, scan.outputs_json
        );
    }
    Ok(())
}
