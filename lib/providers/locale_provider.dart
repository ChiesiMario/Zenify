import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/theme_provider.dart'; // To get sharedPreferencesProvider

class LocaleNotifier extends StateNotifier<Locale?> {
  final Ref ref;
  static const _localeKey = 'app_locale_language_code';

  LocaleNotifier(this.ref) : super(null) {
    _loadLocale();
  }

  void _loadLocale() {
    final prefs = ref.read(sharedPreferencesProvider);
    final langCode = prefs.getString(_localeKey);
    if (langCode != null) {
      if (langCode.contains('_')) {
        final parts = langCode.split('_');
        state = Locale(parts[0], parts[1]);
      } else {
        state = Locale(langCode);
      }
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      String code = locale.languageCode;
      if (locale.countryCode != null) {
        code += '_${locale.countryCode}';
      }
      await prefs.setString(_localeKey, code);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref);
});
