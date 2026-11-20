import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/services/nfc_address.dart';
import 'package:nfc_manager/ndef_record.dart';

void main() {
  test('a wallet address survives NFC text record encoding and decoding', () {
    const address = 'hy1address';
    final message = NdefMessage.decode(encodeNfcAddress(address).encode());
    expect(decodeNfcAddress(message), address);
  });

  test('a truncated language field cannot hide a later valid address', () {
    final truncated = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]),
      identifier: Uint8List(0),
      payload: Uint8List.fromList([63]),
    );
    final message = NdefMessage(
      records: [truncated, ...encodeNfcAddress('hy1next').records],
    );
    expect(decodeNfcAddress(message), 'hy1next');
  });
}
