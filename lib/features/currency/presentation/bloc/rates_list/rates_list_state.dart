part of 'rates_list_bloc.dart';

enum RatesListStatus { initial, loading, success, failure }

final class RatesListState extends Equatable {
  const RatesListState({
    this.status = RatesListStatus.initial,
    this.rates = const [],
    this.failure,
  });

  final RatesListStatus status;
  final List<ExchangeRate> rates;

  /// Non-null whenever [status] is [RatesListStatus.failure].
  final Failure? failure;

  // ── Derived booleans consumed directly by the UI ──────────────────────────

  /// No rates yet and a fetch is in progress — show a full-screen spinner.
  bool get isInitialLoading =>
      status == RatesListStatus.loading && rates.isEmpty;

  /// Rates are already visible and a re-fetch is in progress — show an
  /// inline refresh indicator without replacing the list.
  bool get isRefreshing =>
      status == RatesListStatus.loading && rates.isNotEmpty;

  /// True whenever there is displayable data, regardless of status.
  /// Drives the decision of whether to show a list or a full-screen error.
  bool get hasRates => rates.isNotEmpty;

  RatesListState copyWith({
    RatesListStatus? status,
    List<ExchangeRate>? rates,
    // Nullable-setter pattern: pass `failure: () => null` to clear the field.
    Failure? Function()? failure,
  }) {
    return RatesListState(
      status: status ?? this.status,
      rates: rates ?? this.rates,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, rates, failure];
}
