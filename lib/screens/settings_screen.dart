import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../services/wallet_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _languages = [
    ('en', 'English', '🇬🇧'),
    ('zh', '中文', '🇨🇳'),
    ('de', 'Deutsch', '🇩🇪'),
    ('fr', 'Français', '🇫🇷'),
    ('es', 'Español', '🇪🇸'),
    ('it', 'Italiano', '🇮🇹'),
    ('ja', '日本語', '🇯🇵'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<WalletService>(
      builder: (context, wallet, _) {
        final state = wallet.state;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settings)),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _sectionHeader(l10n.language),
              _languageTile(context, wallet, l10n),
              const SizedBox(height: 8),
              _sectionHeader(l10n.appTheme),
              _themeColorTile(context, wallet, l10n),
              _themeModeTile(context, wallet, l10n),
              const SizedBox(height: 8),
              _sectionHeader(l10n.walletManagement),
              _tile(
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.manageWallets,
                subtitle: l10n.switchCreateDelete,
                onTap: () => Navigator.pushNamed(context, '/wallets'),
              ),
              const SizedBox(height: 8),
              _sectionHeader(l10n.network),
              _networkTile(context, wallet, l10n, state),
              _nodeModeTile(context, wallet, l10n, state),
              _nodeConnectionTile(context, wallet, l10n, state),
              _nodeEndpointTile(context, wallet, l10n, state),
              _poolEndpointTile(context, wallet, l10n, state),
              _explorerEndpointTile(context, wallet, l10n, state),
              const SizedBox(height: 8),
              _sectionHeader(l10n.security),
              _biometricTile(context, wallet, l10n),
              _tile(
                icon: Icons.shield_outlined,
                title: l10n.backupRecoveryPhrase,
                subtitle: l10n.viewYour24WordMnemonic,
                onTap: () {
                  if (state.isUnlocked && state.mnemonic != null) {
                    Navigator.pushNamed(context, '/backup');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.walletMustBeUnlocked)),
                    );
                  }
                },
              ),
              _tile(
                icon: Icons.lock_outline,
                title: l10n.lockWallet,
                subtitle: l10n.clearSessionRequirePassword,
                onTap: () {
                  wallet.lock();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/unlock', (_) => false);
                },
              ),
              const SizedBox(height: 8),
              _sectionHeader(l10n.walletSection),
              FutureBuilder<String>(
                future: wallet.version(),
                builder: (ctx, snap) =>
                    _keyInfoTile(l10n.walletVersion, snap.data ?? '...'),
              ),
              const SizedBox(height: 8),
              _sectionHeader(l10n.dangerZone),
              _tile(
                icon: Icons.delete_forever_outlined,
                title: l10n.deleteWallet,
                subtitle: l10n.removeAllWalletData,
                iconColor: Theme.of(context).colorScheme.error,
                titleColor: Theme.of(context).colorScheme.error,
                onTap: () => _confirmDelete(context, wallet, l10n),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withAlpha(140),
              letterSpacing: 0.8,
            ),
          );
        },
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.only(bottom: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          child: ListTile(
            leading: Icon(icon, color: iconColor ?? cs.primary, size: 24),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: titleColor ?? cs.onSurface,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withAlpha(140),
                    ),
                  )
                : null,
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: cs.onSurface.withAlpha(140),
            ),
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }

  Widget _keyInfoTile(String label, String value) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.only(bottom: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          child: ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withAlpha(140),
              ),
            ),
            subtitle: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }

  Widget _languageTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;
    final currentLocale =
        wallet.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final currentLang = _languages.firstWhere(
      (l) => l.$1 == currentLocale,
      orElse: () => _languages.first,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.language_rounded, color: cs.primary, size: 24),
        title: Text(
          l10n.appLanguage,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${currentLang.$3} ${currentLang.$2}',
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: cs.onSurfaceVariant,
        ),
        onTap: () => _showLanguageSelector(context, wallet, l10n),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _themeColorTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
  ) {
    final currentPreset =
        kThemePresets[wallet.themeColorIndex.clamp(
          0,
          kThemePresets.length - 1,
        )];
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPreset.primary,
            border: Border.all(color: currentPreset.accent, width: 2),
          ),
        ),
        title: Text(
          l10n.themeColor,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          currentPreset.name,
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: cs.onSurfaceVariant,
        ),
        onTap: () => _showThemeColorSelector(context, wallet, l10n),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _themeModeTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.brightness_6_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.themeMode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode, size: 18),
                    label: Text(
                      l10n.lightMode,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.settings_brightness, size: 18),
                    label: Text(
                      l10n.systemMode,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode, size: 18),
                    label: Text(
                      l10n.darkMode,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                selected: {wallet.themeMode},
                onSelectionChanged: (v) => wallet.setThemeMode(v.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeColorSelector(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.55,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
                  child: Row(
                    children: [
                      Text(
                        l10n.themeColor,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                    itemCount: kThemePresets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final preset = kThemePresets[index];
                      final isSelected = index == wallet.themeColorIndex;
                      return Material(
                        color: isSelected
                            ? preset.primary.withAlpha(12)
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isSelected
                                ? BorderSide(color: preset.primary, width: 1.2)
                                : BorderSide.none,
                          ),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: preset.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: preset.accent,
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            preset.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: preset.primary,
                                )
                              : null,
                          onTap: () {
                            wallet.setThemeColorIndex(index);
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _networkTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dns_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.currentNetwork,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<HyphenNetwork>(
                segments: [
                  ButtonSegment(
                    value: HyphenNetwork.mainnet,
                    label: Text(
                      l10n.mainnet,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  ButtonSegment(
                    value: HyphenNetwork.testnet,
                    label: Text(
                      l10n.testnet,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                selected: {state.network},
                onSelectionChanged: (v) => wallet.switchNetwork(v.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nodeModeTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.nodeMode == NodeMode.full
                      ? Icons.dns_rounded
                      : Icons.bolt_rounded,
                  color: cs.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.chooseNodeMode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.nodeMode == NodeMode.full
                            ? l10n.fullNode
                            : l10n.lightNode,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<NodeMode>(
                segments: [
                  ButtonSegment(
                    value: NodeMode.light,
                    label: Text(
                      l10n.lightNode,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  ButtonSegment(
                    value: NodeMode.full,
                    label: Text(
                      l10n.fullNode,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                selected: {state.nodeMode},
                onSelectionChanged: (v) => wallet.setNodeMode(v.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nodeConnectionTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    return FutureBuilder<bool>(
      future: _checkNodeConnection(state.rpcEndpoint),
      builder: (ctx, snap) {
        final cs = Theme.of(ctx).colorScheme;
        final connected = snap.data ?? false;
        final checking = snap.connectionState == ConnectionState.waiting;
        final statusText = checking
            ? l10n.checkingConnection
            : connected
            ? l10n.connected
            : l10n.disconnected;
        final statusColor = checking
            ? cs.onSurfaceVariant
            : connected
            ? Colors.green
            : cs.error;
        final statusIcon = checking
            ? Icons.sync_rounded
            : connected
            ? Icons.check_circle_rounded
            : Icons.error_outline_rounded;
        return Card(
          margin: const EdgeInsets.only(bottom: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          child: ListTile(
            leading: Icon(statusIcon, color: statusColor, size: 22),
            title: Text(
              l10n.nodeConnectionStatus,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              onPressed: () {
                // Force rebuild by triggering notifyListeners
                wallet.setCustomRpcEndpoint(state.rpcEndpoint);
              },
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }

  Widget _nodeEndpointTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.cloud_outlined, color: cs.primary, size: 22),
        title: Text(
          l10n.rpcEndpoint,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          state.rpcEndpoint,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
        trailing: Icon(
          Icons.edit_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        onTap: () => _showNodeEndpointDialog(context, wallet, l10n, state),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _poolEndpointTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = state.usesAutoPoolApiEndpoint
        ? '${l10n.autoDerivedFromRpc}: ${state.effectivePoolApiEndpoint}'
        : state.poolApiEndpoint;
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.account_tree_outlined, color: cs.primary, size: 22),
        title: Text(
          l10n.poolApiEndpoint,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
        trailing: Icon(
          Icons.edit_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        onTap: () => _showPoolEndpointDialog(context, wallet, l10n, state),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _explorerEndpointTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = state.usesAutoExplorerApiEndpoint
        ? '${l10n.autoDerivedFromRpc}: ${state.effectiveExplorerApiEndpoint}'
        : state.explorerApiEndpoint;
    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.explore_outlined, color: cs.primary, size: 22),
        title: Text(
          l10n.explorerApiEndpoint,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
        trailing: Icon(
          Icons.edit_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        onTap: () => _showExplorerEndpointDialog(context, wallet, l10n, state),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _biometricTile(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
  ) {
    // On desktop platforms, hide the biometric tile entirely.
    if (!wallet.isBiometricPlatform) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: wallet.canUseBiometrics(),
      builder: (ctx, snap) {
        final hardwareAvailable = snap.data == true;
        final cs = Theme.of(ctx).colorScheme;
        return Card(
          margin: const EdgeInsets.only(bottom: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          child: SwitchListTile(
            secondary: Icon(
              Icons.fingerprint,
              color: hardwareAvailable ? cs.primary : cs.onSurfaceVariant,
              size: 24,
            ),
            title: Text(
              l10n.biometricUnlock,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: hardwareAvailable ? null : cs.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              hardwareAvailable
                  ? l10n.useFingerprintOrFace
                  : l10n.biometricNotAvailable,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            value: hardwareAvailable && wallet.biometricEnabled,
            onChanged: hardwareAvailable
                ? (v) => wallet.setBiometricEnabled(v)
                : null, // null disables the toggle
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkNodeConnection(String endpoint) async {
    try {
      final parts = endpoint.split(':');
      final host = parts[0];
      final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 38333 : 38333;
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showNodeEndpointDialog(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    final controller = TextEditingController(text: state.rpcEndpoint);
    final savedNodes = <String>[
      state.network == HyphenNetwork.mainnet
          ? kDefaultMainnetRpcEndpoint
          : kDefaultRpcEndpoint,
    ];
    final defaultEndpoint = state.network == HyphenNetwork.mainnet
        ? kDefaultMainnetRpcEndpoint
        : kDefaultRpcEndpoint;
    if (state.rpcEndpoint != defaultEndpoint &&
        !savedNodes.contains(state.rpcEndpoint)) {
      savedNodes.add(state.rpcEndpoint);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.rpcEndpoint,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.availableNodes,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...savedNodes.map((node) {
                      final isActive = node == state.rpcEndpoint;
                      final cs = Theme.of(ctx).colorScheme;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: isActive
                              ? BorderSide(color: cs.primary, width: 1.5)
                              : BorderSide.none,
                        ),
                        color: isActive
                            ? cs.primary.withAlpha(15)
                            : cs.surfaceContainerHighest,
                        elevation: 0,
                        child: ListTile(
                          dense: true,
                          title: Text(
                            node,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                          trailing: isActive
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: cs.primary,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            wallet.setCustomRpcEndpoint(node);
                            Navigator.pop(ctx);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      l10n.addCustomNode,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'host:port',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.check_rounded,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                          onPressed: () {
                            final endpoint = controller.text.trim();
                            if (endpoint.isNotEmpty) {
                              wallet.setCustomRpcEndpoint(endpoint);
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          wallet.setCustomRpcEndpoint(value.trim());
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPoolEndpointDialog(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    final controller = TextEditingController(text: state.poolApiEndpoint);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.poolApiEndpoint,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: state.usesAutoPoolApiEndpoint
                        ? BorderSide(
                            color: Theme.of(ctx).colorScheme.primary,
                            width: 1.5,
                          )
                        : BorderSide.none,
                  ),
                  color: state.usesAutoPoolApiEndpoint
                      ? Theme.of(ctx).colorScheme.primary.withAlpha(15)
                      : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  elevation: 0,
                  child: ListTile(
                    title: Text(
                      l10n.autoDerivedFromRpc,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      state.effectivePoolApiEndpoint,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: state.usesAutoPoolApiEndpoint
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(ctx).colorScheme.primary,
                            size: 18,
                          )
                        : null,
                    onTap: () {
                      wallet.setPoolApiEndpoint('');
                      Navigator.pop(ctx);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'host:port',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.check_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                      onPressed: () {
                        wallet.setPoolApiEndpoint(controller.text.trim());
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    wallet.setPoolApiEndpoint(value.trim());
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExplorerEndpointDialog(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
    WalletState state,
  ) {
    final controller = TextEditingController(text: state.explorerApiEndpoint);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.explorerApiEndpoint,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: state.usesAutoExplorerApiEndpoint
                        ? BorderSide(
                            color: Theme.of(ctx).colorScheme.primary,
                            width: 1.5,
                          )
                        : BorderSide.none,
                  ),
                  color: state.usesAutoExplorerApiEndpoint
                      ? Theme.of(ctx).colorScheme.primary.withAlpha(15)
                      : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  elevation: 0,
                  child: ListTile(
                    title: Text(
                      l10n.autoDerivedFromRpc,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      state.effectiveExplorerApiEndpoint,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: state.usesAutoExplorerApiEndpoint
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(ctx).colorScheme.primary,
                            size: 18,
                          )
                        : null,
                    onTap: () {
                      wallet.setExplorerApiEndpoint('');
                      Navigator.pop(ctx);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'host:port',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.check_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                      onPressed: () {
                        wallet.setExplorerApiEndpoint(controller.text.trim());
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    wallet.setExplorerApiEndpoint(value.trim());
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
  ) {
    final currentLocale =
        wallet.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
                  child: Row(
                    children: [
                      Text(
                        l10n.selectLanguage,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                    itemCount: _languages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final cs = Theme.of(context).colorScheme;
                      final lang = _languages[index];
                      final isSelected = lang.$1 == currentLocale;
                      return Material(
                        color: isSelected
                            ? cs.primary.withAlpha(12)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isSelected
                                ? BorderSide(color: cs.primary, width: 1.2)
                                : BorderSide.none,
                          ),
                          leading: Text(
                            lang.$3,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            lang.$2,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: cs.primary,
                                )
                              : null,
                          onTap: () {
                            wallet.setLocale(Locale(lang.$1));
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    WalletService wallet,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteWallet),
        content: Text(l10n.deleteWalletWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await wallet.deleteWallet();
              if (!context.mounted) return;
              final hasAny = await wallet.hasWallet();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                hasAny ? '/unlock' : '/welcome',
                (_) => false,
              );
            },
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
