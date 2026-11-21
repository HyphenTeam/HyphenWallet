import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('public HYN3 uses binary RPC and the HTTPS API origins', () {
    const state = WalletState();
    expect(state.rpcEndpoint, 'bytesnap.tech:48333');
    expect(
      state.explorerApiOrigin,
      Uri.parse('https://explorer.bytesnap.tech'),
    );
    expect(state.poolApiOrigin, Uri.parse('https://bytesnap.tech'));
    final custom = state.copyWith(
      rpcEndpoint: 'node.example:48333',
      poolApiEndpoint: 'https://pool.example:8443',
    );
    expect(custom.poolApiOrigin, Uri.parse('https://pool.example:8443'));
    expect(custom.explorerApiOrigin, Uri.parse('http://node.example:8080'));
    expect(
      WalletService.isValidRpcEndpoint('https://explorer.bytesnap.tech'),
      isFalse,
    );
  });

  test('upgrade moves the saved legacy default once and preserves a later selection', () async {
    FlutterSecureStorage.setMockInitialValues({
      'custom_rpc_endpoint': '127.0.0.1:48333',
    });
    final first = WalletService();
    addTearDown(first.dispose);
    expect(await first.loadRpcEndpoint(), 'bytesnap.tech:48333');
    await first.setCustomRpcEndpoint('127.0.0.1:48333');
    final reopened = WalletService();
    addTearDown(reopened.dispose);
    expect(await reopened.loadRpcEndpoint(), '127.0.0.1:48333');
  });
}
