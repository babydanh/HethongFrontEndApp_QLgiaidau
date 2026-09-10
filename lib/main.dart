import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:app_quanly_giaidau/core/config/global_error_handler.dart';
import 'package:app_quanly_giaidau/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo biến môi trường
  await dotenv.load(fileName: ".env");

  // Khởi tạo hệ thống Lỗi Toàn Cục (Global Error Handler)
  GlobalErrorHandler.init();

  // Giới hạn cache hình ảnh trong bộ nhớ (tránh OOM khi tải nhiều ảnh avatar)
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      50 * 1024 * 1024; // 50MB

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  const sentryEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );
  const sentryRelease = String.fromEnvironment('APP_RELEASE');
  const sentryTraceSampleRateRaw = String.fromEnvironment(
    'SENTRY_TRACES_SAMPLE_RATE',
    defaultValue: '0.1',
  );
  final sentryTraceSampleRate =
      double.tryParse(sentryTraceSampleRateRaw)?.clamp(0.0, 1.0).toDouble() ??
      0.1;

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn.isEmpty ? null : sentryDsn;
      options.environment = sentryEnvironment;
      options.release = sentryRelease.isEmpty ? null : sentryRelease;
      options.tracesSampleRate = sentryTraceSampleRate;
      options.sendDefaultPii = false;
      options.enablePrintBreadcrumbs = false;
      options.recordHttpBreadcrumbs = false;
    },
    appRunner: () {
      // Sentry installs its platform hooks first; the project handler then
      // preserves the existing error UI while forwarding errors safely.
      GlobalErrorHandler.init();
      runApp(const ProviderScope(child: TournamentApp()));
    },
  );
}
