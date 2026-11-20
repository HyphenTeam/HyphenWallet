# Hyphen Wallet

[简体中文](README_CN.md)

Hyphen Wallet is a Flutter client for the Hyphen research blockchain. Its Rust library derives keys, scans blocks for owned outputs and signs transactions locally. A separate command-line payout agent serves shared mining pools. Use devnet funds while the wallet and protocol await independent review.

## Run on Windows

Install Flutter 3.50.0, Rust 1.97.0 and the Flutter Windows desktop build tools. Start a Hyphen devnet node, then run the following commands from the wallet repository.

```sh
flutter pub get --enforce-lockfile
flutter run -d windows
```

Back up the recovery phrase offline and configure the node's binary RPC endpoint in the wallet. [Wallet operations and payout agent](wiki/Operations.md) · [Hyphen node](https://github.com/HyphenTeam/Hyphen)

## License

The project's own code is licensed under the [PolyForm Strict License 1.0.0](LICENSE). Third-party components and fonts retain their respective terms.
