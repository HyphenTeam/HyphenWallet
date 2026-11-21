import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import '../services/nfc_address.dart';
import '../widgets/latest_receipt_tile.dart';
import '../services/wallet_service.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  bool _nfcBroadcasting = false;

  @override
  void dispose() {
    if (_nfcBroadcasting) NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _startNfcBroadcast(String address, AppLocalizations l10n) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final available = await NfcManager.instance.checkAvailability();
    if (!mounted || _nfcBroadcasting) return;
    if (available != NfcAvailability.enabled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.nfcNotAvailable)));
      return;
    }
    setState(() => _nfcBroadcasting = true);
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        invalidateAfterFirstReadIos: false,
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) return;
            await ndef.write(message: encodeNfcAddress(address));
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.nfcTransferSent)));
            }
          } on Exception catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(error.toString())));
            }
          } finally {
            if (mounted) {
              setState(() => _nfcBroadcasting = false);
              await NfcManager.instance.stopSession();
            }
          }
        },
        onSessionErrorIos: (error) {
          if (!mounted) return;
          setState(() => _nfcBroadcasting = false);
        },
      );
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _nfcBroadcasting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.nfcReadyToScan),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = context.watch<WalletService>();
    final address = wallet.state.address ?? '';
    final cs = Theme.of(context).colorScheme;
    final receipt = wallet.lastReceipt;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiveTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            if (wallet.state.syncError.isNotEmpty)
              Text(wallet.state.syncError, style: TextStyle(color: cs.error)),
            if (receipt != null) LatestReceiptTile(receipt: receipt),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: address.isNotEmpty
                        ? QrImageView(
                            data: address,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.circle,
                              color: Color(0xFF1A1A2E),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Color(0xFF1A1A2E),
                            ),
                          )
                        : Icon(
                            Icons.qr_code_2_rounded,
                            size: 180,
                            color: cs.onSurface.withAlpha(200),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.yourAddress,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline),
                    ),
                    child: SelectableText(
                      address,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: cs.onSurface,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: address));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.addressCopiedToClipboard),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(l10n.copy),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: address));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.addressCopiedToClipboard),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: Text(l10n.share),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!Platform.isWindows &&
                      !Platform.isLinux &&
                      !Platform.isMacOS) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _nfcBroadcasting
                            ? null
                            : () => _startNfcBroadcast(address, l10n),
                        icon: Icon(
                          _nfcBroadcasting
                              ? Icons.nfc_rounded
                              : Icons.nfc_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _nfcBroadcasting
                              ? l10n.nfcReadyToScan
                              : l10n.nfcTapToTransfer,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withAlpha(40)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: cs.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.receiveInfo,
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
