import 'package:equatable/equatable.dart';

/// Returned by repositories via Either<Failure, T>.
/// Never thrown — it is a value, not an exception.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Ready to display in the UI as-is, or map to a localised string.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Mirrors [NetworkException]: no connection or request timed out.
final class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'No internet connection. Please check your network.',
  }) : super(message);
}

/// Mirrors [ServerException]: non-2xx response from the remote API.
final class ServerFailure extends Failure {
  const ServerFailure({
    required this.statusCode,
    String message = 'The server returned an error. Please try again later.',
  }) : super(message);

  final int statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// Mirrors [CacheException]: local storage could not be read or written.
final class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'Could not load cached data. Please connect to the internet.',
  }) : super(message);
}

/// Mirrors [ParsingException]: response shape did not match expectations.
final class ParsingFailure extends Failure {
  const ParsingFailure({
    required this.field,
    String message = 'Received unexpected data from the server.',
  }) : super(message);

  final String field;

  @override
  List<Object?> get props => [message, field];
}
