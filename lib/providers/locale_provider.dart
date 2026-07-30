import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('vi');
  }

  /// Tạm thời chỉ hỗ trợ tiếng Việt
  /// Khi nào thêm tiếng Anh thì mở khoá hàm này
  // Future<void> changeLocale(String languageCode) async {
  //   state = Locale(languageCode);
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(_localeKey, languageCode);
  // }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
