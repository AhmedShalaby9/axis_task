part of 'currency_detail_bloc.dart';

enum CurrencyDetailStatus { initial, loading, success, failure }

final class CurrencyDetailState extends Equatable {
  const CurrencyDetailState({
    this.status = CurrencyDetailStatus.initial,
    this.history,
    this.failure,
  });

  final CurrencyDetailStatus status;

  /// Populated on success. Null until the first successful fetch.
  final RateHistory? history;

  /// Non-null when [status] is [CurrencyDetailStatus.failure].
  final Failure? failure;

  CurrencyDetailState copyWith({
    CurrencyDetailStatus? status,
    RateHistory? history,
    Failure? Function()? failure,
  }) {
    return CurrencyDetailState(
      status: status ?? this.status,
      history: history ?? this.history,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, history, failure];
}
