import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';

class NodeModeScreen extends StatefulWidget {
  final String nextRoute;
  const NodeModeScreen({super.key, this.nextRoute = '/create-wallet'});

  @override
  State<NodeModeScreen> createState() => _NodeModeScreenState();
}

class _NodeModeScreenState extends State<NodeModeScreen>
    with TickerProviderStateMixin {
  NodeMode? _selected;
  late AnimationController _lightController;
  late AnimationController _fullController;
  late AnimationController _pulseController;
  late Animation<double> _lightScale;
  late Animation<double> _fullScale;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _lightScale = CurvedAnimation(
      parent: _lightController,
      curve: Curves.elasticOut,
    );
    _fullScale = CurvedAnimation(
      parent: _fullController,
      curve: Curves.elasticOut,
    );
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _lightController.dispose();
    _fullController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _select(NodeMode mode) {
    setState(() => _selected = mode);
    if (mode == NodeMode.light) {
      _lightController.forward(from: 0);
      _fullController.reverse();
    } else {
      _fullController.forward(from: 0);
      _lightController.reverse();
    }
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    final wallet = context.read<WalletService>();
    await wallet.setNodeMode(_selected!);
    if (!mounted) return;
    Navigator.of(context).pushNamed(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              ScaleTransition(
                scale: _pulse,
                child: Icon(
                  Icons.account_tree_rounded,
                  size: 56,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.chooseNodeMode,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.nodeModeDescription,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  children: [
                    _ModeCard(
                      mode: NodeMode.light,
                      selected: _selected == NodeMode.light,
                      scale: _lightScale,
                      icon: Icons.bolt_rounded,
                      iconColor: cs.secondary,
                      title: l10n.lightNode,
                      subtitle: l10n.lightNodeDesc,
                      features: [
                        l10n.lightFeature1,
                        l10n.lightFeature2,
                        l10n.lightFeature3,
                      ],
                      onTap: () => _select(NodeMode.light),
                    ),
                    const SizedBox(height: 16),
                    _ModeCard(
                      mode: NodeMode.full,
                      selected: _selected == NodeMode.full,
                      scale: _fullScale,
                      icon: Icons.dns_rounded,
                      iconColor: HyphenColors.brightGreen,
                      title: l10n.fullNode,
                      subtitle: l10n.fullNodeDesc,
                      features: [
                        l10n.fullFeature1,
                        l10n.fullFeature2,
                        l10n.fullFeature3,
                      ],
                      onTap: () => _select(NodeMode.full),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selected != null ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    disabledBackgroundColor: cs.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.continueButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final NodeMode mode;
  final bool selected;
  final Animation<double> scale;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String> features;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.scale,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: selected ? scale : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected
                ? cs.surfaceContainerHighest
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? iconColor : cs.outline,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: selected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: selected ? iconColor : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: selected ? iconColor : cs.outline,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: iconColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
