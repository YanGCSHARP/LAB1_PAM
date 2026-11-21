/// Sign-in and sign-up — `POST /auth/login` and `POST /auth/register` of the
/// course template. Both return the JWT of the new session.
///
/// Every method may throw a `RepositoryException`: an `UnauthorizedException`
/// for a wrong email or password, a `ConflictException` for an email that is
/// already registered.
abstract interface class AuthRepository {
  Future<String> login({required String email, required String password});

  Future<String> register({
    required String name,
    required String email,
    required String password,
  });
}
