# Hyphen Wallet

[简体中文](README_CN.md) · [Wallet documentation](https://github.com/HyphenTeam/HyphenWallet/wiki)

Hyphen Wallet scans the neural development network for private payments and mining rewards. Its Rust signer pins the genesis and consensus parameters before authorizing payments.

## Run on Windows

Install Flutter 3.50.0, Rust 1.97.0 and the Flutter Windows desktop build tools. Start a Hyphen devnet node, then run the following commands from the wallet repository.

```sh
flutter pub get --enforce-lockfile
flutter run -d windows
```

Back up the recovery phrase offline and configure the node's binary RPC endpoint in the wallet. [Wallet operations and payout agent](wiki/Operations.md) · [Hyphen node](https://github.com/HyphenTeam/Hyphen)

Build `hyphen-disclose` with `cargo build --release --locked --manifest-path rust/Cargo.toml --bin hyphen-disclose` to issue a scoped ownership and amount proof for one exported output. [Single-output disclosure](wiki/Operations.md#single-output-disclosure)

## License

The project's own code is licensed under the [PolyForm Strict License 1.0.0](LICENSE). Third-party components and fonts retain their respective terms.
