import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/data/repository_exception.dart';
import 'package:walletmate/core/network/api_client.dart';
import 'package:walletmate/core/utils/category_catalog.dart';
import 'package:walletmate/features/accounts/data/api_account_repository.dart';
import 'package:walletmate/features/accounts/domain/account.dart';
import 'package:walletmate/features/auth/data/api_auth_repository.dart';
import 'package:walletmate/features/budgets/data/api_budget_repository.dart';
import 'package:walletmate/features/profile/data/api_profile_repository.dart';
import 'package:walletmate/features/transactions/data/api_transaction_repository.dart';

import '../helpers/fake_http.dart';

/// Pages of one list, in the template's `{items, page, limit, total}` shape.
ResponseBody page(List<Map<String, Object?>> items) =>
    json(200, {'items': items, 'page': 1, 'limit': 100, 'total': items.length});

void main() {
  late FakeHttp server;
  late ApiClient api;

  setUp(() {
    server = FakeHttp((_) => json(200, {}));
    api = ApiClient(
      baseUrl: 'http://server:8080',
      token: () => 'jwt',
      onUnauthorized: () {},
      adapter: server,
    );
  });

  test('accounts: integer ids become strings, kind and opening balance '
      'are read', () async {
    server.handler = (_) => page([
      {
        'id': 1,
        'name': 'Карта Maib',
        'currency': 'MDL',
        'kind': 'card',
        'initialBalance': 1250,
        'balance': 10847.2,
        'createdAt': '2026-11-16T10:00:00Z',
      },
    ]);

    final accounts = await ApiAccountRepository(api).fetchAll();

    expect(accounts.single.id, '1');
    expect(accounts.single.kind, AccountKind.card);
    expect(accounts.single.openingBalance, 1250);
  });

  test('accounts: update sends no opening balance', () async {
    server.handler = (request) => json(200, {
      'id': 3,
      ...request.data as Map<String, Object?>,
      'initialBalance': 250,
    });

    await ApiAccountRepository(api).update(
      const Account(
        id: '3',
        name: ' Вклад ',
        currency: 'EUR',
        kind: AccountKind.savings,
        openingBalance: 999,
      ),
    );

    final request = server.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/accounts/3');
    expect(request.data, {
      'name': 'Вклад',
      'currency': 'EUR',
      'kind': 'savings',
    });
  });

  test(
    'transactions: the account id goes out as a number, the date in UTC',
    () async {
      server.handler = (request) =>
          json(201, {'id': 40, ...request.data as Map<String, Object?>});

      final created = await ApiTransactionRepository(api).create(
        accountId: '2',
        amount: 249.9,
        kind: TransactionKind.expense,
        category: 'food',
        date: DateTime.utc(2026, 11, 2, 15, 40),
        note: 'Продукты',
      );

      final body = server.requests.single.data as Map<String, Object?>;
      expect(body['accountId'], 2);
      expect(body['amount'], 249.9);
      expect(body['type'], 'expense');
      expect(body['date'], '2026-11-02T15:40:00.000Z');
      expect(created.id, '40');
      expect(created.accountId, '2');
    },
  );

  test('transactions: fetchAll reads every page', () async {
    server.handler = (request) {
      final number = request.queryParameters['page'] as int;
      return json(200, {
        'items': [
          {
            'id': number,
            'accountId': 1,
            'amount': 10,
            'type': 'expense',
            'category': 'food',
            'date': '2026-11-0${number}T10:00:00Z',
            'note': null,
          },
        ],
        'page': number,
        'limit': 100,
        'total': 2,
      });
    };

    final transactions = await ApiTransactionRepository(api).fetchAll();

    expect(transactions.map((t) => t.id), ['1', '2']);
  });

  test(
    'budgets: limit and month are sent as the contract names them',
    () async {
      server.handler = (request) => json(201, {
        'id': 5,
        ...request.data as Map<String, Object?>,
        'spentAmount': 0,
      });

      final budget = await ApiBudgetRepository(api)
          .create(category: 'food', limitAmount: 1300, month: '2026-11');

      expect(server.requests.single.data, {
        'category': 'food',
        'limitAmount': 1300.0,
        'month': '2026-11',
      });
      expect(budget.id, '5');
    },
  );

  test('profile: the avatar path becomes a full URL', () async {
    server.handler = (_) => json(200, {
      'id': 1,
      'email': 'demo@walletmate.md',
      'displayName': 'Ion Rusu',
      'defaultCurrency': 'MDL',
      'avatarUrl': '/files/7',
    });

    final profile = await ApiProfileRepository(api).fetch();

    expect(profile.avatarUrl, 'http://server:8080/files/7');
  });

  test('profile: an avatar is uploaded, then linked to the profile', () async {
    server.handler = (request) => switch ((request.method, request.path)) {
      ('POST', '/files') => json(201, {'id': 9, 'url': '/files/9'}),
      ('GET', '/profile') => json(200, {
        'id': 1,
        'email': 'demo@walletmate.md',
        'displayName': 'Ion Rusu',
        'defaultCurrency': 'MDL',
        'avatarUrl': null,
      }),
      _ => json(200, {
        'id': 1,
        'email': 'demo@walletmate.md',
        ...request.data as Map<String, Object?>,
        'avatarUrl': '/files/9',
      }),
    };

    final profile = await ApiProfileRepository(
      api,
    ).uploadAvatar(bytes: [1, 2, 3], filename: 'me.png', mimeType: 'image/png');

    expect(server.requests.first.data, isA<FormData>());
    expect(server.requests.last.data, {
      'displayName': 'Ion Rusu',
      'defaultCurrency': 'MDL',
      'avatarFileId': 9,
    });
    expect(profile.avatarUrl, 'http://server:8080/files/9');
  });

  test(
    'auth: the token is returned, a taken email is said in Russian',
    () async {
      final auth = ApiAuthRepository(api);
      server.handler = (_) => json(200, {
        'token': 'jwt-2',
        'user': {'id': 1, 'email': 'a@b.md', 'name': 'A'},
      });
      expect(await auth.login(email: 'a@b.md', password: 'x'), 'jwt-2');

      server.handler = (_) => error(
        409,
        'EMAIL_TAKEN',
        'An account with this email already exists',
      );
      expect(
        () => auth.register(name: 'A', email: 'a@b.md', password: 'Secret123'),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            'Аккаунт с таким email уже есть',
          ),
        ),
      );
    },
  );
}
