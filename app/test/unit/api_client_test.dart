import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/data/repository_exception.dart';
import 'package:walletmate/core/network/api_client.dart';

import '../helpers/fake_http.dart';

void main() {
  late FakeHttp server;
  late String? token;
  late int expired;
  late ApiClient api;

  setUp(() {
    server = FakeHttp((_) => json(200, {}));
    token = 'jwt-1';
    expired = 0;
    api = ApiClient(
      baseUrl: 'http://server:8080',
      token: () => token,
      onUnauthorized: () => expired++,
      adapter: server,
    );
  });

  group('requests', () {
    test('carry the session token as Bearer', () async {
      await api.get('/accounts');
      expect(server.requests.single.headers['Authorization'], 'Bearer jwt-1');
    });

    test('go without Authorization when signed out', () async {
      token = null;
      await api.post('/auth/login', {'email': 'a@b.md'});
      expect(server.requests.single.headers, isNot(contains('Authorization')));
    });

    test('drop null query parameters', () async {
      await api.get('/transactions', query: {'type': 'expense', 'q': null});
      expect(server.requests.single.queryParameters, {'type': 'expense'});
    });

    test('resolve a server path to a full URL', () {
      expect(api.resolve('/files/7'), 'http://server:8080/files/7');
    });
  });

  group('template errors become repository exceptions', () {
    Future<Object?> failure() async {
      try {
        await api.get('/accounts/1');
      } on Object catch (error) {
        return error;
      }
      return null;
    }

    test('400 keeps the server message', () async {
      server.handler = (_) =>
          error(400, 'VALIDATION_ERROR', 'Сумма должна быть больше нуля');
      final result = await failure();
      expect(result, isA<ValidationException>());
      expect(
        (result! as ValidationException).message,
        'Сумма должна быть больше нуля',
      );
    });

    test('404 and 409 keep the server message', () async {
      server.handler = (_) => error(404, 'NOT_FOUND', 'Счёт не найден');
      expect(
        await failure(),
        isA<NotFoundException>().having(
          (e) => e.message,
          'message',
          'Счёт не найден',
        ),
      );

      server.handler = (_) =>
          error(409, 'CONFLICT', 'Счёт с таким названием уже есть');
      expect(await failure(), isA<ConflictException>());
    });

    test('5xx is a server failure with a Russian message', () async {
      server.handler = (_) => error(500, 'INTERNAL', 'Unexpected server error');
      final result = await failure();
      expect(result, isA<ServerException>());
      expect((result! as ServerException).message, contains('сервере'));
    });

    test('no answer at all is a network failure', () async {
      server.handler = unreachable;
      expect(await failure(), isA<NetworkException>());
    });

    test('401 on a request with a token ends the session', () async {
      server.handler = (_) => error(401, 'UNAUTHORIZED', 'Missing token');
      expect(await failure(), isA<UnauthorizedException>());
      expect(expired, 1);
    });

    test('401 without a token is wrong credentials, not an expiry', () async {
      token = null;
      server.handler = (_) => error(401, 'UNAUTHORIZED', 'Invalid email');
      final result = await failure();
      expect(
        (result! as UnauthorizedException).message,
        'Неверный email или пароль',
      );
      expect(expired, 0);
    });
  });

  group('getAll', () {
    test('walks the pages with the largest page size', () async {
      server.handler = (request) {
        final page = request.queryParameters['page'] as int;
        expect(request.queryParameters['limit'], ApiClient.maxPageSize);
        return json(200, {
          'items': page == 1
              ? List.generate(100, (i) => {'id': i})
              : List.generate(30, (i) => {'id': 100 + i}),
          'page': page,
          'limit': 100,
          'total': 130,
        });
      };

      final items = await api.getAll('/transactions');

      expect(items, hasLength(130));
      expect(server.requests, hasLength(2));
    });

    test('stops at an empty page', () async {
      server.handler = (_) =>
          json(200, {'items': <Object>[], 'page': 1, 'limit': 100, 'total': 0});
      expect(await api.getAll('/budgets'), isEmpty);
      expect(server.requests, hasLength(1));
    });
  });
}
