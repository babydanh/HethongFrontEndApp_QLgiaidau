import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const _localeKey = 'locale';
  static const supportedLanguageCodes = <String>['vi', 'en'];

  @override
  Locale build() {
    final savedLanguageCode = ref
        .watch(sharedPreferencesProvider)
        .value
        ?.getString(_localeKey);
    return _localeFor(savedLanguageCode);
  }

  Future<void> changeLocale(String languageCode) async {
    final locale = _localeFor(languageCode);
    state = locale;

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Locale _localeFor(String? languageCode) {
    if (supportedLanguageCodes.contains(languageCode)) {
      return Locale(languageCode!);
    }
    return const Locale('vi');
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
