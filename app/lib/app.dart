import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/state/app_session.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';

/// Root widget: Material 3 with a light and a dark theme, routed by
/// [GoRouter].
///
/// The router is created once and kept for the app's lifetime — rebuilding it
/// would throw away every tab's navigation stack.
class WalletMateApp extends StatefulWidget {
  const WalletMateApp({
    super.key,
    this.signedIn = false,
    this.initialLocation = AppRoutes.login,
  });

  /// Starts the app already signed in — for tests and deep-link checks.
  final bool signedIn;
  final String initialLocation;

  @override
  State<WalletMateApp> createState() => _WalletMateAppState();
}

class _WalletMateAppState extends State<WalletMateApp> {
  late final AuthSession _session = AuthSession(widget.signedIn);
  final ThemeController _theme = ThemeController();
  late final GoRouter _router = createAppRouter(
    session: _session,
    theme: _theme,
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    _session.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _theme,
      builder: (context, themeMode, _) => MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: const Locale(Formatters.locale),
        supportedLocales: const [Locale(Formatters.locale), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
