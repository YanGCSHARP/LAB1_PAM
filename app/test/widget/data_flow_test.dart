import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walletmate/app.dart';
import 'package:walletmate/core/data/mock/mock_providers.dart';
import 'package:walletmate/core/utils/formatters.dart';
import 'package:walletmate/core/widgets/amount_field.dart';
import 'package:walletmate/core/widgets/app_buttons.dart';
import 'package:walletmate/core/widgets/skeleton.dart';
import 'package:walletmate/core/widgets/state_views.dart';
import 'package:walletmate/features/dashboard/application/dashboard_providers.dart';
import 'package:walletmate/features/transactions/application/transactions_providers.dart';

import '../helpers/test_app.dart';

Future<void> _enterAmount(WidgetTester tester, String amount) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(AmountField),
      matching: find.byType(TextField),
    ),
    amount,
  );
  await tester.pumpAndSettle();
}

Future<void> _pickCategory(WidgetTester tester, String label) async {
  await tester.tap(find.text('Выберите категорию'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(PrimaryButton, 'Сохранить'));
  await tester.pumpAndSettle();
}

/// Scrolls the dashboard down to its budgets card and returns the line that
/// counts budgets needing attention.
Future<Finder> _budgetsSummary(WidgetTester tester) async {
  final summary = find.textContaining('Требуют внимания');
  await tester.scrollUntilVisible(
    summary,
    300,
    scrollable: find
        .descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  return summary;
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting(Formatters.locale));

  group('loading and errors', () {
    testWidgets('a skeleton shows while the list loads', (tester) async {
      await tester.pumpWidget(
        withProviders(
          const WalletMateApp(signedIn: true, initialLocation: '/transactions'),
          latency: const Duration(milliseconds: 350),
        ),
      );
      await tester.pump();

      expect(find.byType(TransactionListSkeleton), findsOneWidget);
      expect(find.text('Кофе и выпечка'), findsNothing);

      // Accounts and operations are requested together: one delay, not two.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byType(TransactionListSkeleton), findsNothing);
      expect(find.text('Кофе и выпечка'), findsOneWidget);
    });

    testWidgets('a failed load shows the error, «Повторить» recovers', (
      tester,
    ) async {
      await pumpApp(tester, '/profile');

      await tester.tap(find.text('Имитировать сбой сети'));
      await tester.pumpAndSettle();
      await _openTab(tester, 'Транзакции');

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Не удалось загрузить данные'), findsOneWidget);
      expect(find.textContaining('Нет связи с сервером'), findsOneWidget);

      appContainer(tester)
          .read(simulateOfflineProvider.notifier)
          .set(offline: false);
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text('Кофе и выпечка'), findsOneWidget);
    });

    testWidgets('a failed save keeps the form and what was typed', (
      tester,
    ) async {
      await pumpApp(tester, '/transactions/new');
      await _enterAmount(tester, '75');
      await _pickCategory(tester, 'Еда');

      appContainer(tester)
          .read(simulateOfflineProvider.notifier)
          .set(offline: true);
      await _tapSave(tester);

      expect(find.textContaining('Нет связи с сервером'), findsOneWidget);
      expect(find.text('Новая операция'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });
  });

  group('changes reach every screen', () {
    testWidgets('a new expense appears in the list and on the dashboard', (
      tester,
    ) async {
      await pumpApp(tester, '/dashboard');
      expect(
        tester.widget<Text>(await _budgetsSummary(tester)).data,
        'Требуют внимания: 2',
      );

      await _openTab(tester, 'Транзакции');
      await tester.tap(find.text('Операция'));
      await tester.pumpAndSettle();

      // 420 + 400 of a 800 limit pushes «Покупки» over.
      await _enterAmount(tester, '400');
      await _pickCategory(tester, 'Покупки');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Заметка'),
        'Наушники',
      );
      await tester.pumpAndSettle();
      await _tapSave(tester);

      expect(find.text('Операция добавлена'), findsOneWidget);
      expect(find.text('Наушники'), findsOneWidget);

      await _openTab(tester, 'Панель');
      expect(
        tester.widget<Text>(await _budgetsSummary(tester)).data,
        'Требуют внимания: 3',
      );

      final data = appContainer(tester)
          .read(dashboardProvider('2026-09'))
          .value!;
      expect(data.summary.totalExpense, 5380);
    });

    testWidgets('an edit is shown on the card it returns to', (tester) async {
      await pumpApp(tester, '/transactions/tx-17');
      await tester.tap(find.byTooltip('Изменить'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Заметка'),
        'Кофе с круассаном',
      );
      await tester.pumpAndSettle();
      await _tapSave(tester);

      expect(find.text('Изменения сохранены'), findsOneWidget);
      expect(find.text('Кофе с круассаном'), findsOneWidget);
      expect(find.text('Кофе и выпечка'), findsNothing);
    });

    testWidgets('a deleted operation leaves the list', (tester) async {
      await pumpApp(tester, '/transactions/tx-17');

      await tester.tap(
        find.widgetWithText(DestructiveButton, 'Удалить операцию'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
      await tester.pumpAndSettle();

      expect(find.text('Операция удалена'), findsOneWidget);
      expect(find.text('Страница не найдена'), findsNothing);
      expect(find.text('Кофе и выпечка'), findsNothing);
      expect(find.text('Вёрстка лендинга'), findsOneWidget);
    });

    testWidgets('a deleted account takes its operations along', (tester) async {
      await pumpApp(tester, '/accounts/acc-2/edit');

      await tester.tap(find.widgetWithText(DestructiveButton, 'Удалить счёт'));
      await tester.pumpAndSettle();
      // Six operations in September and two in August are on this account.
      expect(find.textContaining('будут удалены 8 операций'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
      await tester.pumpAndSettle();

      expect(find.text('Счёт удалён'), findsOneWidget);
      expect(find.text('Наличные'), findsNothing);
      expect(find.text('Карта Maib'), findsOneWidget);

      final transactions = appContainer(tester)
          .read(transactionsProvider)
          .value!;
      expect(transactions.where((t) => t.accountId == 'acc-2'), isEmpty);
    });

    testWidgets('a new account is listed and offered in the form', (
      tester,
    ) async {
      await pumpApp(tester, '/accounts');
      await tester.tap(find.text('Счёт'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Название'),
        'Карта Victoriabank',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Начальный баланс'),
        '500',
      );
      await tester.pumpAndSettle();
      await _tapSave(tester);

      expect(find.text('Счёт создан'), findsOneWidget);
      expect(find.text('Карта Victoriabank'), findsOneWidget);
    });

    testWidgets('a new budget appears in its month', (tester) async {
      await pumpApp(tester, '/budgets');
      expect(find.text('Образование'), findsNothing);

      await tester.tap(find.text('Бюджет'));
      await tester.pumpAndSettle();
      await _pickCategory(tester, 'Образование');
      await tester.enterText(find.byType(TextFormField), '500');
      await tester.pumpAndSettle();
      await _tapSave(tester);

      expect(find.text('Бюджет создан'), findsOneWidget);
      expect(find.text('Образование'), findsOneWidget);
    });

    testWidgets('a renamed profile keeps the new name', (tester) async {
      await pumpApp(tester, '/profile');
      expect(find.text('IR'), findsOneWidget);

      await tester.tap(find.text('Ion Rusu'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Имя'),
        'Ana Popa',
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text('Имя обновлено'), findsOneWidget);
      expect(find.text('Ana Popa'), findsOneWidget);
      expect(find.text('AP'), findsOneWidget);

      // Still there after a round trip through another tab.
      await _openTab(tester, 'Панель');
      await _openTab(tester, 'Профиль');
      expect(find.text('Ana Popa'), findsOneWidget);
    });

    testWidgets('the dashboard steps to the previous month', (tester) async {
      await pumpApp(tester, '/dashboard');
      expect(find.text('Сентябрь 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Предыдущий месяц'));
      await tester.pumpAndSettle();

      expect(find.text('Август 2026'), findsOneWidget);
      // No budgets were set for August.
      expect(find.text('Бюджетов нет'), findsOneWidget);
    });
  });
}
