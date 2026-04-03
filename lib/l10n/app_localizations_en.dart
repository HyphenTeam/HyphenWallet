// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hyphen Wallet';

  @override
  String get quantumResistantWallet => 'Quantum-Resistant Wallet';

  @override
  String get welcomeToHyphen => 'Welcome to Hyphen';

  @override
  String get welcomeSubtitle =>
      'A quantum-resistant privacy wallet\nbuilt for the Hyphen blockchain.';

  @override
  String get wotsSignatures => 'WOTS+ Signatures';

  @override
  String get aesEncryption => 'AES-256 Encryption';

  @override
  String get privacyFirst => 'Privacy First';

  @override
  String get createNewWallet => 'Create New Wallet';

  @override
  String get restoreExistingWallet => 'Restore Existing Wallet';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get enterPasswordToUnlock => 'Enter your password to unlock';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password required';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get unlock => 'Unlock';

  @override
  String get forgotPasswordRestore => 'Forgot password? Restore with mnemonic';

  @override
  String get resetWallet => 'Reset Wallet';

  @override
  String get resetWalletMessage =>
      'This will delete your current wallet data on this device. You can restore it using your 24-word recovery phrase.\n\nMake sure you have your mnemonic phrase before proceeding.';

  @override
  String get cancel => 'Cancel';

  @override
  String get resetAndRestore => 'Reset & Restore';

  @override
  String get createWallet => 'Create Wallet';

  @override
  String get generatingSecureWallet => 'Generating secure wallet...';

  @override
  String get recoveryPhrase => 'Recovery Phrase';

  @override
  String get writeDownWords =>
      'Write down these 24 words in order and keep them in a safe place. This is the ONLY way to recover your wallet.';

  @override
  String get neverSharePhrase =>
      'Never share your recovery phrase with anyone!';

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get iveWrittenItDown => 'I\'ve Written It Down';

  @override
  String get verifyYourPhrase => 'Verify Your Phrase';

  @override
  String get enterWordsToConfirm =>
      'Enter the following words from your recovery phrase to confirm you have saved it correctly.';

  @override
  String wordNumber(Object number) {
    return 'Word #$number';
  }

  @override
  String wordIncorrect(Object number) {
    return 'Word #$number is incorrect. Please try again.';
  }

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get setPassword => 'Set Password';

  @override
  String get passwordEncryptInfo =>
      'This password will encrypt your wallet on this device. You\'ll need it each time you open the app.';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get atLeast8Chars => 'At least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String failedToGenerateWallet(Object error) {
    return 'Failed to generate wallet: $error';
  }

  @override
  String failedToCreateWallet(Object error) {
    return 'Failed to create wallet: $error';
  }

  @override
  String get restoreWallet => 'Restore Wallet';

  @override
  String get enterRecoveryPhrase =>
      'Enter your 24-word recovery phrase, separated by spaces.';

  @override
  String get mnemonicHint => 'word1 word2 word3 ...';

  @override
  String get pleaseEnter12Or24Words => 'Please enter 12 or 24 words';

  @override
  String get continueButton => 'Continue';

  @override
  String get setEncryptionPassword => 'Set Encryption Password';

  @override
  String get passwordEncryptsWallet =>
      'This password encrypts the wallet on this device.';

  @override
  String failedToRestore(Object error) {
    return 'Failed to restore: $error';
  }

  @override
  String get mainnet => 'Mainnet';

  @override
  String get testnet => 'Testnet';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get yourAddress => 'Your Address';

  @override
  String get receive => 'Receive';

  @override
  String get send => 'Send';

  @override
  String get miningRewardKey => 'Mining Payout Address';

  @override
  String get miningRewardKeyDesc =>
      'Use this address with --wallet-address in your miner or --pool-wallet in your pool to receive block rewards to this wallet.';

  @override
  String get addressCopied => 'Address copied';

  @override
  String get miningKeyCopied => 'Mining key copied';

  @override
  String get securityFeatures => 'Security Features';

  @override
  String get wotsQuantumResistant => 'WOTS+ Quantum-Resistant';

  @override
  String get aes256GcmEncryption => 'AES-256-GCM Encryption';

  @override
  String get blake3Kdf => 'Blake3 KDF (100k rounds)';

  @override
  String get icdStealthKeys => 'ICD Stealth Keys';

  @override
  String get receiveTitle => 'Receive';

  @override
  String get mainnetAddress => 'Mainnet Address';

  @override
  String get testnetAddress => 'Testnet Address';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get addressCopiedToClipboard => 'Address copied to clipboard';

  @override
  String get receiveInfo =>
      'Share this address to receive HYP. This address uses stealth keys for enhanced privacy.';

  @override
  String get sendTitle => 'Send';

  @override
  String get recipient => 'Recipient';

  @override
  String get addressRequired => 'Address required';

  @override
  String get invalidHyphenAddress => 'Invalid Hyphen address';

  @override
  String get amount => 'Amount';

  @override
  String get amountRequired => 'Amount required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get networkFee => 'Network Fee';

  @override
  String get privacyLevel => 'Privacy Level';

  @override
  String get ringSignatureClsag => 'Ring Signature + CLSAG';

  @override
  String get invalidRecipientAddress => 'Invalid recipient address';

  @override
  String get sendHyp => 'Send HYP';

  @override
  String get transactionLayer => 'Transaction Layer';

  @override
  String get transactionLayerMessage =>
      'The signing backend is ready. Transaction broadcasting requires connecting the wallet to a Hyphen node via the RPC interface.\n\nUse the pool mining setup to earn HYP first, then transactions will be available once the RPC sync layer is integrated.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Settings';

  @override
  String get network => 'NETWORK';

  @override
  String get currentNetwork => 'Current Network';

  @override
  String get security => 'SECURITY';

  @override
  String get backupRecoveryPhrase => 'Backup Recovery Phrase';

  @override
  String get viewYour24WordMnemonic => 'View your 24-word mnemonic';

  @override
  String get lockWallet => 'Lock Wallet';

  @override
  String get clearSessionRequirePassword =>
      'Clear session and require password';

  @override
  String get walletMustBeUnlocked => 'Wallet must be unlocked to view backup';

  @override
  String get walletSection => 'WALLET';

  @override
  String get viewPublicKey => 'View Public Key';

  @override
  String get spendPublicKey => 'Spend Public Key';

  @override
  String get notAvailable => 'Not available';

  @override
  String get walletVersion => 'Wallet Version';

  @override
  String get dangerZone => 'DANGER ZONE';

  @override
  String get deleteWallet => 'Delete Wallet';

  @override
  String get removeAllWalletData => 'Remove all wallet data from this device';

  @override
  String get deleteWalletWarning =>
      'This action will permanently remove your wallet from this device.\n\nMake sure you have backed up your recovery phrase. Without it, your funds will be lost forever.';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get recoveryPhraseTitle => 'Recovery Phrase';

  @override
  String get neverShareWarning =>
      'Never share your recovery phrase with anyone. Anyone with these words can access your funds.';

  @override
  String get tapBelowToReveal => 'Tap below to reveal';

  @override
  String get revealRecoveryPhrase => 'Reveal Recovery Phrase';

  @override
  String get copiedClearClipboard => 'Copied — clear your clipboard soon!';

  @override
  String get hidePhrase => 'Hide Phrase';

  @override
  String get phraseCopiedWarning =>
      'Recovery phrase copied — clear clipboard soon!';

  @override
  String get walletManagement => 'WALLET MANAGEMENT';

  @override
  String get manageWallets => 'Manage Wallets';

  @override
  String get switchCreateDelete => 'Switch, create or delete wallets';

  @override
  String get wallets => 'Wallets';

  @override
  String get activeWallet => 'Active';

  @override
  String get switchTo => 'Switch';

  @override
  String get renameWallet => 'Rename';

  @override
  String get deleteThisWallet => 'Delete this wallet';

  @override
  String get addNewWallet => 'Add New Wallet';

  @override
  String get createNew => 'Create New';

  @override
  String get importExisting => 'Import Existing';

  @override
  String get walletName => 'Wallet Name';

  @override
  String get enterWalletName => 'Enter wallet name';

  @override
  String get rename => 'Rename';

  @override
  String deleteWalletConfirm(Object name) {
    return 'Delete wallet \"$name\"? This cannot be undone.';
  }

  @override
  String get cannotDeleteActiveWallet =>
      'Cannot delete the active wallet. Switch to another wallet first.';

  @override
  String walletSwitched(Object name) {
    return 'Switched to $name';
  }

  @override
  String get walletRenamed => 'Wallet renamed';

  @override
  String get walletDeleted => 'Wallet deleted';

  @override
  String get language => 'LANGUAGE';

  @override
  String get appLanguage => 'App Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get appTheme => 'APPEARANCE';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get chooseNodeMode => 'Choose Node Mode';

  @override
  String get nodeModeDescription =>
      'Select how your wallet connects to the Hyphen network. You can change this later in Settings.';

  @override
  String get lightNode => 'Light Node';

  @override
  String get lightNodeDesc => 'Connect via remote RPC — fast, low storage';

  @override
  String get fullNode => 'Full Node';

  @override
  String get fullNodeDesc => 'Sync entire blockchain — maximum security';

  @override
  String get lightFeature1 => 'Instant startup';

  @override
  String get lightFeature2 => 'Minimal storage usage';

  @override
  String get lightFeature3 => 'Trusted RPC endpoint';

  @override
  String get fullFeature1 => 'Full chain verification';

  @override
  String get fullFeature2 => 'Built-in block explorer';

  @override
  String get fullFeature3 => 'No third-party trust';

  @override
  String get nodeConnectionStatus => 'Node Connection';

  @override
  String get checkingConnection => 'Checking...';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get onChainMiningRewards => 'On-chain Mining Rewards';

  @override
  String get poolPendingBalance => 'Pool Pending Balance';

  @override
  String get miningPoolMode => 'Pool Mode';

  @override
  String get poolFee => 'Pool Fee';

  @override
  String get rpcEndpoint => 'RPC Endpoint';

  @override
  String get poolApiEndpoint => 'Pool API Endpoint';

  @override
  String get autoDerivedFromRpc => 'Auto-derived from RPC host';

  @override
  String get explorerApiEndpoint => 'Explorer API Endpoint';

  @override
  String get availableNodes => 'Available Nodes';

  @override
  String get addCustomNode => 'Add Custom Node';

  @override
  String get miningPayoutAddressCopied => 'Mining payout address copied';

  @override
  String get biometricUnlock => 'Biometric Unlock';

  @override
  String get useFingerprintOrFace => 'Use fingerprint or face to unlock';

  @override
  String get biometricNotAvailable =>
      'Biometric hardware not available on this device';

  @override
  String get unlockWithBiometrics => 'Unlock with Biometrics';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get systemMode => 'System';

  @override
  String get nfcTransfer => 'NFC Transfer';

  @override
  String get nfcTapToTransfer => 'Tap devices to start a transfer';

  @override
  String get nfcNotAvailable => 'NFC is not available on this device';

  @override
  String get nfcReadyToScan => 'Ready to scan. Hold devices together.';

  @override
  String get nfcTransferSent => 'Transfer address sent via NFC';

  @override
  String get transferSent => 'Sent';

  @override
  String get transferReceived => 'Received';

  @override
  String get noActivityYet => 'No activity yet';
}
