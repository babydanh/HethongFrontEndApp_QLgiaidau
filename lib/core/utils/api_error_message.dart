import 'package:dio/dio.dart';

/// Thông điệp Backend trong body lỗi (`message`). Trả null khi không phải
/// [DioException] hoặc body không có `message`, để người gọi tự chọn thông
/// điệp dự phòng. Không đoán từ `toString()` của Dio.
String? backendErrorMessage(Object? error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;
  final message = data['message'];
  if (message == null) return null;
  final text = message is List ? message.join('; ') : message.toString();
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}
