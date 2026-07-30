// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Hyphen Wallet';

  @override
  String get quantumResistantWallet => 'Hyphen Wallet';

  @override
  String get welcomeToHyphen => 'Willkommen bei Hyphen';

  @override
  String get welcomeSubtitle =>
      'Eine Desktop-Wallet für\nHyphen-Entwicklungsnetze.';

  @override
  String get wotsSignatures => 'WOTS+ Signaturen';

  @override
  String get aesEncryption => 'Authentifizierte Verschlüsselung';

  @override
  String get privacyFirst => 'Lokale Schlüsselspeicherung';

  @override
  String get createNewWallet => 'Neue Wallet erstellen';

  @override
  String get restoreExistingWallet => 'Vorhandene Wallet wiederherstellen';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get enterPasswordToUnlock => 'Passwort eingeben zum Entsperren';

  @override
  String get password => 'Passwort';

  @override
  String get passwordRequired => 'Passwort erforderlich';

  @override
  String get incorrectPassword => 'Falsches Passwort';

  @override
  String get unlock => 'Entsperren';

  @override
  String get forgotPasswordRestore =>
      'Passwort vergessen? Mit Mnemonik wiederherstellen';

  @override
  String get resetWallet => 'Wallet zurücksetzen';

  @override
  String get resetWalletMessage =>
      'Dadurch werden Ihre Wallet-Daten auf diesem Gerät gelöscht. Sie können sie mit Ihrer 24-Wort-Wiederherstellungsphrase wiederherstellen.\n\nStellen Sie sicher, dass Sie Ihre Mnemonik-Phrase haben, bevor Sie fortfahren.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get resetAndRestore => 'Zurücksetzen & Wiederherstellen';

  @override
  String get createWallet => 'Wallet erstellen';

  @override
  String get generatingSecureWallet => 'Sichere Wallet wird generiert...';

  @override
  String get recoveryPhrase => 'Wiederherstellungsphrase';

  @override
  String get writeDownWords =>
      'Schreiben Sie diese 24 Wörter der Reihe nach auf und bewahren Sie sie an einem sicheren Ort auf. Dies ist der EINZIGE Weg, Ihre Wallet wiederherzustellen.';

  @override
  String get neverSharePhrase =>
      'Teilen Sie Ihre Wiederherstellungsphrase niemals mit jemandem!';

  @override
  String get copyToClipboard => 'In Zwischenablage kopieren';

  @override
  String get iveWrittenItDown => 'Ich habe es aufgeschrieben';

  @override
  String get verifyYourPhrase => 'Phrase überprüfen';

  @override
  String get enterWordsToConfirm =>
      'Geben Sie die folgenden Wörter aus Ihrer Wiederherstellungsphrase ein, um zu bestätigen, dass Sie sie korrekt gespeichert haben.';

  @override
  String wordNumber(Object number) {
    return 'Wort #$number';
  }

  @override
  String wordIncorrect(Object number) {
    return 'Wort #$number ist falsch. Bitte versuchen Sie es erneut.';
  }

  @override
  String get verifyAndContinue => 'Überprüfen & Fortfahren';

  @override
  String get setPassword => 'Passwort festlegen';

  @override
  String get passwordEncryptInfo =>
      'Dieses Passwort verschlüsselt Ihre Wallet auf diesem Gerät. Sie benötigen es bei jedem Öffnen der App.';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get atLeast8Chars => 'Mindestens 8 Zeichen';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String failedToGenerateWallet(Object error) {
    return 'Wallet-Generierung fehlgeschlagen: $error';
  }

  @override
  String failedToCreateWallet(Object error) {
    return 'Wallet-Erstellung fehlgeschlagen: $error';
  }

  @override
  String get restoreWallet => 'Wallet wiederherstellen';

  @override
  String get enterRecoveryPhrase =>
      'Geben Sie Ihre 24-Wort-Wiederherstellungsphrase ein, getrennt durch Leerzeichen.';

  @override
  String get mnemonicHint => 'Wort1 Wort2 Wort3 ...';

  @override
  String get pleaseEnter12Or24Words => 'Bitte geben Sie 12 oder 24 Wörter ein';

  @override
  String get continueButton => 'Weiter';

  @override
  String get setEncryptionPassword => 'Verschlüsselungspasswort festlegen';

  @override
  String get passwordEncryptsWallet =>
      'Dieses Passwort verschlüsselt die Wallet auf diesem Gerät.';

  @override
  String failedToRestore(Object error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get mainnet => 'Mainnet';

  @override
  String get testnet => 'Testnet';

  @override
  String get totalBalance => 'Gesamtguthaben';

  @override
  String get yourAddress => 'Ihre Adresse';

  @override
  String get receive => 'Empfangen';

  @override
  String get send => 'Senden';

  @override
  String get miningRewardKey => 'Mining-Auszahlungsadresse';

  @override
  String get miningRewardKeyDesc =>
      'Verwenden Sie diese Adresse mit --wallet-address im Miner oder --pool-wallet im Pool, um Block-Belohnungen an diese Wallet zu erhalten.';

  @override
  String get addressCopied => 'Adresse kopiert';

  @override
  String get miningKeyCopied => 'Mining-Schlüssel kopiert';

  @override
  String get securityFeatures => 'Sicherheitsfunktionen';

  @override
  String get wotsQuantumResistant => 'Experimentelle WOTS+-Signatur';

  @override
  String get aes256GcmEncryption => 'XChaCha20-Poly1305';

  @override
  String get blake3Kdf => 'Argon2id (64 MiB, 3 Durchläufe)';

  @override
  String get icdStealthKeys => 'ICD Stealth-Schlüssel';

  @override
  String get receiveTitle => 'Empfangen';

  @override
  String get mainnetAddress => 'Mainnet-Adresse';

  @override
  String get testnetAddress => 'Testnet-Adresse';

  @override
  String get copy => 'Kopieren';

  @override
  String get share => 'Teilen';

  @override
  String get addressCopiedToClipboard => 'Adresse in Zwischenablage kopiert';

  @override
  String get receiveInfo =>
      'Teilen Sie diese Adresse, um HYP zu empfangen. Diese Adresse verwendet Stealth-Schlüssel für verbesserten Datenschutz.';

  @override
  String get sendTitle => 'Senden';

  @override
  String get recipient => 'Empfänger';

  @override
  String get addressRequired => 'Adresse erforderlich';

  @override
  String get invalidHyphenAddress => 'Ungültige Hyphen-Adresse';

  @override
  String get amount => 'Betrag';

  @override
  String get amountRequired => 'Betrag erforderlich';

  @override
  String get invalidAmount => 'Ungültiger Betrag';

  @override
  String get networkFee => 'Netzwerkgebühr';

  @override
  String get privacyLevel => 'Datenschutzstufe';

  @override
  String get ringSignatureClsag => 'Ringsignatur + CLSAG';

  @override
  String get invalidRecipientAddress => 'Ungültige Empfängeradresse';

  @override
  String get sendHyp => 'HYP senden';

  @override
  String get transactionLayer => 'Transaktionsschicht';

  @override
  String get transactionLayerMessage =>
      'Das Signatur-Backend ist bereit. Transaktionsübertragung erfordert die Verbindung der Wallet mit einem Hyphen-Knoten über die RPC-Schnittstelle.\n\nVerdienen Sie zuerst HYP durch Pool-Mining, dann sind Transaktionen verfügbar, sobald die RPC-Synchronisierungsschicht integriert ist.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Einstellungen';

  @override
  String get network => 'NETZWERK';

  @override
  String get currentNetwork => 'Aktuelles Netzwerk';

  @override
  String get security => 'SICHERHEIT';

  @override
  String get backupRecoveryPhrase => 'Wiederherstellungsphrase sichern';

  @override
  String get viewYour24WordMnemonic => 'Ihre 24-Wort-Mnemonik anzeigen';

  @override
  String get lockWallet => 'Wallet sperren';

  @override
  String get clearSessionRequirePassword =>
      'Sitzung löschen und Passwort verlangen';

  @override
  String get walletMustBeUnlocked =>
      'Wallet muss entsperrt sein, um Backup anzuzeigen';

  @override
  String get walletSection => 'WALLET';

  @override
  String get viewPublicKey => 'Öffentlichen Schlüssel anzeigen';

  @override
  String get spendPublicKey => 'Ausgabe-Schlüssel';

  @override
  String get notAvailable => 'Nicht verfügbar';

  @override
  String get walletVersion => 'Wallet-Version';

  @override
  String get dangerZone => 'GEFAHRENZONE';

  @override
  String get deleteWallet => 'Wallet löschen';

  @override
  String get removeAllWalletData =>
      'Alle Wallet-Daten von diesem Gerät entfernen';

  @override
  String get deleteWalletWarning =>
      'Diese Aktion entfernt Ihre Wallet dauerhaft von diesem Gerät.\n\nStellen Sie sicher, dass Sie Ihre Wiederherstellungsphrase gesichert haben. Ohne sie gehen Ihre Mittel für immer verloren.';

  @override
  String get delete => 'Löschen';

  @override
  String get close => 'Schließen';

  @override
  String get recoveryPhraseTitle => 'Wiederherstellungsphrase';

  @override
  String get neverShareWarning =>
      'Teilen Sie Ihre Wiederherstellungsphrase niemals mit jemandem. Jeder mit diesen Wörtern kann auf Ihr Guthaben zugreifen.';

  @override
  String get tapBelowToReveal => 'Tippen Sie unten zum Anzeigen';

  @override
  String get revealRecoveryPhrase => 'Wiederherstellungsphrase anzeigen';

  @override
  String get copiedClearClipboard =>
      'Kopiert — leeren Sie bald Ihre Zwischenablage!';

  @override
  String get hidePhrase => 'Phrase verbergen';

  @override
  String get phraseCopiedWarning =>
      'Wiederherstellungsphrase kopiert — leeren Sie bald Ihre Zwischenablage!';

  @override
  String get walletManagement => 'WALLET-VERWALTUNG';

  @override
  String get manageWallets => 'Wallets verwalten';

  @override
  String get switchCreateDelete => 'Wallets wechseln, erstellen oder löschen';

  @override
  String get wallets => 'Wallets';

  @override
  String get activeWallet => 'Aktiv';

  @override
  String get switchTo => 'Wechseln';

  @override
  String get renameWallet => 'Umbenennen';

  @override
  String get deleteThisWallet => 'Diese Wallet löschen';

  @override
  String get addNewWallet => 'Neue Wallet hinzufügen';

  @override
  String get createNew => 'Neu erstellen';

  @override
  String get importExisting => 'Vorhandene importieren';

  @override
  String get walletName => 'Wallet-Name';

  @override
  String get enterWalletName => 'Wallet-Name eingeben';

  @override
  String get rename => 'Umbenennen';

  @override
  String deleteWalletConfirm(Object name) {
    return 'Wallet \"$name\" löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get cannotDeleteActiveWallet =>
      'Die aktive Wallet kann nicht gelöscht werden. Wechseln Sie zuerst zu einer anderen Wallet.';

  @override
  String walletSwitched(Object name) {
    return 'Zu $name gewechselt';
  }

  @override
  String get walletRenamed => 'Wallet umbenannt';

  @override
  String get walletDeleted => 'Wallet gelöscht';

  @override
  String get language => 'SPRACHE';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get appTheme => 'DARSTELLUNG';

  @override
  String get themeColor => 'Designfarbe';

  @override
  String get chooseNodeMode => 'Knotenmodus wählen';

  @override
  String get nodeModeDescription =>
      'Wählen Sie, wie sich Ihre Wallet mit dem Hyphen-Netzwerk verbindet. Sie können dies später in den Einstellungen ändern.';

  @override
  String get lightNode => 'Light-Knoten';

  @override
  String get lightNodeDesc =>
      'Verbindung über Remote-RPC — schnell, wenig Speicher';

  @override
  String get fullNode => 'Vollknoten';

  @override
  String get fullNodeDesc =>
      'Gesamte Blockchain synchronisieren — maximale Sicherheit';

  @override
  String get lightFeature1 => 'Sofortiger Start';

  @override
  String get lightFeature2 => 'Minimaler Speicherverbrauch';

  @override
  String get lightFeature3 => 'Vertrauenswürdiger RPC-Endpunkt';

  @override
  String get fullFeature1 => 'Vollständige Kettenverifizierung';

  @override
  String get fullFeature2 => 'Integrierter Block-Explorer';

  @override
  String get fullFeature3 => 'Kein Vertrauen in Dritte';

  @override
  String get nodeConnectionStatus => 'Knotenverbindung';

  @override
  String get checkingConnection => 'Prüfe...';

  @override
  String get connected => 'Verbunden';

  @override
  String get disconnected => 'Nicht verbunden';

  @override
  String get onChainMiningRewards => 'On-chain Mining Rewards';

  @override
  String get poolPendingBalance => 'Pool Pending Balance';

  @override
  String get miningPoolMode => 'Pool Mode';

  @override
  String get poolFee => 'Pool Fee';

  @override
  String get rpcEndpoint => 'RPC-Endpunkt';

  @override
  String get poolApiEndpoint => 'Pool API Endpoint';

  @override
  String get autoDerivedFromRpc => 'Auto-derived from RPC host';

  @override
  String get explorerApiEndpoint => 'Explorer API Endpoint';

  @override
  String get availableNodes => 'Verfügbare Knoten';

  @override
  String get addCustomNode => 'Eigenen Knoten hinzufügen';

  @override
  String get miningPayoutAddressCopied => 'Mining-Auszahlungsadresse kopiert';

  @override
  String get biometricUnlock => 'Biometrische Entsperrung';

  @override
  String get useFingerprintOrFace => 'Fingerabdruck oder Gesicht verwenden';

  @override
  String get biometricNotAvailable =>
      'Biometrische Hardware auf diesem Gerät nicht verfügbar';

  @override
  String get unlockWithBiometrics => 'Biometrisch entsperren';

  @override
  String get themeMode => 'Designmodus';

  @override
  String get lightMode => 'Hell';

  @override
  String get darkMode => 'Dunkel';

  @override
  String get systemMode => 'System';

  @override
  String get nfcTransfer => 'NFC-Übertragung';

  @override
  String get nfcTapToTransfer => 'Geräte zusammenhalten zum Übertragen';

  @override
  String get nfcNotAvailable => 'NFC ist auf diesem Gerät nicht verfügbar';

  @override
  String get nfcReadyToScan =>
      'Bereit zum Scannen. Halten Sie die Geräte zusammen.';

  @override
  String get nfcTransferSent => 'Überweisungsadresse per NFC gesendet';

  @override
  String get transferSent => 'Gesendet';

  @override
  String get transferReceived => 'Empfangen';

  @override
  String get noActivityYet => 'Noch keine Aktivität';
}
