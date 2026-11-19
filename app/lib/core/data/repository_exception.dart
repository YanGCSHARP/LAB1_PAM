/// A repository call that did not succeed.
///
/// Repositories translate whatever went wrong underneath — a mock rule now,
/// an HTTP status from the REST client on L5 — into one of these, so screens
/// handle one type and show [message] as is. Messages are user-facing Russian.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The server could not be reached (no network, timeout). Maps to a failed
/// request without a response on L5.
final class NetworkException extends RepositoryException {
  const NetworkException([
    super.message = 'Нет связи с сервером. Проверьте подключение и повторите.',
  ]);
}

/// The record does not exist or belongs to someone else — HTTP 404.
final class NotFoundException extends RepositoryException {
  const NotFoundException([super.message = 'Запись не найдена']);
}

/// The change breaks a uniqueness rule — HTTP 409.
final class ConflictException extends RepositoryException {
  const ConflictException(super.message);
}

/// The server rejected the input — HTTP 400.
final class ValidationException extends RepositoryException {
  const ValidationException(super.message);
}

/// The token is missing, expired or the credentials are wrong — HTTP 401.
/// Outside the sign-in screen it ends the session.
final class UnauthorizedException extends RepositoryException {
  const UnauthorizedException([
    super.message = 'Сессия истекла. Войдите снова.',
  ]);
}

/// The server failed on its side — HTTP 5xx.
final class ServerException extends RepositoryException {
  const ServerException([
    super.message = 'Ошибка на сервере. Повторите попытку позже.',
  ]);
}

/// User-facing text for any error a provider or a repository call produced.
String errorMessage(Object error) => switch (error) {
  RepositoryException(:final message) => message,
  _ => 'Что-то пошло не так. Повторите попытку.',
};
