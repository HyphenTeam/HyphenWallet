import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mnemonic_grid.dart';

class BackupMnemonicScreen extends StatefulWidget {
  const BackupMnemonicScreen({super.key});

  @override
  State<BackupMnemonicScreen> createState() => _BackupMnemonicScreenState();
}

class _BackupMnemonicScreenState extends State<BackupMnemonicScreen> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = context.watch<WalletService>();
    final mnemonic = wallet.state.mnemonic;
    final words = mnemonic?.split(' ') ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recoveryPhraseTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HyphenColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HyphenColors.warning.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: HyphenColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.neverShareWarning,
                      style: TextStyle(
                        color: HyphenColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!_revealed) ...[
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 64,
                      color: HyphenColors.textSecondary.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tapBelowToReveal,
                      style: const TextStyle(
                        color: HyphenColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _revealed = true),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: Text(l10n.revealRecoveryPhrase),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HyphenColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              MnemonicGrid(words: words),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: mnemonic ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.copiedClearClipboard),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(l10n.copyToClipboard),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => setState(() => _revealed = false),
                    icon: const Icon(Icons.visibility_off_rounded, size: 16),
                    label: Text(l10n.hidePhrase),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
