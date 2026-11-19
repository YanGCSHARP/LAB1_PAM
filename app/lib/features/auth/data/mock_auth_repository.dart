import '../../../core/data/mock/mock_backend.dart';
import 'auth_repository.dart';

/// [AuthRepository] of the mock backend: any well-formed credentials sign
/// in to the demo profile. The forms validate the input before calling it.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._backend);

  final MockBackend _backend;

  static const String token = 'mock-token';

  @override
  Future<String> login({required String email, required String password}) =>
      _backend.request(() => token);

  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) => _backend.request(() {
    _backend.profile = _backend.profile.copyWith(displayName: name);
    return token;
  });
}
