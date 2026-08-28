part of 'currency_detail_bloc.dart';

sealed class CurrencyDetailEvent extends Equatable {
  const CurrencyDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on screen entry. The currency code is read from the ExchangeRate
/// already held by the BLoC — no duplication in the event payload.
final class HistoryRequested extends CurrencyDetailEvent {
  const HistoryRequested();
}
