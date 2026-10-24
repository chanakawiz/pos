import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_provider.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier(this._ref) : super(true) {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await Connectivity().checkConnectivity();
      state = _isConnected(results);

      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        final connected = _isConnected(results);
        final wasDisconnected = !state;
        state = connected;

        // When internet returns after being offline, automatically flush pending sales & pull catalog
        if (connected && wasDisconnected) {
          _ref.read(syncProvider.notifier).syncNow();
        }
      });
    } catch (_) {
      // In tests or environments without connectivity channel, default to true
      state = true;
    }
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier(ref);
});
