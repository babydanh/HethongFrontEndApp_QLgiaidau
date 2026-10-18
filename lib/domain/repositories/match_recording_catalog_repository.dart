import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';

abstract class IMatchRecordingCatalogRepository {
  Future<MatchStreamControlStateModel> getMatchControlState(String matchId);

  Future<MatchRecordingDaysModel> listRecordingDays(String matchId);

  Future<List<MatchRecordingFileModel>> listRecordings(
    String matchId, {
    required String period,
  });

  /// Đoạn phát lại nối tiếp của một ngày (đã lọc an toàn, giữ thứ tự server).
  Future<MatchRecordingPlaylist> getPlaylist(
    String matchId, {
    required String period,
  });
}
