import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/mnemonic_grid.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  int _step = 0;
  String? _mnemonic;
  List<String> _words = [];
  bool _loading = false;
  String? _error;

  final Map<int, String> _verifyAnswers = {};
  List<int> _verifyIndices = [];

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _generateMnemonic();
  }

  Future<void> _generateMnemonic() async {
    setState(() => _loading = true);
    try {
      final wallet = context.read<WalletService>();
      final mnemonic = await wallet.createWallet('__temp__');
      wallet.lock();
      await wallet.deleteWallet();
      setState(() {
        _mnemonic = mnemonic;
        _words = mnemonic.split(' ');
        _loading = false;
        _pickVerificationWords();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _pickVerificationWords() {
    final indices = List<int>.generate(_words.length, (i) => i)..shuffle();
    _verifyIndices = indices.take(4).toList()..sort();
  }

  void _goToVerify() => setState(() => _step = 1);

  void _goToPassword() {
    final l10n = AppLocalizations.of(context)!;
    for (final idx in _verifyIndices) {
      if (_verifyAnswers[idx]?.trim().toLowerCase() != _words[idx].toLowerCase()) {
        setState(() => _error = l10n.wordIncorrect(idx + 1));
        return;
      }
    }
    setState(() { _error = null; _step = 2; });
  }

  Future<void> _finishCreation() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final wallet = context.read<WalletService>();
      await wallet.restoreWallet(_mnemonic!, _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() { _step--; _error = null; });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.createWallet),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (_step > 0) { setState(() { _step--; _error = null; }); } else { Navigator.pop(context); }
            },
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                  child: child,
                ),
              );
            },
            child: _loading
                ? _buildLoading(l10n)
                : switch (_step) {
                    0 => _buildMnemonicStep(l10n),
                    1 => _buildVerifyStep(l10n),
                    2 => _buildPasswordStep(l10n),
                    _ => const SizedBox.shrink(),
                  },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(AppLocalizations l10n) {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: HyphenColors.primary),
          const SizedBox(height: 16),
          Text(l10n.generatingSecureWallet, style: const TextStyle(color: HyphenColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMnemonicStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const ValueKey('mnemonic'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(0),
          const SizedBox(height: 24),
          Text(l10n.recoveryPhrase, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: HyphenColors.textPrimary)),
          const SizedBox(height: 8),
          Text(l10n.writeDownWords, style: const TextStyle(fontSize: 14, color: HyphenColors.textSecondary, height: 1.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HyphenColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HyphenColors.warning.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: HyphenColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.neverSharePhrase, style: TextStyle(color: HyphenColors.warning, fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MnemonicGrid(words: _words),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _mnemonic ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.phraseCopiedWarning), duration: const Duration(seconds: 3)));
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(l10n.copyToClipboard),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(label: l10n.iveWrittenItDown, onPressed: _goToVerify, icon: Icons.check_rounded),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const ValueKey('verify'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(1),
          const SizedBox(height: 24),
          Text(l10n.verifyYourPhrase, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: HyphenColors.textPrimary)),
          const SizedBox(height: 8),
          Text(l10n.enterWordsToConfirm, style: const TextStyle(fontSize: 14, color: HyphenColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          ..._verifyIndices.map((idx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                textInputAction: TextInputAction.next,
                onChanged: (val) => _verifyAnswers[idx] = val,
                decoration: InputDecoration(
                  labelText: l10n.wordNumber(idx + 1),
                  prefixIcon: Container(
                    width: 40, alignment: Alignment.center,
                    child: Text('${idx + 1}', style: const TextStyle(color: HyphenColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            );
          }),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: HyphenColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          GradientButton(label: l10n.verifyAndContinue, onPressed: _goToPassword, icon: Icons.verified_outlined),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const ValueKey('password'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepIndicator(2),
            const SizedBox(height: 24),
            Text(l10n.setPassword, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: HyphenColors.textPrimary)),
            const SizedBox(height: 8),
            Text(l10n.passwordEncryptInfo, style: const TextStyle(fontSize: 14, color: HyphenColors.textSecondary, height: 1.5)),
            const SizedBox(height: 32),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.passwordRequired;
                if (v.length < 8) return l10n.atLeast8Chars;
                return null;
              },
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _finishCreation(),
              validator: (v) {
                if (v != _passwordController.text) return l10n.passwordsDoNotMatch;
                return null;
              },
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: HyphenColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            GradientButton(
              label: _loading ? '' : l10n.createWallet,
              onPressed: _loading ? null : _finishCreation,
              icon: _loading ? null : Icons.check_circle_outline,
              child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _stepIndicator(int current) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive ? HyphenColors.primary : HyphenColors.surfaceLight,
            ),
          ),
        );
      }),
    );
  }
}
