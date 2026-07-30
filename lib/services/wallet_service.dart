import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hyphen_wallet/src/rust/api/wallet.dart' as rust;
import 'package:hyphen_wallet/src/rust/frb_generated.dart';

const _kWalletList = 'wallet_list';
const _kActiveWalletId = 'active_wallet_id';
const _kCurrentNetwork = 'current_network';
const _kAppLocale = 'app_locale';
const _kNodeMode = 'node_mode';
const _kBiometricEnabled = 'biometric_enabled';
const _kBiometricPassword = 'biometric_password';
const _kThemeMode = 'theme_mode';
const _kCustomRpcEndpoint = 'custom_rpc_endpoint';
const _kPoolApiEndpoint = 'pool_api_endpoint';
const _kExplorerApiEndpoint = 'explorer_api_endpoint';
const _kThemeColorIndex = 'theme_color_index';
const _kLastScannedHeight = 'last_scanned_height';
const _kOwnedOutputs = 'owned_outputs';
const _kTransferHistory = 'transfer_history';

const kDefaultRpcEndpoint = 'bytesnap.tech:38333';
const kDefaultMainnetRpcEndpoint = 'bytesnap.tech:18333';

(String host, int port)? _parseEndpoint(String raw, int defaultPort) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  try {
    final uri = trimmed.contains('://')
        ? Uri.parse(trimmed)
        : Uri.parse('http://$trimmed');
    final host = uri.host.isNotEmpty ? uri.host : uri.path;
    if (host.isEmpty) {
      return null;
    }
    return (host, uri.hasPort ? uri.port : defaultPort);
  } catch (_) {
    return null;
  }
}

String _derivePoolApiEndpoint(String rpcEndpoint) {
  final parsed = _parseEndpoint(rpcEndpoint, 38333);
  if (parsed == null) {
    return '';
  }
  return '${parsed.$1}:8081';
}

String _deriveExplorerApiEndpoint(String rpcEndpoint) {
  final parsed = _parseEndpoint(rpcEndpoint, 38333);
  if (parsed == null) {
    return '';
  }
  return '${parsed.$1}:8080';
}

enum HyphenNetwork { mainnet, testnet }

enum NodeMode {
  light,
  full;

  String get displayName {
    switch (this) {
      case NodeMode.light:
        return 'Light Node';
      case NodeMode.full:
        return 'Full Node';
    }
  }
}

class WalletInfo {
  final String id;
  String name;
  final String encryptedData;

  WalletInfo({
    required this.id,
    required this.name,
    required this.encryptedData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'encryptedData': encryptedData,
  };

  factory WalletInfo.fromJson(Map<String, dynamic> json) => WalletInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    encryptedData: json['encryptedData'] as String,
  );
}

/// Direction of a transfer.
enum TransferDirection { sent, received }

/// A transfer event (sent or received).
class TransferActivity {
  final TransferDirection direction;
  final String txHashHex;
  final String recipientAddress;
  final String amountAtomic;
  final String feeAtomic;
  final int timestamp; // unix seconds
  final int? height; // null if pending

  const TransferActivity({
    required this.direction,
    required this.txHashHex,
    required this.recipientAddress,
    required this.amountAtomic,
    required this.feeAtomic,
    required this.timestamp,
    this.height,
  });

  Map<String, dynamic> toJson() => {
    'direction': direction == TransferDirection.sent ? 'sent' : 'received',
    'txHashHex': txHashHex,
    'recipientAddress': recipientAddress,
    'amountAtomic': amountAtomic,
    'feeAtomic': feeAtomic,
    'timestamp': timestamp,
    'height': height,
  };

  factory TransferActivity.fromJson(Map<String, dynamic> json) =>
      TransferActivity(
        direction: json['direction'] == 'sent'
            ? TransferDirection.sent
            : TransferDirection.received,
        txHashHex: json['txHashHex'] as String? ?? '',
        recipientAddress: json['recipientAddress'] as String? ?? '',
        amountAtomic: json['amountAtomic'] as String? ?? '0',
        feeAtomic: json['feeAtomic'] as String? ?? '0',
        timestamp: json['timestamp'] as int? ?? 0,
        height: json['height'] as int?,
      );
}

class RewardActivity {
  final String source;
  final int height;
  final String blockHashHex;
  final String amountAtomic;
  final String rewardAtomic;
  final String feeAtomic;
  final int timestamp;
  final String mode;
  final String kind;
  final String walletAddressHex;
  final String rewardRecipientHex;
  final String finderPubkeyHex;
  final bool directCoinbase;

  const RewardActivity({
    required this.source,
    required this.height,
    required this.blockHashHex,
    required this.amountAtomic,
    required this.rewardAtomic,
    required this.feeAtomic,
    required this.timestamp,
    required this.mode,
    required this.kind,
    required this.walletAddressHex,
    required this.rewardRecipientHex,
    required this.finderPubkeyHex,
    required this.directCoinbase,
  });
}

class WalletState {
  final bool isUnlocked;
  final String? address;
  final String? seedHex;
  final String? mnemonic;
  final String? viewPublicHex;
  final String? spendPublicHex;
  final HyphenNetwork network;
  final String? activeWalletId;
  final List<WalletInfo> wallets;
  final NodeMode nodeMode;
  final String rpcEndpoint;
  final String poolApiEndpoint;
  final String explorerApiEndpoint;
  final String minedRewardsAtomic;
  final String directPoolRewardsAtomic;
  final int minedBlocksFound;
  final int? latestMinedHeight;
  final String pendingPoolRewardsAtomic;
  final String poolPayoutMode;
  final String poolWalletHex;
  final String poolCoinbaseRewardsAtomic;
  final int? poolFeeBps;
  final int poolActiveMiners;
  final bool isPoolWallet;
  final bool directCoinbaseMode;
  final List<RewardActivity> rewardActivities;
  final List<TransferActivity> transferActivities;
  final String onChainBalanceAtomic;

