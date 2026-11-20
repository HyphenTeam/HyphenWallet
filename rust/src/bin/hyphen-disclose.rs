use std::error::Error;
use std::fs::File;
use std::io::{IsTerminal, Read};
use std::time::{SystemTime, UNIX_EPOCH};

use hyphen_crypto::stealth::{
    EphemeralKey, decrypt_amount, derive_commitment_blinding, recover_one_time_key,
};
use hyphen_crypto::{Hash256, PublicKey, SpendKey, ViewKey};
use hyphen_tx::note::{Note, OwnedNote};
use hyphen_tx::transaction::{MAX_TRANSACTION_SIZE, Transaction};
use hyphen_wallet::generate_disclosure;
use rust_lib_hyphen_wallet::chain_identity::CHAIN_IDENTITIES;
use rust_lib_hyphen_wallet::keys::MasterKey;
use serde::Deserialize;
use zeroize::{Zeroize, Zeroizing};

const USAGE: &str = "hyphen-disclose OUTPUT.json AUDITOR_HEX SCOPE_HEX EXPIRES_UNIX [ACCOUNT CHANGE INDEX]\nRead the unlocked wallet's raw 64-byte BIP39 seed from a pipe. Write the plaintext disclosure to stdout.";

#[derive(Deserialize)]
struct ExportedOutput {
    schema: String,
    network: String,
    chain_id: String,
    txid: String,
    transaction_hex: String,
    global_index: u64,
    output_index: u32,
    block_height: u64,
}

fn hex32(text: &str) -> Result<[u8; 32], Box<dyn Error>> {
    let mut bytes = [0; 32];
    hex::decode_to_slice(text, &mut bytes)?;
    Ok(bytes)
}

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    if args == ["--help"] {
        println!("{USAGE}");
        return Ok(());
    }
    if !matches!(args.len(), 4 | 7) {
        return Err(USAGE.into());
    }
    let mut path = [0u32; 3];
    for (part, text) in path.iter_mut().zip(&args[4..]) {
        *part = text.parse()?;
    }
    let auditor = PublicKey(hex32(&args[1])?);
    let scope = Hash256::from_bytes(hex32(&args[2])?);
    let expires_at: u64 = args[3].parse()?;
    let max_bytes = MAX_TRANSACTION_SIZE * 2 + 2048;
    let mut bytes = Vec::new();
    File::open(&args[0])?
        .take(max_bytes as u64 + 1)
        .read_to_end(&mut bytes)?;
    if bytes.len() > max_bytes {
        return Err("output export exceeds size limit".into());
    }
    let export: ExportedOutput = serde_json::from_slice(&bytes)?;
    if export.schema != "hyphen-canonical-output-v1"
        || !CHAIN_IDENTITIES
            .iter()
            .any(|chain| chain.network == export.network && chain.genesis_hash == export.chain_id)
    {
        return Err("unrecognized canonical output format or chain identity".into());
    }
    let transaction = Transaction::deserialise_limited(&hex::decode(export.transaction_hex)?)?;
    if transaction.hash().to_string() != export.txid {
        return Err("exported transaction hash differs".into());
    }
    let output = transaction
        .outputs
        .get(export.output_index as usize)
        .ok_or("invalid output ordinal")?;
    let chain_id = Hash256::from_bytes(hex32(&export.chain_id)?);
    let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
    if expires_at <= now {
        return Err("expiry must be later than the current time".into());
    }
    let input = std::io::stdin();
    if input.is_terminal() {
        return Err("pipe the raw 64-byte seed to stdin".into());
    }
    let mut seed = Zeroizing::new([0u8; 64]);
    let mut reader = input.lock();
    reader.read_exact(seed.as_mut_slice())?;
    if reader.read(&mut [0])? != 0 {
        return Err("seed must contain exactly 64 bytes".into());
    }
    let keys = MasterKey::from_seed(&seed).derive_bip44(path[0], path[1], path[2]);
    let (secret, public) = recover_one_time_key(
        &ViewKey(keys.view_secret.to_bytes()),
        &SpendKey(keys.spend_secret.to_bytes()),
        &EphemeralKey(output.ephemeral_pubkey),
        export.output_index.into(),
    )?;
    let secret = Zeroizing::new(secret);
    if public.compress().to_bytes() != output.one_time_pubkey {
        return Err("the selected wallet address does not own this output".into());
    }
    let shared = Zeroizing::new(*secret - keys.spend_secret);
    let mut owned = OwnedNote {
        note: Note {
            commitment: output.commitment,
            one_time_pubkey: output.one_time_pubkey,
            ephemeral_pubkey: output.ephemeral_pubkey,
            encrypted_amount: output.encrypted_amount,
            global_index: export.global_index,
            block_height: export.block_height,
        },
        value: decrypt_amount(&output.encrypted_amount, &shared),
        blinding: derive_commitment_blinding(&shared).to_bytes(),
        spend_sk: secret.to_bytes(),
    };
    let proof = generate_disclosure(
        &owned,
        &transaction,
        export.output_index,
        chain_id,
        auditor,
        scope,
        now,
        expires_at,
    );
    owned.spend_sk.zeroize();
    println!("{}", serde_json::to_string(&proof?)?);
    Ok(())
}
