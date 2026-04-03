import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/perspective_card.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 60,
              left: -40,
              child: FloatingOrb(
                size: 140,
                color1: HyphenColors.primary,
                color2: HyphenColors.accent,
                period: Duration(seconds: 5),
              ),
            ),
            const Positioned(
              bottom: 120,
              right: -30,
              child: FloatingOrb(
                size: 100,
                color1: HyphenColors.accent,
                color2: HyphenColors.brightGreen,
                period: Duration(seconds: 6),
              ),
            ),
            const Positioned(
              top: 200,
              right: -50,
              child: FloatingOrb(
                size: 80,
                color1: HyphenColors.brightGreen,
                color2: HyphenColors.primary,
                period: Duration(seconds: 7),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      PerspectiveCard(
                        glowColor: cs.primary,
                        elevation: 16,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/images/Hyphen.png',
                              width: 120,
                              height: 120,
                              errorBuilder: (_, _, _) => Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [cs.primary, cs.secondary],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Center(
                                  child: Text(
                                    'H',
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        l10n.welcomeToHyphen,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.welcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _featureBadge(
                            Icons.shield_outlined,
                            l10n.wotsSignatures,
                          ),
                          _featureBadge(Icons.lock_outline, l10n.aesEncryption),
                          _featureBadge(
                            Icons.visibility_off_outlined,
                            l10n.privacyFirst,
                          ),
                        ],
                      ),
                      const Spacer(flex: 3),
                      GradientButton(
                        label: l10n.createNewWallet,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/node-mode'),
                        icon: Icons.add_rounded,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/node-mode-restore'),
                        icon: const Icon(Icons.restore_rounded, size: 20),
                        label: Text(l10n.restoreExistingWallet),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureBadge(IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
