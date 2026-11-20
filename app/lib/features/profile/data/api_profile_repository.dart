import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

/// [ProfileRepository] over `/profile` of the backend, with the avatar
/// uploaded through the template's `POST /files`.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<UserProfile> fetch() async => _read(await _api.get('/profile'));

  @override
  Future<UserProfile> update(UserProfile profile) async {
    final body = await _api.put('/profile', {
      'displayName': profile.displayName.trim(),
      'defaultCurrency': profile.defaultCurrency,
    });
    return _read(body);
  }

  @override
  Future<UserProfile> uploadAvatar({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    final file = await _api.upload(
      '/files',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
    final current = await _api.get('/profile');
    final body = await _api.put('/profile', {
      'displayName': current['displayName'],
      'defaultCurrency': current['defaultCurrency'],
      'avatarFileId': file['id'],
    });
    return _read(body);
  }

  /// The server sends the avatar as a path (`/files/7`); the app needs a URL
  /// it can load.
  UserProfile _read(Json body) {
    final avatar = body['avatarUrl'] as String?;
    return UserProfile.fromJson({
      ...body,
      'avatarUrl': avatar == null ? null : _api.resolve(avatar),
    });
  }
}
