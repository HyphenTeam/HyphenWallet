import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'services/wallet_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/create_wallet_screen.dart';
import 'screens/restore_wallet_screen.dart';
import 'screens/home_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/send_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/backup_mnemonic_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/wallet_management_screen.dart';
import 'screens/mining_activity_screen.dart';
import 'screens/node_mode_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const HyphenWalletApp());
}

class HyphenWalletApp extends StatelessWidget {
  const HyphenWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WalletService(),
      child: Consumer<WalletService>(
        builder: (context, wallet, _) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              final lightTheme = lightDynamic != null
                  ? buildHyphenThemeWithDynamic(
                      presetIndex: wallet.themeColorIndex,
                      dynamicLight: lightDynamic,
                    )
                  : buildHyphenTheme(presetIndex: wallet.themeColorIndex);

              final darkTheme = buildHyphenDarkTheme(
                presetIndex: wallet.themeColorIndex,
                dynamicDark: darkDynamic,
              );

              return MaterialApp(
                title: 'Hyphen Wallet',
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: wallet.themeMode,
                locale: wallet.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('zh'),
                  Locale('de'),
                  Locale('fr'),
                  Locale('es'),
                  Locale('it'),
                  Locale('ja'),
                ],
                initialRoute: '/',
                onGenerateRoute: _onGenerateRoute,
              );
            },
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
        page = const SplashScreen();
      case '/welcome':
        page = const WelcomeScreen();
      case '/node-mode':
        page = const NodeModeScreen(nextRoute: '/create');
      case '/node-mode-restore':
        page = const NodeModeScreen(nextRoute: '/restore');
      case '/create':
        page = const CreateWalletScreen();
      case '/restore':
        page = const RestoreWalletScreen();
      case '/unlock':
        page = const UnlockScreen();
      case '/home':
        page = const HomeScreen();
      case '/receive':
        page = const ReceiveScreen();
      case '/send':
        page = const SendScreen();
      case '/settings':
        page = const SettingsScreen();
      case '/backup':
        page = const BackupMnemonicScreen();
      case '/wallets':
        page = const WalletManagementScreen();
      case '/mining-activity':
        page = const MiningActivityScreen();
      case '/mining-activity/detail':
        final activity = settings.arguments;
        page = activity is RewardActivity
            ? MiningActivityDetailScreen(activity: activity)
            : const SplashScreen();
      default:
        page = const SplashScreen();
    }
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
