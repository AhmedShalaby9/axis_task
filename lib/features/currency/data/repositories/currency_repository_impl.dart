import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/data_origin.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/entities/rate_history.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/currency_local_datasource.dart';
import '../datasources/currency_remote_datasource.dart';
import '../models/currency_rate_model.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  CurrencyRepositoryImpl({
    required this.remote,
    required this.local,
    required this.networkInfo,
  });

  final CurrencyRemoteDatasource remote;
  final CurrencyLocalDatasource local;
  final NetworkInfo networkInfo;

  // ── getRatesForDate ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ExchangeRate>>> getRatesForDate(
    DateTime date,
  ) async {
    if (await networkInfo.isConnected) {
      Failure? remoteFailure;

      try {
        final model = await remote.getRatesForDate(date);

        // Best-effort cache write — a storage failure must not affect the
        // successfully fetched data returned to the caller.
        try {
          await local.cacheRates(model);
        } catch (_) {}

        return Right(_toEntities(model, DataOrigin.network));
      } on NetworkException catch (e) {
        remoteFailure = NetworkFailure(message: e.message);
      } on ServerException catch (e) {
        remoteFailure = ServerFailure(statusCode: e.statusCode, message: e.message);
      } on ParsingException catch (e) {
        remoteFailure = ParsingFailure(field: e.field, message: e.message);
      }

      // Remote failed — attempt cache before surfacing the failure.
      return _fromCache(date, fallback: remoteFailure);
    }

    // Offline — go straight to cache.
    return _fromCache(date);
  }

  Future<Either<Failure, List<ExchangeRate>>> _fromCache(
    DateTime date, {
    Failure? fallback,
  }) async {
    try {
      final model = await local.getCachedRates(date);
      return Right(_toEntities(model, DataOrigin.cache));
    } on CacheException catch (e) {
      // Prefer the remote failure (more informative) if we have one.
      return Left(fallback ?? CacheFailure(message: e.message));
    }
  }

  // ── getRateHistory ───────────────────────────────────────────────────────

  /// Fetches [days] daily snapshots in parallel, extracts [code]'s rate from
  /// each, and returns all successful days sorted oldest → newest.
  ///
  /// Partial success: if ≥ 1 day succeeds, returns Right(RateHistory) with
  /// however many points are available. The chart degrades gracefully.
  /// If 0 days succeed, returns Left with the most recent day's failure
  /// (today-most-recent is the most actionable error to surface).
  @override
  Future<Either<Failure, RateHistory>> getRateHistory({
    required String code,
    required int days,
  }) async {
    final today = DateTime.now();
    final dates = List.generate(days, (i) => today.subtract(Duration(days: i)));
    final upperCode = code.toUpperCase();

    // Fire all date requests concurrently — cached days are cheap hits.
    final results = await Future.wait(
      dates.map((date) => getRatesForDate(date)),
    );

    final points = <RatePoint>[];
    Failure? lastFailure;
    var anyFromCache = false;

    // results[0] = today, results[1] = yesterday, … same order as dates.
    for (final result in results) {
      result.fold(
        (failure) => lastFailure = failure,
        (rates) {
          final match = rates.where((r) => r.code == upperCode);
          if (match.isEmpty) return;
          final rate = match.first;
          points.add(RatePoint(date: rate.rateDate, rate: rate.rate));
          if (rate.dataOrigin == DataOrigin.cache) anyFromCache = true;
        },
      );
    }

    if (points.isEmpty) {
      return Left(lastFailure ?? const CacheFailure());
    }

    // Sort ascending (oldest → newest) for the chart's x-axis.
    points.sort((a, b) => a.date.compareTo(b.date));

    // Most-conservative origin: if any point came from cache, the whole
    // history is considered cached (may contain stale data).
    return Right(RateHistory(
      code: upperCode,
      points: points,
      dataOrigin: anyFromCache ? DataOrigin.cache : DataOrigin.network,
    ));
  }

  // ── Mapping ──────────────────────────────────────────────────────────────

  /// Converts a [CurrencyRateModel] to domain entities.
  ///
  /// Inversion: the API returns EGP→X (e.g. egp.usd = 0.0199).
  /// We invert to X→EGP (e.g. 1 USD = 50.24 EGP) here, once, so every
  /// consumer above the repository always works with display-ready rates.
  ///
  /// Guards against a zero raw rate to avoid division-by-zero — in practice
  /// the API never returns 0 for a valid currency, but we must not crash.
  List<ExchangeRate> _toEntities(CurrencyRateModel model, DataOrigin origin) {
    final rateDate = DateTime.parse(model.date);

    return model.rates.entries.map((entry) {
      final code = entry.key.toUpperCase();
      final rawRate = entry.value; // EGP → X  (e.g. 0.019904)
      final invertedRate = rawRate > 0.0 ? 1.0 / rawRate : 0.0; // X → EGP

      return ExchangeRate(
        code: code,
        name: AppConstants.currencyNames[code] ?? code,
        rate: invertedRate,
        rateDate: rateDate,
        dataOrigin: origin,
        // Delta fields intentionally left at their defaults (0 / unknown).
        // GetAllRatesWithChange populates them after comparing two dates.
      );
    }).toList();
  }
}
