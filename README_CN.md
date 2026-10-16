# Hyphen Wallet

[English](README.md)

Hyphen Wallet 是 Hyphen 主链的独立 Flutter 钱包。Flutter 负责界面和本地状态；Rust 库负责助记词、密钥派生、地址编码、输出扫描、交易构造、签名和节点 RPC。仓库同时构建供 Hyphen Pool 使用的 hyphen-payout-agent。

## 安全状态

这是未经外部钱包、密码学、移动端或供应链审计的实验软件，只应使用研究网络资金。

- 钱包文件使用版本化 Argon2id 和 XChaCha20-Poly1305 认证加密。历史 BLAKE3-XOF 文件只保留解锁和迁移兼容。
- 助记词是最终恢复凭据；设备安全存储和密码不能替代离线助记词备份。
- 链上交易依赖主链的 Ristretto、CLSAG 和范围证明实现，该组合尚未独立审计。
- Ed25519 + WOTS 消息 API 是实验功能。WOTS 公钥没有被共识锚定，当前无状态 API 也不能强制一次性使用，不能据此声称后量子安全。
- pqTransformPassword 只为历史确定性恢复保留，不能为弱密码增加熵，也不是密码 KDF。

## PoUW 链身份兼容

每次 RPC 连接建立后，Wallet 会先请求链状态并同时校验：

- block version = 5
- PoUW protocol version = 3
- network magic
- consensus_params_hash
- genesis_hash

节点缺少任一身份字段、返回旧哈希目标链或身份不匹配时，Wallet 会在扫描和提交交易前拒绝连接。

`PoUW protocol version` 只是链身份字段。Wallet 本身不复算科学工作，也不表示用户任务的有用工作结算已启用；共识验证仍由连接节点负责。

当前 devnet 身份：

```text
network=hyphen-devnet-v2
network_magic=48594456
consensus_params_hash=521f6cdc47f4424c1ea7b9f4d6770cf114f620cdff62958060f8c6953cb69de8
genesis_hash=4c24528fa76c896299d5bfa6d7fee28bf39b21c0efd1684d4b8bafa9819bde55
block_version=5
pouw_protocol_version=3
```

上述取值来自主链的 test-vectors/chain-identity-v5.json，并钉在 rust/src/chain_identity.rs，二者一旦漂移会有单元测试失败。

身份钉扎可防止误连另一条链，但不能证明远程节点诚实地报告规范历史。生产使用应连接可信节点或对比多个独立节点。

## 构建

要求 Flutter 3.44.6 和 Rust 1.97.0：

```powershell
flutter pub get
flutter analyze
cargo test --manifest-path rust/Cargo.toml --locked
cargo clippy --manifest-path rust/Cargo.toml --all-targets --locked -- -D warnings
flutter run -d windows
```

Rust 锁文件固定主链密码学、交易和证明依赖的精确提交。更新依赖提交属于协议升级，必须重新执行 Rust 测试、Flutter 分析、桌面构建和端到端 devnet 转账。

`pubspec.lock` 会记录每个包从哪个 host 解析而来，本仓库提交的锁指向规范的 `pub.dev`，CI 也因此把 `PUB_HOSTED_URL` 固定到同一 host。如果你的机器设置了包镜像（`PUB_HOSTED_URL` / `FLUTTER_STORAGE_BASE_URL`），请在本仓库执行 `flutter pub get` 前取消它：镜像解析出的锁无法通过 CI 的 `flutter pub get --enforce-lockfile`。两个 workflow 会直接点名拒绝这种锁，而不是抛出 97 个依赖差异。

## 钱包流程

创建或恢复钱包后，先离线记录并复核助记词，再接收资产。配置节点 RPC 后从已知高度扫描。重扫会丢弃旧缓存假设，并过滤 key image 已花费的输出。

交易构造会选择本钱包输出、获取诱饵、生成 CLSAG 和范围证明，再提交序列化交易。节点接受只表示进入 mempool，不表示确认；重组后交易可能消失，确认跟踪必须处理这种情况。

payout-agent 是一个仅绑定 loopback 的 HTTP 服务（Courierust 提供，与 Pool 端同一套 HTTP 实现）：token 走 `authorization` 头，在恒定时间内比较；路由为 `/v1/health`、`/v1/submit`、`/v1/status`。它把 intent_id 固定绑定到一份已签名交易，相同 intent 可幂等重试，替换已绑定交易会被拒绝。它不能消除 Pool 运营者、主机失陷或深度重组风险。

## 编码迁移

RustBinary 使用有界字节/集合长度、compact 编码并拒绝尾随字节的配置，与主链哈希和签名所用的配置一致。钱包文件和付款状态都有显式版本。不可识别版本必须报错，禁止在交易哈希、签名或授权路径中自动格式回退。

## 许可证

Hyphen Wallet 使用 PolyForm Strict License 1.0.0，完整条款见 [LICENSE](LICENSE)。
