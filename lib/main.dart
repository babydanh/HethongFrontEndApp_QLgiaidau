import 'package:flutter/material.dart';
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

  // Giới hạn cache hình ảnh trong bộ nhớ (tránh OOM khi tải nhiều ảnh avatar)
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB

  runApp(const ProviderScope(child: TournamentApp()));
}
