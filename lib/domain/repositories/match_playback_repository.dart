import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';

/// Nguồn phát trực tiếp của một trận.
///
/// Cố tình không có bất kỳ khả năng publish nào: app chỉ đọc `playbackUrl` để
/// phát, không bao giờ đẩy luồng. Stream key và thông tin ingest vẫn thuộc về
/// backend.
abstract class IMatchPlaybackRepository {
  /// Trả về nguồn phát của trận. Trả về model với `playbackUrl` null khi trận
  /// chưa gắn camera hoặc sân chưa khai URL — đó là trạng thái bình thường
  /// khi xem live, không phải lỗi.
  Future<MatchPlaybackModel> getMatchPlayback(String matchId);
}
