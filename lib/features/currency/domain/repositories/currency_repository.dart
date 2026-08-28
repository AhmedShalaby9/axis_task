import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/exchange_rate.dart';
import '../entities/rate_history.dart';

abstract interface class CurrencyRepository {
  /// Returns all 5 target currencies' rates for the given [date].
  ///
  /// Rates are already inverted (X→EGP) and entities carry [DataOrigin].
  /// Delta fields are NOT populated here — that is the use case's responsibility.
  Future<Either<Failure, List<ExchangeRate>>> getRatesForDate(DateTime date);

  /// Returns [days] daily rate snapshots for the currency identified by [code].
  ///
  /// [code] is uppercase (e.g. "USD"). [days] defaults to 7 for the detail chart.
  Future<Either<Failure, RateHistory>> getRateHistory({
    required String code,
    required int days,
  });
}
