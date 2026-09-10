import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:app_quanly_giaidau/core/widgets/custom_error_widget.dart';

class GlobalErrorHandler {
  static void init() {
    // 1. Xử lý các lỗi sinh ra từ Flutter framework (UI / Rendering)
    FlutterError.onError = (FlutterErrorDetails details) {
      // Không được nuốt stack trace: nếu chỉ thay ErrorWidget thì logcat mất
      // widget gây lỗi và mọi assertion đều bị quy về một dialog chung.
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
      }
      unawaited(
        Sentry.captureException(details.exception, stackTrace: details.stack),
      );
    };

    // 2. Xử lý các lỗi Asynchronous từ Dart (Future, Stream...)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('Unhandled async error: $error');
        debugPrintStack(stackTrace: stack);
      }
      unawaited(Sentry.captureException(error, stackTrace: stack));
      return true; // Trả về true để báo hệ thống rằng lỗi đã được xử lý
    };

    // 3. Thay thế màn hình Red Screen of Death
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(details: details);
    };
  }
}
