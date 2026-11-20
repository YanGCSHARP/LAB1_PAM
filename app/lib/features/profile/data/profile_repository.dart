import '../domain/user_profile.dart';

/// The signed-in user's profile — `GET /profile` and `PUT /profile`.
///
/// Every method may throw a `RepositoryException`.
abstract interface class ProfileRepository {
  Future<UserProfile> fetch();

  /// Saves the editable fields: display name and default currency.
  Future<UserProfile> update(UserProfile profile);

  /// Uploads an image through `POST /files` and makes it the avatar.
  Future<UserProfile> uploadAvatar({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  });
}
