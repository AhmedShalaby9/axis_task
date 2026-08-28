import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/usecase/usecase.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/usecases/get_all_rates_with_change.dart';

part 'rates_list_event.dart';
part 'rates_list_state.dart';

class RatesListBloc extends Bloc<RatesListEvent, RatesListState> {
  RatesListBloc({
    required GetAllRatesWithChange getAllRatesWithChange,
    required NetworkInfo networkInfo,
  })  : _getAllRatesWithChange = getAllRatesWithChange,
        super(const RatesListState()) {
    on<RatesRequested>(_onRatesRequested);
    on<RatesRefreshed>(_onRatesRefreshed);
    on<ConnectivityRestored>(_onConnectivityRestored);

    // ── Connectivity auto-refresh ──────────────────────────────────────────
    // We only react to false→true transitions. Emitting on every true
    // (e.g. wifi handoff, stream replay) would cause spurious re-fetches.
    _connectivitySub = networkInfo.connectivityStream.listen((isConnected) {
      if (isConnected && _previousConnectivity == false) {
        add(const ConnectivityRestored());
      }
      _previousConnectivity = isConnected;
    });
  }

  final GetAllRatesWithChange _getAllRatesWithChange;
  late final StreamSubscription<bool> _connectivitySub;

  /// Tracks the last known connectivity state to detect the false→true edge.
  /// Starts null so the very first stream emit (whatever its value) is never
  /// treated as a restoration event.
  bool? _previousConnectivity;

  // ── Event handlers ─────────────────────────────────────────────────────────

  Future<void> _onRatesRequested(
    RatesRequested event,
    Emitter<RatesListState> emit,
  ) async {
    // Initial fetch: no rates yet → show full-screen spinner.
    emit(state.copyWith(
      status: RatesListStatus.loading,
      failure: () => null,
    ));
    await _fetchAndEmit(emit);
  }

  Future<void> _onRatesRefreshed(
    RatesRefreshed event,
    Emitter<RatesListState> emit,
  ) async {
    // Preserve existing rates so the list stays visible during the re-fetch.
    emit(state.copyWith(
      status: RatesListStatus.loading,
      failure: () => null,
    ));
    await _fetchAndEmit(emit);
  }

  Future<void> _onConnectivityRestored(
    ConnectivityRestored event,
    Emitter<RatesListState> emit,
  ) async {
    // Behaves identically to a manual refresh — preserve whatever is on screen.
    emit(state.copyWith(
      status: RatesListStatus.loading,
      failure: () => null,
    ));
    await _fetchAndEmit(emit);
  }

  /// Calls the use case and emits success or failure, preserving existing rates
  /// in both cases so the UI never loses data it was already showing.
  Future<void> _fetchAndEmit(Emitter<RatesListState> emit) async {
    final result = await _getAllRatesWithChange(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: RatesListStatus.failure,
        failure: () => failure,
        // rates intentionally not updated — keep showing stale data.
      )),
      (rates) => emit(state.copyWith(
        status: RatesListStatus.success,
        rates: rates,
        failure: () => null,
      )),
    );
  }

  @override
  Future<void> close() {
    _connectivitySub.cancel();
    return super.close();
  }
}
