part of 'rates_list_bloc.dart';

sealed class RatesListEvent extends Equatable {
  const RatesListEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on screen entry — triggers the initial fetch.
final class RatesRequested extends RatesListEvent {
  const RatesRequested();
}

/// Fired by pull-to-refresh. Preserves existing rates during the fetch.
final class RatesRefreshed extends RatesListEvent {
  const RatesRefreshed();
}

/// Fired internally when the connectivity stream emits a false→true
/// transition. Triggers a refresh so the screen self-heals after going offline.
final class ConnectivityRestored extends RatesListEvent {
  const ConnectivityRestored();
}
