import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/wallet_service.dart';

class MiningActivityScreen extends StatelessWidget {
  const MiningActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletService>(
      builder: (context, wallet, _) {
        final activities = wallet.state.rewardActivities;
        return Scaffold(
          appBar: AppBar(title: const Text('Mining Activity')),
          body: activities.isEmpty
              ? const _EmptyActivityState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: activities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _ActivitySummaryCard(
                      activity: activity,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/mining-activity/detail',
                        arguments: activity,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class MiningActivityDetailScreen extends StatelessWidget {
  final RewardActivity activity;

  const MiningActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reward Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _DetailHero(activity: activity),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Block',
            children: [
              _DetailRow(label: 'Height', value: activity.height.toString()),
              _CopyableDetailRow(
                label: 'Block hash',
                value: activity.blockHashHex,
              ),
              _DetailRow(
                label: 'Observed at',
                value: _formatTimestampLong(activity.timestamp),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Amounts',
            children: [
              _DetailRow(
                label: 'Credited amount',
                value: _formatAtomicAmount(activity.amountAtomic),
              ),
              _DetailRow(
                label: 'Block reward',
                value: _formatAtomicAmount(activity.rewardAtomic),
              ),
              _DetailRow(
                label: 'Block fees',
                value: _formatAtomicAmount(activity.feeAtomic),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Classification',
            children: [
              _DetailRow(
                label: 'Source',
                value: _activityLabel(activity.source),
              ),
              _DetailRow(
                label: 'Pool mode',
                value: activity.mode.toUpperCase(),
              ),
              _DetailRow(
                label: 'Reward kind',
                value: activity.kind.toUpperCase(),
              ),
              _DetailRow(
                label: 'Direct coinbase',
                value: activity.directCoinbase ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Addresses',
            children: [
              _CopyableDetailRow(
                label: 'Wallet address',
                value: activity.walletAddressHex,
              ),
              _CopyableDetailRow(
                label: 'Reward recipient',
                value: activity.rewardRecipientHex,
              ),
              _CopyableDetailRow(
                label: 'Finder public key',
                value: activity.finderPubkeyHex,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 40,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No mining reward events yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySummaryCard extends StatelessWidget {
  final RewardActivity activity;
  final VoidCallback onTap;

  const _ActivitySummaryCard({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: _activityColor(activity.source, cs),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activityLabel(activity.source),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Block #${activity.height} · ${_shortHash(activity.blockHashHex)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activity.mode.toUpperCase()} · ${activity.kind.toUpperCase()} · ${_formatTimestamp(activity.timestamp)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAtomicAmount(activity.amountAtomic),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final RewardActivity activity;

  const _DetailHero({required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activityLabel(activity.source),
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatAtomicAmount(activity.amountAtomic),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Block #${activity.height}',
            style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(Icons.copy_rounded, size: 18, color: cs.primary),
            tooltip: 'Copy $label',
          ),
        ],
      ),
    );
  }
}

String _formatAtomicAmount(String atomicString) {
  final atomic = BigInt.tryParse(atomicString) ?? BigInt.zero;
  const decimals = 12;
  final divisor = BigInt.from(10).pow(decimals);
  final whole = atomic ~/ divisor;
  final fraction = (atomic % divisor).toString().padLeft(decimals, '0');
  return '$whole.$fraction HYP';
}

String _shortHash(String value) {
  if (value.length <= 16) {
    return value;
  }
  return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
}

String _formatTimestamp(int timestamp) {
  if (timestamp <= 0) {
    return '-';
  }
  final date = DateTime.fromMillisecondsSinceEpoch(
    timestamp * 1000,
    isUtc: true,
  ).toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

String _formatTimestampLong(int timestamp) {
  if (timestamp <= 0) {
    return '-';
  }
  final date = DateTime.fromMillisecondsSinceEpoch(
    timestamp * 1000,
    isUtc: true,
  ).toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute:$second';
}

String _activityLabel(String source) {
  switch (source) {
    case 'pool':
      return 'Pool reward credit';
    case 'pool_coinbase':
      return 'Pool coinbase receipt';
    default:
      return 'On-chain reward';
  }
}

Color _activityColor(String source, ColorScheme cs) {
  switch (source) {
    case 'pool':
      return Colors.green;
    case 'pool_coinbase':
      return Colors.orange;
    default:
      return cs.primary;
  }
}
