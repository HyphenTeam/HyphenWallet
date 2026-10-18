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
- Every RPC connection performs a chain-info handshake and pins block version
  3, PoUW version 1, network magic, consensus parameter hash, and genesis hash.
  Nodes that omit these fields or expose the legacy hash-target chain are
  rejected before scanning or transaction submission.
- The `PoUW version 1` field is a chain-identity value. Wallet does not verify
  scientific execution itself and does not imply that task-backed useful-work
  settlement is active; the connected node remains responsible for consensus.
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

## Chain compatibility

Wallet RPC mirrors the append-only protobuf fields exposed by the node's chain
status response. Four identities are pinned: `hyphen-mainnet`,
`hyphen-testnet`, `hyphen-devnet-v2` and `hyphen-neural-devnet-v1`. The current
devnet identity is:

```text
network=hyphen-devnet-v2
network_magic=48594456
consensus_params_hash=521f6cdc47f4424c1ea7b9f4d6770cf114f620cdff62958060f8c6953cb69de8
genesis_hash=5f7c144f0ef27880259b2429e46ef175685da679916fcc6b80c45f457465e32d
block_version=5
pouw_protocol_version=3
```

These values mirror `test-vectors/chain-identity-v6.json` of the base chain and are
pinned in `rust/src/chain_identity.rs`; a unit test fails if the two drift.

Every RPC entry point — chain status, output scan and transaction building —
rebuilds the identity from the node's own reply and rejects the connection when
the magic, parameter hash, genesis hash, block version or PoUW protocol version
does not match a pinned vector. Scanning and sending additionally refuse a node
whose class (mainnet versus testnet/devnet) disagrees with the wallet's network
setting, and sending refuses a recipient address minted for the other class.
This pinning prevents accidental cross-chain use. It does not prove that a
remote node is honest about canonical history; use a trusted node or compare
independent nodes.

## Wallet lifecycle

Create or restore a wallet in the UI, write the mnemonic down offline, and
verify the backup before receiving value. Configure the node RPC host and port,
scan from a known height, and compare the displayed chain with the intended
network.

A scan is always a full scan from genesis and its result replaces the cached
output set. Partial scans cannot be exact over this RPC surface: the node
exposes no key-image index, so a range that omits the block where a cached
output was spent leaves that output looking unspent, and the balance stays
inflated after a spend, a restore on another device, or a chain reset. The full
walk costs the same number of `get_block_by_height` calls, because the partial
path already re-reads every earlier block to rebuild the global output index.
A rescan therefore also repairs a wallet that was pointed at a chain which has
since been replaced — the cached outputs of the old chain cannot survive it.

The home screen reports a failed refresh instead of silently keeping stale
numbers: `WalletState.syncError` carries the reason (for example a pinned
identity mismatch) and the balance card renders it as a banner.

Transaction construction selects owned outputs, fetches decoys, constructs
CLSAG signatures and range proofs, and submits a serialized transaction to the
node. Node acceptance means mempool admission, not confirmation. Outputs the
node accepted as spent are dropped from the cache immediately, so the balance
is briefly understated until the change output confirms; the next scan restores
it. Confirmation tracking must tolerate a transaction disappearing after a
reorg.

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

BIP39 is a compatibility boundary: its mnemonic checksum and seed derivation use
SHA-256 and SHA-512 exactly as the standard specifies. Those primitives are not
used as a Hyphen hash; every chain-defined commitment, transaction digest and
pool digest is BLAKE3. Replacing the BIP39 primitives would make standard
mnemonics unrecoverable, so they stay standard-conformant.

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

The listener refuses non-loopback addresses and serves the pool link as HTTP
(`Courierust`, the same implementation the pool speaks to it): `/v1/health`,
`/v1/submit`, `/v1/status`, with the shared token in an `authorization: Bearer`
header, compared in constant time. It validates network-correct recipients,
persists `intent_id -> signed transaction`, permits only one unconfirmed
transaction to avoid overlapping input selection, rebroadcasts after crashes,
and reports confirmation status. It never decides miner balances; Pool
accounting does that independently.

The idempotency property is narrow: for a fixed intent `i`, every successful
retry returns the same transaction hash `h_i`. If a caller tries to bind `i` to
different payment data, the request is rejected. This prevents crash retries
from signing multiple transactions for one intent, but cannot protect a stolen
seed or token.

## Protocol compatibility

