import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walletmate/core/mock/mock_data.dart';
import 'package:walletmate/core/theme/app_theme.dart';
import 'package:walletmate/core/utils/category_catalog.dart';
import 'package:walletmate/core/utils/formatters.dart';
import 'package:walletmate/core/widgets/account_card.dart';
import 'package:walletmate/core/widgets/amount_field.dart';
import 'package:walletmate/core/widgets/app_badge.dart';
import 'package:walletmate/core/widgets/app_buttons.dart';
import 'package:walletmate/core/widgets/app_card.dart';
import 'package:walletmate/core/widgets/app_filter_chip.dart';
import 'package:walletmate/core/widgets/app_toast.dart';
import 'package:walletmate/core/widgets/budget_progress_bar.dart';
import 'package:walletmate/core/widgets/category_badge.dart';
import 'package:walletmate/core/widgets/money_text.dart';
import 'package:walletmate/core/widgets/selector_field.dart';
import 'package:walletmate/core/widgets/skeleton.dart';
import 'package:walletmate/core/widgets/state_views.dart';
import 'package:walletmate/core/widgets/transaction_row.dart';
import 'package:walletmate/core/widgets/type_switch.dart';

Widget _host(Widget child, {required Brightness brightness}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
    locale: const Locale(Formatters.locale),
    supportedLocales: const [Locale(Formatters.locale), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

/// Every component, in each of its states, on one page.
Widget _gallery() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Buttons: enabled, disabled, loading.
      PrimaryButton(label: 'Сохранить', onPressed: () {}),
      const PrimaryButton(label: 'Сохранить', onPressed: null),
      const PrimaryButton(label: 'Сохранить', onPressed: null, loading: true),
      SecondaryButton(
        label: 'Добавить счёт',
        icon: Icons.add,
        onPressed: () {},
      ),
      DestructiveButton(label: 'Удалить счёт', onPressed: () {}),

      // Money at every size, both directions.
      const MoneyText(amount: 4210.50, currency: 'MDL', size: MoneySize.hero),
      const MoneyText(
        amount: 1234.56,
        currency: 'MDL',
        size: MoneySize.large,
        isIncome: true,
      ),
      const MoneyText(amount: 249.90, currency: 'MDL', isIncome: false),
      const MoneyText(amount: 85, currency: 'EUR', size: MoneySize.small),

      // Category marks and badges.
      const Row(
        children: [
          CategoryAvatar(category: 'food'),
          SizedBox(width: 8),
          CategoryBadge(category: 'transport'),
          SizedBox(width: 8),
          AppBadge(label: 'перерасход', tone: BadgeTone.danger),
        ],
      ),

      // Filter chips: default, selected, disabled.
      Row(
        children: [
          AppFilterChip(
            label: 'Категория',
            onTap: () {},
            trailing: Icons.expand_more,
          ),
          const SizedBox(width: 8),
          AppFilterChip(label: 'Еда', selected: true, onTap: () {}),
          const SizedBox(width: 8),
          const AppFilterChip(label: 'Период'),
        ],
      ),

      // Cards and rows.
      AppCard(
        title: 'Бюджеты',
        subtitle: 'Требуют внимания: 2',
        action: TextButton(onPressed: () {}, child: const Text('Все')),
        child: const BudgetProgressBar(
          category: 'transport',
          spentAmount: 640,
          limitAmount: 600,
          currency: 'MDL',
        ),
      ),
      AccountCard(account: mockAccounts.first, onTap: () {}),
      TransactionRow(
        transaction: mockTransactions.first,
        accountName: 'Карта Maib',
        onTap: () {},
      ),
      const TransactionDateHeader(label: 'Сегодня'),

      // Form controls, enabled and disabled.
      const AmountField(currency: 'MDL', isIncome: false),
      const AmountField(
        currency: 'MDL',
        enabled: false,
        errorText: 'Сумма должна быть больше нуля',
      ),
      TypeSwitch(value: TransactionKind.expense, onChanged: (_) {}),
      const TypeSwitch(value: TransactionKind.income),
      SelectorField(label: 'Категория', value: 'Еда', onTap: () {}),
      const SelectorField(label: 'Счёт', placeholder: 'Выберите счёт'),

      // Feedback and placeholder states.
      const AppBanner(message: 'Офлайн — изменения синхронизируются позже'),
      const TransactionListSkeleton(itemCount: 2),
      const CardSkeleton(),
      const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Операций пока нет',
        message: 'Добавьте первую, чтобы увидеть, куда уходят деньги.',
        actionLabel: 'Добавить операцию',
      ),
      const ErrorState(
        title: 'Не удалось загрузить',
        message: 'Проверьте соединение и попробуйте ещё раз.',
      ),
    ],
  );
}

void main() {
  setUpAll(() => initializeDateFormatting(Formatters.locale));

  for (final brightness in Brightness.values) {
    testWidgets('component gallery lays out at 360 px in ${brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_host(_gallery(), brightness: brightness));
      await tester.pump(const Duration(milliseconds: 300));

      // Any overflow during layout is reported as a test failure, so a clean
      // pump is the assertion; this only confirms the page really rendered.
      expect(find.byType(MoneyText), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('money text uses tabular figures at every size', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            MoneyText(amount: 1111.11, currency: 'MDL', size: MoneySize.hero),
            MoneyText(amount: 8888.88, currency: 'MDL', size: MoneySize.large),
            MoneyText(amount: 10, currency: 'MDL'),
            MoneyText(amount: 10, currency: 'MDL', size: MoneySize.small),
          ],
        ),
        brightness: Brightness.dark,
      ),
    );

    final texts = tester.widgetList<Text>(find.byType(Text));
    expect(texts, isNotEmpty);
    for (final text in texts) {
      expect(
        text.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: 'money must never jitter between rows',
      );
    }
  });

  testWidgets('budget row marks the two thresholds with text, not only color', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            BudgetProgressBar(
              category: 'food',
              spentAmount: 1200,
              limitAmount: 1300,
              currency: 'MDL',
            ),
            BudgetProgressBar(
              category: 'transport',
              spentAmount: 640,
              limitAmount: 600,
              currency: 'MDL',
            ),
          ],
        ),
        brightness: Brightness.dark,
      ),
    );

    expect(find.textContaining('перерасход'), findsOneWidget);
    expect(find.textContaining('осталось'), findsOneWidget);
    // Built through the formatter: the ru locale separates the sign with a
    // non-breaking space, which a literal in the test would get wrong.
    expect(find.text(Formatters.percent(1200 / 1300)), findsOneWidget);
  });
}
