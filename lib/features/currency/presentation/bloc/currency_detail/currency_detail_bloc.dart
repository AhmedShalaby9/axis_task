import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/exchange_rate.dart';
import '../../../domain/entities/rate_history.dart';
import '../../../domain/usecases/get_rate_history.dart';

part 'currency_detail_event.dart';
part 'currency_detail_state.dart';

class CurrencyDetailBloc extends Bloc<CurrencyDetailEvent, CurrencyDetailState> {
  CurrencyDetailBloc({
    required this.rate,
    required GetRateHistory getRateHistory,
  })  : _getRateHistory = getRateHistory,
        super(const CurrencyDetailState()) {
    on<HistoryRequested>(_onHistoryRequested);
  }

  /// The already-loaded rate passed in from the list screen.
  /// The detail screen displays rate.code, rate.rate, rate.egpTrend, etc.
  /// without re-fetching what the list BLoC already resolved.
  final ExchangeRate rate;

  final GetRateHistory _getRateHistory;

  Future<void> _onHistoryRequested(
    HistoryRequested event,
    Emitter<CurrencyDetailState> emit,
  ) async {
    emit(state.copyWith(status: CurrencyDetailStatus.loading));

    final result = await _getRateHistory(
      RateHistoryParams(code: rate.code),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: CurrencyDetailStatus.failure,
        failure: () => failure,
      )),
      (history) => emit(state.copyWith(
        status: CurrencyDetailStatus.success,
        history: history,
        failure: () => null,
      )),
    );
  }
}
