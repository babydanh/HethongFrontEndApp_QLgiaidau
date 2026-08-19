import 'package:app_quanly_giaidau/domain/entities/violation_report.dart';

abstract class IReportRepository {
  /// Lấy các báo cáo do người dùng hiện tại gửi.
  /// GET /users/reports/me
  Future<ViolationReportPage> getMine({
    String? cursor,
    int limit = 10,
  });
}