  const WalletState({
    this.isUnlocked = false,
    this.address,
    this.seedHex,
    this.mnemonic,
    this.viewPublicHex,
    this.spendPublicHex,
    this.network = HyphenNetwork.testnet,
    this.activeWalletId,
    this.wallets = const [],
    this.nodeMode = NodeMode.light,
    this.rpcEndpoint = kDefaultRpcEndpoint,
    this.poolApiEndpoint = '',
    this.explorerApiEndpoint = '',
    this.minedRewardsAtomic = '0',
    this.directPoolRewardsAtomic = '0',
    this.minedBlocksFound = 0,
    this.latestMinedHeight,
    this.pendingPoolRewardsAtomic = '0',
    this.poolPayoutMode = '',
    this.poolWalletHex = '',
    this.poolCoinbaseRewardsAtomic = '0',
    this.poolFeeBps,
    this.poolActiveMiners = 0,
    this.isPoolWallet = false,
    this.directCoinbaseMode = false,
    this.rewardActivities = const [],
    this.transferActivities = const [],
    this.onChainBalanceAtomic = '0',
  });

  WalletState copyWith({
    bool? isUnlocked,
    String? address,
    String? seedHex,
    String? mnemonic,
    String? viewPublicHex,
    String? spendPublicHex,
    HyphenNetwork? network,
    String? activeWalletId,
    List<WalletInfo>? wallets,
    NodeMode? nodeMode,
    String? rpcEndpoint,
    String? poolApiEndpoint,
    String? explorerApiEndpoint,
    String? minedRewardsAtomic,
    String? directPoolRewardsAtomic,
    int? minedBlocksFound,
    int? latestMinedHeight,
    String? pendingPoolRewardsAtomic,
    String? poolPayoutMode,
    String? poolWalletHex,
    String? poolCoinbaseRewardsAtomic,
    int? poolFeeBps,
    int? poolActiveMiners,
    bool? isPoolWallet,
    bool? directCoinbaseMode,
    List<RewardActivity>? rewardActivities,
    List<TransferActivity>? transferActivities,
    String? onChainBalanceAtomic,
  }) {
    return WalletState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      address: address ?? this.address,
      seedHex: seedHex ?? this.seedHex,
      mnemonic: mnemonic ?? this.mnemonic,
      viewPublicHex: viewPublicHex ?? this.viewPublicHex,
      spendPublicHex: spendPublicHex ?? this.spendPublicHex,
      network: network ?? this.network,
      activeWalletId: activeWalletId ?? this.activeWalletId,
      wallets: wallets ?? this.wallets,
      nodeMode: nodeMode ?? this.nodeMode,
      rpcEndpoint: rpcEndpoint ?? this.rpcEndpoint,
      poolApiEndpoint: poolApiEndpoint ?? this.poolApiEndpoint,
      explorerApiEndpoint: explorerApiEndpoint ?? this.explorerApiEndpoint,
      minedRewardsAtomic: minedRewardsAtomic ?? this.minedRewardsAtomic,
      directPoolRewardsAtomic:
          directPoolRewardsAtomic ?? this.directPoolRewardsAtomic,
      minedBlocksFound: minedBlocksFound ?? this.minedBlocksFound,
      latestMinedHeight: latestMinedHeight ?? this.latestMinedHeight,
      pendingPoolRewardsAtomic:
          pendingPoolRewardsAtomic ?? this.pendingPoolRewardsAtomic,
      poolPayoutMode: poolPayoutMode ?? this.poolPayoutMode,
      poolWalletHex: poolWalletHex ?? this.poolWalletHex,
      poolCoinbaseRewardsAtomic:
          poolCoinbaseRewardsAtomic ?? this.poolCoinbaseRewardsAtomic,
      poolFeeBps: poolFeeBps ?? this.poolFeeBps,
      poolActiveMiners: poolActiveMiners ?? this.poolActiveMiners,
      isPoolWallet: isPoolWallet ?? this.isPoolWallet,
      directCoinbaseMode: directCoinbaseMode ?? this.directCoinbaseMode,
      rewardActivities: rewardActivities ?? this.rewardActivities,
      transferActivities: transferActivities ?? this.transferActivities,
      onChainBalanceAtomic: onChainBalanceAtomic ?? this.onChainBalanceAtomic,
    );
  }

  bool get usesAutoPoolApiEndpoint => poolApiEndpoint.trim().isEmpty;

  String get effectivePoolApiEndpoint {
    final explicit = poolApiEndpoint.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return _derivePoolApiEndpoint(rpcEndpoint);
  }

  bool get usesAutoExplorerApiEndpoint => explorerApiEndpoint.trim().isEmpty;

  String get effectiveExplorerApiEndpoint {
    final explicit = explorerApiEndpoint.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return _deriveExplorerApiEndpoint(rpcEndpoint);
  }

  WalletInfo? get activeWallet {
    if (activeWalletId == null) return null;
    try {
      return wallets.firstWhere((w) => w.id == activeWalletId);
    } catch (_) {
      return null;
    }
  }
}

