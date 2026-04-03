# hyphen_wallet

Hyphen wallet is a Flutter application backed by Rust through `flutter_rust_bridge`.

## Supported platforms

Primary targets in this repository:

- Windows
- Android
- Linux
- macOS

Secondary targets:

- iOS
- Web

The Rust bridge output is generated into `lib/src/rust/` and is required for analysis and builds.

## Key capabilities

- Multi-wallet create / restore / rename / switch / delete flows
- BIP39 mnemonic creation and recovery
- Hybrid post-quantum signing exposed from Rust
- Mainnet / testnet switching with address re-derivation
- Light-node and full-node operating modes
- Mining payout address display and QR receive flow
- Localized UI with seven languages

## Development workflow

```bash
cd hyphen_wallet
flutter pub get
flutter_rust_bridge_codegen generate
flutter analyze
flutter run
```

If you modify Rust APIs under `rust/src/api/`, regenerate bindings before running Flutter tools.

## Platform commands

```bash
# Windows
flutter run -d windows
flutter build windows

# Android
flutter run -d android
flutter build apk

# Linux
flutter run -d linux
flutter build linux

# macOS
flutter run -d macos
flutter build macos
```

## Release notes

- Android release signing is not checked into the repository. Configure your own release keystore before distribution.
- Linux desktop builds require GTK3 development packages on the host.
- macOS builds and signing must be performed on macOS.
- When FRB-generated files are missing, `flutter analyze` will fail on imports from `lib/src/rust/`.

## Validation

Commands executed for the current repository update:

```bash
cargo test --workspace
cargo clippy --workspace --all-targets
cd hyphen_wallet
flutter analyze
```

Observed result:

- `cargo test --workspace`: passed
- `flutter analyze`: passed
- `cargo clippy --workspace --all-targets`: passed with two existing warnings outside the wallet app
