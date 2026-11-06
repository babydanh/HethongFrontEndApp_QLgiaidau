import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

/// Thông điệp cho lỗi khi ghi vòng/giải: 409 là dữ liệu đã đổi hoặc trùng,
/// còn lại ưu tiên lời Backend, rồi tới lỗi mạng/timeout, rồi lỗi chung.
String seriesLegsErrorText(Object error, AppLocalizations l10n) {
  if (error is DioException && error.response?.statusCode == 409) {
    return l10n.seriesLegsConflict;
  }
  return ErrorParser.parse(error, l10n.seriesLegsActionFailed, l10n);
}
