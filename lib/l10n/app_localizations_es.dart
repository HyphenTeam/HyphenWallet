// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Hyphen Cartera';

  @override
  String get quantumResistantWallet => 'Hyphen Wallet';

  @override
  String get welcomeToHyphen => 'Bienvenido a Hyphen';

  @override
  String get welcomeSubtitle =>
      'Una cartera de escritorio para\nredes de desarrollo Hyphen.';

  @override
  String get wotsSignatures => 'Firmas WOTS+';

  @override
  String get aesEncryption => 'Cifrado autenticado';

  @override
  String get privacyFirst => 'Claves almacenadas localmente';

  @override
  String get createNewWallet => 'Crear nueva cartera';

  @override
  String get restoreExistingWallet => 'Restaurar cartera existente';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get enterPasswordToUnlock => 'Ingrese su contraseña para desbloquear';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordRequired => 'Contraseña requerida';

  @override
  String get incorrectPassword => 'Contraseña incorrecta';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get forgotPasswordRestore =>
      '¿Olvidó su contraseña? Restaurar con mnemónico';

  @override
  String get resetWallet => 'Restablecer cartera';

  @override
  String get resetWalletMessage =>
      'Esto eliminará los datos de su cartera en este dispositivo. Puede restaurarla usando su frase de recuperación de 24 palabras.\n\nAsegúrese de tener su frase mnemónica antes de continuar.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get resetAndRestore => 'Restablecer y restaurar';

  @override
  String get createWallet => 'Crear cartera';

  @override
  String get generatingSecureWallet => 'Generando cartera segura...';

  @override
  String get recoveryPhrase => 'Frase de recuperación';

  @override
  String get writeDownWords =>
      'Escriba estas 24 palabras en orden y guárdelas en un lugar seguro. Esta es la ÚNICA forma de recuperar su cartera.';

  @override
  String get neverSharePhrase =>
      '¡Nunca comparta su frase de recuperación con nadie!';

  @override
  String get copyToClipboard => 'Copiar al portapapeles';

  @override
  String get iveWrittenItDown => 'Ya lo anoté';

  @override
  String get verifyYourPhrase => 'Verificar su frase';

  @override
  String get enterWordsToConfirm =>
      'Ingrese las siguientes palabras de su frase de recuperación para confirmar que las ha guardado correctamente.';

  @override
  String wordNumber(Object number) {
    return 'Palabra #$number';
  }

  @override
  String wordIncorrect(Object number) {
    return 'La palabra #$number es incorrecta. Por favor, inténtelo de nuevo.';
  }

  @override
  String get verifyAndContinue => 'Verificar y continuar';

  @override
  String get setPassword => 'Establecer contraseña';

  @override
  String get passwordEncryptInfo =>
      'Esta contraseña cifrará su cartera en este dispositivo. La necesitará cada vez que abra la aplicación.';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get atLeast8Chars => 'Al menos 8 caracteres';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String failedToGenerateWallet(Object error) {
    return 'Error al generar la cartera: $error';
  }

  @override
  String failedToCreateWallet(Object error) {
    return 'Error al crear la cartera: $error';
  }

  @override
  String get restoreWallet => 'Restaurar cartera';

  @override
  String get enterRecoveryPhrase =>
      'Ingrese su frase de recuperación de 24 palabras, separadas por espacios.';

  @override
  String get mnemonicHint => 'palabra1 palabra2 palabra3 ...';

  @override
  String get pleaseEnter12Or24Words => 'Por favor, ingrese 12 o 24 palabras';

  @override
  String get continueButton => 'Continuar';

  @override
  String get setEncryptionPassword => 'Establecer contraseña de cifrado';

  @override
  String get passwordEncryptsWallet =>
      'Esta contraseña cifra la cartera en este dispositivo.';

  @override
  String failedToRestore(Object error) {
    return 'Error al restaurar: $error';
  }

  @override
  String get mainnet => 'Red principal';

  @override
  String get testnet => 'Red de prueba';

  @override
  String get totalBalance => 'Saldo total';

  @override
  String get yourAddress => 'Su dirección';

  @override
  String get receive => 'Recibir';

  @override
  String get send => 'Enviar';

  @override
  String get miningRewardKey => 'Dirección de pago de minería';

  @override
  String get miningRewardKeyDesc =>
      'Use esta dirección con --wallet-address en el minero o --pool-wallet en el pool para recibir recompensas de bloque en esta cartera.';

  @override
  String get addressCopied => 'Dirección copiada';

  @override
  String get miningKeyCopied => 'Clave de minería copiada';

  @override
  String get securityFeatures => 'Características de seguridad';

  @override
  String get wotsQuantumResistant => 'Firma WOTS+ experimental';

  @override
  String get aes256GcmEncryption => 'XChaCha20-Poly1305';

  @override
  String get blake3Kdf => 'Argon2id (64 MiB, 3 pasadas)';

  @override
  String get icdStealthKeys => 'Claves ocultas ICD';

  @override
  String get receiveTitle => 'Recibir';

  @override
  String get mainnetAddress => 'Dirección de red principal';

  @override
  String get testnetAddress => 'Dirección de red de prueba';

  @override
  String get copy => 'Copiar';

  @override
  String get share => 'Compartir';

  @override
  String get addressCopiedToClipboard => 'Dirección copiada al portapapeles';

  @override
  String get receiveInfo =>
      'Comparta esta dirección para recibir HYP. Esta dirección usa claves ocultas para mayor privacidad.';

  @override
  String get sendTitle => 'Enviar';

  @override
  String get recipient => 'Destinatario';

  @override
  String get addressRequired => 'Dirección requerida';

  @override
  String get invalidHyphenAddress => 'Dirección Hyphen inválida';

  @override
  String get amount => 'Cantidad';

  @override
  String get amountRequired => 'Cantidad requerida';

  @override
  String get invalidAmount => 'Cantidad inválida';

  @override
  String get networkFee => 'Tarifa de red';

  @override
  String get privacyLevel => 'Nivel de privacidad';

  @override
  String get ringSignatureClsag => 'Firma de anillo + CLSAG';

  @override
  String get invalidRecipientAddress => 'Dirección del destinatario inválida';

  @override
  String get sendHyp => 'Enviar HYP';

  @override
  String get transactionLayer => 'Capa de transacción';

  @override
  String get transactionLayerMessage =>
      'El backend de firma está listo. La transmisión de transacciones requiere conectar la cartera a un nodo Hyphen a través de la interfaz RPC.\n\nUse primero la minería en pool para ganar HYP, luego las transacciones estarán disponibles una vez que se integre la capa de sincronización RPC.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Configuración';

  @override
  String get network => 'RED';

  @override
  String get currentNetwork => 'Red actual';

  @override
  String get security => 'SEGURIDAD';

  @override
  String get backupRecoveryPhrase => 'Respaldar frase de recuperación';

  @override
  String get viewYour24WordMnemonic => 'Ver su mnemónico de 24 palabras';

  @override
  String get lockWallet => 'Bloquear cartera';

  @override
  String get clearSessionRequirePassword =>
      'Limpiar sesión y requerir contraseña';

  @override
  String get walletMustBeUnlocked =>
      'La cartera debe estar desbloqueada para ver el respaldo';

  @override
  String get walletSection => 'CARTERA';

  @override
  String get viewPublicKey => 'Clave pública de vista';

  @override
  String get spendPublicKey => 'Clave pública de gasto';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get walletVersion => 'Versión de cartera';

  @override
  String get dangerZone => 'ZONA DE PELIGRO';

  @override
  String get deleteWallet => 'Eliminar cartera';

  @override
  String get removeAllWalletData =>
      'Eliminar todos los datos de la cartera de este dispositivo';

  @override
  String get deleteWalletWarning =>
      'Esta acción eliminará permanentemente su cartera de este dispositivo.\n\nAsegúrese de haber respaldado su frase de recuperación. Sin ella, sus fondos se perderán para siempre.';

  @override
  String get delete => 'Eliminar';

  @override
  String get close => 'Cerrar';

  @override
  String get recoveryPhraseTitle => 'Frase de recuperación';

  @override
  String get neverShareWarning =>
      'Nunca comparta su frase de recuperación con nadie. Cualquier persona con estas palabras puede acceder a sus fondos.';

  @override
  String get tapBelowToReveal => 'Toque abajo para revelar';

  @override
  String get revealRecoveryPhrase => 'Revelar frase de recuperación';

  @override
  String get copiedClearClipboard =>
      'Copiado — ¡limpie pronto su portapapeles!';

  @override
  String get hidePhrase => 'Ocultar frase';

  @override
  String get phraseCopiedWarning =>
      'Frase de recuperación copiada — ¡limpie pronto su portapapeles!';

  @override
  String get walletManagement => 'GESTIÓN DE CARTERAS';

  @override
  String get manageWallets => 'Gestionar carteras';

  @override
  String get switchCreateDelete => 'Cambiar, crear o eliminar carteras';

  @override
  String get wallets => 'Carteras';

  @override
  String get activeWallet => 'Activa';

  @override
  String get switchTo => 'Cambiar';

  @override
  String get renameWallet => 'Renombrar';

  @override
  String get deleteThisWallet => 'Eliminar esta cartera';

  @override
  String get addNewWallet => 'Agregar nueva cartera';

  @override
  String get createNew => 'Crear nueva';

  @override
  String get importExisting => 'Importar existente';

  @override
  String get walletName => 'Nombre de cartera';

  @override
  String get enterWalletName => 'Ingrese nombre de cartera';

  @override
  String get rename => 'Renombrar';

  @override
  String deleteWalletConfirm(Object name) {
    return '¿Eliminar cartera \"$name\"? Esto no se puede deshacer.';
  }

  @override
  String get cannotDeleteActiveWallet =>
      'No se puede eliminar la cartera activa. Primero cambie a otra cartera.';

  @override
  String walletSwitched(Object name) {
    return 'Cambiado a $name';
  }

  @override
  String get walletRenamed => 'Cartera renombrada';

  @override
  String get walletDeleted => 'Cartera eliminada';

  @override
  String get language => 'IDIOMA';

  @override
  String get appLanguage => 'Idioma de la aplicación';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get appTheme => 'APARIENCIA';

  @override
  String get themeColor => 'Color del tema';

  @override
  String get chooseNodeMode => 'Elegir modo de nodo';

  @override
  String get nodeModeDescription =>
      'Selecciona cómo tu billetera se conecta a la red Hyphen. Puedes cambiarlo más tarde en Ajustes.';

  @override
  String get lightNode => 'Nodo ligero';

  @override
  String get lightNodeDesc =>
      'Conectar vía RPC remoto — rápido, bajo almacenamiento';

  @override
  String get fullNode => 'Nodo completo';

  @override
  String get fullNodeDesc =>
      'Sincronizar toda la blockchain — máxima seguridad';

  @override
  String get lightFeature1 => 'Inicio instantáneo';

  @override
  String get lightFeature2 => 'Uso mínimo de almacenamiento';

  @override
  String get lightFeature3 => 'Endpoint RPC de confianza';

  @override
  String get fullFeature1 => 'Verificación completa de la cadena';

  @override
  String get fullFeature2 => 'Explorador de bloques integrado';

  @override
  String get fullFeature3 => 'Sin confianza en terceros';

  @override
  String get nodeConnectionStatus => 'Conexión al nodo';

  @override
  String get checkingConnection => 'Verificando...';

  @override
  String get connected => 'Conectado';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get onChainMiningRewards => 'On-chain Mining Rewards';

  @override
  String get poolPendingBalance => 'Pool Pending Balance';

  @override
  String get miningPoolMode => 'Pool Mode';

  @override
  String get poolFee => 'Pool Fee';

  @override
  String get rpcEndpoint => 'Punto de acceso RPC';

  @override
  String get poolApiEndpoint => 'Pool API Endpoint';

  @override
  String get autoDerivedFromRpc => 'Auto-derived from RPC host';

  @override
  String get explorerApiEndpoint => 'Explorer API Endpoint';

  @override
  String get availableNodes => 'Nodos disponibles';

  @override
  String get addCustomNode => 'Añadir nodo personalizado';

  @override
  String get miningPayoutAddressCopied =>
      'Dirección de pago de minería copiada';

  @override
  String get biometricUnlock => 'Desbloqueo biométrico';

  @override
  String get useFingerprintOrFace => 'Usar huella o rostro para desbloquear';

  @override
  String get biometricNotAvailable =>
      'Hardware biométrico no disponible en este dispositivo';

  @override
  String get unlockWithBiometrics => 'Desbloquear con biometría';

  @override
  String get themeMode => 'Modo de tema';

  @override
  String get lightMode => 'Claro';

  @override
  String get darkMode => 'Oscuro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get nfcTransfer => 'Transferencia NFC';

  @override
  String get nfcTapToTransfer => 'Acerque los dispositivos para transferir';

  @override
  String get nfcNotAvailable => 'NFC no disponible en este dispositivo';

  @override
  String get nfcReadyToScan => 'Listo para escanear. Acerque los dispositivos.';

  @override
  String get nfcTransferSent => 'Dirección de transferencia enviada por NFC';

  @override
  String get transferSent => 'Enviado';

  @override
  String get transferReceived => 'Recibido';

  @override
  String get noActivityYet => 'Sin actividad aún';
}
