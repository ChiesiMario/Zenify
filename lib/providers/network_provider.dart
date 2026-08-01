import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/theme_provider.dart';

class NetworkState {
  final bool isOffline;
  NetworkState({this.isOffline = false});
}

class NetworkNotifier extends StateNotifier<NetworkState> {
  final Ref _ref;
  Timer? _timer;
  bool _isChecking = false;
  static const _offlineKey = 'is_offline_mode';

  NetworkNotifier(Ref ref) : _ref = ref, super(NetworkState(
    isOffline: ref.read(sharedPreferencesProvider).getBool(_offlineKey) ?? false
  )) {
    _startTimer();
    checkNetwork(); // 初始檢測
  }

  Future<void> _saveOfflineState(bool isOffline) async {
    await _ref.read(sharedPreferencesProvider).setBool(_offlineKey, isOffline);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkNetwork();
    });
  }

  Future<void> checkNetwork() async {
    if (_isChecking) return;
    _isChecking = true;

    final api = _ref.read(subsonicApiProvider);
    if (api == null) {
      _isChecking = false;
      return;
    }

    bool success = false;
    for (int i = 0; i < 3; i++) {
      try {
        final result = await api.ping();
        if (result) {
          success = true;
          break;
        }
      } catch (e) {
        // 忽略錯誤，繼續重試
      }
      if (i < 2) {
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    if (mounted) {
      if (success && state.isOffline) {
        state = NetworkState(isOffline: false);
        await _saveOfflineState(false);
      } else if (!success && !state.isOffline) {
        state = NetworkState(isOffline: true);
        await _saveOfflineState(true);
      }
    }
    _isChecking = false;
  }

  Future<bool> testConnectionManual() async {
    final api = _ref.read(subsonicApiProvider);
    if (api == null) return false;
    
    try {
      final result = await api.ping();
      if (result) {
        if (mounted && state.isOffline) {
          state = NetworkState(isOffline: false);
          await _saveOfflineState(false);
        }
        return true;
      }
    } catch (e) {
      // 忽略錯誤
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final networkProvider = StateNotifierProvider<NetworkNotifier, NetworkState>((ref) {
  return NetworkNotifier(ref);
});
