import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walletmate/core/theme/app_theme.dart';
import 'package:walletmate/core/utils/formatters.dart';
import 'package:walletmate/features/dashboard/presentation/dashboard_screen.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
    locale: const Locale(Formatters.locale),
    supportedLocales: const [Locale(Formatters.locale), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting(Formatters.locale));

  testWidgets('dashboard shows balances, chart legend and budgets', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const DashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Сентябрь 2026'), findsOneWidget);
    expect(find.text('Карта Maib'), findsOneWidget);
    expect(find.text('Структура расходов'), findsOneWidget);

    // The legend lists every expense category of the month.
    expect(find.text('Жильё'), findsOneWidget);
    expect(find.text('Еда'), findsWidgets);

    // The page has two scrollables (the accounts strip and the page itself),
    // so the page one is addressed explicitly.
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Бюджеты'), findsOneWidget);
    expect(find.text('Требуют внимания: 2'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('dashboard fits 360 px in ${brightness.name} theme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(const DashboardScreen(), brightness: brightness),
      );
      await tester.pumpAndSettle();

      // Scrolling the whole screen surfaces any overflow in the lower cards,
      // which the test framework reports as a failure.
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
