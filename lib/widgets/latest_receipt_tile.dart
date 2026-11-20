import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../services/payment_amount.dart';

class LatestReceiptTile extends StatelessWidget {
  final ({String hash, BigInt amount, BigInt confirmations}) receipt;

  const LatestReceiptTile({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: ListTile(
        title: Text(l10n.latestUnspentReceived),
        subtitle: SelectableText(
          '${formatPaymentAmount(receipt.amount)}\n${l10n.blockConfirmations} · ${receipt.confirmations}\n${receipt.hash}',
        ),
      ),
    );
  }
}
