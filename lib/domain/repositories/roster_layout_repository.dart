import 'package:app_quanly_giaidau/domain/entities/roster_layout.dart';

/// Hỏi AI về bố cục file Excel danh sách VĐV. Tách khỏi `TournamentManagementRepository` vì chỉ màn
/// nhập Excel dùng.
abstract interface class RosterLayoutRepository {
  /// `POST /ai/tournaments/:id/roster-layout` với bản tóm tắt đã che dữ liệu cá nhân ([sheets] là JSON
  /// của `buildRosterLayoutDigest`). `retryEmptyLayout` thêm `?retryReason=EMPTY_LAYOUT` cho lần hỏi lại.
  /// Ném `DioException` khi 429/503 hoặc lỗi mạng: người gọi giữ kết quả luật và báo trạng thái.
  Future<RosterLayoutResponse> analyzeRosterLayout(
    String tournamentId, {
    required List<Map<String, dynamic>> sheets,
    String locale = 'vi',
    bool retryEmptyLayout = false,
  });
}
