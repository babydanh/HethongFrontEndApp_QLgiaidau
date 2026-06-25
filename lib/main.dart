import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_quanly_giaidau/core/config/global_error_handler.dart';
import 'package:app_quanly_giaidau/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo biến môi trường
  await dotenv.load(fileName: ".env");

  // Khởi tạo hệ thống Lỗi Toàn Cục (Global Error Handler)
  GlobalErrorHandler.init();

  // Khởi tạo Smart Orientation
  final view = PlatformDispatcher.instance.views.first;
  final logicalWidth = view.physicalSize.width / view.devicePixelRatio;

  if (logicalWidth < 600) {
    // Khóa cứng màn hình dọc (Portrait) cho Điện thoại di động
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } else {
    // Mở khóa hoàn toàn đa hướng cho Tablet / TV / Web
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  runApp(
    const ProviderScope(
      child: TournamentApp(),
    ),
  );
}
