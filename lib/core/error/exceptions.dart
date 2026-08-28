/// Thrown by data sources only. Never crosses the repository boundary.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

/// No network connection, or the request timed out.
final class NetworkException extends AppException {
  const NetworkException({
    String message = 'No internet connection. Please check your network.',
  }) : super(message);
}

/// The server responded with a non-2xx status code.
final class ServerException extends AppException {
  const ServerException({
    required this.statusCode,
    String message = 'An unexpected server error occurred.',
  }) : super(message);

  final int statusCode;
}

/// Local cache read or write failed (key missing, corrupt data, I/O error).
final class CacheException extends AppException {
  const CacheException({
    String message = 'Failed to access locally cached data.',
  }) : super(message);
}

/// JSON decoding succeeded but the payload did not match the expected shape.
final class ParsingException extends AppException {
  const ParsingException({
    required this.field,
    String message = 'Failed to parse the server response.',
  }) : super(message);

  /// The field or key that caused the failure — aids debugging.
  final String field;
}
