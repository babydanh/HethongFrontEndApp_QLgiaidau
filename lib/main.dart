import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_quanly_giaidau/core/config/global_error_handler.dart';
import 'package:app_quanly_giaidau/app.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Khởi tạo biến môi trường
  await dotenv.load(fileName: ".env");

  // Khởi tạo hệ thống Lỗi Toàn Cục (Global Error Handler)
  GlobalErrorHandler.init();

  // Khóa màn hình dọc (Portrait) cho ứng dụng theo chuẩn
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const ProviderScope(
      child: TournamentApp(),
    ),
  );
}
