# Hyphen Wallet

[English](README.md)

Hyphen Wallet 是 Hyphen 研究链的 Flutter 钱包。Rust 库在本地派生密钥、扫描属于钱包的输出并签署交易。仓库还包含供共享矿池使用的独立命令行付款代理。钱包和协议尚待独立审计，现阶段请使用开发网测试资金。

## 在 Windows 上运行

安装 Flutter 3.50.0、Rust 1.97.0 和 Flutter 所需的 Windows 桌面构建工具。启动 Hyphen 开发网节点后，在钱包仓库根目录执行以下命令。

```sh
flutter pub get --enforce-lockfile
flutter run -d windows
```

离线备份助记词，并在钱包中填写节点的二进制 RPC 地址。[钱包使用与付款代理](wiki/Operations.md) · [Hyphen 节点](https://github.com/HyphenTeam/Hyphen)

## 许可证

项目自身代码采用 [PolyForm Strict License 1.0.0](LICENSE)。第三方组件和字体适用各自的许可条款。
