import '../../../core/data/mock/mock_backend.dart';
import '../../../core/data/repository_exception.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

/// [ProfileRepository] over the in-memory [MockBackend].
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<UserProfile> fetch() => _backend.request(() => _backend.profile);

  @override
  Future<UserProfile> update(UserProfile profile) {
    return _backend.request(() {
      // Only the editable fields are taken; id and email stay the server's.
      final updated = _backend.profile.copyWith(
        displayName: profile.displayName.trim(),
        defaultCurrency: profile.defaultCurrency,
      );
      _backend.profile = updated;
      return updated;
    });
  }

  /// The mock backend keeps no files: an avatar needs the server.
  @override
  Future<UserProfile> uploadAvatar({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) {
    return _backend.request(
      () => throw const ValidationException(
        'Аватар загружается только на сервер. Запустите приложение с backend.',
      ),
    );
  }
}
