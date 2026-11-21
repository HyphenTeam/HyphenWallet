import 'dart:convert';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/services/wallet_service.dart';
import 'package:hyphen_wallet/src/rust/frb_generated.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final library = Platform.environment['HYPHEN_WALLET_TEST_LIBRARY'];
  test(
    'Flutter creation, encrypted unlock and historical recovery through FFI',
    () async {
      await RustLib.init(externalLibrary: ExternalLibrary.open(library!));
      FlutterSecureStorage.setMockInitialValues({});
      final service = WalletService();
      addTearDown(service.dispose);
      const password = 'public-fixture';
      final words = await service.createWallet(password);
      final address = service.state.address;
      expect(words.split(' '), hasLength(24));
      expect(words, startsWith('hy3-'));
      expect(words, endsWith('-hy3'));
      final envelope = base64Decode(service.state.wallets.single.encryptedData);
      expect(ascii.decode(envelope.sublist(0, 8)), 'HYWLT001');
      service.lock();
      await expectLater(service.unlock('wrong password'), throwsA(anything));
      expect(service.state.isUnlocked, isFalse);
      await service.unlock(password);
      expect(service.state.address, address);
      await service.restoreWallet(words, password);
      expect(service.state.address, address);
      const historical =
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon about';
      await service.restoreWallet(historical, password);
      expect(
        service.state.address,
        'hy12LqVc3VPiSoMTgxpVubj4yusXPYoFKERshuLsEWD88ZXRKwPEeLcgBXoJck7CQ1FTBhjdtVttHmTFBewYeR7VDtxSvKkeE',
      );
    },
    skip: library == null
        ? 'Set HYPHEN_WALLET_TEST_LIBRARY to the built wallet library'
        : false,
  );
}
