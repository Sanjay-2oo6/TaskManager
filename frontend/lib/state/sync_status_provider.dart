import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, bool>((ref) {
  return SyncStatusNotifier();
});

class SyncStatusNotifier extends StateNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  SyncStatusNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    final results = await Connectivity().checkConnectivity();
    state = results.any((r) => r != ConnectivityResult.none);

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      state = results.any((r) => r != ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
