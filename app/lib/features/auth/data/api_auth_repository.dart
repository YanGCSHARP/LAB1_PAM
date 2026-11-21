import '../../../core/data/repository_exception.dart';
import '../../../core/network/api_client.dart';
import 'auth_repository.dart';

/// [AuthRepository] over the backend. The template answers in English;
/// the two answers a person can cause are translated here.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final body = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return body['token'] as String;
  }

  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final body = await _api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });
      return body['token'] as String;
    } on ConflictException {
      throw const ConflictException('Аккаунт с таким email уже есть');
    }
  }
}
