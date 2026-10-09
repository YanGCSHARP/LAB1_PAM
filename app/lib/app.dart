import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';
import 'features/auth/presentation/login_screen.dart';

/// Root widget: Material 3 with a light and a dark theme.
///
/// [themeMode] follows the system setting — the in-app theme switch on the
/// profile screen is visual only until the app has a state layer to hold it.
class WalletMateApp extends StatelessWidget {
  const WalletMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale(Formatters.locale),
      supportedLocales: const [Locale(Formatters.locale), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LoginScreen(),
    );
  }
}
