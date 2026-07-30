// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Hyphen ウォレット';

  @override
  String get quantumResistantWallet => 'Hyphen Wallet';

  @override
  String get welcomeToHyphen => 'Hyphen へようこそ';

  @override
  String get welcomeSubtitle => 'Hyphen 開発ネットワーク向けの\nデスクトップウォレット。';

  @override
  String get wotsSignatures => 'WOTS+ 署名';

  @override
  String get aesEncryption => '認証付き暗号化';

  @override
  String get privacyFirst => 'ローカル鍵ストレージ';

  @override
  String get createNewWallet => '新しいウォレットを作成';

  @override
  String get restoreExistingWallet => '既存のウォレットを復元';

  @override
  String get welcomeBack => 'おかえりなさい';

  @override
  String get enterPasswordToUnlock => 'パスワードを入力してロック解除';

  @override
  String get password => 'パスワード';

  @override
  String get passwordRequired => 'パスワードが必要です';

  @override
  String get incorrectPassword => 'パスワードが正しくありません';

  @override
  String get unlock => 'ロック解除';

  @override
  String get forgotPasswordRestore => 'パスワードを忘れた場合はニーモニックで復元';

  @override
  String get resetWallet => 'ウォレットをリセット';

  @override
  String get resetWalletMessage =>
      'このデバイスのウォレットデータが削除されます。24語のリカバリーフレーズで復元できます。\n\n続行する前にニーモニックフレーズがあることを確認してください。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get resetAndRestore => 'リセットして復元';

  @override
  String get createWallet => 'ウォレットを作成';

  @override
  String get generatingSecureWallet => '安全なウォレットを生成中...';

  @override
  String get recoveryPhrase => 'リカバリーフレーズ';

  @override
  String get writeDownWords =>
      'これらの24語を順番に書き留め、安全な場所に保管してください。これがウォレットを復元する唯一の方法です。';

  @override
  String get neverSharePhrase => 'リカバリーフレーズを絶対に他人と共有しないでください！';

  @override
  String get copyToClipboard => 'クリップボードにコピー';

  @override
  String get iveWrittenItDown => '書き留めました';

  @override
  String get verifyYourPhrase => 'フレーズを確認';

  @override
  String get enterWordsToConfirm =>
      'リカバリーフレーズから以下の単語を入力して、正しく保存されていることを確認してください。';

  @override
  String wordNumber(Object number) {
    return '単語 #$number';
  }

  @override
  String wordIncorrect(Object number) {
    return '単語 #$number が正しくありません。もう一度お試しください。';
  }

  @override
  String get verifyAndContinue => '確認して続行';

  @override
  String get setPassword => 'パスワードを設定';

  @override
  String get passwordEncryptInfo =>
      'このパスワードはデバイス上のウォレットを暗号化します。アプリを開くたびに必要になります。';

  @override
  String get confirmPassword => 'パスワードを確認';

  @override
  String get atLeast8Chars => '8文字以上';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String failedToGenerateWallet(Object error) {
    return 'ウォレット生成に失敗しました：$error';
  }

  @override
  String failedToCreateWallet(Object error) {
    return 'ウォレット作成に失敗しました：$error';
  }

  @override
  String get restoreWallet => 'ウォレットを復元';

  @override
  String get enterRecoveryPhrase => '24語のリカバリーフレーズをスペースで区切って入力してください。';

  @override
  String get mnemonicHint => '単語1 単語2 単語3 ...';

  @override
  String get pleaseEnter12Or24Words => '12語または24語を入力してください';

  @override
  String get continueButton => '続行';

  @override
  String get setEncryptionPassword => '暗号化パスワードを設定';

  @override
  String get passwordEncryptsWallet => 'このパスワードはデバイス上のウォレットを暗号化します。';

  @override
  String failedToRestore(Object error) {
    return '復元に失敗しました：$error';
  }

  @override
  String get mainnet => 'メインネット';

  @override
  String get testnet => 'テストネット';

  @override
  String get totalBalance => '合計残高';

  @override
  String get yourAddress => 'あなたのアドレス';

  @override
  String get receive => '受取';

  @override
  String get send => '送金';

  @override
  String get miningRewardKey => 'マイニング支払アドレス';

  @override
  String get miningRewardKeyDesc =>
      'マイナーで --wallet-address またはプールで --pool-wallet にこのアドレスを使用して、ブロック報酬をこのウォレットに受け取ります。';

  @override
  String get addressCopied => 'アドレスをコピーしました';

  @override
  String get miningKeyCopied => 'マイニングキーをコピーしました';

  @override
  String get securityFeatures => 'セキュリティ機能';

  @override
  String get wotsQuantumResistant => '実験的 WOTS+ 署名';

  @override
  String get aes256GcmEncryption => 'XChaCha20-Poly1305';

  @override
  String get blake3Kdf => 'Argon2id（64 MiB、3 パス）';

  @override
  String get icdStealthKeys => 'ICD ステルスキー';

  @override
  String get receiveTitle => '受取';

  @override
  String get mainnetAddress => 'メインネットアドレス';

  @override
  String get testnetAddress => 'テストネットアドレス';

  @override
  String get copy => 'コピー';

  @override
  String get share => '共有';

  @override
  String get addressCopiedToClipboard => 'アドレスをクリップボードにコピーしました';

  @override
  String get receiveInfo =>
      'このアドレスを共有してHYPを受け取ります。このアドレスはプライバシー強化のためにステルスキーを使用しています。';

  @override
  String get sendTitle => '送金';

  @override
  String get recipient => '受取人';

  @override
  String get addressRequired => 'アドレスが必要です';

  @override
  String get invalidHyphenAddress => '無効なHyphenアドレス';

  @override
  String get amount => '金額';

  @override
  String get amountRequired => '金額が必要です';

  @override
  String get invalidAmount => '無効な金額';

  @override
  String get networkFee => 'ネットワーク手数料';

  @override
  String get privacyLevel => 'プライバシーレベル';

  @override
  String get ringSignatureClsag => 'リング署名 + CLSAG';

  @override
  String get invalidRecipientAddress => '無効な受取人アドレス';

  @override
  String get sendHyp => 'HYPを送金';

  @override
  String get transactionLayer => 'トランザクション層';

  @override
  String get transactionLayerMessage =>
      '署名バックエンドは準備完了です。トランザクションのブロードキャストにはRPCインターフェースを介してHyphenノードにウォレットを接続する必要があります。\n\nまずプールマイニングでHYPを獲得し、RPC同期層が統合されればトランザクションが利用可能になります。';

  @override
  String get ok => 'OK';

  @override
  String get settings => '設定';

  @override
  String get network => 'ネットワーク';

  @override
  String get currentNetwork => '現在のネットワーク';

  @override
  String get security => 'セキュリティ';

  @override
  String get backupRecoveryPhrase => 'リカバリーフレーズのバックアップ';

  @override
  String get viewYour24WordMnemonic => '24語のニーモニックを表示';

  @override
  String get lockWallet => 'ウォレットをロック';

  @override
  String get clearSessionRequirePassword => 'セッションをクリアしてパスワードを要求';

  @override
  String get walletMustBeUnlocked => 'バックアップを表示するにはウォレットのロック解除が必要です';

  @override
  String get walletSection => 'ウォレット';

  @override
  String get viewPublicKey => 'ビュー公開鍵';

  @override
  String get spendPublicKey => 'スペンド公開鍵';

  @override
  String get notAvailable => '利用不可';

  @override
  String get walletVersion => 'ウォレットバージョン';

  @override
  String get dangerZone => '危険ゾーン';

  @override
  String get deleteWallet => 'ウォレットを削除';

  @override
  String get removeAllWalletData => 'このデバイスからすべてのウォレットデータを削除';

  @override
  String get deleteWalletWarning =>
      'この操作はデバイスからウォレットを完全に削除します。\n\nリカバリーフレーズをバックアップしていることを確認してください。フレーズがないと資金は永久に失われます。';

  @override
  String get delete => '削除';

  @override
  String get close => '閉じる';

  @override
  String get recoveryPhraseTitle => 'リカバリーフレーズ';

  @override
  String get neverShareWarning =>
      'リカバリーフレーズを絶対に他人と共有しないでください。これらの単語を持つ誰もがあなたの資金にアクセスできます。';

  @override
  String get tapBelowToReveal => '下をタップして表示';

  @override
  String get revealRecoveryPhrase => 'リカバリーフレーズを表示';

  @override
  String get copiedClearClipboard => 'コピーしました — すぐにクリップボードをクリアしてください！';

  @override
  String get hidePhrase => 'フレーズを非表示';

  @override
  String get phraseCopiedWarning => 'リカバリーフレーズをコピーしました — すぐにクリップボードをクリアしてください！';

  @override
  String get walletManagement => 'ウォレット管理';

  @override
  String get manageWallets => 'ウォレットを管理';

  @override
  String get switchCreateDelete => 'ウォレットの切替、作成、削除';

  @override
  String get wallets => 'ウォレット';

  @override
  String get activeWallet => '使用中';

  @override
  String get switchTo => '切替';

  @override
  String get renameWallet => '名前変更';

  @override
  String get deleteThisWallet => 'このウォレットを削除';

  @override
  String get addNewWallet => '新しいウォレットを追加';

  @override
  String get createNew => '新規作成';

  @override
  String get importExisting => '既存をインポート';

  @override
  String get walletName => 'ウォレット名';

  @override
  String get enterWalletName => 'ウォレット名を入力';

  @override
  String get rename => '名前変更';

  @override
  String deleteWalletConfirm(Object name) {
    return 'ウォレット「$name」を削除しますか？この操作は取り消せません。';
  }

  @override
  String get cannotDeleteActiveWallet =>
      '使用中のウォレットは削除できません。先に別のウォレットに切り替えてください。';

  @override
  String walletSwitched(Object name) {
    return '$name に切り替えました';
  }

  @override
  String get walletRenamed => 'ウォレットの名前を変更しました';

  @override
  String get walletDeleted => 'ウォレットを削除しました';

  @override
  String get language => '言語';

  @override
  String get appLanguage => 'アプリの言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get appTheme => '外観';

  @override
  String get themeColor => 'テーマカラー';

  @override
  String get chooseNodeMode => 'ノードモードを選択';

  @override
  String get nodeModeDescription =>
      'ウォレットがHyphenネットワークに接続する方法を選択してください。後から設定で変更できます。';

  @override
  String get lightNode => 'ライトノード';

  @override
  String get lightNodeDesc => 'リモートRPC経由で接続 — 高速・低容量';

  @override
  String get fullNode => 'フルノード';

  @override
  String get fullNodeDesc => 'ブロックチェーン全体を同期 — 最高のセキュリティ';

  @override
  String get lightFeature1 => '即座に起動';

  @override
  String get lightFeature2 => '最小限のストレージ使用';

  @override
  String get lightFeature3 => '信頼されたRPCエンドポイント';

  @override
  String get fullFeature1 => '完全なチェーン検証';

  @override
  String get fullFeature2 => '内蔵ブロックエクスプローラー';

  @override
  String get fullFeature3 => '第三者への信頼不要';

  @override
  String get nodeConnectionStatus => 'ノード接続';

  @override
  String get checkingConnection => '確認中...';

  @override
  String get connected => '接続済み';

  @override
  String get disconnected => '未接続';

  @override
  String get onChainMiningRewards => 'On-chain Mining Rewards';

  @override
  String get poolPendingBalance => 'Pool Pending Balance';

  @override
  String get miningPoolMode => 'Pool Mode';

  @override
  String get poolFee => 'Pool Fee';

  @override
  String get rpcEndpoint => 'RPCエンドポイント';

  @override
  String get poolApiEndpoint => 'Pool API Endpoint';

  @override
  String get autoDerivedFromRpc => 'Auto-derived from RPC host';

  @override
  String get explorerApiEndpoint => 'Explorer API Endpoint';

  @override
  String get availableNodes => '利用可能なノード';

  @override
  String get addCustomNode => 'カスタムノードを追加';

  @override
  String get miningPayoutAddressCopied => 'マイニング支払いアドレスがコピーされました';

  @override
  String get biometricUnlock => '生体認証ロック解除';

  @override
  String get useFingerprintOrFace => '指紋または顔認証を使用';

  @override
  String get biometricNotAvailable => 'このデバイスでは生体認証ハードウェアを使用できません';

  @override
  String get unlockWithBiometrics => '生体認証で解除';

  @override
  String get themeMode => 'テーマモード';

  @override
  String get lightMode => 'ライト';

  @override
  String get darkMode => 'ダーク';

  @override
  String get systemMode => 'システム';

  @override
  String get nfcTransfer => 'NFC送金';

  @override
  String get nfcTapToTransfer => 'デバイスを近づけて送金を開始';

  @override
  String get nfcNotAvailable => 'このデバイスではNFCを利用できません';

  @override
  String get nfcReadyToScan => 'スキャン準備完了。デバイスを近づけてください。';

  @override
  String get nfcTransferSent => 'NFCで送金アドレスを送信しました';

  @override
  String get transferSent => '送信';

  @override
  String get transferReceived => '受信';

  @override
  String get noActivityYet => 'アクティビティはまだありません';
}
