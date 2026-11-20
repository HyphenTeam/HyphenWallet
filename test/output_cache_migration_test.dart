import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('upgrade removes both legacy output caches across wallets', () async {
    const storage = FlutterSecureStorage();
    const retained = {
      'wallet_list': 'encrypted wallet records',
      'active_wallet_id': '12',
      'owned_outputs_v2_12_scope': 'public output metadata',
    };
    FlutterSecureStorage.setMockInitialValues({
      ...retained,
      'owned_outputs_12': 'legacy per-wallet cache',
      'owned_outputs_WyIxMyIsImRldm5ldCJd': 'legacy per-endpoint cache',
    });
    final wallet = WalletService();
    addTearDown(wallet.dispose);
    await wallet.migrateOutputCache();
    await wallet.migrateOutputCache();
    expect(await storage.readAll(), {
      ...retained,
      'output_cache_v2_migrated': 'true',
    });
  });

  test(
    'deleting a wallet removes only its credentials and output scopes',
    () async {
      const storage = FlutterSecureStorage();
      FlutterSecureStorage.setMockInitialValues({
        'biometric_password_12': 'fixture',
        'biometric_password_123': 'retained',
        'owned_outputs_v2_12_a': '[]',
        'owned_outputs_v2_12_b': '[]',
        'owned_outputs_v2_123_a': 'retained',
        'transfer_history_12': '[]',
      });
      final wallet = WalletService();
      addTearDown(wallet.dispose);
      await wallet.deleteWalletById('12');
      expect(await storage.readAll(), {
        'biometric_password_123': 'retained',
        'owned_outputs_v2_123_a': 'retained',
        'wallet_list': '[]',
      });
      await wallet.setBiometricEnabled(false);
      expect(await storage.read(key: 'biometric_password_123'), isNull);
      expect(await storage.read(key: 'biometric_enabled'), 'false');
    },
  );
}
