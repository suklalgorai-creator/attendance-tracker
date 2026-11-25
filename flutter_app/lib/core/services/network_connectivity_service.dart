import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network reachability abstraction and mockable test implementation.
///
/// Ownership: Core Connectivity
// ==========================================
// CONNECTIVITY SERVICE - Online/Offline Stream
// ==========================================
abstract class NetworkConnectivityService {
  /// Stream emitting boolean state (true = online, false = offline).
  Stream<bool> get onConnectivityChanged;

  /// Current online status check.
  Future<bool> get isOnline;

  void dispose();
}

/// Offline-safe / Mockable implementation for deterministic unit testing.
class FakeNetworkConnectivityService implements NetworkConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _currentStatus;

  FakeNetworkConnectivityService({bool initialOnline = true})
    : _currentStatus = initialOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isOnline async => _currentStatus;

  void setOnline(bool online) {
    if (_currentStatus != online) {
      _currentStatus = online;
      _controller.add(online);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}

/// Production implementation wrapping [Connectivity] from `connectivity_plus`.
class NetworkConnectivityServiceImpl implements NetworkConnectivityService {
  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkConnectivityServiceImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen(_handleResults);
  }

  void _handleResults(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    _controller.add(hasConnection);
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
