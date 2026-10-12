import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walletmate/app.dart';
import 'package:walletmate/core/utils/formatters.dart';
import 'package:walletmate/core/widgets/amount_field.dart';
import 'package:walletmate/core/widgets/app_buttons.dart';
import 'package:walletmate/core/widgets/app_filter_chip.dart';

Future<void> _open(
  WidgetTester tester,
  String location, {
  bool signedIn = true,
}) async {
  // Tall enough for every form to fit without scrolling.
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    WalletMateApp(signedIn: signedIn, initialLocation: location),
  );
  await tester.pumpAndSettle();
}

/// `tester.pageBack()` looks for the English "Back" tooltip; the app runs in
/// Russian, so the back button is found by type instead.
Future<void> _back(WidgetTester tester) => tester.tap(find.byType(BackButton));

PrimaryButton _saveButton(WidgetTester tester) => tester.widget<PrimaryButton>(
  find.widgetWithText(PrimaryButton, 'Сохранить'),
);

void main() {
  setUpAll(() => initializeDateFormatting(Formatters.locale));

  group('auth', () {
    testWidgets('empty sign-in shows field errors and stays on login', (
      tester,
    ) async {
      await _open(tester, '/login', signedIn: false);

      await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
      await tester.pumpAndSettle();

      expect(find.text('Введите email'), findsOneWidget);
      expect(find.text('Введите пароль'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('registration checks password strength and confirmation', (
      tester,
    ) async {
      await _open(tester, '/login', signedIn: false);
      await tester.tap(find.text('Зарегистрироваться'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Ion');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'ion@utm.md',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Пароль'),
        'short',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Повторите пароль'),
        'other',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Создать аккаунт'));
      await tester.pumpAndSettle();

      expect(find.text('Минимум 8 символов'), findsOneWidget);
      expect(find.text('Пароли не совпадают'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Пароль'),
        'Student2026',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Повторите пароль'),
        'Student2026',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Создать аккаунт'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('a deep link while signed out lands on login', (tester) async {
      await _open(tester, '/transactions/tx-01', signedIn: false);

      expect(find.text('Рады видеть снова'), findsOneWidget);
    });

    testWidgets('signing out returns to the login screen', (tester) async {
      await _open(tester, '/profile');

      await tester.tap(find.widgetWithText(DestructiveButton, 'Выйти'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Выйти'));
      await tester.pumpAndSettle();

      expect(find.text('Рады видеть снова'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('routes', () {
    testWidgets('a deep link opens the transaction card', (tester) async {
      await _open(tester, '/transactions/tx-01');

      expect(find.text('Операция'), findsOneWidget);
      expect(find.text('Стипендия за сентябрь'), findsOneWidget);
    });

    testWidgets('an unknown path shows the 404 screen', (tester) async {
      await _open(tester, '/no-such-page');

      expect(find.text('Страница не найдена'), findsOneWidget);

      await tester.tap(find.text('На главную'));
      await tester.pumpAndSettle();
      expect(find.text('Структура расходов'), findsOneWidget);
    });

    testWidgets('an unknown id shows the 404 screen', (tester) async {
      await _open(tester, '/transactions/tx-999');

      expect(find.text('Страница не найдена'), findsOneWidget);
    });

    testWidgets('a tab keeps its stack while another tab is open', (
      tester,
    ) async {
      await _open(tester, '/transactions');

      await tester.tap(find.text('Кофе и выпечка'));
      await tester.pumpAndSettle();
      expect(find.text('Операция'), findsOneWidget);

      await tester.tap(find.text('Бюджеты').last);
      await tester.pumpAndSettle();
      expect(find.text('Операция'), findsNothing);

      await tester.tap(find.text('Транзакции').last);
      await tester.pumpAndSettle();
      expect(find.text('Операция'), findsOneWidget);
      expect(find.text('Кофе и выпечка'), findsOneWidget);
    });

    testWidgets('a chart legend row opens the filtered list', (tester) async {
      await _open(tester, '/dashboard');

      await tester.tap(find.text('Жильё'));
      await tester.pumpAndSettle();

      final chip = tester.widget<AppFilterChip>(
        find.widgetWithText(AppFilterChip, 'Жильё'),
      );
      expect(chip.selected, isTrue);
      expect(find.text('Аренда квартиры'), findsOneWidget);
      expect(find.text('Стипендия за сентябрь'), findsNothing);
    });

    testWidgets('the accounts screen opens from the profile', (tester) async {
      await _open(tester, '/profile');

      await tester.tap(find.text('Мои счета'));
      await tester.pumpAndSettle();
      expect(find.text('Всего на счетах'), findsOneWidget);

      await _back(tester);
      await tester.pumpAndSettle();
      expect(find.text('Валюта по умолчанию'), findsOneWidget);
    });
  });

  group('transaction form', () {
    testWidgets('save is enabled only once the form is valid', (tester) async {
      await _open(tester, '/transactions/new');

      expect(_saveButton(tester).onPressed, isNull);

      await tester.enterText(
        find.descendant(
          of: find.byType(AmountField),
          matching: find.byType(TextField),
        ),
        '0',
      );
      await tester.pumpAndSettle();
      expect(find.text('Сумма должна быть больше нуля'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(AmountField),
          matching: find.byType(TextField),
        ),
        '125,50',
      );
      await tester.pumpAndSettle();
      expect(_saveButton(tester).onPressed, isNull, reason: 'no category');

      await tester.tap(find.text('Выберите категорию'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Еда'));
      await tester.pumpAndSettle();

      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('switching type clears a category of the other side', (
      tester,
    ) async {
      await _open(tester, '/transactions/tx-02/edit');
      expect(find.text('Еда'), findsOneWidget);

      await tester.tap(find.text('Доход'));
      await tester.pumpAndSettle();

      expect(find.text('Выберите категорию'), findsWidgets);
      expect(_saveButton(tester).onPressed, isNull);
    });

    testWidgets('leaving with unsaved edits asks first', (tester) async {
      await _open(tester, '/transactions');
      await tester.tap(find.text('Операция'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(AmountField),
          matching: find.byType(TextField),
        ),
        '50',
      );
      await tester.pumpAndSettle();

      await _back(tester);
      await tester.pumpAndSettle();
      expect(find.text('Отменить изменения?'), findsOneWidget);

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(find.text('Новая операция'), findsOneWidget);

      await _back(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Не сохранять'));
      await tester.pumpAndSettle();
      expect(find.text('Новая операция'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('an untouched form closes without asking', (tester) async {
      await _open(tester, '/transactions');
      await tester.tap(find.text('Операция'));
      await tester.pumpAndSettle();

      await _back(tester);
      await tester.pumpAndSettle();

      expect(find.text('Отменить изменения?'), findsNothing);
      expect(find.text('Новая операция'), findsNothing);
    });

    testWidgets('saving closes the form despite the guard', (tester) async {
      await _open(tester, '/transactions/tx-02');
      await tester.tap(find.byTooltip('Изменить'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(AmountField),
          matching: find.byType(TextField),
        ),
        '300',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text('Отменить изменения?'), findsNothing);
      expect(find.text('Изменения сохранены'), findsOneWidget);
      // Back on the card the form was opened from.
      expect(find.text('Продукты, Linella'), findsOneWidget);
    });
  });

  group('budget form', () {
    testWidgets('a second budget for the same category and month is refused', (
      tester,
    ) async {
      await _open(tester, '/budgets/new?month=2026-09');

      await tester.tap(find.text('Выберите категорию'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Еда'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '500');
      await tester.pumpAndSettle();

      expect(
        find.text('На этот месяц бюджет по категории уже есть'),
        findsOneWidget,
      );
      expect(_saveButton(tester).onPressed, isNull);

      // The same category is fine in another month.
      await tester.tap(find.text('Сентябрь 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Октябрь 2026'));
      await tester.pumpAndSettle();

      expect(
        find.text('На этот месяц бюджет по категории уже есть'),
        findsNothing,
      );
      expect(_saveButton(tester).onPressed, isNotNull);
    });
  });

  group('account form', () {
    testWidgets('a duplicate account name is refused', (tester) async {
      await _open(tester, '/accounts/new');

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Название'),
        'наличные',
      );
      await tester.pumpAndSettle();

      expect(find.text('Счёт с таким названием уже есть'), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNull);
    });
  });
}