`hyphen-crypto`, `hyphen-tx`, `hyphen-proof`, and `hyphen-wire` are pinned to
public Hyphen Git revision `576bc67d972d1156fbabb1ddf579104d5ff2ff88` (chain
identity v6); the wallet does not use a local path dependency. Binary encoding
uses RustBinary 0.1.8 with Hyphen's bounded, compact, trailing-byte-rejecting
profile — the same profile the chain hashes and signs over. Changing the chain
revision or wire profile is a protocol upgrade. Format fallback must not enter
transaction hashes or signatures.

## CI and releases

CI runs Rust formatting, strict Clippy, tests, Flutter formatting/analysis, and
a desktop build gate. Successful CI on `main` triggers commit-bound desktop and
payout-agent builds. Release archives contain build/debug metadata and BLAKE3
files and are published as prereleases because the wallet is not audited.

`pubspec.lock` records the host every package was resolved from, and the
committed lock targets the canonical `pub.dev`; CI pins `PUB_HOSTED_URL` to that
host for the same reason. If your machine exports a package mirror
(`PUB_HOSTED_URL` / `FLUTTER_STORAGE_BASE_URL`), unset it before running
`flutter pub get` in this repository: a mirror-resolved lock cannot satisfy the
`flutter pub get --enforce-lockfile` CI runs. Both workflows refuse such a lock
by name instead of failing with a 97-package diff.

Never upload a mnemonic, seed file, encrypted wallet, payout token, screenshots
containing recovery words, or production signing state.

## License

HyphenWallet is licensed under the PolyForm Strict License 1.0.0. See
[LICENSE](LICENSE) for the complete terms.

---

<!-- hyphen-bilingual-chinese -->

# 中文版

# Hyphen Wallet

[English](README.md)

Hyphen Wallet 是独立 Flutter 钱包仓库。Flutter 负责界面和本地业务状态，Rust 负责 mnemonic、密钥派生、地址、链扫描、交易构造、签名与节点 RPC。这个仓库还生成 `hyphen-payout-agent`，供 Hyphen Pool 在共享模式下自动付款。

## 安全状态

这是实验性钱包，没有完成外部钱包、密码学、移动端或供应链审计，只应使用 devnet 资产。

钱包文件已经改为版本化 Argon2id + XChaCha20-Poly1305：Argon2id 使用 64 MiB、3 次迭代、1 lane，header 也进入 AEAD 认证。旧 BLAKE3-XOF 格式只保留解密兼容，用于打开并迁移历史钱包。

Mnemonic 才是恢复权限。系统安全存储和密码不能替代离线 mnemonic 备份。链上交易仍依赖主链的 Ristretto、CLSAG 和范围证明，它们尚未外审。

代码中的 Ed25519 + WOTS 消息接口是实验接口：WOTS 公钥没有由共识或身份注册表预先承诺，stateless API 也无法保证一个 WOTS key 只使用一次，所以不能据此声称钱包或区块链已经抗量子。历史 `pqTransformPassword` 只为确定性恢复兼容而保留；固定哈希变换不会增加弱密码的熵，也不是合格的 password KDF。

## 平台与构建

仓库包含 Windows、Linux、macOS 桌面工程。iOS runner 存在，但签名和 App Store provisioning 必须由发布者完成。仓库没有完整 Android application 工程；Web 也不能直接使用当前 native Rust 交易栈。因此自动 Release 发布三个桌面 bundle 和 payout-agent，不虚构 Android/iOS 安装包。

使用 Flutter 3.44.6 和 Rust 1.97.0：

```powershell
flutter pub get
flutter analyze
cargo test --manifest-path rust\Cargo.toml --locked
flutter run -d windows
```

Rust lockfile 固定了 Hyphen 主链依赖提交。升级这个提交属于协议兼容变更，必须重新运行 Rust 测试、Flutter analyze、桌面构建和 devnet 真实转账测试。

## 钱包工作流

创建或恢复钱包后，先离线记录 mnemonic，并实际验证恢复结果，再接收资产。配置节点 RPC，确认网络身份，从可信高度扫描。

每次扫描都是从创世块开始的完整扫描，扫描结果是权威集合，直接替换本地缓存。当前 RPC 没有 key image 索引，局部扫描会漏掉“缓存输出在更晚的区块里被花费”这件事，余额就会虚高；而局部扫描为了重建全局输出序号本来就要重新读一遍之前所有区块，调用次数与全量扫描相同，所以准确性没有额外代价。链被重置、在另一台设备上花费、或从助记词恢复之后，一次全量扫描就能把钱包修回正确状态。

节点身份在建链状态、扫描输出、构造交易三条路径上都会被强制校验：magic、参数哈希、创世哈希、区块版本、PoUW 协议版本必须命中钉死的四条向量；扫描与发送还会拒绝网络等级不符的节点，发送还会拒绝另一网络等级的收款地址。刷新失败不会被静默吞掉，`WalletState.syncError` 会把原因（例如身份不匹配）交给首页显示成横幅。

