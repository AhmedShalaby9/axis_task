import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/egp_trend.dart';
import '../entities/exchange_rate.dart';
import '../repositories/currency_repository.dart';

/// Fetches all 5 currency rates with their 24-hour deltas in exactly 2 API calls.
///
/// Call 1 → today's rates.
/// Call 2 → yesterday's rates.
///
/// Sign convention (applied to already-inverted X→EGP rates):
///   absoluteDelta = today.rate − yesterday.rate
///   delta < 0  →  fewer EGP per unit  →  EGP strengthened  →  EgpTrend.stronger
///   delta > 0  →  more EGP per unit   →  EGP weakened      →  EgpTrend.weaker
///   delta = 0  →  no change           →                     →  EgpTrend.unchanged
///
/// Edge case — yesterday's request fails:
///   Today's rates are returned with absoluteDelta = 0, percentDelta = 0,
///   egpTrend = unknown for ALL currencies. Rationale: the rates list is the
///   primary feature; deltas are supplementary. A failed comparison must not
///   block a fully valid today snapshot. Unknown (not unchanged) because we
///   have no information — the rate may well have moved.
///
/// Edge case — currency present today but absent from yesterday's response:
///   That specific currency gets egpTrend = unknown while all other currencies
///   that DO have yesterday data receive correct deltas.
class GetAllRatesWithChange
    implements UseCase<List<ExchangeRate>, NoParams> {
  GetAllRatesWithChange(this._repository);

  final CurrencyRepository _repository;

  @override
  Future<Either<Failure, List<ExchangeRate>>> call(NoParams params) async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // ── Request 1: today ────────────────────────────────────────────────────
    final todayResult = await _repository.getRatesForDate(today);

    // Today's failure is unrecoverable — propagate it.
    if (todayResult.isLeft()) return todayResult;
    final todayRates = todayResult.getOrElse(() => []);

    // ── Request 2: yesterday ────────────────────────────────────────────────
    final yesterdayResult = await _repository.getRatesForDate(yesterday);

    // Yesterday's failure degrades gracefully: null sentinel → all deltas unknown.
    final Map<String, ExchangeRate>? yesterdayByCode = yesterdayResult.fold(
      (_) => null,
      (rates) => {for (final r in rates) r.code: r},
    );

    // ── Compute deltas ──────────────────────────────────────────────────────
    final decorated = todayRates.map((todayRate) {
      // yesterdayByCode is null when the entire yesterday request failed.
      // A missing key means this specific currency was absent from yesterday.
      // Both cases are genuinely unknown — not "unchanged".
      final yesterdayRate = yesterdayByCode?[todayRate.code];

      if (yesterdayRate == null) {
        return todayRate.copyWith(
          absoluteDelta: 0.0,
          percentDelta: 0.0,
          egpTrend: EgpTrend.unknown,
        );
      }

      final absoluteDelta = todayRate.rate - yesterdayRate.rate;
      final percentDelta = yesterdayRate.rate != 0.0
          ? (absoluteDelta / yesterdayRate.rate) * 100.0
          : 0.0;

      // Sign convention — see class-level doc.
      final egpTrend = switch (absoluteDelta) {
        < 0 => EgpTrend.stronger,
        > 0 => EgpTrend.weaker,
        _ => EgpTrend.unchanged,
      };

      return todayRate.copyWith(
        absoluteDelta: absoluteDelta,
        percentDelta: percentDelta,
        egpTrend: egpTrend,
      );
    }).toList();

    return Right(decorated);
  }
}
