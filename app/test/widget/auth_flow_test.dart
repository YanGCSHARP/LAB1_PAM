import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walletmate/app.dart';
import 'package:walletmate/core/data/repository_exception.dart';
import 'package:walletmate/core/network/token_storage.dart';
import 'package:walletmate/core/state/app_session.dart';
import 'package:walletmate/core/utils/formatters.dart';
import 'package:walletmate/features/auth/application/auth_service.dart';
import 'package:walletmate/features/auth/data/auth_repository.dart';

import '../helpers/test_app.dart';

/// Accepts one password and hands out numbered tokens.
class _FakeAuth implements AuthRepository {
  int issued = 0;

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    if (password != 'Demo1234') {
      throw const UnauthorizedException('Неверный email или пароль');
    }
    return 'jwt-${++issued}';
  }

  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async => throw const ConflictException('Аккаунт с таким email уже есть');
}

void main() {
  setUpAll(() => initializeDateFormatting(Formatters.locale));

  late _FakeAuth auth;
  late MemoryTokenStorage storage;

  setUp(() {
    auth = _FakeAuth();
    storage = MemoryTokenStorage();
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    String location = '/login',
  }) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(),
          authRepositoryProvider.overrideWithValue(auth),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child: WalletMateApp(initialLocation: location),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester, String password) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'demo@walletmate.md',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      password,
    );
    await tester.tap(find.text('Войти').last);
    await tester.pumpAndSettle();
  }

  testWidgets('a wrong password is reported and the form stays', (
    tester,
  ) async {
    await pumpLogin(tester);

    await signIn(tester, 'wrong-password');

    expect(find.text('Неверный email или пароль'), findsOneWidget);
    expect(find.text('Вход'), findsOneWidget);
    expect(await storage.read(), isNull);
  });

  testWidgets('signing in stores the token and opens the dashboard', (
    tester,
  ) async {
    await pumpLogin(tester);

    await signIn(tester, 'Demo1234');

    expect(await storage.read(), 'jwt-1');
    expect(find.text('Панель'), findsWidgets);
    final session = ProviderScope.containerOf(
      tester.element(find.byType(WalletMateApp)),
    ).read(authSessionProvider);
    expect(session.token, 'jwt-1');
  });

  testWidgets('a taken email on sign-up is reported', (tester) async {
    await pumpLogin(tester, location: '/register');

    await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Ion');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'demo@walletmate.md',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'Secret123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Повторите пароль'),
      'Secret123',
    );
    await tester.tap(find.text('Создать аккаунт'));
    await tester.pumpAndSettle();

    expect(find.text('Аккаунт с таким email уже есть'), findsOneWidget);
    expect(find.text('Регистрация'), findsOneWidget);
  });

  testWidgets('signing out clears the token and returns to the login', (
    tester,
  ) async {
    await pumpLogin(tester);
    await signIn(tester, 'Demo1234');

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Профиль'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Выйти').last, 200);
    await tester.tap(find.text('Выйти').last);
    await tester.pumpAndSettle();
    // The confirmation dialog.
    await tester.tap(find.text('Выйти').last);
    await tester.pumpAndSettle();

    expect(await storage.read(), isNull);
    expect(find.text('Вход'), findsOneWidget);
  });

  test('a stored token restores the session on start', () async {
    await storage.write('jwt-saved');
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        tokenStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authServiceProvider).restore();

    final session = container.read(authSessionProvider);
    expect(session.isSignedIn, isTrue);
    expect(session.token, 'jwt-saved');
  });

  test('an expired token signs out and forgets the token', () async {
    await storage.write('jwt-old');
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        tokenStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authServiceProvider).restore();

    container.read(authServiceProvider).expire();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authSessionProvider).isSignedIn, isFalse);
    expect(await storage.read(), isNull);
  });
}
