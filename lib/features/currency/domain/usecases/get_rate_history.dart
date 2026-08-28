import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/rate_history.dart';
import '../repositories/currency_repository.dart';

class RateHistoryParams extends Equatable {
  const RateHistoryParams({required this.code, this.days = 7});

  /// ISO 4217 code, uppercase. E.g. "USD".
  final String code;

  /// Number of daily snapshots to retrieve. Defaults to 7 for the detail chart.
  final int days;

  @override
  List<Object?> get props => [code, days];
}

class GetRateHistory implements UseCase<RateHistory, RateHistoryParams> {
  GetRateHistory(this._repository);

  final CurrencyRepository _repository;

  @override
  Future<Either<Failure, RateHistory>> call(RateHistoryParams params) {
    return _repository.getRateHistory(code: params.code, days: params.days);
  }
}
