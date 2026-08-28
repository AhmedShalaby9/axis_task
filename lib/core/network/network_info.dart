import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class NetworkInfo {
  /// One-shot check — use for deciding whether to attempt a network request.
  Future<bool> get isConnected;

  /// Continuous stream — use to trigger auto-refresh when connectivity returns.
  /// Emits true when any network interface is available, false when offline.
  Stream<bool> get connectivityStream;
}

final class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
