# Hyphen Wallet

[中文说明](README_CN.md)

Hyphen Wallet is the independent Flutter client for the Hyphen base chain. The
Flutter application owns presentation and local state; the Rust library owns
mnemonic handling, key derivation, address encoding, output scanning,
transaction construction, signing, and node RPC framing. This repository also
builds `hyphen-payout-agent`, the narrowly scoped signer used by Hyphen Pool.

## Security status

This is experimental wallet software. It has not received an external wallet,
cryptographic, mobile, or supply-chain audit. Use devnet funds only.

- Wallet files use a versioned Argon2id envelope (64 MiB, 3 iterations, one
  lane) and XChaCha20-Poly1305 authenticated encryption. Historical BLAKE3-XOF
  files remain read-only compatible so users can unlock and migrate them.
- The mnemonic remains the recovery authority. Device secure storage and a
  password do not replace an offline mnemonic backup.
- Chain transactions currently rely on the base chain's Ristretto/CLSAG/range
  proof stack. That stack is not independently audited.
- The Ed25519 + WOTS message API is experimental. Its WOTS public key is not
  anchored by consensus and the stateless API cannot enforce one-time use. It
  is not evidence that the wallet or chain is post-quantum secure.
- The historical `pqTransformPassword` API is retained for deterministic
  recovery compatibility. A deterministic transform cannot add entropy to a
  weak password and is not a password KDF.

## Supported build targets

Windows, Linux, and macOS desktop projects are present. An iOS runner is present
but release signing and App Store provisioning are operator responsibilities.
There is no complete Android application project in this repository, and the
web target cannot use the native Rust transaction stack as-is. Automated GitHub
releases therefore publish desktop bundles and the payout-agent executable.

## Build

Use Flutter 3.44.6 and Rust 1.97.0:

```bash
flutter pub get
flutter analyze
cargo test --manifest-path rust/Cargo.toml --locked
flutter run -d windows   # or linux / macos
```

The Rust lockfile pins the exact Hyphen base-chain commit used for crypto,
transaction, and proof compatibility. Updating that commit is a protocol
upgrade and must be followed by Rust tests, Flutter analysis, a desktop build,
and an end-to-end devnet transfer test.

## Wallet lifecycle

Create or restore a wallet in the UI, write the mnemonic down offline, and
verify the backup before receiving value. Configure the node RPC host and port,
scan from a known height, and compare the displayed chain with the intended
network. A rescan discards stale cached assumptions and filters outputs whose
key images are already spent.

Transaction construction selects owned outputs, fetches decoys, constructs
CLSAG signatures and range proofs, and submits a serialized transaction to the
node. Node acceptance means mempool admission, not confirmation. Confirmation
tracking must tolerate a transaction disappearing after a reorg.

## Wallet mathematics

For a Pedersen amount commitment

```text
C = vG + rH,
```

`v` is the amount and `r` is a blinding scalar. A valid confidential transfer
must prove every output amount lies in range and preserve value. Ignoring the
protocol's pseudo-output notation, the conservation relation is

```text
sum C_in - sum C_out - fee G = 0,
```

after input and output blindings are balanced. Range proofs prevent satisfying
the group equation with negative values represented modulo the scalar field.
CLSAG proves that one member of each input ring knows the spend secret while
hiding which member, and the key image/nullifier gives a deterministic
double-spend marker. These claims depend on the exact base-chain verifier and
its cryptographic assumptions; UI balance arithmetic is not a substitute.

The encrypted-wallet format authenticates its 64-byte header as associated
data. Let `K = Argon2id(prehash(password), salt)` and let AEAD encryption be

```text
(ciphertext, tag) = XChaCha20Poly1305.Encrypt(K, nonce, mnemonic, header).
```

Changing the format version, KDF parameters, salt, nonce, ciphertext, or tag
causes authentication failure. Random 128-bit salts separate equal passwords;
random 192-bit nonces make accidental nonce reuse negligible. Security still
depends on password entropy, OS randomness, Argon2 and XChaCha20-Poly1305, and
the device remaining uncompromised.

## Automatic pool payout agent

Build the agent:

```bash
cargo build --release --locked --manifest-path rust/Cargo.toml \
  --bin hyphen-payout-agent
```

It accepts a 64-byte raw BIP39 seed or 128 hex characters in `--seed-file` and
a 32-256 character secret in `--token-file`:

```bash
./rust/target/release/hyphen-payout-agent \
  --bind 127.0.0.1:38401 \
  --node-host 127.0.0.1 \
  --node-port 48333 \
  --seed-file ./pool.seed \
  --token-file ./payout.token \
  --state-dir ./payout_agent_state \
  --network devnet \
  --account 0 \
  --ring-size 4 \
  --fee 1000
```

The listener refuses non-loopback addresses. It checks the token in constant
time, validates network-correct recipients, persists `intent_id -> signed
transaction`, permits only one unconfirmed transaction to avoid overlapping
input selection, rebroadcasts after crashes, and reports confirmation status.
It never decides miner balances; Pool accounting does that independently.

The idempotency property is narrow: for a fixed intent `i`, every successful
retry returns the same transaction hash `h_i`. If a caller tries to bind `i` to
different payment data, the request is rejected. This prevents crash retries
from signing multiple transactions for one intent, but cannot protect a stolen
seed or token.

## CI and releases

CI runs Rust formatting, strict Clippy, tests, Flutter formatting/analysis, and
a desktop build gate. Successful CI on `main` triggers commit-bound desktop and
payout-agent builds. Release archives contain build/debug metadata and SHA-256
files and are published as prereleases because the wallet is not audited.

Never upload a mnemonic, seed file, encrypted wallet, payout token, screenshots
containing recovery words, or production signing state.

## License

HyphenWallet is licensed under the GNU Affero General Public License v3.0. See
[LICENSE](LICENSE) for the complete terms.
