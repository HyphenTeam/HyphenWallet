import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/services/wallet_service.dart';

void main() {
  test('latest receipt tracks canonical unspent outputs and exact amounts', () {
    final tip = BigInt.from(8);
    const outputs =
        '[{"received_tx_hash":"old","value":3,"block_height":2},'
        '{"received_tx_hash":"recent","value":"9007199254740993","block_height":7},'
        '{"received_tx_hash":"recent","value":1,"block_height":7},'
        '{"value":100,"block_height":8}]';
    final receipt = latestUnspentReceipt(outputs, tip)!;
    expect(receipt.hash, 'recent');
    expect(receipt.amount, BigInt.parse('9007199254740994'));
    expect(receipt.confirmations, BigInt.two);
    expect(latestUnspentReceipt('[{"value":1,"block_height":8}]', tip), isNull);
  });
}
