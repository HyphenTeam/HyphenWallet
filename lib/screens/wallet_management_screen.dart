import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../services/wallet_service.dart';

class WalletManagementScreen extends StatelessWidget {
  const WalletManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<WalletService>(
      builder: (context, wallet, _) {
        final state = wallet.state;
        final wallets = state.wallets;
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.wallets)),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              ...wallets.map((w) {
                final isActive = w.id == state.activeWalletId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isActive
                        ? BorderSide(color: cs.primary, width: 1.5)
                        : BorderSide.none,
                  ),
                  color: cs.surfaceContainerHighest,
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? cs.primary
                          : cs.onSurfaceVariant.withAlpha(40),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 20,
                        color: isActive ? Colors.white : cs.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      w.name,
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    subtitle: isActive
                        ? Text(
                            l10n.activeWallet,
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : null,
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (action) =>
                          _handleAction(context, wallet, w, action, l10n),
                      itemBuilder: (ctx) => [
                        if (!isActive)
                          PopupMenuItem(
                            value: 'switch',
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz_rounded, size: 18),
                                const SizedBox(width: 10),
                                Text(l10n.switchTo),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded, size: 18),
                              const SizedBox(width: 10),
                              Text(l10n.renameWallet),
                            ],
                          ),
                        ),
                        if (!isActive)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: cs.error,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.deleteThisWallet,
                                  style: TextStyle(color: cs.error),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onTap: isActive
                        ? null
                        : () => _switchWallet(context, wallet, w, l10n),
                  ),
                );
              }),
              const SizedBox(height: 16),
              _addWalletSection(context, l10n),
            ],
          ),
        );
      },
    );
  }

  void _handleAction(
    BuildContext context,
    WalletService wallet,
    WalletInfo w,
    String action,
    AppLocalizations l10n,
  ) {
    switch (action) {
      case 'switch':
        _switchWallet(context, wallet, w, l10n);
      case 'rename':
        _showRenameDialog(context, wallet, w, l10n);
      case 'delete':
        _confirmDeleteWallet(context, wallet, w, l10n);
    }
  }

  void _switchWallet(
    BuildContext context,
    WalletService wallet,
    WalletInfo w,
    AppLocalizations l10n,
  ) {
    wallet.switchWallet(w.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.walletSwitched(w.name))));
    Navigator.of(context).pushNamedAndRemoveUntil('/unlock', (_) => false);
  }

  void _showRenameDialog(
    BuildContext context,
    WalletService wallet,
    WalletInfo w,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController(text: w.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameWallet),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.walletName,
            hintText: l10n.enterWalletName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                wallet.renameWallet(w.id, name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.walletRenamed)));
              }
            },
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWallet(
    BuildContext context,
    WalletService wallet,
    WalletInfo w,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;
    if (w.id == wallet.state.activeWalletId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cannotDeleteActiveWallet)));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteWallet),
        content: Text(l10n.deleteWalletConfirm(w.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await wallet.deleteWalletById(w.id);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.walletDeleted)));
              }
            },
            child: Text(l10n.delete, style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
  }

  Widget _addWalletSection(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Text(
            l10n.addNewWallet,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/create'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.createNew),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/restore'),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(l10n.importExisting),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