发送交易时，Rust 选择 owned outputs，获取 ring decoy，构造 CLSAG 与范围证明，再将序列化交易交给节点。节点 accepted 只表示进入 mempool，不是确认；节点确认已花费的输入会立即从缓存移除，因此余额会短暂偏低，找零确认后由下一次扫描补回。交易状态必须按区块高度计算确认数，并能处理 reorg 后交易暂时消失。

## 交易与本地加密的数学说明

Pedersen 金额承诺为：

```text
C=vG+rH.
```

`v` 是金额，`r` 是盲因子。忽略协议中的 pseudo-output 记法，守恒关系可以写成：

```text
sum C_in - sum C_out - fee G = 0.
```

输入输出盲因子必须平衡。仅有群等式仍可能用标量域中的“负数”伪造金额，所以每个输出还要通过范围证明。CLSAG 证明每个输入 ring 中某一成员知道 spend secret，但不暴露是哪一个；key image/nullifier 是确定性双花标记。最终安全性取决于主链验证器和底层密码假设，UI 里的余额加减不能代替共识验证。

钱包文件计算：

```text
K=Argon2id(BLAKE3-DeriveKey(password),salt)
(ciphertext,tag)=XChaCha20Poly1305.Encrypt(K,nonce,mnemonic,header).
```

Header 固定包含 magic、版本、KDF/AEAD 标识、参数、128-bit salt 和 192-bit nonce，并作为 associated data。修改版本、参数、salt、nonce、ciphertext 或 tag 都会认证失败。随机 salt 隔离相同密码，随机 nonce 让意外复用概率极低；但整体安全仍取决于密码熵、系统随机数、标准算法实现和设备没有被攻陷。

BIP39 是兼容性边界：助记词校验和种子派生必须按标准使用 SHA-256 与 SHA-512。它们不是 Hyphen 定义的哈希；链上所有承诺、交易摘要和矿池摘要都使用 BLAKE3。替换 BIP39 的这两处原语会让标准助记词无法恢复，因此保留标准实现。

## 自动付款 Agent

```powershell
cargo build --release --locked --manifest-path rust\Cargo.toml --bin hyphen-payout-agent
```

`--seed-file` 接受 64 raw bytes 或 128 hex 字符的 BIP39 seed，`--token-file` 接受 32 到 256 字符秘密：

```powershell
.\rust\target\release\hyphen-payout-agent.exe `
  --bind 127.0.0.1:38401 `
  --node-host 127.0.0.1 `
  --node-port 48333 `
  --seed-file .\pool.seed `
  --token-file .\payout.token `
  --state-dir .\payout_agent_state `
  --network devnet `
  --account 0 `
  --ring-size 4 `
  --fee 1000
```

Agent 拒绝非 loopback 监听，常量时间比较 token，检查收款地址网络，持久化 `intent_id -> signed transaction`，只允许一个未确认交易以避免重叠选 input，崩溃后重播并跟踪确认。它不计算矿工余额，余额属于 Pool 账本职责。

幂等性质是：固定 intent `i` 的成功重试始终返回同一交易哈希 `h_i`；若试图让同一个 `i` 对应不同付款参数，Agent 拒绝。它防止普通崩溃重试为一个 intent 签出多笔交易，不能防止 seed 或 token 被盗。

## 协议兼容性

`hyphen-crypto`、`hyphen-tx`、`hyphen-proof` 和 `hyphen-wire` 固定到 Hyphen 公开 Git
revision `576bc67d972d1156fbabb1ddf579104d5ff2ff88`（chain identity v6），Wallet 不使用本地
路径依赖。二进制编码使用 RustBinary 0.1.8，并采用与主链相同的 compact、有界、拒绝尾随
字节配置——主链哈希与签名所用的正是这一配置。改变链 revision 或 wire profile 都属于协议
升级；格式回退解码不得进入交易哈希或签名。

## CI 和 Release

CI 执行 Rust 格式、严格 Clippy、测试，Flutter 格式和 analyze，并包含桌面构建门禁。只有 `main` CI 成功才自动构建桌面应用和 payout-agent。每个包包含提交号、工具链、调试信息与 BLAKE3，并作为 prerelease 发布，因为钱包尚未外审。

Mnemonic、seed 文件、加密钱包、payout token、恢复词截图和生产签名状态都不能上传。

## 许可证

HyphenWallet 使用 PolyForm Strict License 1.0.0，完整条款见 [LICENSE](LICENSE)。
