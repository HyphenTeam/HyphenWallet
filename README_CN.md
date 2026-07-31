# Hyphen Wallet (Chinese Compatibility Entry)

This compatibility entry preserves the Chinese documentation URL. The complete
English-first, Chinese-second README is available in [README.md](README.md).

---

<!-- hyphen-bilingual-chinese -->

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

创建或恢复钱包后，先离线记录 mnemonic，并实际验证恢复结果，再接收资产。配置节点 RPC，确认网络身份，从可信高度扫描。重扫会重新判断已拥有输出，并通过 key image 查询移除已经花费的输出。

发送交易时，Rust 选择 owned outputs，获取 ring decoy，构造 CLSAG 与范围证明，再将序列化交易交给节点。节点 accepted 只表示进入 mempool，不是确认；交易状态必须按区块高度计算确认数，并能处理 reorg 后交易暂时消失。

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

## CI 和 Release

CI 执行 Rust 格式、严格 Clippy、测试，Flutter 格式和 analyze，并包含桌面构建门禁。只有 `main` CI 成功才自动构建桌面应用和 payout-agent。每个包包含提交号、工具链、调试信息与 SHA-256，并作为 prerelease 发布，因为钱包尚未外审。

Mnemonic、seed 文件、加密钱包、payout token、恢复词截图和生产签名状态都不能上传。

## 许可证

HyphenWallet 使用 PolyForm Strict License 1.0.0，完整条款见 [LICENSE](LICENSE)。
