import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Base contract for all use cases.
///
/// [Type] is the success value.
/// [Params] is the input; use [NoParams] for use cases that need no arguments.
abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Passed to [UseCase.call] when a use case requires no input.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
