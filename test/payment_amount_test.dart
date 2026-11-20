import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/services/payment_amount.dart';

void main() {
  test('payment input preserves every atomic unit through the u64 limit', () {
    expect(parsePaymentAmount('.000000000001'), BigInt.one);
    expect(
      parsePaymentAmount('9007.199254740993'),
      BigInt.parse('9007199254740993'),
    );
    expect(
      parsePaymentAmount('18446744.073709551615'),
      (BigInt.one << 64) - BigInt.one,
    );
    for (final value in [
      '18446744.073709551616',
      '0',
      '-1',
      '1e5',
      'NaN',
      '0.0000000000001',
    ]) {
      expect(parsePaymentAmount(value), isNull, reason: value);
    }
  });
}
