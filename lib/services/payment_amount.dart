final _decimalAmount = RegExp(r'^0*([0-9]{1,8})(?:\.([0-9]{0,12}))?$');

String formatPaymentAmount(BigInt atomic) {
  final unit = BigInt.from(1000000000000);
  return '${atomic ~/ unit}.${(atomic % unit).abs().toString().padLeft(12, '0')} HPN';
}

BigInt? parsePaymentAmount(String text) {
  final value = text.trim();
  final match = _decimalAmount.firstMatch(
    value.startsWith('.') ? '0$value' : value,
  );
  if (match == null) return null;
  final fraction = (match.group(2) ?? '').padRight(12, '0');
  final atomic = BigInt.parse('${match.group(1)}$fraction');
  return atomic > BigInt.zero && atomic.bitLength <= 64 ? atomic : null;
}
