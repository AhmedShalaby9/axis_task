import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:axis_task/core/enums/data_origin.dart';
import 'package:axis_task/core/error/exceptions.dart';
import 'package:axis_task/core/error/failures.dart';
import 'package:axis_task/core/network/network_info.dart';
import 'package:axis_task/features/currency/data/datasources/currency_local_datasource.dart';
import 'package:axis_task/features/currency/data/datasources/currency_remote_datasource.dart';
import 'package:axis_task/features/currency/data/models/currency_rate_model.dart';
import 'package:axis_task/features/currency/data/repositories/currency_repository_impl.dart';

class MockRemote extends Mock implements CurrencyRemoteDatasource {}
class MockLocal extends Mock implements CurrencyLocalDatasource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

/// A complete model covering all 5 target currencies.
CurrencyRateModel _modelForDate(String date) => CurrencyRateModel(
      date: date,
      rates: {
        'usd': 0.019904522,
        'eur': 0.017091341,
        'gbp': 0.014646497,
        'sar': 0.074641957,
        'jpy': 3.17830652,
      },
    );

final tModel = _modelForDate('2026-08-28');
final tDateTime = DateTime(2026, 8, 28);

void main() {
  late MockRemote mockRemote;
  late MockLocal mockLocal;
  late MockNetworkInfo mockNetworkInfo;
  late CurrencyRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(_modelForDate('2000-01-01'));
  });

  setUp(() {
    mockRemote = MockRemote();
    mockLocal = MockLocal();
    mockNetworkInfo = MockNetworkInfo();
    repository = CurrencyRepositoryImpl(
      remote: mockRemote,
      local: mockLocal,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getRatesForDate', () {
    test('online success: caches the response and returns DataOrigin.network', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getRatesForDate(any())).thenAnswer((_) async => tModel);
      when(() => mockLocal.cacheRates(any())).thenAnswer((_) async {});

      final result = await repository.getRatesForDate(tDateTime);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => []).every((r) => r.dataOrigin == DataOrigin.network), isTrue);
      verify(() => mockLocal.cacheRates(any())).called(1);
    });

    test('offline: serves cache with DataOrigin.cache and never calls remote', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.getCachedRates(any())).thenAnswer((_) async => tModel);

      final result = await repository.getRatesForDate(tDateTime);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => []).every((r) => r.dataOrigin == DataOrigin.cache), isTrue);
      verifyNever(() => mockRemote.getRatesForDate(any()));
    });

    test('remote 500 while online falls back to cache with DataOrigin.cache', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getRatesForDate(any()))
          .thenThrow(const ServerException(statusCode: 500));
      when(() => mockLocal.getCachedRates(any())).thenAnswer((_) async => tModel);

      final result = await repository.getRatesForDate(tDateTime);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => []).every((r) => r.dataOrigin == DataOrigin.cache), isTrue);
    });

    test('remote fails and cache misses: returns the remote failure, not CacheFailure', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getRatesForDate(any()))
          .thenThrow(const ServerException(statusCode: 503));
      when(() => mockLocal.getCachedRates(any())).thenThrow(const CacheException());

      final result = await repository.getRatesForDate(tDateTime);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>(),
            reason: 'The more specific remote error is more actionable than a generic cache miss.'),
        (_) => fail('expected Left'),
      );
    });

    test('inverts raw EGP→X rate to X→EGP: 0.019904522 becomes ~50.24', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.getRatesForDate(any())).thenAnswer((_) async => tModel);
      when(() => mockLocal.cacheRates(any())).thenAnswer((_) async {});

      final result = await repository.getRatesForDate(tDateTime);
      final usd = result.getOrElse(() => []).firstWhere((r) => r.code == 'USD');

      // 1 / 0.019904522 ≈ 50.239
      expect(usd.rate, closeTo(1 / 0.019904522, 0.001));
    });
  });

  group('getRateHistory', () {
    // Helpers

    void stubOnline() {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocal.cacheRates(any())).thenAnswer((_) async {});
    }

    void stubCacheMiss() {
      when(() => mockLocal.getCachedRates(any())).thenThrow(const CacheException());
    }

    String _pad(int n) => n.toString().padLeft(2, '0');

    test('2 of 7 dates failing returns 5 points sorted oldest → newest', () async {
      stubOnline();
      stubCacheMiss();

      var callCount = 0;
      when(() => mockRemote.getRatesForDate(any())).thenAnswer((inv) async {
        callCount++;
        final d = inv.positionalArguments[0] as DateTime;
        if (callCount == 3 || callCount == 5) {
          throw const ServerException(statusCode: 500);
        }
        return _modelForDate('${d.year}-${_pad(d.month)}-${_pad(d.day)}');
      });

      final result = await repository.getRateHistory(code: 'USD', days: 7);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (history) {
          expect(history.points.length, 5);
          expect(history.code, 'USD');
          // Points must be sorted ascending by date.
          for (var i = 0; i < history.points.length - 1; i++) {
            expect(history.points[i].date.isBefore(history.points[i + 1].date), isTrue);
          }
        },
      );
    });

    test('all 7 dates failing returns Left', () async {
      stubOnline();
      stubCacheMiss();
      when(() => mockRemote.getRatesForDate(any()))
          .thenThrow(const NetworkException());

      final result = await repository.getRateHistory(code: 'USD', days: 7);

      expect(result.isLeft(), isTrue);
    });

    test('DataOrigin.cache when any point came from cache', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.getCachedRates(any())).thenAnswer((inv) async {
        final d = inv.positionalArguments[0] as DateTime;
        return _modelForDate('${d.year}-${_pad(d.month)}-${_pad(d.day)}');
      });

      final result = await repository.getRateHistory(code: 'USD', days: 7);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (history) => expect(history.dataOrigin, DataOrigin.cache,
            reason: 'Most-conservative rule: any cache point makes the whole history cache-origin.'),
      );
    });
  });
}
