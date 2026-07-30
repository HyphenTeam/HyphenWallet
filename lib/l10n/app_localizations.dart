import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hyphen Wallet'**
  String get appTitle;

  /// No description provided for @quantumResistantWallet.
  ///
  /// In en, this message translates to:
  /// **'Hyphen Wallet'**
  String get quantumResistantWallet;

  /// No description provided for @welcomeToHyphen.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Hyphen'**
  String get welcomeToHyphen;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A desktop wallet for\nHyphen development networks.'**
  String get welcomeSubtitle;

  /// No description provided for @wotsSignatures.
  ///
  /// In en, this message translates to:
  /// **'WOTS+ Signatures'**
  String get wotsSignatures;

  /// No description provided for @aesEncryption.
  ///
  /// In en, this message translates to:
  /// **'Authenticated Encryption'**
  String get aesEncryption;

  /// No description provided for @privacyFirst.
  ///
  /// In en, this message translates to:
  /// **'Local Key Storage'**
  String get privacyFirst;

  /// No description provided for @createNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Create New Wallet'**
  String get createNewWallet;

  /// No description provided for @restoreExistingWallet.
  ///
  /// In en, this message translates to:
  /// **'Restore Existing Wallet'**
  String get restoreExistingWallet;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @enterPasswordToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to unlock'**
  String get enterPasswordToUnlock;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get passwordRequired;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @forgotPasswordRestore.
  ///
  /// In en, this message translates to:
  /// **'Forgot password? Restore with mnemonic'**
  String get forgotPasswordRestore;

  /// No description provided for @resetWallet.
  ///
  /// In en, this message translates to:
  /// **'Reset Wallet'**
  String get resetWallet;

  /// No description provided for @resetWalletMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete your current wallet data on this device. You can restore it using your 24-word recovery phrase.\n\nMake sure you have your mnemonic phrase before proceeding.'**
  String get resetWalletMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @resetAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Reset & Restore'**
  String get resetAndRestore;

  /// No description provided for @createWallet.
  ///
  /// In en, this message translates to:
  /// **'Create Wallet'**
  String get createWallet;

  /// No description provided for @generatingSecureWallet.
  ///
  /// In en, this message translates to:
  /// **'Generating secure wallet...'**
  String get generatingSecureWallet;

  /// No description provided for @recoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Recovery Phrase'**
  String get recoveryPhrase;

  /// No description provided for @writeDownWords.
  ///
  /// In en, this message translates to:
  /// **'Write down these 24 words in order and keep them in a safe place. This is the ONLY way to recover your wallet.'**
  String get writeDownWords;

  /// No description provided for @neverSharePhrase.
  ///
  /// In en, this message translates to:
  /// **'Never share your recovery phrase with anyone!'**
  String get neverSharePhrase;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// No description provided for @iveWrittenItDown.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Written It Down'**
  String get iveWrittenItDown;

  /// No description provided for @verifyYourPhrase.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phrase'**
  String get verifyYourPhrase;

  /// No description provided for @enterWordsToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter the following words from your recovery phrase to confirm you have saved it correctly.'**
  String get enterWordsToConfirm;

  /// No description provided for @wordNumber.
  ///
  /// In en, this message translates to:
  /// **'Word #{number}'**
  String wordNumber(Object number);

  /// No description provided for @wordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Word #{number} is incorrect. Please try again.'**
  String wordIncorrect(Object number);

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPassword;

  /// No description provided for @passwordEncryptInfo.
  ///
  /// In en, this message translates to:
  /// **'This password will encrypt your wallet on this device. You\'ll need it each time you open the app.'**
  String get passwordEncryptInfo;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @atLeast8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Chars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @failedToGenerateWallet.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate wallet: {error}'**
  String failedToGenerateWallet(Object error);

  /// No description provided for @failedToCreateWallet.
  ///
  /// In en, this message translates to:
  /// **'Failed to create wallet: {error}'**
  String failedToCreateWallet(Object error);

  /// No description provided for @restoreWallet.
  ///
  /// In en, this message translates to:
  /// **'Restore Wallet'**
  String get restoreWallet;

  /// No description provided for @enterRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Enter your 24-word recovery phrase, separated by spaces.'**
  String get enterRecoveryPhrase;

  /// No description provided for @mnemonicHint.
  ///
  /// In en, this message translates to:
  /// **'word1 word2 word3 ...'**
  String get mnemonicHint;

  /// No description provided for @pleaseEnter12Or24Words.
  ///
  /// In en, this message translates to:
  /// **'Please enter 12 or 24 words'**
  String get pleaseEnter12Or24Words;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @setEncryptionPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Encryption Password'**
  String get setEncryptionPassword;

  /// No description provided for @passwordEncryptsWallet.
  ///
  /// In en, this message translates to:
  /// **'This password encrypts the wallet on this device.'**
  String get passwordEncryptsWallet;

  /// No description provided for @failedToRestore.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore: {error}'**
  String failedToRestore(Object error);

  /// No description provided for @mainnet.
  ///
  /// In en, this message translates to:
  /// **'Mainnet'**
  String get mainnet;

  /// No description provided for @testnet.
  ///
  /// In en, this message translates to:
  /// **'Testnet'**
  String get testnet;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @yourAddress.
  ///
  /// In en, this message translates to:
  /// **'Your Address'**
  String get yourAddress;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @miningRewardKey.
  ///
  /// In en, this message translates to:
  /// **'Mining Payout Address'**
  String get miningRewardKey;

  /// No description provided for @miningRewardKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'Use this address with --wallet-address in your miner or --pool-wallet in your pool to receive block rewards to this wallet.'**
  String get miningRewardKeyDesc;

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get addressCopied;

  /// No description provided for @miningKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Mining key copied'**
  String get miningKeyCopied;

  /// No description provided for @securityFeatures.
  ///
  /// In en, this message translates to:
  /// **'Security Features'**
  String get securityFeatures;

  /// No description provided for @wotsQuantumResistant.
  ///
  /// In en, this message translates to:
  /// **'Experimental WOTS+ signing'**
  String get wotsQuantumResistant;

  /// No description provided for @aes256GcmEncryption.
  ///
  /// In en, this message translates to:
  /// **'XChaCha20-Poly1305'**
  String get aes256GcmEncryption;

  /// No description provided for @blake3Kdf.
  ///
  /// In en, this message translates to:
  /// **'Argon2id (64 MiB, 3 passes)'**
  String get blake3Kdf;

  /// No description provided for @icdStealthKeys.
  ///
  /// In en, this message translates to:
  /// **'ICD Stealth Keys'**
  String get icdStealthKeys;

  /// No description provided for @receiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receiveTitle;

  /// No description provided for @mainnetAddress.
  ///
  /// In en, this message translates to:
  /// **'Mainnet Address'**
  String get mainnetAddress;

  /// No description provided for @testnetAddress.
  ///
  /// In en, this message translates to:
  /// **'Testnet Address'**
  String get testnetAddress;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @addressCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get addressCopiedToClipboard;

  /// No description provided for @receiveInfo.
  ///
  /// In en, this message translates to:
  /// **'Share this address to receive HYP. This address uses stealth keys for enhanced privacy.'**
  String get receiveInfo;

  /// No description provided for @sendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendTitle;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address required'**
  String get addressRequired;

  /// No description provided for @invalidHyphenAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Hyphen address'**
  String get invalidHyphenAddress;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount required'**
  String get amountRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @networkFee.
  ///
  /// In en, this message translates to:
  /// **'Network Fee'**
  String get networkFee;

  /// No description provided for @privacyLevel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Level'**
  String get privacyLevel;

  /// No description provided for @ringSignatureClsag.
  ///
  /// In en, this message translates to:
  /// **'Ring Signature + CLSAG'**
  String get ringSignatureClsag;

  /// No description provided for @invalidRecipientAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid recipient address'**
  String get invalidRecipientAddress;

  /// No description provided for @sendHyp.
  ///
  /// In en, this message translates to:
  /// **'Send HYP'**
  String get sendHyp;

  /// No description provided for @transactionLayer.
  ///
  /// In en, this message translates to:
  /// **'Transaction Layer'**
  String get transactionLayer;

  /// No description provided for @transactionLayerMessage.
  ///
  /// In en, this message translates to:
  /// **'The signing backend is ready. Transaction broadcasting requires connecting the wallet to a Hyphen node via the RPC interface.\n\nUse the pool mining setup to earn HYP first, then transactions will be available once the RPC sync layer is integrated.'**
  String get transactionLayerMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'NETWORK'**
  String get network;

  /// No description provided for @currentNetwork.
  ///
  /// In en, this message translates to:
  /// **'Current Network'**
  String get currentNetwork;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get security;

  /// No description provided for @backupRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Backup Recovery Phrase'**
  String get backupRecoveryPhrase;

  /// No description provided for @viewYour24WordMnemonic.
  ///
  /// In en, this message translates to:
  /// **'View your 24-word mnemonic'**
  String get viewYour24WordMnemonic;

  /// No description provided for @lockWallet.
  ///
  /// In en, this message translates to:
  /// **'Lock Wallet'**
  String get lockWallet;

  /// No description provided for @clearSessionRequirePassword.
  ///
  /// In en, this message translates to:
  /// **'Clear session and require password'**
  String get clearSessionRequirePassword;

  /// No description provided for @walletMustBeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Wallet must be unlocked to view backup'**
  String get walletMustBeUnlocked;

  /// No description provided for @walletSection.
  ///
  /// In en, this message translates to:
  /// **'WALLET'**
  String get walletSection;

  /// No description provided for @viewPublicKey.
  ///
  /// In en, this message translates to:
  /// **'View Public Key'**
  String get viewPublicKey;

  /// No description provided for @spendPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Spend Public Key'**
  String get spendPublicKey;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @walletVersion.
  ///
  /// In en, this message translates to:
  /// **'Wallet Version'**
  String get walletVersion;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get dangerZone;

  /// No description provided for @deleteWallet.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get deleteWallet;

  /// No description provided for @removeAllWalletData.
  ///
  /// In en, this message translates to:
  /// **'Remove all wallet data from this device'**
  String get removeAllWalletData;

  /// No description provided for @deleteWalletWarning.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently remove your wallet from this device.\n\nMake sure you have backed up your recovery phrase. Without it, your funds will be lost forever.'**
  String get deleteWalletWarning;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @recoveryPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Phrase'**
  String get recoveryPhraseTitle;

  /// No description provided for @neverShareWarning.
  ///
  /// In en, this message translates to:
  /// **'Never share your recovery phrase with anyone. Anyone with these words can access your funds.'**
  String get neverShareWarning;

  /// No description provided for @tapBelowToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap below to reveal'**
  String get tapBelowToReveal;

  /// No description provided for @revealRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Reveal Recovery Phrase'**
  String get revealRecoveryPhrase;

  /// No description provided for @copiedClearClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied — clear your clipboard soon!'**
  String get copiedClearClipboard;

  /// No description provided for @hidePhrase.
  ///
  /// In en, this message translates to:
  /// **'Hide Phrase'**
  String get hidePhrase;

  /// No description provided for @phraseCopiedWarning.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase copied — clear clipboard soon!'**
  String get phraseCopiedWarning;

  /// No description provided for @walletManagement.
  ///
  /// In en, this message translates to:
  /// **'WALLET MANAGEMENT'**
  String get walletManagement;

  /// No description provided for @manageWallets.
  ///
  /// In en, this message translates to:
  /// **'Manage Wallets'**
  String get manageWallets;

  /// No description provided for @switchCreateDelete.
  ///
  /// In en, this message translates to:
  /// **'Switch, create or delete wallets'**
  String get switchCreateDelete;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @activeWallet.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeWallet;

  /// No description provided for @switchTo.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchTo;

  /// No description provided for @renameWallet.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameWallet;

  /// No description provided for @deleteThisWallet.
  ///
  /// In en, this message translates to:
  /// **'Delete this wallet'**
  String get deleteThisWallet;

  /// No description provided for @addNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Add New Wallet'**
  String get addNewWallet;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @importExisting.
  ///
  /// In en, this message translates to:
  /// **'Import Existing'**
  String get importExisting;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// No description provided for @enterWalletName.
  ///
  /// In en, this message translates to:
  /// **'Enter wallet name'**
  String get enterWalletName;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @deleteWalletConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete wallet \"{name}\"? This cannot be undone.'**
  String deleteWalletConfirm(Object name);

  /// No description provided for @cannotDeleteActiveWallet.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the active wallet. Switch to another wallet first.'**
  String get cannotDeleteActiveWallet;

  /// No description provided for @walletSwitched.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String walletSwitched(Object name);

  /// No description provided for @walletRenamed.
  ///
  /// In en, this message translates to:
  /// **'Wallet renamed'**
  String get walletRenamed;

  /// No description provided for @walletDeleted.
  ///
  /// In en, this message translates to:
  /// **'Wallet deleted'**
  String get walletDeleted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get language;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appTheme;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// No description provided for @chooseNodeMode.
  ///
  /// In en, this message translates to:
  /// **'Choose Node Mode'**
  String get chooseNodeMode;

  /// No description provided for @nodeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Select how your wallet connects to the Hyphen network. You can change this later in Settings.'**
  String get nodeModeDescription;

  /// No description provided for @lightNode.
  ///
  /// In en, this message translates to:
  /// **'Light Node'**
  String get lightNode;

  /// No description provided for @lightNodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect via remote RPC — fast, low storage'**
  String get lightNodeDesc;

  /// No description provided for @fullNode.
  ///
  /// In en, this message translates to:
  /// **'Full Node'**
  String get fullNode;

  /// No description provided for @fullNodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync entire blockchain — maximum security'**
  String get fullNodeDesc;

  /// No description provided for @lightFeature1.
  ///
  /// In en, this message translates to:
  /// **'Instant startup'**
  String get lightFeature1;

  /// No description provided for @lightFeature2.
  ///
  /// In en, this message translates to:
  /// **'Minimal storage usage'**
  String get lightFeature2;

  /// No description provided for @lightFeature3.
  ///
  /// In en, this message translates to:
  /// **'Trusted RPC endpoint'**
  String get lightFeature3;

  /// No description provided for @fullFeature1.
  ///
  /// In en, this message translates to:
  /// **'Full chain verification'**
  String get fullFeature1;

  /// No description provided for @fullFeature2.
  ///
  /// In en, this message translates to:
  /// **'Built-in block explorer'**
  String get fullFeature2;

  /// No description provided for @fullFeature3.
  ///
  /// In en, this message translates to:
  /// **'No third-party trust'**
  String get fullFeature3;

  /// No description provided for @nodeConnectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Node Connection'**
  String get nodeConnectionStatus;

  /// No description provided for @checkingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checkingConnection;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @onChainMiningRewards.
  ///
  /// In en, this message translates to:
  /// **'On-chain Mining Rewards'**
  String get onChainMiningRewards;

  /// No description provided for @poolPendingBalance.
  ///
  /// In en, this message translates to:
  /// **'Pool Pending Balance'**
  String get poolPendingBalance;

  /// No description provided for @miningPoolMode.
  ///
  /// In en, this message translates to:
  /// **'Pool Mode'**
  String get miningPoolMode;

  /// No description provided for @poolFee.
  ///
  /// In en, this message translates to:
  /// **'Pool Fee'**
  String get poolFee;

  /// No description provided for @rpcEndpoint.
  ///
  /// In en, this message translates to:
  /// **'RPC Endpoint'**
  String get rpcEndpoint;

  /// No description provided for @poolApiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Pool API Endpoint'**
  String get poolApiEndpoint;

  /// No description provided for @autoDerivedFromRpc.
  ///
  /// In en, this message translates to:
  /// **'Auto-derived from RPC host'**
  String get autoDerivedFromRpc;

  /// No description provided for @explorerApiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Explorer API Endpoint'**
  String get explorerApiEndpoint;

  /// No description provided for @availableNodes.
  ///
  /// In en, this message translates to:
  /// **'Available Nodes'**
  String get availableNodes;

  /// No description provided for @addCustomNode.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Node'**
  String get addCustomNode;

  /// No description provided for @miningPayoutAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Mining payout address copied'**
  String get miningPayoutAddressCopied;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get biometricUnlock;

  /// No description provided for @useFingerprintOrFace.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face to unlock'**
  String get useFingerprintOrFace;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric hardware not available on this device'**
  String get biometricNotAvailable;

  /// No description provided for @unlockWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Biometrics'**
  String get unlockWithBiometrics;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @nfcTransfer.
  ///
  /// In en, this message translates to:
  /// **'NFC Transfer'**
  String get nfcTransfer;

  /// No description provided for @nfcTapToTransfer.
  ///
  /// In en, this message translates to:
  /// **'Tap devices to start a transfer'**
  String get nfcTapToTransfer;

  /// No description provided for @nfcNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'NFC is not available on this device'**
  String get nfcNotAvailable;

  /// No description provided for @nfcReadyToScan.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan. Hold devices together.'**
  String get nfcReadyToScan;

  /// No description provided for @nfcTransferSent.
  ///
  /// In en, this message translates to:
  /// **'Transfer address sent via NFC'**
  String get nfcTransferSent;

  /// No description provided for @transferSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get transferSent;

  /// No description provided for @transferReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get transferReceived;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
