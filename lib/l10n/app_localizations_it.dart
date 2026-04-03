// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Hyphen Portafoglio';

  @override
  String get quantumResistantWallet => 'Portafoglio resistente ai quanti';

  @override
  String get welcomeToHyphen => 'Benvenuto su Hyphen';

  @override
  String get welcomeSubtitle =>
      'Un portafoglio di privacy resistente ai quanti\ncostruito per la blockchain Hyphen.';

  @override
  String get wotsSignatures => 'Firme WOTS+';

  @override
  String get aesEncryption => 'Crittografia AES-256';

  @override
  String get privacyFirst => 'Privacy prima di tutto';

  @override
  String get createNewWallet => 'Crea nuovo portafoglio';

  @override
  String get restoreExistingWallet => 'Ripristina portafoglio esistente';

  @override
  String get welcomeBack => 'Bentornato';

  @override
  String get enterPasswordToUnlock => 'Inserisci la password per sbloccare';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password richiesta';

  @override
  String get incorrectPassword => 'Password errata';

  @override
  String get unlock => 'Sblocca';

  @override
  String get forgotPasswordRestore =>
      'Password dimenticata? Ripristina con mnemonico';

  @override
  String get resetWallet => 'Reimposta portafoglio';

  @override
  String get resetWalletMessage =>
      'Questo eliminerà i dati del portafoglio su questo dispositivo. Puoi ripristinarlo con la frase di recupero di 24 parole.\n\nAssicurati di avere la frase mnemonica prima di procedere.';

  @override
  String get cancel => 'Annulla';

  @override
  String get resetAndRestore => 'Reimposta e ripristina';

  @override
  String get createWallet => 'Crea portafoglio';

  @override
  String get generatingSecureWallet => 'Generazione portafoglio sicuro...';

  @override
  String get recoveryPhrase => 'Frase di recupero';

  @override
  String get writeDownWords =>
      'Scrivi queste 24 parole in ordine e conservale in un luogo sicuro. Questo è l\'UNICO modo per recuperare il tuo portafoglio.';

  @override
  String get neverSharePhrase =>
      'Non condividere mai la frase di recupero con nessuno!';

  @override
  String get copyToClipboard => 'Copia negli appunti';

  @override
  String get iveWrittenItDown => 'L\'ho scritta';

  @override
  String get verifyYourPhrase => 'Verifica la tua frase';

  @override
  String get enterWordsToConfirm =>
      'Inserisci le seguenti parole dalla frase di recupero per confermare che l\'hai salvata correttamente.';

  @override
  String wordNumber(Object number) {
    return 'Parola #$number';
  }

  @override
  String wordIncorrect(Object number) {
    return 'La parola #$number non è corretta. Riprova.';
  }

  @override
  String get verifyAndContinue => 'Verifica e continua';

  @override
  String get setPassword => 'Imposta password';

  @override
  String get passwordEncryptInfo =>
      'Questa password crittograferà il portafoglio su questo dispositivo. Ne avrai bisogno ogni volta che apri l\'app.';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get atLeast8Chars => 'Almeno 8 caratteri';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono';

  @override
  String failedToGenerateWallet(Object error) {
    return 'Generazione portafoglio fallita: $error';
  }

  @override
  String failedToCreateWallet(Object error) {
    return 'Creazione portafoglio fallita: $error';
  }

  @override
  String get restoreWallet => 'Ripristina portafoglio';

  @override
  String get enterRecoveryPhrase =>
      'Inserisci la frase di recupero di 24 parole, separate da spazi.';

  @override
  String get mnemonicHint => 'parola1 parola2 parola3 ...';

  @override
  String get pleaseEnter12Or24Words => 'Inserisci 12 o 24 parole';

  @override
  String get continueButton => 'Continua';

  @override
  String get setEncryptionPassword => 'Imposta password di crittografia';

  @override
  String get passwordEncryptsWallet =>
      'Questa password crittografa il portafoglio su questo dispositivo.';

  @override
  String failedToRestore(Object error) {
    return 'Ripristino fallito: $error';
  }

  @override
  String get mainnet => 'Rete principale';

  @override
  String get testnet => 'Rete di test';

  @override
  String get totalBalance => 'Saldo totale';

  @override
  String get yourAddress => 'Il tuo indirizzo';

  @override
  String get receive => 'Ricevi';

  @override
  String get send => 'Invia';

  @override
  String get miningRewardKey => 'Indirizzo pagamento mining';

  @override
  String get miningRewardKeyDesc =>
      'Usa questo indirizzo con --wallet-address nel miner o --pool-wallet nel pool per ricevere le ricompense dei blocchi in questo portafoglio.';

  @override
  String get addressCopied => 'Indirizzo copiato';

  @override
  String get miningKeyCopied => 'Chiave mining copiata';

  @override
  String get securityFeatures => 'Funzionalità di sicurezza';

  @override
  String get wotsQuantumResistant => 'WOTS+ resistente ai quanti';

  @override
  String get aes256GcmEncryption => 'Crittografia AES-256-GCM';

  @override
  String get blake3Kdf => 'Blake3 KDF (100k cicli)';

  @override
  String get icdStealthKeys => 'Chiavi stealth ICD';

  @override
  String get receiveTitle => 'Ricevi';

  @override
  String get mainnetAddress => 'Indirizzo rete principale';

  @override
  String get testnetAddress => 'Indirizzo rete di test';

  @override
  String get copy => 'Copia';

  @override
  String get share => 'Condividi';

  @override
  String get addressCopiedToClipboard => 'Indirizzo copiato negli appunti';

  @override
  String get receiveInfo =>
      'Condividi questo indirizzo per ricevere HYP. Questo indirizzo usa chiavi stealth per una privacy migliorata.';

  @override
  String get sendTitle => 'Invia';

  @override
  String get recipient => 'Destinatario';

  @override
  String get addressRequired => 'Indirizzo richiesto';

  @override
  String get invalidHyphenAddress => 'Indirizzo Hyphen non valido';

  @override
  String get amount => 'Importo';

  @override
  String get amountRequired => 'Importo richiesto';

  @override
  String get invalidAmount => 'Importo non valido';

  @override
  String get networkFee => 'Commissione di rete';

  @override
  String get privacyLevel => 'Livello di privacy';

  @override
  String get ringSignatureClsag => 'Firma ad anello + CLSAG';

  @override
  String get invalidRecipientAddress => 'Indirizzo destinatario non valido';

  @override
  String get sendHyp => 'Invia HYP';

  @override
  String get transactionLayer => 'Livello transazione';

  @override
  String get transactionLayerMessage =>
      'Il backend di firma è pronto. La trasmissione delle transazioni richiede la connessione del portafoglio a un nodo Hyphen tramite l\'interfaccia RPC.\n\nUsa prima il mining in pool per guadagnare HYP, poi le transazioni saranno disponibili una volta integrato il livello di sincronizzazione RPC.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Impostazioni';

  @override
  String get network => 'RETE';

  @override
  String get currentNetwork => 'Rete attuale';

  @override
  String get security => 'SICUREZZA';

  @override
  String get backupRecoveryPhrase => 'Backup frase di recupero';

  @override
  String get viewYour24WordMnemonic =>
      'Visualizza il tuo mnemonico di 24 parole';

  @override
  String get lockWallet => 'Blocca portafoglio';

  @override
  String get clearSessionRequirePassword =>
      'Cancella sessione e richiedi password';

  @override
  String get walletMustBeUnlocked =>
      'Il portafoglio deve essere sbloccato per vedere il backup';

  @override
  String get walletSection => 'PORTAFOGLIO';

  @override
  String get viewPublicKey => 'Chiave pubblica di visualizzazione';

  @override
  String get spendPublicKey => 'Chiave pubblica di spesa';

  @override
  String get notAvailable => 'Non disponibile';

  @override
  String get walletVersion => 'Versione portafoglio';

  @override
  String get dangerZone => 'ZONA PERICOLOSA';

  @override
  String get deleteWallet => 'Elimina portafoglio';

  @override
  String get removeAllWalletData =>
      'Rimuovi tutti i dati del portafoglio da questo dispositivo';

  @override
  String get deleteWalletWarning =>
      'Questa azione rimuoverà permanentemente il portafoglio da questo dispositivo.\n\nAssicurati di aver salvato la frase di recupero. Senza di essa, i tuoi fondi saranno persi per sempre.';

  @override
  String get delete => 'Elimina';

  @override
  String get close => 'Chiudi';

  @override
  String get recoveryPhraseTitle => 'Frase di recupero';

  @override
  String get neverShareWarning =>
      'Non condividere mai la frase di recupero con nessuno. Chiunque abbia queste parole può accedere ai tuoi fondi.';

  @override
  String get tapBelowToReveal => 'Tocca sotto per rivelare';

  @override
  String get revealRecoveryPhrase => 'Rivela frase di recupero';

  @override
  String get copiedClearClipboard => 'Copiato — cancella presto gli appunti!';

  @override
  String get hidePhrase => 'Nascondi frase';

  @override
  String get phraseCopiedWarning =>
      'Frase di recupero copiata — cancella presto gli appunti!';

  @override
  String get walletManagement => 'GESTIONE PORTAFOGLI';

  @override
  String get manageWallets => 'Gestisci portafogli';

  @override
  String get switchCreateDelete => 'Cambia, crea o elimina portafogli';

  @override
  String get wallets => 'Portafogli';

  @override
  String get activeWallet => 'Attivo';

  @override
  String get switchTo => 'Passa a';

  @override
  String get renameWallet => 'Rinomina';

  @override
  String get deleteThisWallet => 'Elimina questo portafoglio';

  @override
  String get addNewWallet => 'Aggiungi nuovo portafoglio';

  @override
  String get createNew => 'Crea nuovo';

  @override
  String get importExisting => 'Importa esistente';

  @override
  String get walletName => 'Nome portafoglio';

  @override
  String get enterWalletName => 'Inserisci nome portafoglio';

  @override
  String get rename => 'Rinomina';

  @override
  String deleteWalletConfirm(Object name) {
    return 'Eliminare il portafoglio \"$name\"? Questa azione non può essere annullata.';
  }

  @override
  String get cannotDeleteActiveWallet =>
      'Impossibile eliminare il portafoglio attivo. Passa prima a un altro portafoglio.';

  @override
  String walletSwitched(Object name) {
    return 'Passato a $name';
  }

  @override
  String get walletRenamed => 'Portafoglio rinominato';

  @override
  String get walletDeleted => 'Portafoglio eliminato';

  @override
  String get language => 'LINGUA';

  @override
  String get appLanguage => 'Lingua dell\'app';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get appTheme => 'ASPETTO';

  @override
  String get themeColor => 'Colore del tema';

  @override
  String get chooseNodeMode => 'Scegli modalità nodo';

  @override
  String get nodeModeDescription =>
      'Seleziona come il tuo portafoglio si connette alla rete Hyphen. Puoi cambiarlo più tardi nelle impostazioni.';

  @override
  String get lightNode => 'Nodo leggero';

  @override
  String get lightNodeDesc =>
      'Connessione tramite RPC remoto — veloce, poco spazio';

  @override
  String get fullNode => 'Nodo completo';

  @override
  String get fullNodeDesc =>
      'Sincronizza tutta la blockchain — massima sicurezza';

  @override
  String get lightFeature1 => 'Avvio istantaneo';

  @override
  String get lightFeature2 => 'Utilizzo minimo dello spazio';

  @override
  String get lightFeature3 => 'Endpoint RPC affidabile';

  @override
  String get fullFeature1 => 'Verifica completa della catena';

  @override
  String get fullFeature2 => 'Esplora blocchi integrato';

  @override
  String get fullFeature3 => 'Nessuna fiducia verso terzi';

  @override
  String get nodeConnectionStatus => 'Connessione al nodo';

  @override
  String get checkingConnection => 'Verifica...';

  @override
  String get connected => 'Connesso';

  @override
  String get disconnected => 'Disconnesso';

  @override
  String get onChainMiningRewards => 'On-chain Mining Rewards';

  @override
  String get poolPendingBalance => 'Pool Pending Balance';

  @override
  String get miningPoolMode => 'Pool Mode';

  @override
  String get poolFee => 'Pool Fee';

  @override
  String get rpcEndpoint => 'Endpoint RPC';

  @override
  String get poolApiEndpoint => 'Pool API Endpoint';

  @override
  String get autoDerivedFromRpc => 'Auto-derived from RPC host';

  @override
  String get explorerApiEndpoint => 'Explorer API Endpoint';

  @override
  String get availableNodes => 'Nodi disponibili';

  @override
  String get addCustomNode => 'Aggiungi nodo personalizzato';

  @override
  String get miningPayoutAddressCopied => 'Indirizzo pagamento mining copiato';

  @override
  String get biometricUnlock => 'Sblocco biometrico';

  @override
  String get useFingerprintOrFace => 'Usa impronta o viso per sbloccare';

  @override
  String get biometricNotAvailable =>
      'Hardware biometrico non disponibile su questo dispositivo';

  @override
  String get unlockWithBiometrics => 'Sblocca con biometria';

  @override
  String get themeMode => 'Modalità tema';

  @override
  String get lightMode => 'Chiaro';

  @override
  String get darkMode => 'Scuro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get nfcTransfer => 'Trasferimento NFC';

  @override
  String get nfcTapToTransfer => 'Avvicina i dispositivi per trasferire';

  @override
  String get nfcNotAvailable => 'NFC non disponibile su questo dispositivo';

  @override
  String get nfcReadyToScan =>
      'Pronto alla scansione. Tieni i dispositivi vicini.';

  @override
  String get nfcTransferSent => 'Indirizzo di trasferimento inviato via NFC';

  @override
  String get transferSent => 'Inviato';

  @override
  String get transferReceived => 'Ricevuto';

  @override
  String get noActivityYet => 'Nessuna attività';
}
