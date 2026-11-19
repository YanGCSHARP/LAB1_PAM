import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_service.dart';
import '../data/repository_exception.dart';
import '../state/app_session.dart';
import 'api_config.dart';

/// JSON object as the backend sends it.
typedef Json = Map<String, dynamic>;

/// The one door to the backend.
///
/// Adds the JWT of the current session to every request and turns every
/// failure into a [RepositoryException], so repositories and screens never
/// see Dio types. The server speaks the course template's contract: errors
/// come as `{"error": {"code", "message"}}`, lists as
/// `{items, page, limit, total}`.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required String? Function() token,
    required this.onUnauthorized,
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 15),
           contentType: Headers.jsonContentType,
         ),
       ) {
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
    }
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final jwt = token();
          if (jwt != null) {
            options.headers['Authorization'] = 'Bearer $jwt';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  /// Called when a request that carried a token gets 401.
  final void Function() onUnauthorized;

  /// Page size used when a whole collection is needed — the template's
  /// maximum.
  static const int maxPageSize = 100;

  Future<Json> get(String path, {Map<String, Object?>? query}) =>
      _send(() => _dio.get<Object?>(path, queryParameters: _clean(query)));

  Future<Json> post(String path, Json body) =>
      _send(() => _dio.post<Object?>(path, data: body));

  Future<Json> put(String path, Json body) =>
      _send(() => _dio.put<Object?>(path, data: body));

  Future<void> delete(String path) => _send(() => _dio.delete<Object?>(path));

  /// `POST /files` of the template: one multipart field named `file`.
  Future<Json> upload(
    String path, {
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    return _send(() => _dio.post<Object?>(path, data: form));
  }

  /// Every item of a paginated list: walks `page=1, 2, …` with the largest
  /// page size until `total` items have arrived.
  Future<List<Json>> getAll(String path, {Map<String, Object?>? query}) async {
    final items = <Json>[];
    for (var page = 1; ; page++) {
      final body = await get(
        path,
        query: {...?query, 'page': page, 'limit': maxPageSize},
      );
      final batch = (body['items'] as List).cast<Json>();
      items.addAll(batch);
      final total = body['total'] as int;
      if (batch.isEmpty || items.length >= total) {
        return items;
      }
    }
  }

  /// Full URL of a path the server returned, e.g. an avatar's `/files/7`.
  String resolve(String path) =>
      Uri.parse(_dio.options.baseUrl).resolve(path).toString();

  static Map<String, Object?>? _clean(Map<String, Object?>? query) =>
      query == null
      ? null
      : {for (final MapEntry(:key, :value) in query.entries) key: ?value};

  Future<Json> _send(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      return data is Json ? data : const {};
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  RepositoryException _translate(DioException error) {
    final response = error.response;
    if (response == null) {
      // No answer at all: no network, refused connection, timeout.
      return const NetworkException();
    }
    final message = _serverMessage(response.data);
    final status = response.statusCode ?? 0;
    final hadToken = error.requestOptions.headers.containsKey('Authorization');
    return switch (status) {
      400 => ValidationException(message ?? 'Проверьте введённые данные'),
      401 when hadToken => _expire(),
      401 => const UnauthorizedException('Неверный email или пароль'),
      404 => NotFoundException(message ?? 'Запись не найдена'),
      409 => ConflictException(message ?? 'Такая запись уже есть'),
      >= 500 => const ServerException(),
      _ => ServerException('Неожиданный ответ сервера ($status)'),
    };
  }

  /// A request with a token got 401: the token expired or was revoked, so
  /// the session ends and the router returns to the sign-in screen.
  RepositoryException _expire() {
    onUnauthorized();
    return const UnauthorizedException();
  }

  static String? _serverMessage(Object? body) {
    if (body case {'error': {'message': final String message}}) {
      return message;
    }
    return null;
  }
}

/// The app's [ApiClient]: the current session's token, and a 401 on an
/// authorized request signs the session out.
final apiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.watch(authSessionProvider);
  return ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    token: () => session.token,
    // Read lazily: the auth service itself depends on this client.
    onUnauthorized: () => ref.read(authServiceProvider).expire(),
  );
});
