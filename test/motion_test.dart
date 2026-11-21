import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/l10n/app_localizations.dart';
import 'package:hyphen_wallet/screens/mining_activity_screen.dart';
import 'package:hyphen_wallet/screens/node_mode_screen.dart';
import 'package:hyphen_wallet/screens/welcome_screen.dart';
import 'package:hyphen_wallet/services/wallet_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class _Rewards extends WalletService {
  int timestamp = 1;

  @override
  WalletState get state => WalletState(
    rewardActivities: [
      RewardActivity(
        source: 'on_chain',
        height: 7,
        blockHashHex: 'a' * 64,
        amountAtomic: '1000000000000',
        rewardAtomic: '1000000000000',
        feeAtomic: '0',
        timestamp: timestamp,
        mode: 'solo',
        kind: 'coinbase',
        walletAddressHex: '',
        rewardRecipientHex: '',
        finderPubkeyHex: '',
        directCoinbase: true,
      ),
    ],
  );

  void refresh() {
    timestamp++;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'welcome and node selection settle without scheduling idle frames',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const WelcomeScreen(),
          routes: {'/node-mode': (_) => const NodeModeScreen()},
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
      expect(tester.binding.transientCallbackCount, 0);
      await tester.tap(find.text('Create New Wallet'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.tap(find.text('Light Node'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('reward amount flies in both directions across a list refresh', (
    tester,
  ) async {
    final wallet = _Rewards();
    addTearDown(wallet.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<WalletService>.value(
        value: wallet,
        child: MaterialApp(
          home: const MiningActivityScreen(),
          routes: {
            '/mining-activity/detail': (context) => MiningActivityDetailScreen(
              activity:
                  ModalRoute.of(context)!.settings.arguments! as RewardActivity,
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final summary = find.byWidgetPredicate(
      (w) => w is Hero && w.tag == wallet.state.rewardActivities.single.eventId,
    );
    final amount = tester
        .widget<Text>(find.descendant(of: summary, matching: find.byType(Text)))
        .data;
    final inFlight = find.byElementPredicate(
      (el) =>
          el.widget is Text &&
          (el.widget as Text).data == amount &&
          el.findAncestorWidgetOfExactType<Scaffold>() == null,
    );
    await tester.tap(summary);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(inFlight, findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Reward Details'), findsOneWidget);
    wallet.refresh();
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(inFlight, findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Mining Activity'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
