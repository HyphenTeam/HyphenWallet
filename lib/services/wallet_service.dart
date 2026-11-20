import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
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
const _kOwnedOutputs = 'owned_outputs_v2';
const _kOutputCacheMigrated = 'output_cache_v2_migrated';
const _kTransferHistory = 'transfer_history';

/// RPC ports per profile. The non-mainnet node this wallet points at is the
/// devnet profile, which listens on 48333; nothing serves testnet's 38333.
const kDefaultRpcPort = 48333;
const kDefaultMainnetRpcPort = 18333;

const kDefaultRpcEndpoint = 'bytesnap.tech:48333';
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
  final parsed = _parseEndpoint(rpcEndpoint, kDefaultRpcPort);
  if (parsed == null) {
    return '';
  }
  return '${parsed.$1}:8081';
}

String _deriveExplorerApiEndpoint(String rpcEndpoint) {
  final parsed = _parseEndpoint(rpcEndpoint, kDefaultRpcPort);
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

  /// Why the last refresh could not read the chain, empty when it succeeded.
  final String syncError;

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
    this.syncError = '',
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
    String? syncError,
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
      syncError: syncError ?? this.syncError,
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

class _SerialOperations {
  Future<void> _pending = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class WalletService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false, migrateWithBackup: true),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  WalletState _state = const WalletState();
  WalletState get state => _state;
  final _outputs = _SerialOperations();
  final _credentials = _SerialOperations();
  int _unlockGeneration = 0;
  (int, String)? get paymentSession {
    final key = _outputKey;
    return key == null ? null : (_unlockGeneration, key);
  }

  bool _initialized = false;
  bool get initialized => _initialized;

  Locale? _locale;
  Locale? get locale => _locale;
  Timer? _minedRewardsTimer;
  Timer? _paymentTimer;
  (int, String, String)? _scannedTip;
  BigInt? get scannedBalance {
    final tip = _scannedTip;
    if (tip == null ||
        paymentSession != (tip.$1, tip.$2) ||
        _state.syncError.isNotEmpty) {
      return null;
    }
    return BigInt.parse(_state.onChainBalanceAtomic);
  }

  ({String hash, BigInt amount, BigInt confirmations})? _lastReceipt;
  ({String hash, BigInt amount, BigInt confirmations})? get lastReceipt =>
      scannedBalance == null ? null : _lastReceipt;
  int _themeColorIndex = 0;
  int get themeColorIndex => _themeColorIndex;
  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    await RustLib.init();
    await _storage.delete(key: _kBiometricPassword);
    await migrateOutputCache();
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

  @visibleForTesting
  Future<void> migrateOutputCache() async {
    if (await _storage.read(key: _kOutputCacheMigrated) == 'true') return;
    for (final key in (await _storage.readAll()).keys.toList(growable: false)) {
      if (key == 'owned_outputs' ||
          (key.startsWith('owned_outputs_') &&
              !key.startsWith('${_kOwnedOutputs}_'))) {
        await _storage.delete(key: key);
      }
    }
    await _storage.write(key: _kOutputCacheMigrated, value: 'true');
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
    _unlockGeneration++;
    _biometricEnabled = enabled;
    await _credentials.run(() async {
      if (!enabled) {
        final keys = (await _storage.readAll()).keys
            .where(
              (key) =>
                  key == _kBiometricPassword ||
                  key.startsWith('${_kBiometricPassword}_'),
            )
            .toList(growable: false);
        for (final key in keys) {
          await _storage.delete(key: key);
        }
      }
      await _storage.write(key: _kBiometricEnabled, value: enabled.toString());
    });
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to unlock Hyphen Wallet',
  }) async {
    if (!_biometricEnabled) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  /// Verify a password against the active wallet's encrypted data.
  /// Returns true if the password successfully decrypts the wallet.
  Future<bool> verifyPassword(String password) async {
    final generation = _unlockGeneration;
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
      return generation == _unlockGeneration &&
          activeId == _state.activeWalletId;
    } catch (_) {
      return false;
    }
  }

  /// Whether the current platform supports biometric authentication.
  bool get isBiometricPlatform => Platform.isAndroid || Platform.isIOS;

  Future<String> createWallet(String password, {String? name}) async {
    final generation = _unlockGeneration;
    final mnemonic = await rust.generateMnemonic(wordCount: 24);
    if (generation != _unlockGeneration) {
      throw StateError('Wallet selection changed');
    }
    await restoreWallet(mnemonic, password, name: name);
    return mnemonic;
  }

  Future<void> restoreWallet(
    String mnemonic,
    String password, {
    String? name,
  }) async {
    final generation = ++_unlockGeneration;
    final pqPassphrase = await rust.pqTransformPassword(password: password);
    final result = await rust.restoreWallet(
      mnemonic: mnemonic,
      passphrase: pqPassphrase,
    );
    final walletName = name ?? 'Wallet ${_state.wallets.length + 1}';
    final walletId = DateTime.now().microsecondsSinceEpoch.toString();
    await _credentials.run(() async {
      if (generation != _unlockGeneration) {
        throw StateError('Wallet selection changed');
      }
      await _persistNewWallet(walletId, walletName, result.mnemonic, password);
    });
    final wallets = await _loadWalletList();
    if (generation != _unlockGeneration) {
      _state = _state.copyWith(wallets: wallets);
      notifyListeners();
      throw StateError('Wallet selection changed');
    }
    _state = WalletState(
      network: _state.network,
      nodeMode: _state.nodeMode,
      rpcEndpoint: _state.rpcEndpoint,
      poolApiEndpoint: _state.poolApiEndpoint,
      explorerApiEndpoint: _state.explorerApiEndpoint,
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
    _startMinedRewardsPolling();
    await _refreshMinedRewards();
    notifyListeners();
  }

  Future<void> unlock(String password) async {
    final generation = _unlockGeneration;
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
    bool current() =>
        generation == _unlockGeneration && activeId == _state.activeWalletId;
    await _credentials.run(() async {
      if (current() && _biometricEnabled) {
        await _storage.write(
          key: '${_kBiometricPassword}_$activeId',
          value: password,
        );
      }
    });
    if (!current()) {
      throw StateError('Wallet unlock was cancelled');
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
    await refreshAll();
    await loadTransferHistory();
    if (!current()) throw StateError('Wallet unlock was cancelled');
    notifyListeners();
  }

  /// Attempts biometric unlock.  Returns true on success.
  Future<bool> unlockWithBiometrics({
    String reason = 'Authenticate to unlock Hyphen Wallet',
  }) async {
    final activeId = _state.activeWalletId;
    final generation = _unlockGeneration;
    if (!_biometricEnabled || activeId == null) return false;
    final authenticated = await authenticateWithBiometrics(reason: reason);
    if (!authenticated) return false;
    final password = await _storage.read(
      key: '${_kBiometricPassword}_$activeId',
    );
    if (!_biometricEnabled ||
        activeId != _state.activeWalletId ||
        generation != _unlockGeneration ||
        password == null ||
        password.isEmpty) {
      return false;
    }
    await unlock(password);
    return true;
  }

  void lock() {
    _unlockGeneration++;
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
    _unlockGeneration++;
    _stopMinedRewardsPolling();
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
    await _credentials.run(
      () => _storage.write(key: _kActiveWalletId, value: walletId),
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
    if (_state.activeWalletId == walletId) lock();
    await _credentials.run(
      () => _storage.delete(key: '${_kBiometricPassword}_$walletId'),
    );
    await _outputs.run(() async {
      await _storage.delete(key: '${_kTransferHistory}_$walletId');
      for (final key in (await _storage.readAll()).keys.toList(
        growable: false,
      )) {
        if (key.startsWith('${_kOwnedOutputs}_${walletId}_')) {
          await _storage.delete(key: key);
        }
      }
    });
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
    _unlockGeneration++;
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
      _state.network == HyphenNetwork.mainnet
          ? kDefaultMainnetRpcPort
          : kDefaultRpcPort,
    );
    return parsed ?? ('127.0.0.1', kDefaultRpcPort);
  }

  String? get _outputKey {
    if (!_state.isUnlocked || _state.activeWalletId == null) return null;
    final (host, port) = _rpcHostPort;
    final scope = jsonEncode([_state.network.name, host, port]);
    return '${_kOwnedOutputs}_${_state.activeWalletId}_${base64Url.encode(utf8.encode(scope))}';
  }

  /// Scan the chain for wallet-owned outputs and update the balance.
  ///
  /// Every scan walks from genesis to the tip and its result *replaces* the
  /// cached set. A partial scan cannot be exact over this RPC surface: the node
  /// exposes no key-image index, so any block range that omits the block where a
  /// cached output was spent keeps that output looking unspent, and the balance
  /// stays inflated after a spend, a restore on another device, or a chain
  /// reset. The full walk costs the same number of `get_block_by_height` calls —
  /// the partial path already re-reads every earlier block to rebuild the global
  /// output index — so exactness is free here.
  Future<void> scanWalletOutputs() async {
    final key = _outputKey;
    final seed = _state.seedHex;
    if (key == null || seed == null) {
      throw Exception('Wallet not unlocked');
    }

    final (host, port) = _rpcHostPort;
    final isMainnet = _state.network == HyphenNetwork.mainnet;
    final session = paymentSession;
    await _outputs.run(() async {
      if (session == null || paymentSession != session) return;
      try {
        final result = await rust.scanWalletOutputs(
          host: host,
          port: port,
          seedHex: seed,
          account: 0,
          startHeight: BigInt.zero,
          endHeight: (BigInt.one << 64) - BigInt.one,
          isMainnet: isMainnet,
          cacheDirectory: (await getTemporaryDirectory()).path,
        );
        if (paymentSession != session) return;
        await _storage.write(key: key, value: result.outputsJson);
        if (paymentSession != session) return;
        _lastReceipt = latestUnspentReceipt(
          result.outputsJson,
          result.scannedHeight,
        );
        _state = _state.copyWith(
          onChainBalanceAtomic: result.totalBalance.toString(),
          syncError: '',
        );
        _scannedTip = (session.$1, session.$2, result.scannedHashHex);
        notifyListeners();
      } catch (error) {
        if (paymentSession == session) {
          _scannedTip = null;
          _state = _state.copyWith(syncError: error.toString());
          notifyListeners();
        }
        rethrow;
      }
    });
  }

  /// Read the balance from the current session's successful scan.
  Future<BigInt> getSpendableBalance() async {
    if (!_state.isUnlocked || _state.activeWalletId == null) {
      return BigInt.zero;
    }
    return scannedBalance ??
        (throw StateError('Wallet balance requires a successful scan'));
  }

  /// Get cached owned outputs JSON for transaction building.
  Future<String> getOwnedOutputsJson() async {
    final key = _outputKey;
    if (key == null) return '[]';
    final json = await _storage.read(key: key);
    return _outputKey == key ? json ?? '[]' : '[]';
  }

  /// Send a shielded transaction.
  ///
  /// [recipientAddress] must be a valid hy1... address.
  /// [amountAtomic] is the amount in atomic units (1 HPN = 1e12 atomic).
  /// [feeAtomic] is the transaction fee in atomic units.
  /// The consensus-mandated ring size for the current network.
  int get networkRingSize => _state.network == HyphenNetwork.mainnet ? 16 : 4;

  Future<rust.TransactionSendResult> sendTransaction({
    required String recipientAddress,
    required BigInt amountAtomic,
    required BigInt feeAtomic,
    int? ringSize,
  }) async {
    final size = ringSize ?? networkRingSize;
    if (amountAtomic <= BigInt.zero ||
        feeAtomic < BigInt.zero ||
        (amountAtomic + feeAtomic).bitLength > 64) {
      throw ArgumentError('Invalid payment amount or fee');
    }
    final key = _outputKey;
    final seed = _state.seedHex;
    if (key == null || seed == null) {
      throw Exception('Wallet not unlocked');
    }

    final (host, port) = _rpcHostPort;
    final session = paymentSession;
    return _outputs.run(() async {
      if (paymentSession != session) {
        throw StateError('Wallet selection changed');
      }
      final outputsJson = await _storage.read(key: key) ?? '[]';
      if (paymentSession != session) {
        throw StateError('Wallet selection changed');
      }
      final result = await rust.sendTransaction(
        host: host,
        port: port,
        seedHex: seed,
        account: 0,
        recipientAddress: recipientAddress,
        amount: amountAtomic,
        fee: feeAtomic,
        ownedOutputsJson: outputsJson,
        ringSize: size,
      );

      if (result.accepted && result.spentIndicesCsv.isNotEmpty) {
        await _removeSpentOutputs(key, result.spentIndicesCsv);
      }

      return result;
    });
  }

  /// Drops the outputs consumed by a transaction the node accepted.
  ///
  /// The change output only becomes visible once the block is mined, so the
  /// balance is briefly understated instead of double counted; the next scan
  /// restores it.
  Future<void> removeSpentOutputs(String spentIndicesCsv) async {
    final key = _outputKey;
    if (key != null) {
      await _outputs.run(() => _removeSpentOutputs(key, spentIndicesCsv));
    }
  }

  Future<void> _removeSpentOutputs(String key, String spentIndicesCsv) async {
    if (spentIndicesCsv.isEmpty) return;
    final spent = <int>{};
    for (final raw in spentIndicesCsv.split(',')) {
      final index = int.tryParse(raw.trim());
      if (index != null) spent.add(index);
    }
    if (spent.isEmpty) return;

    final json = await _storage.read(key: key);
    if (json == null || json.isEmpty || json == '[]') return;

    final decoded = jsonDecode(json);
    if (decoded is! List) return;
    final remaining = [
      for (final item in decoded)
        if (item is Map<String, dynamic> &&
            !spent.contains(item['global_index']))
          item,
    ];
    final updated = jsonEncode(remaining);
    await _storage.write(key: key, value: updated);
    if (_outputKey != key) return;
    _scannedTip = null;
    notifyListeners();
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
    if (!_state.isUnlocked || walletId == null) return;
    final raw = await _storage.read(key: '${_kTransferHistory}_$walletId');
    if (!_state.isUnlocked ||
        walletId != _state.activeWalletId ||
        raw == null ||
        raw.isEmpty) {
      return;
    }
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
    _state = _state.copyWith(rpcEndpoint: endpoint, onChainBalanceAtomic: '0');
    _scannedTip = null;
    notifyListeners();
    await refreshAll();
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
        onChainBalanceAtomic: '0',
        address: info.address,
        spendPublicHex: info.spendPublicHex,
        viewPublicHex: info.viewPublicHex,
      );
    } else {
      _state = _state.copyWith(network: network, onChainBalanceAtomic: '0');
    }
    _scannedTip = null;
    notifyListeners();
    await refreshAll();
  }

  Future<void> refreshMinedRewards() async {
    await _refreshMinedRewards();
    notifyListeners();
  }

  /// Refresh both the scanned on-chain balance and the mining reward panels.
  ///
  /// Pull-to-refresh used to call [_refreshMinedRewards] alone, so a wallet
  /// that received coinbase outputs kept showing a zero balance until the send
  /// screen happened to trigger a scan.
  ///
  Future<void> refreshAll() async {
    final session = paymentSession;
    if (session != null) {
      try {
        await scanWalletOutputs();
      } catch (_) {
        // scanWalletOutputs already published the failure for this session.
      }
    }
    if (paymentSession != session) return;
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
    final session = paymentSession;
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

    if (paymentSession != session) return;
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

    if (!_state.isUnlocked || spendPubkey != _state.spendPublicHex) return;
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
    _paymentTimer?.cancel();
    var scanning = false;
    _paymentTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final session = paymentSession;
      if (session == null || scanning) return;
      scanning = true;
      try {
        final (host, port) = _rpcHostPort;
        final status = await rust.getChainStatus(host: host, port: port);
        if (!timer.isActive || paymentSession != session) return;
        final tip = (session.$1, session.$2, status.tipHashHex);
        if (tip != _scannedTip || _state.syncError.isNotEmpty) {
          if (_scannedTip != null) {
            _scannedTip = null;
            notifyListeners();
          }
          await scanWalletOutputs();
        }
      } catch (error) {
        if (timer.isActive &&
            paymentSession == session &&
            _state.syncError != error.toString()) {
          _state = _state.copyWith(syncError: error.toString());
          notifyListeners();
        }
      } finally {
        scanning = false;
      }
    });
    var refreshing = false;
    _minedRewardsTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (refreshing) return;
      refreshing = true;
      try {
        await _refreshMinedRewards();
        if (timer.isActive) notifyListeners();
      } finally {
        refreshing = false;
      }
    });
  }

  void _stopMinedRewardsPolling() {
    _paymentTimer?.cancel();
    _paymentTimer = null;
    _scannedTip = null;
    _lastReceipt = null;
    _minedRewardsTimer?.cancel();
    _minedRewardsTimer = null;
  }
}

({String hash, BigInt amount, BigInt confirmations})? latestUnspentReceipt(
  String outputs,
  BigInt height,
) {
  String? latestHash;
  var amount = BigInt.zero;
  var confirmations = BigInt.zero;
  for (final row in (jsonDecode(outputs) as List).reversed) {
    final hash = row['received_tx_hash'] as String?;
    if (hash == null) continue;
    latestHash ??= hash;
    if (hash != latestHash) break;
    amount += BigInt.parse(row['value'].toString());
    confirmations =
        height - BigInt.from(row['block_height'] as int) + BigInt.one;
  }
  return latestHash == null
      ? null
      : (hash: latestHash, amount: amount, confirmations: confirmations);
}
