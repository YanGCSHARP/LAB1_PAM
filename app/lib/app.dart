import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/state/app_session.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';
import 'features/auth/application/auth_service.dart';

/// Retry policy for the [ProviderScope]: never retry a failed load
/// automatically — the error state offers «Повторить» instead.
Duration? noRetry(int retryCount, Object error) => null;

/// Root widget: Material 3 with a light and a dark theme, routed by
/// [GoRouter]. Must sit under a [ProviderScope].
///
/// The router is created once and kept for the app's lifetime — rebuilding it
/// would throw away every tab's navigation stack.
class WalletMateApp extends ConsumerStatefulWidget {
  const WalletMateApp({
    super.key,
    this.signedIn = false,
    this.initialLocation = AppRoutes.login,
  });

  /// Starts the app already signed in — for tests and deep-link checks.
  final bool signedIn;
  final String initialLocation;

  @override
  ConsumerState<WalletMateApp> createState() => _WalletMateAppState();
}

class _WalletMateAppState extends ConsumerState<WalletMateApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final session = ref.read(authSessionProvider);
    if (widget.signedIn) {
      session.signIn();
    }
    _router = createAppRouter(
      session: session,
      auth: ref.read(authServiceProvider),
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale(Formatters.locale),
      supportedLocales: const [Locale(Formatters.locale), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
