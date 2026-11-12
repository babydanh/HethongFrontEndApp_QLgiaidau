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

  /// `POST /livestream/matches/{id}/start`. Ghi MP4 đi theo lệnh này.
  Future<MatchStreamCommandResult> startMatchStream(String matchId);

  /// `POST /livestream/matches/{id}/stop`.
  Future<MatchStreamCommandResult> stopMatchStream(String matchId);

  /// Trạng thái phát/bản ghi theo từng trận của giải.
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  );

  /// Tải MP4 đầy đủ của một ngày (có token) về [savePath].
  Future<void> downloadFullRecording(
    String matchId, {
    required String period,
    required String savePath,
  });
}
