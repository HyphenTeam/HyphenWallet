// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get latestUnspentReceived =>
      'Dernier paiement avec un solde disponible';

  @override
  String get blockConfirmations => 'Confirmations de bloc';

  @override
  String get appTitle => 'Hyphen Portefeuille';

  @override
  String get quantumResistantWallet => 'Hyphen Wallet';

  @override
  String get welcomeToHyphen => 'Bienvenue sur Hyphen';

  @override
  String get welcomeSubtitle =>
      'Un portefeuille de bureau pour\nles réseaux de développement Hyphen.';

  @override
  String get aesEncryption => 'Chiffrement authentifié';

  @override
  String get privacyFirst => 'Clés stockées localement';

  @override
  String get createNewWallet => 'Créer un nouveau portefeuille';

  @override
  String get restoreExistingWallet => 'Restaurer un portefeuille existant';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get enterPasswordToUnlock =>
      'Entrez votre mot de passe pour déverrouiller';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String get incorrectPassword => 'Mot de passe incorrect';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get cancel => 'Annuler';

  @override
  String get createWallet => 'Créer le portefeuille';

  @override
  String get generatingSecureWallet => 'Génération du portefeuille sécurisé...';

  @override
  String get recoveryPhrase => 'Phrase de récupération';

  @override
  String get writeDownWords =>
      'Conservez ces 24 mots dans l’ordre et le mot de passe d’origine séparément. Les deux sont nécessaires pour retrouver la même adresse.';

  @override
  String get neverSharePhrase =>
      'Ne partagez jamais votre phrase de récupération avec quiconque !';

  @override
  String get copyToClipboard => 'Copier dans le presse-papiers';

  @override
  String get iveWrittenItDown => 'Je l\'ai noté';

  @override
  String get verifyYourPhrase => 'Vérifiez votre phrase';

  @override
  String get enterWordsToConfirm =>
      'Entrez les mots suivants de votre phrase de récupération pour confirmer que vous l\'avez correctement sauvegardée.';

  @override
  String wordNumber(Object number) {
    return 'Mot n°$number';
  }

  @override
  String wordIncorrect(Object number) {
    return 'Le mot n°$number est incorrect. Veuillez réessayer.';
  }

  @override
  String get verifyAndContinue => 'Vérifier et continuer';

  @override
  String get setPassword => 'Définir le mot de passe';

  @override
  String get passwordEncryptInfo =>
      'Le mot de passe chiffre le portefeuille et détermine ses clés. Pour le restaurer, saisissez le mot de passe d’origine. Un autre mot de passe donne une autre adresse.';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get atLeast8Chars => 'Au moins 8 caractères';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String failedToGenerateWallet(Object error) {
    return 'Échec de la génération du portefeuille : $error';
  }

  @override
  String failedToCreateWallet(Object error) {
    return 'Échec de la création du portefeuille : $error';
  }

  @override
  String get restoreWallet => 'Restaurer le portefeuille';

  @override
  String get enterRecoveryPhrase =>
      'Saisissez les mots dans l’ordre. Pour HYN3, conservez hy3- au début du premier mot et -hy3 à la fin du dernier.';

  @override
  String get mnemonicHint => 'mot1 mot2 mot3 ...';

  @override
  String get pleaseEnter12Or24Words => 'Saisissez 12, 15, 18, 21 ou 24 mots';

  @override
  String get continueButton => 'Continuer';

  @override
  String get setEncryptionPassword => 'Définir le mot de passe de chiffrement';

  @override
  String get passwordEncryptsWallet =>
      'Ce mot de passe chiffre le portefeuille sur cet appareil.';

  @override
  String failedToRestore(Object error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get mainnet => 'Réseau principal';

  @override
  String get testnet => 'Réseau de test';

  @override
  String get totalBalance => 'Solde total';

  @override
  String get yourAddress => 'Votre adresse';

  @override
  String get receive => 'Recevoir';

  @override
  String get send => 'Envoyer';

  @override
  String get miningRewardKey => 'Adresse de paiement du minage';

  @override
  String get miningRewardKeyDesc =>
      'Utilisez cette adresse avec --wallet-address dans le mineur ou --pool-wallet dans le pool pour recevoir les récompenses de bloc dans ce portefeuille.';

  @override
  String get addressCopied => 'Adresse copiée';

  @override
  String get miningKeyCopied => 'Clé de minage copiée';

  @override
  String get securityFeatures => 'Fonctionnalités de sécurité';

  @override
  String get wotsQuantumResistant => 'Signature WOTS+ expérimentale';

  @override
  String get aes256GcmEncryption => 'XChaCha20-Poly1305';

  @override
  String get blake3Kdf => 'Argon2id (64 MiB, 3 passages)';

  @override
  String get icdStealthKeys => 'Clés furtives ICD';

  @override
  String get receiveTitle => 'Recevoir';

  @override
  String get mainnetAddress => 'Adresse réseau principal';

  @override
  String get testnetAddress => 'Adresse réseau de test';

  @override
  String get copy => 'Copier';

  @override
  String get share => 'Partager';

  @override
  String get addressCopiedToClipboard =>
      'Adresse copiée dans le presse-papiers';

  @override
  String get receiveInfo =>
      'Partagez cette adresse pour recevoir des HPN. Cette adresse utilise des clés furtives pour une confidentialité accrue.';

  @override
  String get sendTitle => 'Envoyer';

  @override
  String get recipient => 'Destinataire';

  @override
  String get addressRequired => 'Adresse requise';

  @override
  String get invalidHyphenAddress => 'Adresse Hyphen invalide';

  @override
  String get amount => 'Montant';

  @override
  String get amountRequired => 'Montant requis';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get networkFee => 'Frais de réseau';

  @override
  String get privacyLevel => 'Niveau de confidentialité';

  @override
  String get ringSignatureClsag => 'Signature en anneau + CLSAG';

  @override
  String get invalidRecipientAddress => 'Adresse du destinataire invalide';

  @override
  String get sendHyp => 'Envoyer HPN';

  @override
  String get transactionLayer => 'Couche de transaction';

  @override
  String get transactionLayerMessage =>
      'Le backend de signature est prêt. La diffusion des transactions nécessite la connexion du portefeuille à un nœud Hyphen via l\'interface RPC.\n\nUtilisez d\'abord le minage en pool pour gagner des HPN, puis les transactions seront disponibles une fois la couche de synchronisation RPC intégrée.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Paramètres';

  @override
  String get network => 'RÉSEAU';

  @override
  String get currentNetwork => 'Réseau actuel';

  @override
  String get security => 'SÉCURITÉ';

  @override
  String get backupRecoveryPhrase => 'Sauvegarder la phrase de récupération';

  @override
  String get viewYour24WordMnemonic => 'Voir votre mnémonique de 24 mots';

  @override
  String get lockWallet => 'Verrouiller le portefeuille';

  @override
  String get clearSessionRequirePassword =>
      'Effacer la session et exiger le mot de passe';

  @override
  String get walletMustBeUnlocked =>
      'Le portefeuille doit être déverrouillé pour voir la sauvegarde';

  @override
  String get walletSection => 'PORTEFEUILLE';

  @override
  String get viewPublicKey => 'Clé publique de visualisation';

  @override
  String get spendPublicKey => 'Clé publique de dépense';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get walletVersion => 'Version du portefeuille';

  @override
  String get dangerZone => 'ZONE DANGEREUSE';

  @override
  String get deleteWallet => 'Supprimer le portefeuille';

  @override
  String get removeAllWalletData =>
      'Supprimer toutes les données du portefeuille de cet appareil';

  @override
  String get deleteWalletWarning =>
      'Le portefeuille sera supprimé de cet appareil. Vérifiez d’abord que la phrase et le mot de passe d’origine permettent de retrouver la même adresse.';

  @override
  String get delete => 'Supprimer';

  @override
  String get close => 'Fermer';

  @override
  String get recoveryPhraseTitle => 'Phrase de récupération';

  @override
  String get neverShareWarning =>
      'Gardez votre phrase secrète et conservez séparément le mot de passe d’origine. Les deux sont nécessaires à la restauration.';

  @override
  String get tapBelowToReveal => 'Appuyez ci-dessous pour révéler';

  @override
  String get revealRecoveryPhrase => 'Révéler la phrase de récupération';

  @override
  String get copiedClearClipboard =>
      'Copié — effacez bientôt votre presse-papiers !';

  @override
  String get hidePhrase => 'Masquer la phrase';

  @override
  String get phraseCopiedWarning =>
      'Phrase de récupération copiée — effacez bientôt votre presse-papiers !';

  @override
  String get walletManagement => 'GESTION DES PORTEFEUILLES';

  @override
  String get manageWallets => 'Gérer les portefeuilles';

  @override
  String get switchCreateDelete =>
      'Changer, créer ou supprimer des portefeuilles';

  @override
  String get wallets => 'Portefeuilles';

  @override
  String get activeWallet => 'Actif';

  @override
  String get switchTo => 'Basculer';

  @override
  String get renameWallet => 'Renommer';

  @override
  String get deleteThisWallet => 'Supprimer ce portefeuille';

  @override
  String get addNewWallet => 'Ajouter un nouveau portefeuille';

  @override
  String get createNew => 'Créer nouveau';

  @override
  String get importExisting => 'Importer existant';

  @override
  String get walletName => 'Nom du portefeuille';

  @override
  String get enterWalletName => 'Entrez le nom du portefeuille';

  @override
  String get rename => 'Renommer';

  @override
  String deleteWalletConfirm(Object name) {
    return 'Supprimer le portefeuille \"$name\" ? Cette action est irréversible.';
  }

  @override
  String get cannotDeleteActiveWallet =>
      'Impossible de supprimer le portefeuille actif. Basculez d\'abord vers un autre portefeuille.';

  @override
  String walletSwitched(Object name) {
    return 'Basculé vers $name';
  }

  @override
  String get walletRenamed => 'Portefeuille renommé';

  @override
  String get walletDeleted => 'Portefeuille supprimé';

  @override
  String get language => 'LANGUE';

  @override
  String get appLanguage => 'Langue de l\'application';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get appTheme => 'APPARENCE';

  @override
  String get themeColor => 'Couleur du thème';

  @override
  String get chooseNodeMode => 'Choisir le mode nœud';

  @override
  String get nodeModeDescription =>
      'Sélectionnez comment votre portefeuille se connecte au réseau Hyphen. Vous pourrez changer cela plus tard dans les paramètres.';

  @override
  String get lightNode => 'Nœud léger';

  @override
  String get lightNodeDesc =>
      'Connexion via RPC distant — rapide, peu de stockage';

  @override
  String get fullNode => 'Nœud complet';

  @override
  String get fullNodeDesc =>
      'Synchroniser toute la blockchain — sécurité maximale';

  @override
  String get lightFeature1 => 'Démarrage instantané';

  @override
  String get lightFeature2 => 'Utilisation minimale du stockage';

  @override
  String get lightFeature3 => 'Point d\'accès RPC de confiance';

  @override
  String get fullFeature1 => 'Vérification complète de la chaîne';

  @override
  String get fullFeature2 => 'Explorateur de blocs intégré';

  @override
  String get fullFeature3 => 'Aucune confiance tierce requise';

  @override
  String get nodeConnectionStatus => 'Connexion au nœud';

  @override
  String get checkingConnection => 'Vérification...';

  @override
  String get connected => 'Connecté';

  @override
  String get disconnected => 'Déconnecté';

  @override
  String get onChainMiningRewards => 'On-chain Mining Rewards';

  @override
  String get poolPendingBalance => 'Pool Pending Balance';

  @override
  String get miningPoolMode => 'Pool Mode';

  @override
  String get poolFee => 'Pool Fee';

  @override
  String get rpcEndpoint => 'Point d\'accès RPC';

  @override
  String get poolApiEndpoint => 'Pool API Endpoint';

  @override
  String get autoDerivedFromRpc => 'Auto-derived from RPC host';

  @override
  String get explorerApiEndpoint => 'Explorer API Endpoint';

  @override
  String get availableNodes => 'Nœuds disponibles';

  @override
  String get addCustomNode => 'Ajouter un nœud personnalisé';

  @override
  String get miningPayoutAddressCopied =>
      'Adresse de paiement du minage copiée';

  @override
  String get biometricUnlock => 'Déverrouillage biométrique';

  @override
  String get useFingerprintOrFace => 'Utiliser l\'empreinte ou le visage';

  @override
  String get biometricNotAvailable =>
      'Matériel biométrique non disponible sur cet appareil';

  @override
  String get unlockWithBiometrics => 'Déverrouiller avec la biométrie';

  @override
  String get themeMode => 'Mode du thème';

  @override
  String get lightMode => 'Clair';

  @override
  String get darkMode => 'Sombre';

  @override
  String get systemMode => 'Système';

  @override
  String get nfcTransfer => 'Transfert NFC';

  @override
  String get nfcTapToTransfer => 'Approchez les appareils pour transférer';

  @override
  String get nfcNotAvailable => 'NFC non disponible sur cet appareil';

  @override
  String get nfcReadyToScan => 'Prêt à scanner. Tenez les appareils ensemble.';

  @override
  String get nfcTransferSent => 'Adresse de transfert envoyée via NFC';

  @override
  String get transferSent => 'Envoyé';

  @override
  String get transferReceived => 'Reçu';

  @override
  String get noActivityYet => 'Pas encore d\'activité';
}