class WalletService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  WalletState _state = const WalletState();
  WalletState get state => _state;

  bool _initialized = false;
  bool get initialized => _initialized;

  Locale? _locale;
  Locale? get locale => _locale;
  Timer? _minedRewardsTimer;
  int _themeColorIndex = 0;
  int get themeColorIndex => _themeColorIndex;
  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    await RustLib.init();
    final networkStr = await _storage.read(key: _kCurrentNetwork);
    final network = networkStr == 'mainnet'
        ? HyphenNetwork.mainnet
        : HyphenNetwork.testnet;
    final wallets = await _loadWalletList();
    final activeId = await _storage.read(key: _kActiveWalletId);
    final localeStr = await _storage.read(key: _kAppLocale);
    if (localeStr != null && localeStr.isNotEmpty) {
      _locale = Locale(localeStr);
    }
    final themeStr = await _storage.read(key: _kThemeColorIndex);
    if (themeStr != null) {
      _themeColorIndex = int.tryParse(themeStr) ?? 0;
    }
    final bioStr = await _storage.read(key: _kBiometricEnabled);
    _biometricEnabled = bioStr == 'true';
    final tmStr = await _storage.read(key: _kThemeMode);
    _themeMode = switch (tmStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final nodeModeStr = await _storage.read(key: _kNodeMode);
    final nodeMode = nodeModeStr == 'full' ? NodeMode.full : NodeMode.light;
    final customRpc = await _storage.read(key: _kCustomRpcEndpoint);
    final poolApiEndpoint = await _storage.read(key: _kPoolApiEndpoint);
    final explorerApiEndpoint = await _storage.read(key: _kExplorerApiEndpoint);
    final rpcEndpoint =
        customRpc ??
        (network == HyphenNetwork.mainnet
            ? kDefaultMainnetRpcEndpoint
            : kDefaultRpcEndpoint);
    _state = WalletState(
      isUnlocked: false,
      network: network,
      wallets: wallets,
      activeWalletId: activeId,
      nodeMode: nodeMode,
      rpcEndpoint: rpcEndpoint,
      poolApiEndpoint: poolApiEndpoint ?? '',
      explorerApiEndpoint: explorerApiEndpoint ?? '',
    );
    _initialized = true;
    notifyListeners();
    _startMinedRewardsPolling();
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<bool> hasWallet() async {
    final wallets = await _loadWalletList();
    return wallets.isNotEmpty;
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    if (locale != null) {
      await _storage.write(key: _kAppLocale, value: locale.languageCode);
    } else {
      await _storage.delete(key: _kAppLocale);
    }
    notifyListeners();
  }

  Future<void> setThemeColorIndex(int index) async {
    _themeColorIndex = index;
    await _storage.write(key: _kThemeColorIndex, value: index.toString());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.write(key: _kThemeMode, value: value);
    notifyListeners();
  }

  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    if (!isBiometricPlatform) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Check if running on a mobile platform (biometric hardware may exist).
  /// Returns false on desktop.
  bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;

  /// Check if the device has any enrolled biometrics (fingerprint, face, etc.).
  Future<bool> hasEnrolledBiometrics() async {
    if (!isBiometricPlatform) return false;
    try {
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _storage.write(key: _kBiometricEnabled, value: enabled.toString());
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to unlock Hyphen Wallet',
  }) async {
    if (!_biometricEnabled) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Verify a password against the active wallet's encrypted data.
  /// Returns true if the password successfully decrypts the wallet.
  Future<bool> verifyPassword(String password) async {
    final activeId = _state.activeWalletId;
    if (activeId == null) return false;
    final walletInfo = _state.wallets.firstWhere(
      (w) => w.id == activeId,
      orElse: () => throw Exception('Active wallet not found'),
    );
    try {
      final encrypted = Uint8List.fromList(
        base64Decode(walletInfo.encryptedData),
      );
      await rust.decryptWallet(encryptedData: encrypted, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the current platform supports biometric authentication.
  bool get isBiometricPlatform => Platform.isAndroid || Platform.isIOS;

  Future<String> createWallet(String password, {String? name}) async {
    final pqPassphrase = await rust.pqTransformPassword(password: password);
    final result = await rust.restoreWallet(
      mnemonic: (await rust.generateMnemonic(wordCount: 24)),
      passphrase: pqPassphrase,
    );
    final walletName = name ?? 'Wallet ${_state.wallets.length + 1}';
    final walletId = DateTime.now().millisecondsSinceEpoch.toString();
    await _persistNewWallet(walletId, walletName, result.mnemonic, password);
    final wallets = await _loadWalletList();
    _state = _state.copyWith(
      isUnlocked: true,
      mnemonic: result.mnemonic,
      seedHex: result.seedHex,
      address: _state.network == HyphenNetwork.mainnet
          ? result.addressMainnet
          : result.addressTestnet,
      viewPublicHex: result.viewPublicHex,
      spendPublicHex: result.spendPublicHex,
      activeWalletId: walletId,
      wallets: wallets,
    );
    await _refreshMinedRewards();
    notifyListeners();
    return result.mnemonic;
  }

  Future<void> restoreWallet(
    String mnemonic,
    String password, {
    String? name,
  }) async {
    final pqPassphrase = await rust.pqTransformPassword(password: password);
    final result = await rust.restoreWallet(
      mnemonic: mnemonic,
      passphrase: pqPassphrase,
    );
    final walletName = name ?? 'Wallet ${_state.wallets.length + 1}';
    final walletId = DateTime.now().millisecondsSinceEpoch.toString();
    await _persistNewWallet(walletId, walletName, result.mnemonic, password);
    final wallets = await _loadWalletList();
    _state = _state.copyWith(
      isUnlocked: true,
      mnemonic: result.mnemonic,
      seedHex: result.seedHex,
      address: _state.network == HyphenNetwork.mainnet
          ? result.addressMainnet
          : result.addressTestnet,
      viewPublicHex: result.viewPublicHex,
      spendPublicHex: result.spendPublicHex,
      activeWalletId: walletId,
      wallets: wallets,
    );
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<void> unlock(String password) async {
    final activeId = _state.activeWalletId;
    if (activeId == null) throw Exception('No active wallet');
    final walletInfo = _state.wallets.firstWhere(
      (w) => w.id == activeId,
      orElse: () => throw Exception('Active wallet not found'),
    );
    final encrypted = Uint8List.fromList(
      base64Decode(walletInfo.encryptedData),
    );
    final mnemonic = await rust.decryptWallet(
      encryptedData: encrypted,
      password: password,
    );
    final pqPassphrase = await rust.pqTransformPassword(password: password);
    final result = await rust.restoreWallet(
      mnemonic: mnemonic,
      passphrase: pqPassphrase,
    );
    // Cache password for biometric unlock if enabled.
    if (_biometricEnabled) {
      await _storage.write(key: _kBiometricPassword, value: password);
    }
    _state = _state.copyWith(
      isUnlocked: true,
      mnemonic: result.mnemonic,
      seedHex: result.seedHex,
      address: _state.network == HyphenNetwork.mainnet
          ? result.addressMainnet
          : result.addressTestnet,
      viewPublicHex: result.viewPublicHex,
      spendPublicHex: result.spendPublicHex,
    );
    _startMinedRewardsPolling();
    await _refreshMinedRewards();
    await loadTransferHistory();
    notifyListeners();
  }

  /// Attempts biometric unlock.  Returns true on success.
  Future<bool> unlockWithBiometrics({
    String reason = 'Authenticate to unlock Hyphen Wallet',
  }) async {
    if (!_biometricEnabled) return false;
    final authenticated = await authenticateWithBiometrics(reason: reason);
    if (!authenticated) return false;
    final password = await _storage.read(key: _kBiometricPassword);
    if (password == null || password.isEmpty) return false;
    await unlock(password);
    return true;
  }

  void lock() {
    _stopMinedRewardsPolling();
    _state = WalletState(
      isUnlocked: false,
      network: _state.network,
      activeWalletId: _state.activeWalletId,
      wallets: _state.wallets,
      nodeMode: _state.nodeMode,
      rpcEndpoint: _state.rpcEndpoint,
      poolApiEndpoint: _state.poolApiEndpoint,
      explorerApiEndpoint: _state.explorerApiEndpoint,
    );
    notifyListeners();
  }

  Future<void> switchWallet(String walletId) async {
    await _storage.write(key: _kActiveWalletId, value: walletId);
    _state = WalletState(
      isUnlocked: false,
      network: _state.network,
      activeWalletId: walletId,
      wallets: _state.wallets,
      nodeMode: _state.nodeMode,
      rpcEndpoint: _state.rpcEndpoint,
      poolApiEndpoint: _state.poolApiEndpoint,
      explorerApiEndpoint: _state.explorerApiEndpoint,
    );
    notifyListeners();
  }

  Future<void> renameWallet(String walletId, String newName) async {
    final wallets = List<WalletInfo>.from(_state.wallets);
    final idx = wallets.indexWhere((w) => w.id == walletId);
    if (idx == -1) return;
    wallets[idx].name = newName;
    await _saveWalletList(wallets);
    _state = _state.copyWith(wallets: wallets);
    notifyListeners();
  }

  Future<void> deleteWalletById(String walletId) async {
    final wallets = List<WalletInfo>.from(_state.wallets);
    wallets.removeWhere((w) => w.id == walletId);
    await _saveWalletList(wallets);
    if (_state.activeWalletId == walletId) {
      final newActiveId = wallets.isNotEmpty ? wallets.first.id : null;
      if (newActiveId != null) {
        await _storage.write(key: _kActiveWalletId, value: newActiveId);
      } else {
        await _storage.delete(key: _kActiveWalletId);
      }
      _state = WalletState(
        isUnlocked: false,
        network: _state.network,
        activeWalletId: newActiveId,
        wallets: wallets,
        nodeMode: _state.nodeMode,
        rpcEndpoint: _state.rpcEndpoint,
        poolApiEndpoint: _state.poolApiEndpoint,
        explorerApiEndpoint: _state.explorerApiEndpoint,
      );
    } else {
      _state = _state.copyWith(wallets: wallets);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopMinedRewardsPolling();
    super.dispose();
  }

  Future<void> deleteWallet() async {
    if (_state.activeWalletId != null) {
      await deleteWalletById(_state.activeWalletId!);
    }
  }

  Future<String> deriveAddress(int account, int index) async {
    if (_state.seedHex == null) throw Exception('Wallet not unlocked');
    final info = await rust.deriveKey(
      seedHex: _state.seedHex!,
      account: account,
      change: 0,
      index: index,
      isMainnet: _state.network == HyphenNetwork.mainnet,
    );
    return info.address;
  }

  Future<String> derivationPath(int account, int change, int index) async {
    return rust.getDerivationPath(
      account: account,
      change: change,
      index: index,
    );
  }

  Future<rust.SignResult> signMessage(Uint8List message) async {
    if (_state.seedHex == null) throw Exception('Wallet not unlocked');
    return rust.signMessage(
      seedHex: _state.seedHex!,
      account: 0,
      change: 0,
      index: 0,
      message: message,
    );
  }

  Future<bool> validateAddress(String address) async {
    return rust.validateAddress(address: address);
  }

  /// Get the RPC host and port from the current endpoint.
  (String, int) get _rpcHostPort {
    final parsed = _parseEndpoint(
      _state.rpcEndpoint,
      _state.network == HyphenNetwork.mainnet ? 18333 : 38333,
    );
    return parsed ?? ('127.0.0.1', 38333);
  }

  /// Scan the blockchain for wallet-owned outputs and update balance.
  Future<void> scanWalletOutputs() async {
    if (!_state.isUnlocked || _state.seedHex == null) {
      throw Exception('Wallet not unlocked');
    }

    final (host, port) = _rpcHostPort;

    // Get chain height
    final status = await rust.getChainStatus(host: host, port: port);

    // Load last scanned height
    final lastScannedStr = await _storage.read(
      key: '${_kLastScannedHeight}_${_state.activeWalletId}',
    );
    final startHeight = lastScannedStr != null
        ? (int.tryParse(lastScannedStr) ?? 0) + 1
        : 0;

    if (startHeight > status.height.toInt()) {
      // Already up to date - just load existing outputs
      await _loadCachedOutputs();
      notifyListeners();
      return;
    }

    // Scan for new outputs
    final result = await rust.scanWalletOutputs(
      host: host,
      port: port,
      seedHex: _state.seedHex!,
      account: 0,
      startHeight: BigInt.from(startHeight),
      endHeight: status.height,
      isMainnet: _state.network == HyphenNetwork.mainnet,
    );

    // Merge with existing cached outputs
    final existingJson = await _storage.read(
      key: '${_kOwnedOutputs}_${_state.activeWalletId}',
    );
    String mergedJson;
    if (existingJson != null &&
        existingJson.isNotEmpty &&
        existingJson != '[]') {
      // Merge arrays
      final existing = existingJson.substring(
        0,
        existingJson.length - 1,
      ); // remove ]
      final newOutputs = result.outputsJson.substring(1); // remove [
      if (result.outputCount > BigInt.zero) {
        mergedJson = '$existing,$newOutputs';
      } else {
        mergedJson = existingJson;
      }
    } else {
      mergedJson = result.outputsJson;
    }

    // Save updated outputs and scanned height
    await _storage.write(
      key: '${_kOwnedOutputs}_${_state.activeWalletId}',
      value: mergedJson,
    );
    await _storage.write(
      key: '${_kLastScannedHeight}_${_state.activeWalletId}',
      value: result.scannedHeight.toString(),
    );

    _updateOnChainBalance(mergedJson);
    notifyListeners();
  }

  /// Load cached outputs from storage and update balance.
  Future<void> _loadCachedOutputs() async {
    final json = await _storage.read(
      key: '${_kOwnedOutputs}_${_state.activeWalletId}',
    );
    _updateOnChainBalance(json);
  }

  void _updateOnChainBalance(String? json) {
    if (json == null || json.isEmpty || json == '[]') {
      _state = _state.copyWith(onChainBalanceAtomic: '0');
      return;
    }
    try {
      final list = jsonDecode(json) as List;
      var total = BigInt.zero;
      for (final item in list) {
        total += BigInt.from(item['value'] as int? ?? 0);
      }
      _state = _state.copyWith(onChainBalanceAtomic: total.toString());
    } catch (_) {
      _state = _state.copyWith(onChainBalanceAtomic: '0');
    }
  }

  /// Get the current spendable balance by reading cached outputs.
  Future<BigInt> getSpendableBalance() async {
    if (!_state.isUnlocked || _state.activeWalletId == null) {
      return BigInt.zero;
    }
    final json = await _storage.read(
      key: '${_kOwnedOutputs}_${_state.activeWalletId}',
    );
    if (json == null || json.isEmpty || json == '[]') return BigInt.zero;

    // Parse the outputs and sum values
    try {
      final list = jsonDecode(json) as List;
      var total = BigInt.zero;
      for (final item in list) {
        final value = item['value'] as int? ?? 0;
        total += BigInt.from(value);
      }
      return total;
    } catch (_) {
      return BigInt.zero;
    }
  }

  /// Get cached owned outputs JSON for transaction building.
  Future<String> getOwnedOutputsJson() async {
    if (!_state.isUnlocked || _state.activeWalletId == null) {
      return '[]';
    }
    final json = await _storage.read(
      key: '${_kOwnedOutputs}_${_state.activeWalletId}',
    );
    return json ?? '[]';
  }

  /// Send a shielded transaction.
  ///
  /// [recipientAddress] must be a valid hy1... address.
  /// [amountAtomic] is the amount in atomic units (1 HYP = 1e12 atomic).
  /// [feeAtomic] is the transaction fee in atomic units.
  /// The consensus-mandated ring size for the current network.
  int get networkRingSize => _state.network == HyphenNetwork.mainnet ? 16 : 4;

  Future<rust.TransactionSendResult> sendTransaction({
    required String recipientAddress,
    required BigInt amountAtomic,
    required BigInt feeAtomic,
    int? ringSize,
  }) async {
    ringSize ??= networkRingSize;
    if (!_state.isUnlocked || _state.seedHex == null) {
      throw Exception('Wallet not unlocked');
    }

    final (host, port) = _rpcHostPort;
    final outputsJson = await getOwnedOutputsJson();

    final result = await rust.sendTransaction(
      host: host,
      port: port,
      seedHex: _state.seedHex!,
      account: 0,
      recipientAddress: recipientAddress,
      amount: amountAtomic,
      fee: feeAtomic,
      ownedOutputsJson: outputsJson,
      ringSize: ringSize,
    );

    if (result.accepted && result.spentIndicesCsv.isNotEmpty) {
      await removeSpentOutputs(result.spentIndicesCsv);
    }

    return result;
  }

  Future<void> removeSpentOutputs(String spentIndicesCsv) async {
    if (spentIndicesCsv.isEmpty || _state.activeWalletId == null) return;
    final spentSet = spentIndicesCsv
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => int.parse(s.trim()))
        .toSet();
    if (spentSet.isEmpty) return;

    final json = await _storage.read(
      key: '${_kOwnedOutputs}_${_state.activeWalletId}',
    );
    if (json == null || json.isEmpty || json == '[]') return;

    try {
      final list = jsonDecode(json) as List;
      final filtered = list
          .where((item) => !spentSet.contains(item['global_index'] as int?))
          .toList();
      await _storage.write(
        key: '${_kOwnedOutputs}_${_state.activeWalletId}',
        value: jsonEncode(filtered),
      );
    } catch (_) {}
  }

  /// Record a sent transfer in the persistent transfer history.
  Future<void> recordSentTransfer({
    required String txHashHex,
    required String recipientAddress,
    required BigInt amountAtomic,
    required BigInt feeAtomic,
  }) async {
    final activity = TransferActivity(
      direction: TransferDirection.sent,
      txHashHex: txHashHex,
      recipientAddress: recipientAddress,
      amountAtomic: amountAtomic.toString(),
      feeAtomic: feeAtomic.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final history = List<TransferActivity>.from(_state.transferActivities)
      ..insert(0, activity);
    _state = _state.copyWith(transferActivities: history);
    await _persistTransferHistory();
    notifyListeners();
  }

  /// Load transfer history from secure storage.
  Future<void> loadTransferHistory() async {
    final walletId = _state.activeWalletId;
    if (walletId == null) return;
    final raw = await _storage.read(key: '${_kTransferHistory}_$walletId');
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => TransferActivity.fromJson(e as Map<String, dynamic>))
          .toList();
      _state = _state.copyWith(transferActivities: list);
      notifyListeners();
    } catch (_) {
      // Corrupt data — reset
    }
  }

  /// Persist the current transfer history to secure storage.
  Future<void> _persistTransferHistory() async {
    final walletId = _state.activeWalletId;
    if (walletId == null) return;
    final encoded = jsonEncode(
      _state.transferActivities.map((e) => e.toJson()).toList(),
    );
    await _storage.write(key: '${_kTransferHistory}_$walletId', value: encoded);
  }

  Future<void> setNodeMode(NodeMode mode) async {
    await _storage.write(
      key: _kNodeMode,
      value: mode == NodeMode.full ? 'full' : 'light',
    );
    _state = _state.copyWith(nodeMode: mode);
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<void> setCustomRpcEndpoint(String endpoint) async {
    await _storage.write(key: _kCustomRpcEndpoint, value: endpoint);
    _state = _state.copyWith(rpcEndpoint: endpoint);
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<void> setPoolApiEndpoint(String endpoint) async {
    final normalized = endpoint.trim();
    if (normalized.isEmpty) {
      await _storage.delete(key: _kPoolApiEndpoint);
    } else {
      await _storage.write(key: _kPoolApiEndpoint, value: normalized);
    }
    _state = _state.copyWith(poolApiEndpoint: normalized);
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<void> setExplorerApiEndpoint(String endpoint) async {
    final normalized = endpoint.trim();
    if (normalized.isEmpty) {
      await _storage.delete(key: _kExplorerApiEndpoint);
    } else {
      await _storage.write(key: _kExplorerApiEndpoint, value: normalized);
    }
    _state = _state.copyWith(explorerApiEndpoint: normalized);
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<void> switchNetwork(HyphenNetwork network) async {
    await _storage.write(
      key: _kCurrentNetwork,
      value: network == HyphenNetwork.mainnet ? 'mainnet' : 'testnet',
    );
    if (_state.isUnlocked && _state.seedHex != null) {
      final info = await rust.deriveKey(
        seedHex: _state.seedHex!,
        account: 0,
        change: 0,
        index: 0,
        isMainnet: network == HyphenNetwork.mainnet,
      );
      _state = _state.copyWith(
        network: network,
        address: info.address,
        spendPublicHex: info.spendPublicHex,
        viewPublicHex: info.viewPublicHex,
      );
    } else {
      _state = _state.copyWith(network: network);
    }
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<void> refreshMinedRewards() async {
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<String> version() async {
    return rust.walletVersion();
  }

  Future<List<WalletInfo>> _loadWalletList() async {
    final raw = await _storage.read(key: _kWalletList);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => WalletInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveWalletList(List<WalletInfo> wallets) async {
    final json = jsonEncode(wallets.map((w) => w.toJson()).toList());
    await _storage.write(key: _kWalletList, value: json);
  }

  Future<void> _persistNewWallet(
    String walletId,
    String name,
    String mnemonic,
    String password,
  ) async {
    final encrypted = await rust.encryptWallet(
      mnemonic: mnemonic,
      password: password,
    );
    final encBase64 = base64Encode(encrypted);
    final wallets = await _loadWalletList();
    wallets.add(WalletInfo(id: walletId, name: name, encryptedData: encBase64));
    await _saveWalletList(wallets);
    await _storage.write(key: _kActiveWalletId, value: walletId);
  }

  Future<void> _refreshMinedRewards() async {
    final spendPubkey = _state.spendPublicHex;
    if (!_state.isUnlocked || spendPubkey == null || spendPubkey.length != 64) {
      _state = _state.copyWith(
        minedRewardsAtomic: '0',
        directPoolRewardsAtomic: '0',
        minedBlocksFound: 0,
        latestMinedHeight: null,
        pendingPoolRewardsAtomic: '0',
        poolPayoutMode: '',
        poolWalletHex: '',
        poolCoinbaseRewardsAtomic: '0',
        poolFeeBps: null,
        poolActiveMiners: 0,
        isPoolWallet: false,
        directCoinbaseMode: false,
        rewardActivities: const [],
      );
      return;
    }

    var pendingPoolRewardsAtomic = '0';
    var directPoolRewardsAtomic = '0';
    var poolPayoutMode = '';
    var poolWalletHex = '';
    var poolCoinbaseRewardsAtomic = '0';
    int? poolFeeBps;
    var poolActiveMiners = 0;
    var isPoolWallet = false;
    var directCoinbaseMode = false;
    final activities = <RewardActivity>[];

    for (final uri in _buildPoolBalanceUris(spendPubkey)) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != 200) {
          continue;
        }

        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;

        pendingPoolRewardsAtomic =
            (json['pending_payout_atomic'] as String?) ?? '0';
        directPoolRewardsAtomic =
            (json['direct_reward_atomic'] as String?) ?? '0';
        poolPayoutMode = (json['mode'] as String?) ?? '';
        poolWalletHex = ((json['pool_wallet'] as String?) ?? '').toLowerCase();
        poolFeeBps = (json['pool_fee_bps'] as num?)?.toInt();
        poolActiveMiners = (json['active_miners'] as num?)?.toInt() ?? 0;
        isPoolWallet = (json['is_pool_wallet'] as bool?) ?? false;
        directCoinbaseMode = (json['direct_coinbase_mode'] as bool?) ?? false;
        final rewardEvents =
            (json['recent_reward_events'] as List<dynamic>? ?? const []);
        for (final rawEvent in rewardEvents) {
          final event = rawEvent as Map<String, dynamic>;
          activities.add(
            RewardActivity(
              source: 'pool',
              height: (event['height'] as num?)?.toInt() ?? 0,
              blockHashHex: (event['block_hash_hex'] as String?) ?? '',
              amountAtomic: (event['amount_atomic'] as String?) ?? '0',
              rewardAtomic: (event['amount_atomic'] as String?) ?? '0',
              feeAtomic: '0',
              timestamp: (event['timestamp'] as num?)?.toInt() ?? 0,
              mode: (event['mode'] as String?) ?? poolPayoutMode,
              kind: (event['kind'] as String?) ?? '',
              walletAddressHex: ((event['wallet_address'] as String?) ?? '')
                  .toLowerCase(),
              rewardRecipientHex: ((event['reward_recipient'] as String?) ?? '')
                  .toLowerCase(),
              finderPubkeyHex: ((event['finder_pubkey'] as String?) ?? '')
                  .toLowerCase(),
              directCoinbase:
                  (event['direct_coinbase'] as bool?) ?? directCoinbaseMode,
            ),
          );
        }
        break;
      } catch (_) {
        // Try the next candidate URI.
      } finally {
        client.close(force: true);
      }
    }

    var minedRewardsAtomic = '0';
    var minedBlocksFound = 0;
    int? latestMinedHeight;
    final onChainBelongsToPoolWallet =
        isPoolWallet &&
        !directCoinbaseMode &&
        poolWalletHex == spendPubkey.toLowerCase();

    for (final uri in _buildExplorerRewardsUris(spendPubkey)) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != 200) {
          continue;
        }

        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;

        final totalRewardAtomic =
            (json['total_reward_atomic'] as String?) ?? '0';
        minedRewardsAtomic = onChainBelongsToPoolWallet
            ? '0'
            : totalRewardAtomic;
        poolCoinbaseRewardsAtomic = onChainBelongsToPoolWallet
            ? totalRewardAtomic
            : '0';
        minedBlocksFound = (json['blocks_found'] as num?)?.toInt() ?? 0;
        latestMinedHeight = (json['latest_height'] as num?)?.toInt();
        break;
      } catch (_) {
        // Try the next candidate URI.
      } finally {
        client.close(force: true);
      }
    }

    for (final uri in _buildExplorerBlockUris(spendPubkey)) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != 200) {
          continue;
        }

        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final blocks = (json['blocks'] as List<dynamic>? ?? const []);
        for (final rawBlock in blocks) {
          final block = rawBlock as Map<String, dynamic>;
          final rewardAtomic = (block['reward_atomic'] as num?)?.toInt() ?? 0;
          final feeAtomic = (block['total_fee_atomic'] as num?)?.toInt() ?? 0;
          final rewardRecipientHex = onChainBelongsToPoolWallet
              ? poolWalletHex.toLowerCase()
              : spendPubkey.toLowerCase();
          activities.add(
            RewardActivity(
              source: onChainBelongsToPoolWallet ? 'pool_coinbase' : 'on_chain',
              height: (block['height'] as num?)?.toInt() ?? 0,
              blockHashHex: (block['hash'] as String?) ?? '',
              amountAtomic: (BigInt.from(rewardAtomic) + BigInt.from(feeAtomic))
                  .toString(),
              rewardAtomic: rewardAtomic.toString(),
              feeAtomic: feeAtomic.toString(),
              timestamp: (block['timestamp'] as num?)?.toInt() ?? 0,
              mode: poolPayoutMode,
              kind: onChainBelongsToPoolWallet
                  ? 'pool_coinbase'
                  : 'direct_coinbase',
              walletAddressHex: spendPubkey.toLowerCase(),
              rewardRecipientHex: rewardRecipientHex,
              finderPubkeyHex: ((block['miner_pubkey'] as String?) ?? '')
                  .toLowerCase(),
              directCoinbase: !onChainBelongsToPoolWallet,
            ),
          );
        }
        break;
      } catch (_) {
        // Try the next candidate URI.
      } finally {
        client.close(force: true);
      }
    }

    activities.sort((left, right) {
      final byHeight = right.height.compareTo(left.height);
      if (byHeight != 0) {
        return byHeight;
      }
      return right.timestamp.compareTo(left.timestamp);
    });

    final dedupedActivities = <RewardActivity>[];
    final seen = <String>{};
    for (final activity in activities) {
      final key =
          '${activity.source}:${activity.height}:${activity.blockHashHex}:${activity.amountAtomic}:${activity.kind}';
      if (seen.add(key)) {
        dedupedActivities.add(activity);
      }
      if (dedupedActivities.length >= 128) {
        break;
      }
    }

    final explorerConfirmed =
        BigInt.tryParse(minedRewardsAtomic) ?? BigInt.zero;
    final poolDirectConfirmed =
        BigInt.tryParse(directPoolRewardsAtomic) ?? BigInt.zero;
    final unifiedConfirmed = explorerConfirmed > poolDirectConfirmed
        ? explorerConfirmed
        : poolDirectConfirmed;

    _state = _state.copyWith(
      minedRewardsAtomic: unifiedConfirmed.toString(),
      directPoolRewardsAtomic: directPoolRewardsAtomic,
      minedBlocksFound: minedBlocksFound,
      latestMinedHeight: latestMinedHeight,
      pendingPoolRewardsAtomic: pendingPoolRewardsAtomic,
      poolPayoutMode: poolPayoutMode,
      poolWalletHex: poolWalletHex,
      poolCoinbaseRewardsAtomic: poolCoinbaseRewardsAtomic,
      poolFeeBps: poolFeeBps,
      poolActiveMiners: poolActiveMiners,
      isPoolWallet: isPoolWallet,
      directCoinbaseMode: directCoinbaseMode,
      rewardActivities: dedupedActivities,
    );
  }

  List<Uri> _buildExplorerRewardsUris(String spendPubkey) {
    final explicit = _state.explorerApiEndpoint.trim();
    final uris = <Uri>[];
    final seen = <String>{};

    void addEndpoint(String raw, int defaultPort) {
      final parsed = _parseEndpoint(raw, defaultPort);
      if (parsed == null) {
        return;
      }
      final key = '${parsed.$1}:${parsed.$2}';
      if (!seen.add(key)) {
        return;
      }
      uris.add(
        Uri(
          scheme: 'http',
          host: parsed.$1,
          port: parsed.$2,
          path: '/api/miner/$spendPubkey/rewards',
        ),
      );
    }

    if (explicit.isNotEmpty) {
      addEndpoint(explicit, 8080);
      return uris;
    }

    final derived = _deriveExplorerApiEndpoint(_state.rpcEndpoint);
    if (derived.isNotEmpty) {
      addEndpoint(derived, 8080);
    }

    if (_state.nodeMode == NodeMode.full) {
      addEndpoint('127.0.0.1:8080', 8080);
      addEndpoint('localhost:8080', 8080);
    }

    return uris;
  }

  List<Uri> _buildExplorerBlockUris(String spendPubkey) {
    return _buildExplorerRewardsUris(spendPubkey)
        .map(
          (uri) => uri.replace(
            path: '/api/miner/$spendPubkey/blocks',
            queryParameters: {'limit': '64'},
          ),
        )
        .toList(growable: false);
  }

  List<Uri> _buildPoolBalanceUris(String spendPubkey) {
    final explicit = _state.poolApiEndpoint.trim();
    final uris = <Uri>[];
    final seen = <String>{};

    void addEndpoint(String raw, int defaultPort) {
      final parsed = _parseEndpoint(raw, defaultPort);
      if (parsed == null) {
        return;
      }
      final key = '${parsed.$1}:${parsed.$2}';
      if (!seen.add(key)) {
        return;
      }
      uris.add(
        Uri(
          scheme: 'http',
          host: parsed.$1,
          port: parsed.$2,
          path: '/api/pool/wallet/$spendPubkey/balance',
          queryParameters: {'limit': '64'},
        ),
      );
    }

    if (explicit.isNotEmpty) {
      addEndpoint(explicit, 8081);
      return uris;
    }

    final derived = _derivePoolApiEndpoint(_state.rpcEndpoint);
    if (derived.isNotEmpty) {
      addEndpoint(derived, 8081);
    }

    if (_state.nodeMode == NodeMode.full) {
      addEndpoint('127.0.0.1:8081', 8081);
      addEndpoint('localhost:8081', 8081);
    }

    return uris;
  }

  void _startMinedRewardsPolling() {
    _minedRewardsTimer?.cancel();
    _minedRewardsTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _refreshMinedRewards();
      notifyListeners();
    });
  }

  void _stopMinedRewardsPolling() {
    _minedRewardsTimer?.cancel();
    _minedRewardsTimer = null;
  }
}
