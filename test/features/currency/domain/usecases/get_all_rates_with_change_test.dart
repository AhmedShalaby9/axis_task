import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:axis_task/core/enums/data_origin.dart';
import 'package:axis_task/core/error/failures.dart';
import 'package:axis_task/core/usecase/usecase.dart';
import 'package:axis_task/features/currency/domain/entities/egp_trend.dart';
import 'package:axis_task/features/currency/domain/entities/exchange_rate.dart';
import 'package:axis_task/features/currency/domain/repositories/currency_repository.dart';
import 'package:axis_task/features/currency/domain/usecases/get_all_rates_with_change.dart';

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

/// Minimal entity for test input — delta fields are left at defaults (0/unknown)
/// because the use case is responsible for computing and overwriting them.
ExchangeRate _rate(String code, double rate) => ExchangeRate(
      code: code,
      name: code,
      rate: rate,
      rateDate: DateTime(2026, 8, 28),
      dataOrigin: DataOrigin.network,
    );

/// Stubs two sequential [getRatesForDate] calls on [mock]:
///   call 1 (today)     → [todayResult]
///   call 2 (yesterday) → [yesterdayResult]
void _stubSequential(
  MockCurrencyRepository mock, {
  required Either<Failure, List<ExchangeRate>> todayResult,
  required Either<Failure, List<ExchangeRate>> yesterdayResult,
}) {
  var callCount = 0;
  when(() => mock.getRatesForDate(any())).thenAnswer((_) async {
    callCount++;
    return callCount == 1 ? todayResult : yesterdayResult;
  });
}

void main() {
  late MockCurrencyRepository mockRepository;
  late GetAllRatesWithChange useCase;

  // Today's rates: already-inverted X→EGP values.
  // USD 49.80 < yesterday 50.00 → rate fell → EGP strengthened.
  // EUR 59.00 > yesterday 58.00 → rate rose → EGP weakened.
  final tTodayRates = [
    _rate('USD', 49.80),
    _rate('EUR', 59.00),
    _rate('GBP', 68.27),
    _rate('SAR', 13.40),
    _rate('JPY', 0.3147),
  ];

  final tYesterdayRates = [
    _rate('USD', 50.00),
    _rate('EUR', 58.00),
    _rate('GBP', 68.27),
    _rate('SAR', 13.40),
    _rate('JPY', 0.3200),
  ];

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    mockRepository = MockCurrencyRepository();
    useCase = GetAllRatesWithChange(mockRepository);
  });

  test('makes exactly 2 repository calls regardless of currency count', () async {
    when(() => mockRepository.getRatesForDate(any()))
        .thenAnswer((_) async => Right(tTodayRates));

    await useCase(const NoParams());

    verify(() => mockRepository.getRatesForDate(any())).called(2);
  });

  test(
      'falling inverted rate → EgpTrend.stronger '
      '(USD 49.80 today < 50.00 yesterday: fewer EGP per USD = EGP gained)', () async {
    _stubSequential(mockRepository,
        todayResult: Right(tTodayRates), yesterdayResult: Right(tYesterdayRates));

    final result = await useCase(const NoParams());
    final usd = result.getOrElse(() => []).firstWhere((r) => r.code == 'USD');

    expect(usd.egpTrend, EgpTrend.stronger,
        reason: 'A falling inverted rate means fewer EGP per unit of foreign currency.');
    expect(usd.absoluteDelta, closeTo(-0.20, 0.001));
    expect(usd.percentDelta, closeTo(-0.40, 0.01)); // -0.20 / 50.00 * 100
  });

  test('rising inverted rate → EgpTrend.weaker (EUR 59.00 > 58.00)', () async {
    _stubSequential(mockRepository,
        todayResult: Right(tTodayRates), yesterdayResult: Right(tYesterdayRates));

    final result = await useCase(const NoParams());
    final eur = result.getOrElse(() => []).firstWhere((r) => r.code == 'EUR');

    expect(eur.egpTrend, EgpTrend.weaker);
    expect(eur.absoluteDelta, closeTo(1.00, 0.001));
  });

  test('computes absoluteDelta and percentDelta correctly for all 5 currencies', () async {
    _stubSequential(mockRepository,
        todayResult: Right(tTodayRates), yesterdayResult: Right(tYesterdayRates));

    final result = await useCase(const NoParams());
    final rates = result.getOrElse(() => []);

    final usd = rates.firstWhere((r) => r.code == 'USD');
    final gbp = rates.firstWhere((r) => r.code == 'GBP');

    // USD: (49.80 - 50.00) / 50.00 * 100 = -0.40 %
    expect(usd.absoluteDelta, closeTo(-0.20, 0.001));
    expect(usd.percentDelta, closeTo(-0.40, 0.01));

    // GBP: same rate both days → delta = 0, trend = unchanged
    expect(gbp.absoluteDelta, closeTo(0.0, 0.001));
    expect(gbp.egpTrend, EgpTrend.unchanged);
  });

  test('yesterday request fails entirely → all 5 rates returned with EgpTrend.unknown', () async {
    _stubSequential(mockRepository,
        todayResult: Right(tTodayRates),
        yesterdayResult: Left(const NetworkFailure()));

    final result = await useCase(const NoParams());
    final rates = result.getOrElse(() => []);

    expect(rates.length, 5);
    expect(rates.every((r) => r.egpTrend == EgpTrend.unknown), isTrue,
        reason: 'No yesterday data means no information about direction.');
    expect(rates.every((r) => r.absoluteDelta == 0.0), isTrue);
  });

  test(
      'one currency missing from yesterday → that one unknown, '
      'the other four receive correct deltas', () async {
    final yesterdayWithoutUsd =
        tYesterdayRates.where((r) => r.code != 'USD').toList();
    _stubSequential(mockRepository,
        todayResult: Right(tTodayRates),
        yesterdayResult: Right(yesterdayWithoutUsd));

    final result = await useCase(const NoParams());
    final rates = result.getOrElse(() => []);
    final usd = rates.firstWhere((r) => r.code == 'USD');
    final others = rates.where((r) => r.code != 'USD').toList();

    expect(usd.egpTrend, EgpTrend.unknown);
    expect(others.length, 4);
    expect(others.every((r) => r.egpTrend != EgpTrend.unknown), isTrue);
  });

  test('today fails → Left propagates and yesterday is never fetched', () async {
    when(() => mockRepository.getRatesForDate(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(const NoParams());

    expect(result.isLeft(), isTrue);
    // Exactly one call: today. The short-circuit prevents the yesterday call.
    verify(() => mockRepository.getRatesForDate(any())).called(1);
  });
}
