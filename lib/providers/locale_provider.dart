import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const String _localeKey = 'app_locale';

  @override
  Locale build() {
    // Try loading saved locale synchronously from local state
    // async load handled during init
    return const Locale('vi');
  }

  Future<void> changeLocale(String languageCode) async {
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  /// Vietnamese name for display in language selector
  static String displayName(String code) {
    switch (code) {
      case 'vi': return 'Tiếng Việt';
      case 'en': return 'English';
      default: return code;
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
