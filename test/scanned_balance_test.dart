import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/l10n/app_localizations.dart';
import 'package:hyphen_wallet/screens/home_screen.dart';
import 'package:hyphen_wallet/services/wallet_service.dart';
import 'package:hyphen_wallet/src/rust/api/wallet.dart';
import 'package:hyphen_wallet/src/rust/frb_generated.dart';
import 'package:provider/provider.dart';

class _ScanApi extends Fake implements RustLibApi {
  bool offline = false;
  bool detached = false;

  @override
  Future<Uint8List> crateApiWalletEncryptWallet({
    required String mnemonic,
    required String password,
  }) async => Uint8List(1);

  @override
  Future<WalletCreateResult> crateApiWalletRestoreWalletWithPassword({
    required String mnemonic,
    required String password,
  }) async => WalletCreateResult(
    mnemonic: mnemonic,
    seedHex: '01',
    addressMainnet: '',
    addressTestnet: '',
    viewPublicHex: '',
    spendPublicHex: '',
  );

  @override
  Future<WalletScanResult> crateApiWalletScanWalletOutputs({
    required String host,
    required int port,
    required String seedHex,
    required int account,
    required BigInt startHeight,
    required BigInt endHeight,
    required bool isMainnet,
    String? cacheDirectory,
  }) async {
    if (offline) throw StateError('disconnected');
    return WalletScanResult(
      totalBalance: detached ? BigInt.zero : BigInt.one,
      outputCount: detached ? BigInt.zero : BigInt.one,
      scannedHeight: BigInt.one,
      scannedHashHex: (detached ? 'b' : 'a') * 64,
      outputsJson: detached
          ? '[]'
          : '[{"value":1,"received_tx_hash":"transfer","block_height":1}]',
    );
  }
}

class _MiningWallet extends WalletService {
  @override
  WalletState get state =>
      super.state.copyWith(pendingPoolRewardsAtomic: '99000000000000');
}

void main() {
  testWidgets(
    'home and receipts use only the successful scan for the active wallet',
    (tester) async {
      final api = _ScanApi();
      RustLib.initMock(api: api);
      FlutterSecureStorage.setMockInitialValues({});
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => '.',
      );
      final wallet = _MiningWallet();
      addTearDown(wallet.dispose);
      await wallet.restoreWallet('fixture', 'fixture');
      await tester.pumpWidget(
        ChangeNotifierProvider<WalletService>.value(
          value: wallet,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('— HPN'), findsOneWidget);
      await wallet.scanWalletOutputs();
      await tester.pump();
      expect(find.text('0.000000000001 HPN'), findsOneWidget);
      expect(wallet.lastReceipt?.amount, BigInt.one);
      const storage = FlutterSecureStorage();
      final outputKey = (await storage.readAll()).keys.singleWhere(
        (key) => key.startsWith('owned_outputs_v2_'),
      );
      await storage.write(key: outputKey, value: '[{"value":900000000000000}]');
      expect(await wallet.getSpendableBalance(), BigInt.one);
      api.offline = true;
      await wallet.refreshAll();
      await tester.pump();
      expect(find.text('— HPN'), findsOneWidget);
      expect(wallet.lastReceipt, isNull);
      expect(wallet.state.syncError, contains('disconnected'));
      api.offline = false;
      await wallet.refreshAll();
      expect(wallet.lastReceipt?.hash, 'transfer');
      final id = wallet.state.activeWalletId!;
      await storage.write(
        key: 'transfer_history_$id',
        value: jsonEncode([
          {'direction': 'sent', 'recipientAddress': 'old-chain-transfer'},
        ]),
      );
      await wallet.loadTransferHistory();
      expect(wallet.state.transferActivities, isEmpty);
      await storage.write(
        key: 'transfer_history_HYN3_$id',
        value: jsonEncode([
          {'direction': 'received', 'recipientAddress': 'forged-incoming'},
          {'direction': 'unknown', 'recipientAddress': 'unknown-direction'},
          {'direction': 'sent', 'recipientAddress': 'known-outgoing'},
        ]),
      );
      await wallet.loadTransferHistory();
      await tester.tap(find.text('Activity').last);
      await tester.pumpAndSettle();
      expect(find.text('known-outgoing'), findsOneWidget);
      expect(find.text('forged-incoming'), findsNothing);
      expect(find.text('unknown-direction'), findsNothing);
      expect(find.textContaining('\ntransfer'), findsOneWidget);
      api.detached = true;
      await wallet.scanWalletOutputs();
      await tester.pump();
      expect(find.textContaining('\ntransfer'), findsNothing);
      expect(wallet.scannedBalance, BigInt.zero);
      wallet.lock();
      expect(wallet.scannedBalance, isNull);
      expect(wallet.lastReceipt, isNull);
    },
  );
}
