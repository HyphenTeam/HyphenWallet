// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Hyphen 钱包';

  @override
  String get quantumResistantWallet => '抗量子钱包';

  @override
  String get welcomeToHyphen => '欢迎来到 Hyphen';

  @override
  String get welcomeSubtitle => '为 Hyphen 区块链打造的\n抗量子隐私钱包。';

  @override
  String get wotsSignatures => 'WOTS+ 签名';

  @override
  String get aesEncryption => 'AES-256 加密';

  @override
  String get privacyFirst => '隐私优先';

  @override
  String get createNewWallet => '创建新钱包';

  @override
  String get restoreExistingWallet => '恢复已有钱包';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get enterPasswordToUnlock => '输入密码解锁';

  @override
  String get password => '密码';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get incorrectPassword => '密码错误';

  @override
  String get unlock => '解锁';

  @override
  String get forgotPasswordRestore => '忘记密码？使用助记词恢复';

  @override
  String get resetWallet => '重置钱包';

  @override
  String get resetWalletMessage =>
      '此操作将删除设备上的钱包数据。您可以使用24个助记词恢复。\n\n请确保您已保存好助记词后再继续。';

  @override
  String get cancel => '取消';

  @override
  String get resetAndRestore => '重置并恢复';

  @override
  String get createWallet => '创建钱包';

  @override
  String get generatingSecureWallet => '正在生成安全钱包...';

  @override
  String get recoveryPhrase => '助记词';

  @override
  String get writeDownWords => '请按顺序写下这24个词并保存在安全的地方。这是恢复钱包的唯一方式。';

  @override
  String get neverSharePhrase => '切勿将助记词分享给任何人！';

  @override
  String get copyToClipboard => '复制到剪贴板';

  @override
  String get iveWrittenItDown => '我已记录完毕';

  @override
  String get verifyYourPhrase => '验证助记词';

  @override
  String get enterWordsToConfirm => '请输入助记词中的以下单词，以确认您已正确保存。';

  @override
  String wordNumber(Object number) {
    return '第 $number 个词';
  }

  @override
  String wordIncorrect(Object number) {
    return '第 $number 个词不正确，请重试。';
  }

  @override
  String get verifyAndContinue => '验证并继续';

  @override
  String get setPassword => '设置密码';

  @override
  String get passwordEncryptInfo => '此密码将加密设备上的钱包。每次打开应用时都需要输入。';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get atLeast8Chars => '至少8个字符';

  @override
  String get passwordsDoNotMatch => '密码不匹配';

  @override
  String failedToGenerateWallet(Object error) {
    return '生成钱包失败：$error';
  }

  @override
  String failedToCreateWallet(Object error) {
    return '创建钱包失败：$error';
  }

  @override
  String get restoreWallet => '恢复钱包';

  @override
  String get enterRecoveryPhrase => '输入您的24个助记词，用空格分隔。';

  @override
  String get mnemonicHint => '单词1 单词2 单词3 ...';

  @override
  String get pleaseEnter12Or24Words => '请输入12或24个单词';

  @override
  String get continueButton => '继续';

  @override
  String get setEncryptionPassword => '设置加密密码';

  @override
  String get passwordEncryptsWallet => '此密码将加密设备上的钱包。';

  @override
  String failedToRestore(Object error) {
    return '恢复失败：$error';
  }

  @override
  String get mainnet => '主网';

  @override
  String get testnet => '测试网';

  @override
  String get totalBalance => '总余额';

  @override
  String get yourAddress => '您的地址';

  @override
  String get receive => '收款';

  @override
  String get send => '发送';

  @override
  String get miningRewardKey => '挖矿收款地址';

  @override
  String get miningRewardKeyDesc =>
      '在矿机中使用 --wallet-address 或矿池中使用 --pool-wallet 参数填入此地址，以将区块奖励发送到此钱包。';

  @override
  String get addressCopied => '地址已复制';

  @override
  String get miningKeyCopied => '挖矿密钥已复制';

  @override
  String get securityFeatures => '安全特性';

  @override
  String get wotsQuantumResistant => 'WOTS+ 抗量子签名';

  @override
  String get aes256GcmEncryption => 'AES-256-GCM 加密';

  @override
  String get blake3Kdf => 'Blake3 KDF（10万轮）';

  @override
  String get icdStealthKeys => 'ICD 隐身密钥';

  @override
  String get receiveTitle => '收款';

  @override
  String get mainnetAddress => '主网地址';

  @override
  String get testnetAddress => '测试网地址';

  @override
  String get copy => '复制';

  @override
  String get share => '分享';

  @override
  String get addressCopiedToClipboard => '地址已复制到剪贴板';

  @override
  String get receiveInfo => '分享此地址以接收 HYP。此地址使用隐身密钥增强隐私。';

  @override
  String get sendTitle => '发送';

  @override
  String get recipient => '收款方';

  @override
  String get addressRequired => '请输入地址';

  @override
  String get invalidHyphenAddress => '无效的 Hyphen 地址';

  @override
  String get amount => '金额';

  @override
  String get amountRequired => '请输入金额';

  @override
  String get invalidAmount => '无效金额';

  @override
  String get networkFee => '网络手续费';

  @override
  String get privacyLevel => '隐私级别';

  @override
  String get ringSignatureClsag => '环签名 + CLSAG';

  @override
  String get invalidRecipientAddress => '无效的收款地址';

  @override
  String get sendHyp => '发送 HYP';

  @override
  String get transactionLayer => '交易层';

  @override
  String get transactionLayerMessage =>
      '签名后端已就绪。交易广播需要通过 RPC 接口连接到 Hyphen 节点。\n\n请先通过矿池挖矿赚取 HYP，RPC 同步层集成后即可进行交易。';

  @override
  String get ok => '确定';

  @override
  String get settings => '设置';

  @override
  String get network => '网络';

  @override
  String get currentNetwork => '当前网络';

  @override
  String get security => '安全';

  @override
  String get backupRecoveryPhrase => '备份助记词';

  @override
  String get viewYour24WordMnemonic => '查看您的24个助记词';

  @override
  String get lockWallet => '锁定钱包';

  @override
  String get clearSessionRequirePassword => '清除会话并要求输入密码';

  @override
  String get walletMustBeUnlocked => '必须解锁钱包才能查看备份';

  @override
  String get walletSection => '钱包';

  @override
  String get viewPublicKey => '查看公钥';

  @override
  String get spendPublicKey => '支出公钥';

  @override
  String get notAvailable => '不可用';

  @override
  String get walletVersion => '钱包版本';

  @override
  String get dangerZone => '危险操作';

  @override
  String get deleteWallet => '删除钱包';

  @override
  String get removeAllWalletData => '从此设备移除所有钱包数据';

  @override
  String get deleteWalletWarning =>
      '此操作将永久删除设备上的钱包。\n\n请确保已备份助记词。没有助记词，资金将永久丢失。';

  @override
  String get delete => '删除';

  @override
  String get close => '关闭';

  @override
  String get recoveryPhraseTitle => '助记词';

  @override
  String get neverShareWarning => '切勿将助记词分享给任何人。拥有这些词的任何人都可以访问您的资金。';

  @override
  String get tapBelowToReveal => '点击下方显示';

  @override
  String get revealRecoveryPhrase => '显示助记词';

  @override
  String get copiedClearClipboard => '已复制 — 请尽快清除剪贴板！';

  @override
  String get hidePhrase => '隐藏助记词';

  @override
  String get phraseCopiedWarning => '助记词已复制 — 请尽快清除剪贴板！';

  @override
  String get walletManagement => '钱包管理';

  @override
  String get manageWallets => '管理钱包';

  @override
  String get switchCreateDelete => '切换、创建或删除钱包';

  @override
  String get wallets => '钱包';

  @override
  String get activeWallet => '使用中';

  @override
  String get switchTo => '切换';

  @override
  String get renameWallet => '重命名';

  @override
  String get deleteThisWallet => '删除此钱包';

  @override
  String get addNewWallet => '添加新钱包';

  @override
  String get createNew => '创建新钱包';

  @override
  String get importExisting => '导入已有钱包';

  @override
  String get walletName => '钱包名称';

  @override
  String get enterWalletName => '输入钱包名称';

  @override
  String get rename => '重命名';

  @override
  String deleteWalletConfirm(Object name) {
    return '删除钱包 $name ？此操作不可撤销。';
  }

  @override
  String get cannotDeleteActiveWallet => '无法删除当前使用的钱包。请先切换到其他钱包。';

  @override
  String walletSwitched(Object name) {
    return '已切换到 $name';
  }

  @override
  String get walletRenamed => '钱包已重命名';

  @override
  String get walletDeleted => '钱包已删除';

  @override
  String get language => '语言';

  @override
  String get appLanguage => '应用语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get appTheme => '外观';

  @override
  String get themeColor => '主题色彩';

  @override
  String get chooseNodeMode => '选择节点模式';

  @override
  String get nodeModeDescription => '选择钱包连接 Hyphen 网络的方式。你可以稍后在设置中更改。';

  @override
  String get lightNode => '轻节点';

  @override
  String get lightNodeDesc => '通过远程 RPC 连接 — 快速、低存储';

  @override
  String get fullNode => '全节点';

  @override
  String get fullNodeDesc => '同步整条区块链 — 最高安全性';

  @override
  String get lightFeature1 => '即时启动';

  @override
  String get lightFeature2 => '极少存储占用';

  @override
  String get lightFeature3 => '信任 RPC 端点';

  @override
  String get fullFeature1 => '完整链验证';

  @override
  String get fullFeature2 => '内置区块浏览器';

  @override
  String get fullFeature3 => '无需第三方信任';

  @override
  String get nodeConnectionStatus => '节点连接';

  @override
  String get checkingConnection => '检查中...';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '未连接';

  @override
  String get onChainMiningRewards => '链上已入账挖矿奖励';

  @override
  String get poolPendingBalance => '矿池待结算余额';

  @override
  String get miningPoolMode => '矿池模式';

  @override
  String get poolFee => '矿池费率';

  @override
  String get rpcEndpoint => 'RPC 端点';

  @override
  String get poolApiEndpoint => '矿池 API 端点';

  @override
  String get autoDerivedFromRpc => '自动跟随 RPC 主机';

  @override
  String get explorerApiEndpoint => '区块浏览器 API 端点';

  @override
  String get availableNodes => '可用节点';

  @override
  String get addCustomNode => '添加自定义节点';

  @override
  String get miningPayoutAddressCopied => '挖矿收款地址已复制';

  @override
  String get biometricUnlock => '生物识别解锁';

  @override
  String get useFingerprintOrFace => '使用指纹或面容解锁';

  @override
  String get biometricNotAvailable => '此设备不支持生物识别硬件';

  @override
  String get unlockWithBiometrics => '生物识别解锁';

  @override
  String get themeMode => '主题模式';

  @override
  String get lightMode => '浅色';

  @override
  String get darkMode => '深色';

  @override
  String get systemMode => '跟随系统';

  @override
  String get nfcTransfer => 'NFC 转账';

  @override
  String get nfcTapToTransfer => '碰一碰即可发起转账';

  @override
  String get nfcNotAvailable => '此设备不支持 NFC';

  @override
  String get nfcReadyToScan => '准备扫描，请将设备贴近';

  @override
  String get nfcTransferSent => '已通过 NFC 发送转账地址';

  @override
  String get transferSent => '发送';

  @override
  String get transferReceived => '收到';

  @override
  String get noActivityYet => '暂无活动记录';
}
