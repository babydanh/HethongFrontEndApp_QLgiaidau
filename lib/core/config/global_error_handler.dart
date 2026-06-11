import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/widgets/custom_error_widget.dart';

class GlobalErrorHandler {
  static void init() {
    // 1. Xử lý các lỗi sinh ra từ Flutter framework (UI / Rendering)
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('🚨 Đã xảy ra lỗi Flutter: ${details.exception}\n${details.stack}');
      
      // Nếu là lỗi phát sinh trong luồng render (build) thì sẽ được ErrorWidget.builder bắt
      // Các lỗi khác (như click button sinh lỗi) thì in ra console/crashlytics.
      
      // Nếu có dùng Crashlytics:
      // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // 2. Xử lý các lỗi Asynchronous từ Dart (Future, Stream...)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('🚨 Đã xảy ra lỗi Dart (Async): $error\n$stack');
      
      // Nếu có dùng Crashlytics:
      // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      
      return true; // Trả về true để báo hệ thống rằng lỗi đã được xử lý (tránh crash app nếu có thể)
    };

    // 3. Thay thế màn hình Red Screen of Death
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // In lỗi ra log nếu cần, sau đó trả về Widget thân thiện
      debugPrint('💥 Lỗi Rendering UI: ${details.exception}');
      return CustomErrorWidget(details: details);
    };

    debugPrint('✅ Đã khởi tạo thành công màng lọc lỗi (Global Error Handler)');
  }
}
