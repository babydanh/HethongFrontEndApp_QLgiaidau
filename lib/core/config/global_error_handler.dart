import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/widgets/custom_error_widget.dart';

class GlobalErrorHandler {
  static void init() {
    // 1. Xử lý các lỗi sinh ra từ Flutter framework (UI / Rendering)
    FlutterError.onError = (FlutterErrorDetails details) {
      // Unhandled Flutter errors
    };

    // 2. Xử lý các lỗi Asynchronous từ Dart (Future, Stream...)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      return true; // Trả về true để báo hệ thống rằng lỗi đã được xử lý
    };

    // 3. Thay thế màn hình Red Screen of Death
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(details: details);
    };
  }
}
