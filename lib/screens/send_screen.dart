import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../services/wallet_service.dart';
import '../widgets/gradient_button.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _scanNfc(AppLocalizations l10n) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final available = await NfcManager.instance.isAvailable();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.nfcNotAvailable)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.nfcReadyToScan),
        duration: const Duration(seconds: 5),
      ),
    );
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          await NfcManager.instance.stopSession();
          return;
        }
        final message = await ndef.read();
        await NfcManager.instance.stopSession();
        for (final record in message.records) {
          final payload = String.fromCharCodes(record.payload);
          // NDEF text record has a 1-byte status + language code prefix
          final text = record.typeNameFormat == NdefTypeNameFormat.nfcWellknown
              ? payload.substring(1 + payload.codeUnitAt(0) & 0x3F)
              : payload;
          if (text.startsWith('hy1')) {
            if (!mounted) return;
            setState(() => _addressController.text = text.trim());
            return;
          }
        }
      },
      onError: (error) async {
        await NfcManager.instance.stopSession();
      },
    );
  }

  /// Shows a password confirmation dialog. Returns true if the password is
  /// correct, false/null if the user cancels or enters the wrong password.
  Future<bool?> _showPasswordDialog(
      AppLocalizations l10n, WalletService walletService) async {
    final controller = TextEditingController();
    String? errorText;
    bool verifying = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(l10n.enterPasswordToUnlock),
              content: TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  errorText: errorText,
                ),
                enabled: !verifying,
                onSubmitted: (_) async {
                  final pw = controller.text;
                  if (pw.isEmpty) {
                    setDialogState(() => errorText = l10n.passwordRequired);
                    return;
                  }
                  setDialogState(() {
                    verifying = true;
                    errorText = null;
                  });
                  final ok = await walletService.verifyPassword(pw);
                  if (ok) {
                    Navigator.pop(ctx, true);
                  } else {
                    setDialogState(() {
                      verifying = false;
                      errorText = l10n.incorrectPassword;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: verifying ? null : () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: verifying
                      ? null
                      : () async {
                          final pw = controller.text;
                          if (pw.isEmpty) {
                            setDialogState(
                                () => errorText = l10n.passwordRequired);
                            return;
                          }
                          setDialogState(() {
                            verifying = true;
                            errorText = null;
                          });
                          final ok = await walletService.verifyPassword(pw);
                          if (ok) {
                            Navigator.pop(ctx, true);
                          } else {
                            setDialogState(() {
                              verifying = false;
                              errorText = l10n.incorrectPassword;
                            });
                          }
                        },
                  child: verifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.unlock),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendTransaction(AppLocalizations l10n) async {
    if (_isSending) return;

    final walletService = context.read<WalletService>();
    final amountText = _amountController.text.trim();
    final recipientText = _addressController.text.trim();
    final amountHyp = double.parse(amountText);
    final feeHyp = 0.0001;

    // ── Step 1: Show confirmation dialog ──
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sendTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.recipient,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            SelectableText(recipientText,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
            const SizedBox(height: 12),
            Text(l10n.amount,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            Text('$amountHyp HYP',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.networkFee,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            Text('$feeHyp HYP', style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.send)),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // ── Step 2: Authenticate before sending ──
    if (walletService.isBiometricPlatform && walletService.biometricEnabled) {
      // Mobile with biometric enabled → use biometric auth
      final authed = await walletService.authenticateWithBiometrics(
        reason: 'Authorize transaction of $amountHyp HYP',
      );
      if (!authed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.biometricUnlock)));
        return;
      }
    } else {
      // Desktop or mobile without biometric → password confirmation
      final passwordOk = await _showPasswordDialog(l10n, walletService);
      if (passwordOk != true) return;
    }

    // ── Step 3: Execute transfer ──
    setState(() => _isSending = true);

    try {
      // Scan for latest outputs
      try {
        await walletService.scanWalletOutputs();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
        return;
      }

      // Parse amount (HYP to atomic units: 1 HYP = 1e12 atomic)
      final amountAtomic = BigInt.from(amountHyp * 1e12);
      final feeAtomic = BigInt.from(1e8); // 0.0001 HYP

      // Check balance
      final balance = await walletService.getSpendableBalance();
      if (balance < amountAtomic + feeAtomic) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Insufficient balance')),
        );
        return;
      }

      final result = await walletService.sendTransaction(
        recipientAddress: recipientText,
        amountAtomic: amountAtomic,
        feeAtomic: feeAtomic,
        ringSize: walletService.networkRingSize,
      );

      if (!mounted) return;

      if (result.accepted) {
        // Record the sent transfer in history
        await walletService.recordSentTransfer(
          txHashHex: result.txHashHex,
          recipientAddress: recipientText,
          amountAtomic: amountAtomic,
          feeAtomic: feeAtomic,
        );

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Transaction Sent'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your transaction has been submitted.'),
                if (result.vreUsedAdaptive) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Adaptive VRE parameters were used because the '
                            'chain is still young. Ring entropy will increase '
                            'automatically as the network grows.',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SelectableText(
                  'TX: ${result.txHashHex}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction rejected: ${result.errorMessage}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _addressController,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.addressRequired;
                  }
                  if (!v.trim().startsWith('hy1')) {
                    return l10n.invalidHyphenAddress;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: l10n.recipient,
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  hintText: 'hy1...',
                  suffixIcon:
                      (!Platform.isWindows &&
                          !Platform.isLinux &&
                          !Platform.isMacOS)
                      ? IconButton(
                          icon: const Icon(Icons.nfc_rounded, size: 20),
                          tooltip: l10n.nfcTapToTransfer,
                          onPressed: () => _scanNfc(l10n),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.amountRequired;
                  if (double.tryParse(v.trim()) == null) {
                    return l10n.invalidAmount;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  prefixIcon: const Icon(Icons.toll_outlined, size: 20),
                  suffixText: 'HYP',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(
                  children: [
                    _infoRow(l10n.networkFee, '0.0001 HYP'),
                    const SizedBox(height: 12),
                    _infoRow(l10n.privacyLevel, l10n.ringSignatureClsag),
                    const SizedBox(height: 12),
                    _infoRow(
                      l10n.network,
                      context.watch<WalletService>().state.network ==
                              HyphenNetwork.mainnet
                          ? l10n.mainnet
                          : l10n.testnet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: _isSending ? 'Sending...' : l10n.sendHyp,
                icon: _isSending ? Icons.hourglass_top : Icons.send_rounded,
                onPressed: _isSending
                    ? null
                    : () {
                        if (!_formKey.currentState!.validate()) return;
                        _sendTransaction(l10n);
                      },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
