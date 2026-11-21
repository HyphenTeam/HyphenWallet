# Wallet operations · 钱包使用指南

## Recovery, scanning and confirmation

New HYN3 recovery phrases start with `hy3-` and end with `-hy3`. Copy both markers. The Rust encoder supports 12, 15, 18, 21 or 24 words. Restore a marked phrase with the original password. The HYN3 derivation uses a BLAKE3 checksum, Argon2id v19 and a 64-byte keyed BLAKE3 XOF. Unmarked historical phrases select the original password transform and PBKDF2 derivation. Confirm the receiving address after recovery. HYN2 balances and signed receipts belong to their original genesis. [Protocol transcripts and migration procedure](https://github.com/HyphenTeam/Hyphen/wiki/HYN3-Identity-and-Recovery)

Record the recovery words in their original order and retain the password used to create the Flutter wallet. Store the two backups separately and offline. The wallet derives its keys from both inputs, so a different password produces a different address. After recovery, compare the receiving address with a copy saved when the wallet was created. Local wallet files use Argon2id for key derivation and XChaCha20-Poly1305 for authenticated encryption.

The restore screen adds a wallet and trims the ends of the phrase. Historical recovery reads its internal whitespace and the original password as UTF-8 bytes. Preserve repeated spaces and the original Unicode form. An executable built from wallet commit `aac6300` and its own lockfile produced the same receiving address for the historical recovery fixture.

To migrate an old encrypted container, unlock it with the original password and record the receiving address. Use Add wallet → Restore with the exact original phrase and password. This writes a separate `HYWLT001` record. Lock and unlock the restored wallet and compare its address with the original before using it. This procedure preserves the original encrypted record and recovery derivation.

To reproduce the Flutter service recovery test, build the Rust library in release mode, set `HYPHEN_WALLET_TEST_LIBRARY` to its absolute path, and run `flutter test test/native_recovery_test.dart`. On Windows the library is `rust/target/release/rust_lib_hyphen_wallet.dll`. The test uses the native cryptographic functions with an in-memory secure-storage fixture. [Native recovery test](../test/native_recovery_test.dart)

Connect to the binary RPC endpoint of a trusted HYN3 node. The wallet defaults to `127.0.0.1:48333`. The Rust client pins the network magic, genesis hash, consensus parameter hash, block version and work protocol version. It checks block ancestry and transaction roots, reconstructs global output indices, and tracks spent key images from genesis. An output range starting later in the chain still accounts for earlier spends. Public key images can spill to temporary files in the application cache during a large scan.

After sending, use the transaction hash to check canonical inclusion and rescan for change. RPC admission places a transaction in the mempool. A restored wallet may take time to rebuild its balance as it reads the chain. A remote node supplies the canonical history used for the scan.

Upgrade the node before upgrading scanning clients. For a rewarded block, binary RPC must return the miner's `block_authorization` in field 6. The scanner verifies the signature and reconstructs the output from the recipient keys and `header.reward`. On HYN3 it also checks that `header.extra_nonce` commits to the two authorized recipient keys.  For ordinary payments the wallet checks the reported block, position and transaction root. Confirmation depth comes from that node's reported tip.

While unlocked, the wallet checks the tip hash every five seconds and rescans after a change. Receive shows the latest incoming payment with unspent outputs, its remaining amount and confirmations. A reorganization can remove the receipt and reduce the balance. In the local PPLNS test, the receipt disappeared after height 16 was replaced and returned when the same transaction confirmed at height 22. Sender change is excluded.

Upgrading the app removes legacy output caches and the shared biometric credential. Rescan to rebuild spendable outputs. New caches contain amounts and output derivation data. The unlocked wallet derives the one-time spending key when signing. Biometric unlock uses a wallet-specific credential after password unlock with biometrics enabled. The payment form accepts at most 12 decimal places and retains the exact atomic amount through signing.

The experimental WOTS message-signing entry point now returns an error. Its previous interface could select the same one-time key for multiple messages. The corrected verifier uses the complete three-digit checksum, so a historical experimental signature can fail verification. Ordinary payments use CLSAG. The historical password transform uses the WOTS public key and preserves its previous derivation.

## Conditional offline payments

The home balance comes from a successful output scan for the active wallet and RPC endpoint. It displays all twelve decimal places. When the node reports a changed tip, or synchronization fails, the wallet hides the previous balance and incoming receipt until it completes a scan. Mining totals and pending pool rewards appear in the rewards panel. For an offline order, keep your signed invoice and check the canonical payment with `hyphen-offline confirm OWN_NODE_DB PACKET INVOICE OWN_ADDRESS NET --min-confirmations N` after synchronizing and stopping your own node.

首页余额取自当前钱包在所选节点上的成功扫描，显示完整十二位小数。发现链顶变化或同步失败时，钱包暂时隐藏余额和上次入款，重扫成功后恢复。累计挖矿奖励和矿池待付款在奖励栏单列。双离线订单请保留自己签发的请求，待自己的节点同步并停止后，用上面的 `confirm` 命令核对该笔兑付。

收款页和活动页都从成功的链扫描读取最近一笔仍有未花输出的入款。本地历史中的方向、金额及交易号不能证明入账。对具体订单，可让自有 HYN3 节点保持运行，用 `hyphen-offline confirm-online --rpc 127.0.0.1:48333 PACKET INVOICE OWN_ADDRESS NET --min-confirmations N` 核对。加上 `--save-settlement observed.tx` 可留存签名原文，用于复核竞争兑付。

Receive and Activity show the latest incoming transfer with unspent outputs from the active scan. Local history supplies outgoing submissions. For order-specific verification, `confirm-online` checks the retained invoice against your own running HYN3 node. The optional evidence file preserves the observed transaction across reorganizations.

For whole-reserve payments on `neural-devnet`, `hyphen-reserve-wallet prepare` saves the signed funding transaction. `submit` relays the saved transaction, and `balance` scans the canonical chain for wallet outputs. The node repository’s `hyphen-offline` signer verifies a local checkpoint and the recipient’s request before recording a conditional receipt. Back up the latest signed delivery together with the funding terms. The Flutter NFC screen exchanges receiving addresses. [Offline payment commands and recovery](https://github.com/HyphenTeam/Hyphen/wiki/Offline-Payments)

## Single-output disclosure

On a stopped, synchronized node, export the public transaction and its current output position. On the wallet host, run `hyphen-disclose` with the intended auditor public key, scope digest and expiry as Unix seconds. Its standard input takes the raw 64-byte BIP39 seed from the unlocked wallet. The default account, change and address index are all zero. Supply the three numbers after the expiry for another address. These POSIX shell commands use binary stdin redirection and UTF-8 JSON files.

```sh
hyphen-audit --network "$NETWORK" --data-dir "$NODE_DB" --export-output "$GLOBAL_INDEX" > output.json
hyphen-disclose output.json "$AUDITOR_HEX" "$SCOPE_HEX" "$EXPIRES_UNIX" < "$RAW_SEED_FILE" > disclosure.json
hyphen-audit --network "$NETWORK" --data-dir "$NODE_DB" --disclosure disclosure.json --auditor "$AUDITOR_HEX" --scope "$SCOPE_HEX"
```

The recipient verifies against their own node's current branch and clock. The JSON reveals the amount, blinding and transaction location to everyone who receives it. The auditor and scope are bound to the Schnorr proof. Deliver the file through a confidential channel.

## Shared pool payout agent

The HYN3 pool uses direct SOLO coinbase rewards. The agent below is maintained for independent payout integration.

Build the signer and start it on the same host as the pool. Provide a dedicated 64-byte seed (raw bytes or 128 hex digits) and a 32–256 character bearer token. Use a fee accepted by the node's relay policy. The example uses devnet atomic units.

```sh
cargo build --release --locked --manifest-path rust/Cargo.toml --bin hyphen-payout-agent
./rust/target/release/hyphen-payout-agent --network neural-devnet --bind 127.0.0.1:38401 --node-host 127.0.0.1 --node-port 48333 --seed-file pool.seed --token-file payout.token --state-dir payout_agent_state/neural-v3 --fee 1000000
```

The agent exposes authenticated `/v1/health`, `/v1/submit` and `/v1/status` routes on loopback. It saves the signed transaction before broadcasting it, reuses it on retry and processes unconfirmed payouts in sequence. Preserve the seed, token and agent state across restarts. [SOLO pool settlement](https://github.com/HyphenTeam/HyphenPool/wiki/Operations#solo-settlement)

One agent holds the state-directory lock for its lifetime. It replaces the saved state atomically from a temporary file in the same directory. If the old main file is absent at upgrade, the agent can recover the previous `.bak`. A corrupt main file produces a startup error. Stop the agent before copying its state for backup.

## Builds and compatibility

The historical HYOF receipt candidate uses wallet commit `ba84c48231e57243ce5b583e4fe2a392163eaa34` and shared consensus commit `f78878eb53e2966ac10aaf51a272e57cf1e757b9`. The Windows desktop distribution requires the executable, its DLLs and the `data` directory together. Its native bridge verified the canonical payout and scan anchor against the recipient's running local node. The Android ARM64 APK passed APK Signature Scheme v2 verification with the local Android Debug certificate. Both applications contain the four font files from the frozen source. Physical-device NFC, secure storage and hardware signing still need acceptance testing.

| Receipt candidate / 收款核验候选 | SHA-256 |
| --- | --- |
| Windows x64 `hyphen_wallet.exe` | `3af3e29355ecc7d8d92ba8fdae3e5824845ffe8ead44ed7a19211c3db2846361` |
| Windows x64 `rust_lib_hyphen_wallet.dll` | `c6cd90fa5f234ea323d60ec042ebffffb71eb5b89a43a0b0ce5c94e3d3217e30` |
| Windows `data/app.so` | `59092b44b731901c169a631972ad945ad9da86e849306b6ca5d6afbaf8ed9c90` |
| Android ARM64 `hyphen-wallet-arm64.apk` | `69dc0af8894fc421482930ef1b0fa0ed5a5ca55c6aec0356eea2215a0c11aebd` |

桌面版启动时需要保留同一目录下的动态库和 `data`。此次开发网实测逐项核对实际到账交易、净额和扫描链顶。Android 包采用调试证书，真机 NFC、硬件签名和安全存储仍待验收。下表保留较早的收款界面构建记录。

| Local release build with the receive view | SHA-256 |
| --- | --- |
| Windows x64 `hyphen_wallet.exe` | `9c9a8838ff7f280448b8eecb1f99d3a093e4c905a235fb398f866fc43330c2cb` |
| `rust_lib_hyphen_wallet.dll` | `45372bcdc0bd08301546233f4de945361c109814b92410ea9339a2a34a874918` |
| `data/app.so` | `7a9b16eae01de43332e41233a4d5b8aecb41991fae0825c60f90e6cf3f646b0e` |
| Android ARM64 `app-release.apk` | `8c87b844c1c8a9445da7c245b50264b8fa377c92269f118b420e4dfe3170c9da` |

`apksigner verify --print-certs` identified the local APK signer as `CN=Android Debug`, certificate SHA-256 `44ee3a577dfaa59d7b6d692168f4bfd17e56ea70dcd51557dff57fc425a63cc8`.

The four TTF files extracted from this APK and the four files in the Windows release assets each matched the source manifest byte for byte. The Google Sans license file also matched in both builds. The record is `target/font-payload-review-xph9hiy9/result.json` in the node workspace.

The Rust lockfile pins the base-chain revision and `pubspec.lock` pins Flutter packages. Run `flutter analyze`, `flutter test` and `cargo test --locked --manifest-path rust/Cargo.toml` after protocol or bridge changes. The node's identity vectors and an actual devnet transfer cover compatibility across repositories. The Windows and Android builds use a native Rust library. The release signing identity is a separate deployment choice. Fonts are registered in `pubspec.yaml`; their checksums are listed in `assets/fonts/manifest.json`.

Google Sans includes the authors' license. The wallet bundles three static HarmonyOS Sans SC 2.400 files. Huawei's older SC package contains static version 1.0. Its current download contains one SC font with SHA-256 `8978e05044e7089ad6a9de38c505c8148305607983487435a916d2610700a7ca`. Neither package matches the three hashes in the wallet manifest. The accompanying grant covers unmodified fonts supplied under the agreement and requires an in-app notice and retention of the copyright notice and agreement. Distribution of the wallet's exact files still needs matching provenance and terms. [Wallet font manifest](../assets/fonts/manifest.json) · [Google Sans license](../assets/fonts/GoogleSans-OFL.txt) · [Huawei design resources](https://developer.huawei.com/consumer/cn/design/resource)

## 中文说明

在 `neural-devnet` 上，使用 `hyphen-reserve-wallet prepare` 保存已签名的预锁交易，再用 `submit` 提交。`balance` 扫描规范链并计算钱包余额。收款人使用 `hyphen-offline`，依据自己的检查点和签名请求核验收到的凭证。请将最新的签名凭证与原始预锁条款一并备份。Flutter 的 NFC 收款功能用于交换收款地址。[离线付款与恢复](https://github.com/HyphenTeam/Hyphen/wiki/Offline-Payments)

钱包中的三款 HarmonyOS Sans SC 静态字重标记为 2.400 版。华为旧版下载包含 1.0 版静态字体，当前下载包含单个 SC 字体，两者均与钱包清单的三个哈希不同。发布仍需核对这三份原文件的来源、适用授权及软件内的声明要求。[字体清单](../assets/fonts/manifest.json) · [华为设计资源](https://developer.huawei.com/consumer/cn/design/resource)

本地备选 Regular、Medium、Bold 文件逐字节匹配旧版 `HarmonyOS-Sans.zip` 中的同名字重。该包的 SHA-256 为 `fb02c86e358cd9aad8d4dfa957ee502381e7ee2e94499a9133add4324b6ce69a`，也与已核对的华为旧版包一致。钱包静态 2.400 的来源仍待确认。

请分别离线备份按顺序排列的助记词和创建 Flutter 钱包时使用的原密码。两者共同派生密钥。输入其他密码会得到不同的地址，恢复后请与以前保存的收款地址核对。本地钱包文件使用 Argon2id 和 XChaCha20-Poly1305 认证加密。

恢复入口会新增一个钱包，支持 12、15、18、21 或 24 个词。HYN3 须保留首词的 `hy3-`、末词的 `-hy3` 及原始密码。未标记的历史助记词使用旧版密码变换，内部空白和密码的 Unicode 字节形式均影响地址。历史恢复测试另以旧版 `aac6300` 核对同一组公开测试词与密码对应的收款地址。

连接可信 HYN3 节点的二进制 RPC，默认端点为 `127.0.0.1:48333`。钱包核对网络标识、创世哈希、共识参数哈希和协议版本，从创世块开始验证祖先与交易根，重建全局输出索引并核对已花费输入。指定较晚的输出起始高度时，仍会检查之前发生的花费。大型扫描可把公开的 key image 临时写入应用缓存目录。发送后按交易哈希查链上确认，再重扫找零。

先升级节点，再升级钱包。扫描奖励时，钱包验证矿工授权、重算收款输出，并核对块头 `extra_nonce` 中的奖励收款公钥承诺。普通付款会核对块内位置与交易根，确认深度依赖所连节点的链顶。解锁后每五秒检查链顶哈希，变化时重扫。收款页显示最近一笔仍有未花输出的普通收款及其剩余金额和确认数，排除找零。分叉时收款可能撤销，同一交易重新确认后恢复。输出缓存和转账历史按 HYN3 身份隔离。

发送金额最多保留 12 位小数，确认和签名使用同一笔整数金额。实验性 WOTS 消息签名入口已停用，校验和修正后，部分旧消息签名可能无法通过验证。日常付款采用 CLSAG，历史密码变换只使用 WOTS 公钥。

单输出披露使用上面的三条命令。在已同步并停止的节点上导出指定全局索引的交易，钱包端通过标准输入向 `hyphen-disclose` 传入解锁后的原始 64 字节 BIP39 种子，并指定审计方公钥、范围摘要和到期 Unix 时间。账户、找零分支和地址索引默认均为零，可在到期时间后显式指定。接收者在自己的节点上核对当前规范链位置与有效期。披露文件明文包含金额、盲因子和输出位置，应通过保密渠道传递。

共享矿池使用上面的命令在回环地址运行独立付款代理，为矿池单独准备种子、令牌与持久化状态目录。矿池按意图编号预留余额，代理先持久化签名交易再提交；同一意图重试会复用同一笔交易。重启时保留三者。依赖或桥接层升级后，应运行上列检查，并在开发网上核对一次完整付款。
