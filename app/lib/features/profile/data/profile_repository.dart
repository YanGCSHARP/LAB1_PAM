import '../domain/user_profile.dart';

/// The signed-in user's profile — `GET /auth/me` and its update.
///
/// Every method may throw a `RepositoryException`.
abstract interface class ProfileRepository {
  Future<UserProfile> fetch();

  /// Saves the editable fields: display name and default currency.
  Future<UserProfile> update(UserProfile profile);
}
