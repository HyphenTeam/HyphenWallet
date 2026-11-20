import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

NdefMessage encodeNfcAddress(String address) => NdefMessage(
  records: [
    NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]), // NFC Forum Text RTD
      identifier: Uint8List(0),
      payload: Uint8List.fromList([2, 0x65, 0x6e, ...ascii.encode(address)]),
    ),
  ],
);

String? decodeNfcAddress(NdefMessage? message) {
  if (message == null) return null;
  for (final record in message.records) {
    final payload = record.payload;
    var start = 0;
    if (record.typeNameFormat == TypeNameFormat.wellKnown) {
      if (record.type.length != 1 ||
          record.type.first != 0x54 ||
          payload.isEmpty ||
          payload.first & 0x80 != 0) {
        continue;
      }
      start = 1 + (payload.first & 0x3f);
    }
    if (start >= payload.length) continue;
    final text = String.fromCharCodes(payload, start).trim();
    if (text.startsWith('hy1')) return text;
  }
  return null;
}
