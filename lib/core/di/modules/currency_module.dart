import 'package:get_it/get_it.dart';

import '../../../features/currency/data/datasources/currency_local_datasource.dart';
import '../../../features/currency/data/datasources/currency_remote_datasource.dart';
import '../../../features/currency/data/repositories/currency_repository_impl.dart';
import '../../../features/currency/domain/entities/exchange_rate.dart';
import '../../../features/currency/domain/repositories/currency_repository.dart';
import '../../../features/currency/domain/usecases/get_all_rates_with_change.dart';
import '../../../features/currency/domain/usecases/get_rate_history.dart';
import '../../../features/currency/presentation/bloc/currency_detail/currency_detail_bloc.dart';
import '../../../features/currency/presentation/bloc/rates_list/rates_list_bloc.dart';
import '../../network/network_info.dart';

void registerCurrencyModule(GetIt sl) {
  // ── Datasources ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<CurrencyRemoteDatasource>(
    () => CurrencyRemoteDatasourceImpl(sl()),
  );

  sl.registerLazySingleton<CurrencyLocalDatasource>(
    () => CurrencyLocalDatasourceImpl(sl()),
  );

  // ── Repository ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<CurrencyRepository>(
    () => CurrencyRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
    ),
  );

  // ── Use cases ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetAllRatesWithChange(sl()));
  sl.registerLazySingleton(() => GetRateHistory(sl()));

  // ── BLoCs ──────────────────────────────────────────────────────────────────
  // RatesListBloc: new instance per page mount, dependencies are singletons.
  sl.registerFactory(
    () => RatesListBloc(
      getAllRatesWithChange: sl(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // CurrencyDetailBloc: requires the already-loaded ExchangeRate at creation
  // time. registerFactoryParam lets callers pass it via sl(param1: rate).
  sl.registerFactoryParam<CurrencyDetailBloc, ExchangeRate, void>(
    (rate, _) => CurrencyDetailBloc(
      rate: rate,
      getRateHistory: sl(),
    ),
  );
}
