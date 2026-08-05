import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/theme_provider.dart';

class CacheLimitNotifier extends Notifier<double> {
  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble('cache_limit_gb') ?? 10.0;
  }
  
  void setLimit(double val) {
    state = val;
    ref.read(sharedPreferencesProvider).setDouble('cache_limit_gb', val);
  }
}

final cacheLimitProvider = NotifierProvider<CacheLimitNotifier, double>(() {
  return CacheLimitNotifier();
});
