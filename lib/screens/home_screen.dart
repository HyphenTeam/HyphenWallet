import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../services/wallet_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _navIndex = 0;
  late final AnimationController _balanceController;
  late final Animation<double> _balanceFade;
  late final Animation<Offset> _balanceSlide;

  @override
  void initState() {
    super.initState();
    _balanceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _balanceFade = CurvedAnimation(
      parent: _balanceController,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    _balanceSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _balanceController,
            curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _balanceController.forward();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<WalletService>(
      builder: (context, wallet, _) {
        final state = wallet.state;
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: cs.surface,
          body: IndexedStack(
            index: _navIndex,
            children: [
              _HomeTab(
                state: state,
                l10n: l10n,
                wallet: wallet,
                balanceFade: _balanceFade,
                balanceSlide: _balanceSlide,
              ),
              _ActivityTab(state: state),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) {
              if (i == 2) {
                Navigator.pushNamed(context, '/send');
                return;
              }
              if (i == 3) {
                Navigator.pushNamed(context, '/settings');
                return;
              }
              setState(() => _navIndex = i);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: '${l10n.receive.substring(0, 0)}Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: const Icon(Icons.arrow_upward_rounded),
                selectedIcon: const Icon(Icons.arrow_upward_rounded),
                label: l10n.send,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: '${l10n.receive.substring(0, 0)}Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final WalletState state;
  final AppLocalizations l10n;
  final WalletService wallet;
  final Animation<double> balanceFade;
  final Animation<Offset> balanceSlide;

  const _HomeTab({
    required this.state,
    required this.l10n,
    required this.wallet,
    required this.balanceFade,
    required this.balanceSlide,
  });

  @override
  Widget build(BuildContext context) {
    final walletName = state.activeWallet?.name ?? 'Hyphen';
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () => wallet.refreshMinedRewards(),
      color: HyphenColors.forestGreen,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: HyphenColors.brightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'H',
                      style: TextStyle(
                        color: HyphenColors.forestGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  walletName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              _NetworkChip(state: state, wallet: wallet, l10n: l10n),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined, size: 26),
                onPressed: () => Navigator.pushNamed(context, '/wallets'),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  SlideTransition(
                    position: balanceSlide,
                    child: FadeTransition(
                      opacity: balanceFade,
                      child: _BalanceHero(state: state, l10n: l10n),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _QuickActions(l10n: l10n),
                  const SizedBox(height: 28),
                  if (state.poolPayoutMode.isNotEmpty) ...[
                    _PoolInfoStrip(state: state, l10n: l10n),
                    const SizedBox(height: 20),
                  ],
                  _MiningBreakdown(state: state, l10n: l10n),
                  const SizedBox(height: 20),
                  _AddressCard(state: state, l10n: l10n),
                  const SizedBox(height: 20),
                  _SecurityStrip(l10n: l10n),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkChip extends StatelessWidget {
  final WalletState state;
  final WalletService wallet;
  final AppLocalizations l10n;

  const _NetworkChip({
    required this.state,
    required this.wallet,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMainnet = state.network == HyphenNetwork.mainnet;
    return ActionChip(
      label: Text(
        isMainnet ? l10n.mainnet : l10n.testnet,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isMainnet ? HyphenColors.forestGreen : cs.tertiary,
        ),
      ),
      avatar: Icon(
        isMainnet ? Icons.circle : Icons.circle_outlined,
        size: 8,
        color: isMainnet ? Colors.green : Colors.orange,
      ),
      onPressed: () {
        final next = isMainnet ? HyphenNetwork.testnet : HyphenNetwork.mainnet;
        wallet.switchNetwork(next);
      },
      backgroundColor: isMainnet
          ? HyphenColors.brightGreen.withAlpha(30)
          : Colors.orange.withAlpha(25),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BalanceHero extends StatelessWidget {
  final WalletState state;
  final AppLocalizations l10n;

  const _BalanceHero({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final onChain = BigInt.tryParse(state.onChainBalanceAtomic) ?? BigInt.zero;
    final miningTotal = _sumAtomic([
      state.minedRewardsAtomic,
      state.pendingPoolRewardsAtomic,
      state.poolCoinbaseRewardsAtomic,
    ]);
    final total = onChain > miningTotal ? onChain : miningTotal;
    final parts = _splitAtomic(total);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163300), Color(0xFF1E4D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HyphenColors.forestGreen.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.totalBalance,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HyphenColors.brightGreen.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.nodeMode == NodeMode.full
                          ? Icons.dns_rounded
                          : Icons.bolt_rounded,
                      size: 12,
                      color: HyphenColors.brightGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.nodeMode == NodeMode.full
                          ? l10n.fullNode
                          : l10n.lightNode,
                      style: TextStyle(
                        color: HyphenColors.brightGreen.withAlpha(220),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                parts.$1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              Text(
                '.${parts.$2}',
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HYP',
                style: TextStyle(
                  color: HyphenColors.brightGreen.withAlpha(200),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.network == HyphenNetwork.mainnet
                ? l10n.mainnet
                : l10n.testnet,
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final AppLocalizations l10n;
  const _QuickActions({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In dark mode, forestGreen is nearly invisible on dark backgrounds.
    // Use the theme's primary (which is brightGreen in dark mode) instead.
    final actionColor = isDark ? cs.primary : HyphenColors.forestGreen;
    final actionBg = isDark
        ? cs.primary.withAlpha(30)
        : HyphenColors.brightGreen.withAlpha(35);
    return Row(
      children: [
        _QuickActionPill(
          icon: Icons.arrow_downward_rounded,
          label: l10n.receive,
          color: actionColor,
          bg: actionBg,
          onTap: () => Navigator.pushNamed(context, '/receive'),
        ),
        const SizedBox(width: 10),
        _QuickActionPill(
          icon: Icons.arrow_upward_rounded,
          label: l10n.send,
          color: actionColor,
          bg: actionBg,
          onTap: () => Navigator.pushNamed(context, '/send'),
        ),
        const SizedBox(width: 10),
        _QuickActionPill(
          icon: Icons.backup_outlined,
          label: 'Backup',
          color: isDark ? cs.tertiary : cs.tertiary,
          bg: cs.tertiary.withAlpha(isDark ? 30 : 20),
          onTap: () => Navigator.pushNamed(context, '/backup'),
        ),
      ],
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PoolInfoStrip extends StatelessWidget {
  final WalletState state;
  final AppLocalizations l10n;
  const _PoolInfoStrip({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final mode = state.poolPayoutMode.toUpperCase();
    final fee = state.poolFeeBps != null
        ? '${(state.poolFeeBps! / 100).toStringAsFixed(2)}%'
        : '-';
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_outlined, size: 18, color: cs.outline),
          const SizedBox(width: 10),
          Text(
            '${l10n.miningPoolMode}: ',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: HyphenColors.brightGreen.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Builder(
              builder: (ctx) {
                final dark = Theme.of(ctx).brightness == Brightness.dark;
                return Text(
                  mode,
                  style: TextStyle(
                    color: dark ? Theme.of(ctx).colorScheme.primary : HyphenColors.forestGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Text(
            '${l10n.poolFee}: $fee',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MiningBreakdown extends StatelessWidget {
  final WalletState state;
  final AppLocalizations l10n;
  const _MiningBreakdown({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final settled = _formatAtomic(state.minedRewardsAtomic);
    final pending = _formatAtomic(state.pendingPoolRewardsAtomic);
    final coinbase = _formatAtomic(state.poolCoinbaseRewardsAtomic);
    final hasCoinbase =
        (BigInt.tryParse(state.poolCoinbaseRewardsAtomic) ?? BigInt.zero) >
        BigInt.zero;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mining Rewards',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.green,
            label: l10n.onChainMiningRewards,
            value: settled,
          ),
          const SizedBox(height: 10),
          _MetricRow(
            icon: Icons.schedule_rounded,
            iconColor: Colors.orange,
            label: l10n.poolPendingBalance,
            value: pending,
          ),
          if (hasCoinbase) ...[
            const SizedBox(height: 10),
            _MetricRow(
              icon: Icons.account_balance_rounded,
              iconColor: cs.tertiary,
              label: 'Pool coinbase',
              value: coinbase,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final WalletState state;
  final AppLocalizations l10n;
  const _AddressCard({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final address = state.address ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : HyphenColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.yourAddress,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              address,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/receive'),
                  icon: const Icon(Icons.qr_code_rounded, size: 16),
                  label: const Text('QR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: cs.outline),
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.primary
                        : HyphenColors.forestGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.addressCopied),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(l10n.copy),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

class _SecurityStrip extends StatelessWidget {
  final AppLocalizations l10n;
  const _SecurityStrip({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final features = [
      (Icons.shield_outlined, l10n.wotsQuantumResistant),
      (Icons.lock_outline, l10n.aes256GcmEncryption),
      (Icons.key_outlined, l10n.blake3Kdf),
      (Icons.visibility_off_outlined, l10n.icdStealthKeys),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.securityFeatures,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: features
                .map(
                  (f) => Chip(
                    avatar: Icon(f.$1, size: 14, color: Colors.green),
                    label: Text(f.$2, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final WalletState state;
  const _ActivityTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Build a unified, chronologically-sorted activity list.
    final List<_UnifiedActivity> unified = [];

    for (final r in state.rewardActivities) {
      unified.add(_UnifiedActivity(
        timestamp: r.timestamp,
        reward: r,
      ));
    }
    for (final t in state.transferActivities) {
      unified.add(_UnifiedActivity(
        timestamp: t.timestamp,
        transfer: t,
      ));
    }
    // Sort newest first
    unified.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        if (unified.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: cs.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noActivityYet,
                    style: TextStyle(color: cs.outline, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: unified.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 60, endIndent: 20),
            itemBuilder: (context, i) {
              final item = unified[i];
              if (item.reward != null) {
                return _ActivityListItem(
                  activity: item.reward!,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/mining-activity/detail',
                    arguments: item.reward,
                  ),
                );
              } else {
                return _TransferListItem(
                  transfer: item.transfer!,
                  l10n: l10n,
                );
              }
            },
          ),
      ],
    );
  }
}

/// A unified wrapper for either a mining reward or a transfer activity.
class _UnifiedActivity {
  final int timestamp;
  final RewardActivity? reward;
  final TransferActivity? transfer;
  const _UnifiedActivity({
    required this.timestamp,
    this.reward,
    this.transfer,
  });
}

/// List tile for a transfer activity (sent or received).
class _TransferListItem extends StatelessWidget {
  final TransferActivity transfer;
  final AppLocalizations l10n;
  const _TransferListItem(
      {required this.transfer, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSent = transfer.direction == TransferDirection.sent;
    final icon = isSent ? Icons.call_made_rounded : Icons.call_received_rounded;
    final color = isSent ? Colors.red : Colors.green;
    final label = isSent ? l10n.transferSent : l10n.transferReceived;
    final sign = isSent ? '-' : '+';
    final amount = _formatAtomic(transfer.amountAtomic);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      subtitle: Text(
        transfer.recipientAddress.length > 20
            ? '${transfer.recipientAddress.substring(0, 10)}…${transfer.recipientAddress.substring(transfer.recipientAddress.length - 10)}'
            : transfer.recipientAddress,
        style: TextStyle(fontSize: 12, color: cs.outline),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sign$amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            _fmtTimestamp(transfer.timestamp),
            style: TextStyle(fontSize: 11, color: cs.outline),
          ),
        ],
      ),
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  final RewardActivity activity;
  final VoidCallback onTap;
  const _ActivityListItem({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amount = _formatAtomic(activity.amountAtomic);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _activityColor(activity.source).withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _activityIcon(activity.source),
          size: 20,
          color: _activityColor(activity.source),
        ),
      ),
      title: Text(
        _activityLabel(activity.source),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      subtitle: Text(
        'Block #${activity.height} · ${_shortHash(activity.blockHashHex)}',
        style: TextStyle(fontSize: 12, color: cs.outline),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          Text(
            _fmtTimestamp(activity.timestamp),
            style: TextStyle(fontSize: 11, color: cs.outline),
          ),
        ],
      ),
    );
  }
}

BigInt _sumAtomic(List<String> values) {
  var total = BigInt.zero;
  for (final v in values) {
    total += BigInt.tryParse(v) ?? BigInt.zero;
  }
  return total;
}

(String, String) _splitAtomic(BigInt atomic) {
  const d = 12;
  final divisor = BigInt.from(10).pow(d);
  final whole = (atomic ~/ divisor).toString();
  final frac = (atomic % divisor).abs().toString().padLeft(d, '0');
  return (whole, frac.substring(0, math.min(4, frac.length)));
}

String _formatAtomic(String s) {
  final a = BigInt.tryParse(s) ?? BigInt.zero;
  const d = 12;
  final divisor = BigInt.from(10).pow(d);
  return '${a ~/ divisor}.${(a % divisor).abs().toString().padLeft(d, "0")} HYP';
}

String _shortHash(String v) =>
    v.length <= 16 ? v : '${v.substring(0, 8)}…${v.substring(v.length - 8)}';

String _fmtTimestamp(int ts) {
  if (ts <= 0) return '-';
  final d = DateTime.fromMillisecondsSinceEpoch(
    ts * 1000,
    isUtc: true,
  ).toLocal();
  return '${d.month.toString().padLeft(2, "0")}/${d.day.toString().padLeft(2, "0")}'
      ' ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}

String _activityLabel(String s) => switch (s) {
  'pool' => 'Pool reward credit',
  'pool_coinbase' => 'Pool coinbase receipt',
  _ => 'On-chain reward',
};

IconData _activityIcon(String s) => switch (s) {
  'pool' => Icons.hub_rounded,
  'pool_coinbase' => Icons.account_balance_rounded,
  _ => Icons.diamond_outlined,
};

Color _activityColor(String s) => switch (s) {
  'pool' => Colors.green,
  'pool_coinbase' => Colors.orange,
  _ => HyphenColors.forestGreen,
};
