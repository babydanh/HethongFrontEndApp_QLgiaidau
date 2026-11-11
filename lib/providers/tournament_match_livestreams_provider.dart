import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/match_stream_control_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trạng thái phát/bản ghi theo từng trận của giải
/// (`GET /livestream/tournaments/{id}/matches`), khoá theo `matchId`.
///
/// Lỗi tải (401/403/404/5xx/timeout) cho map rỗng: thẻ trận vẫn hiện, nút theo
/// mặc định an toàn (không LIVE, không bản ghi) thay vì làm hỏng cả bảng.
class TournamentMatchLivestreamsNotifier
    extends AsyncNotifier<Map<String, MatchLivestreamSummary>> {
  TournamentMatchLivestreamsNotifier(this.tournamentId);

  final String tournamentId;

  Future<Map<String, MatchLivestreamSummary>> _load() async {
    final rows = await ref
        .read(matchRecordingCatalogRepositoryProvider)
        .listTournamentMatchLivestreams(tournamentId);
    return {for (final row in rows) row.matchId: row};
  }

  @override
  Future<Map<String, MatchLivestreamSummary>> build() async {
    try {
      return await _load();
    } on Object {
      return const <String, MatchLivestreamSummary>{};
    }
  }

  /// Đọc lại; lỗi thì giữ bản đã có thay vì xoá trạng thái đang hiện.
  Future<void> refresh() async {
    try {
      final next = await _load();
      if (ref.mounted) state = AsyncData(next);
    } on Object {
      // Giữ nguyên danh sách hiện có.
    }
  }

  /// Bắt đầu/Dừng phát một trận rồi tải lại danh sách và làm mới video.
  Future<MatchStreamToggleResult> toggle(
    String matchId, {
    required bool isLive,
  }) async {
    final result = await runMatchStreamCommand(
      ref.read(matchRecordingCatalogRepositoryProvider),
      matchId,
      stop: isLive,
    );
    if (result.kind == MatchStreamToggleKind.started ||
        result.kind == MatchStreamToggleKind.stopped) {
      if (ref.mounted) ref.invalidate(matchPlaybackProvider(matchId));
      await refresh();
    }
    return result;
  }
}

final tournamentMatchLivestreamsProvider =
    AsyncNotifierProvider.family<
      TournamentMatchLivestreamsNotifier,
      Map<String, MatchLivestreamSummary>,
      String
    >(TournamentMatchLivestreamsNotifier.new);
