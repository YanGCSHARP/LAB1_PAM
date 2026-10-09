import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walletmate/app.dart';
import 'package:walletmate/core/utils/formatters.dart';

void main() {
  setUpAll(() => initializeDateFormatting(Formatters.locale));

  testWidgets('app starts on the login screen', (tester) async {
    await tester.pumpWidget(const WalletMateApp());

    expect(find.text('Вход'), findsWidgets);
    expect(find.text('Куда делись деньги в этом месяце?'), findsOneWidget);
  });

  testWidgets('login screen fits a 360 px wide screen', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WalletMateApp());
    await tester.pumpAndSettle();

    // A layout overflow reports itself as a test failure, so reaching the
    // assertion below means the screen laid out cleanly.
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('signing in opens the shell with four tabs', (tester) async {
    await tester.pumpWidget(const WalletMateApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Панель'), findsWidgets);
    expect(find.text('Транзакции'), findsWidgets);
    expect(find.text('Бюджеты'), findsWidgets);
    expect(find.text('Профиль'), findsWidgets);
  });
}
