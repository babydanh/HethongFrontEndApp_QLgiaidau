import 'package:app_quanly_giaidau/core/utils/api_error_message.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

/// Thông báo lỗi cho người dùng khi gọi API chuỗi giải: ưu tiên thông điệp
/// Backend (400/403/404/409), rồi lỗi mạng, cuối cùng là [fallback].
String seriesMgmtErrorText(
  AppLocalizations l10n,
  Object error, {
  required String fallback,
}) {
  final backend = backendErrorMessage(error);
  if (backend != null) return backend;
  if (error is DioException && _isNetworkError(error.type)) {
    return l10n.seriesMgmtNetworkError;
  }
  return fallback;
}

bool _isNetworkError(DioExceptionType type) =>
    type == DioExceptionType.connectionError ||
    type == DioExceptionType.connectionTimeout ||
    type == DioExceptionType.sendTimeout ||
    type == DioExceptionType.receiveTimeout;
