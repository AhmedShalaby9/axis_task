import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:axis_task/core/enums/data_origin.dart';
import 'package:axis_task/core/error/failures.dart';
import 'package:axis_task/core/network/network_info.dart';
import 'package:axis_task/core/usecase/usecase.dart';
import 'package:axis_task/features/currency/domain/entities/exchange_rate.dart';
import 'package:axis_task/features/currency/domain/usecases/get_all_rates_with_change.dart';
import 'package:axis_task/features/currency/presentation/bloc/rates_list/rates_list_bloc.dart';

class MockGetAllRatesWithChange extends Mock implements GetAllRatesWithChange {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

ExchangeRate _rate(String code) => ExchangeRate(
      code: code,
      name: code,
      rate: 50.0,
      rateDate: DateTime(2026, 8, 28),
      dataOrigin: DataOrigin.network,
    );

void main() {
  late MockGetAllRatesWithChange mockUseCase;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<bool> connectivityController;

  final tRates = ['USD', 'EUR', 'GBP', 'SAR', 'JPY'].map(_rate).toList();

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockUseCase = MockGetAllRatesWithChange();
    mockNetworkInfo = MockNetworkInfo();
    connectivityController = StreamController<bool>();
    when(() => mockNetworkInfo.connectivityStream)
        .thenAnswer((_) => connectivityController.stream);
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
  });

  tearDown(() async => connectivityController.close());

  RatesListBloc buildBloc() => RatesListBloc(
        getAllRatesWithChange: mockUseCase,
        networkInfo: mockNetworkInfo,
      );

  // ── Fetch lifecycle ──────────────────────────────────────────────────────────

  blocTest<RatesListBloc, RatesListState>(
    'initial fetch emits loading then success with the fetched rates',
    setUp: () =>
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tRates)),
    build: buildBloc,
    act: (bloc) => bloc.add(const RatesRequested()),
    expect: () => [
      const RatesListState(status: RatesListStatus.loading),
      RatesListState(status: RatesListStatus.success, rates: tRates),
    ],
  );

  blocTest<RatesListBloc, RatesListState>(
    'refresh failure preserves existing rates — list stays visible while snackbar shows',
    setUp: () => when(() => mockUseCase(any()))
        .thenAnswer((_) async => const Left(NetworkFailure())),
    build: buildBloc,
    seed: () => RatesListState(status: RatesListStatus.success, rates: tRates),
    act: (bloc) => bloc.add(const RatesRefreshed()),
    expect: () => [
      // isRefreshing = true here (rates present + loading) — list stays visible.
      RatesListState(status: RatesListStatus.loading, rates: tRates),
      RatesListState(
        status: RatesListStatus.failure,
        rates: tRates,
        failure: const NetworkFailure(),
      ),
    ],
  );

  // ── Connectivity auto-refresh ──────────────────────────────────────────────

  blocTest<RatesListBloc, RatesListState>(
    'connectivity false→true transition triggers a refresh',
    setUp: () =>
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tRates)),
    build: buildBloc,
    act: (bloc) async {
      connectivityController.add(false);
      await Future.delayed(Duration.zero);
      connectivityController.add(true);
      await Future.delayed(Duration.zero);
    },
    expect: () => [
      const RatesListState(status: RatesListStatus.loading),
      RatesListState(status: RatesListStatus.success, rates: tRates),
    ],
  );

  blocTest<RatesListBloc, RatesListState>(
    'connectivity true→true does NOT trigger a refresh',
    build: buildBloc,
    act: (bloc) async {
      // Both emits are "true"; no false→true edge exists.
      connectivityController.add(true);
      await Future.delayed(Duration.zero);
      connectivityController.add(true);
      await Future.delayed(Duration.zero);
    },
    expect: () => [],
  );

  blocTest<RatesListBloc, RatesListState>(
    'initial connectivity true (no prior false) does NOT trigger a refresh',
    setUp: () =>
        when(() => mockUseCase(any())).thenAnswer((_) async => Right(tRates)),
    build: buildBloc,
    act: (bloc) async {
      // The very first emit is true — _previousConnectivity starts null,
      // so null→true must not be treated as a restoration event.
      connectivityController.add(true);
      await Future.delayed(Duration.zero);
    },
    expect: () => [],
  );

  // ── Subscription lifecycle ───────────────────────────────────────────────────

  test('stream subscription is cancelled when the BLoC is closed', () async {
    final bloc = buildBloc();

    expect(connectivityController.hasListener, isTrue,
        reason: 'BLoC must subscribe to connectivityStream on construction.');

    await bloc.close();

    expect(connectivityController.hasListener, isFalse,
        reason: 'Lingering subscription after close() would leak memory.');
  });
}
