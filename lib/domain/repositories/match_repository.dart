import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/match_event.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/domain/entities/penalty.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

class TournamentNotStartedException implements Exception {
  const TournamentNotStartedException();
}

abstract class IMatchRepository {
  Future<MatchModel> create(String tournamentId, MatchModel match);
  Stream<List<MatchModel>> watchByTournament(
    String tournamentId, {
    String? divisionId,
  });
  Stream<List<MatchModel>> watchLive(String tournamentId);
  Stream<MatchModel?> watchMatch(String tournamentId, String matchId);

  /// Chỉ gửi trường nào được truyền; trường không truyền giữ nguyên trên
  /// server. Trường trong [clear] được gửi null để xoá (ví dụ gỡ lịch).
  /// Trả về lịch server đang lưu, có thể khác lịch đã yêu cầu nếu server dời.
  Future<MatchScheduleSnapshot> updateSchedule(
    String tournamentId,
    String matchId, {
    String? courtName,
    String? courtAddress,

    /// Court the match plays on. Changing it makes the backend hand the match
    /// that court's camera; a match that already has a manually assigned
    /// camera keeps it.
    String? courtId,
    String? refereeId,
    DateTime? scheduledAt,

    /// Thời lượng riêng của trận (ghi vào cấu hình trận).
    int? durationMinutes,
    Set<MatchScheduleField> clear = const {},
  });

  /// Xem trước xếp tự động. Không ghi gì xuống server.
  Future<SchedulePlanPreview> previewSchedulePlan(
    String tournamentId, {
    required DateTime day,
    required List<String> courtIds,
    required List<String> matchIds,
    required DateTime windowStart,
    required DateTime windowEnd,
    required int durationMinutes,
    int minimumStartIntervalMinutes = 15,
    int changeoverMinutes = 0,
  });
  Future<void> updateLiveState(
    String tournamentId,
    String matchId, {
    int? score1,
    int? score2,
    List<MatchEvent>? events,
    String? status,
    int? maxScore,
    bool? winByTwo,
    int? timeLimitMinutes,
    String? refereeName,
    List<Penalty>? penalties,
  });

  Future<void> startMatch(
    String tournamentId,
    String matchId, {
    int? maxScore,
    int? timeLimitMinutes,
    String? refereeName,
    bool useLiteParticipantAccess = false,
  });

  Future<void> completeMatch(
    String tournamentId,
    String matchId, {
    required String winnerId,
    required String loserId,
    required int finalScore1,
    required int finalScore2,
  });

  /// Cập nhật scoreDetails theo đúng backend DTO.
  /// Gửi p1SetsWon, p2SetsWon, scoreDetails.sets, winnerId, overrideReason.
  Future<void> updateScoreDetails(
    String tournamentId,
    String matchId, {
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    Map<String, dynamic>? scoreDetailsExtras,
    String? winnerId,
    String? overrideReason,
    int? expectedRevision,
    bool useLiteParticipantAccess = false,
  });

  /// Ghi cài đặt sân pickleball lên server (`PATCH /matches/:id/court-state`).
  /// Trả về trận đã cập nhật, cùng shape với GET match.
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  );

  Future<void> advanceWinner(
    String tournamentId,
    String nextMatchId, {
    required String winnerId,
    required String winnerName,
    required bool isTeam1,
  });

  Future<void> walkover(
    String tournamentId,
    String matchId, {
    required String winnerId,
    required String loserId,
  });

  Future<List<MatchModel>> getAllByTournament(
    String tournamentId, {
    String? divisionId,
  });
  Future<void> deleteAll(String tournamentId);
  Future<List<MatchModel>> getMatches({String? status, bool? publicOnly});

  Future<void> setScoreboardVisibility(
    String matchId, {
    required bool visible,
    required bool isClubMatch,
  });

  Future<({bool h2hOverlayVisible, bool bracketOverlayVisible})>
  setOverlayVisibility(
    String matchId, {
    required LiveOverlayKind kind,
    required bool visible,
    required bool isClubMatch,
  });

  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getPublicMatchesPaged({
    String? cursor,
    int limit = 10,
    String? search,
    String? categoryId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? trigger,
  });

  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getTournamentMatchesPaged({
    required String tournamentId,
    String? status,
    String? cursor,
    int limit = 4,
    String? trigger,
  });

  /// Gửi cheer (cổ vũ) cho trận đấu — POST /matches/:id/cheer.
  /// Guest cheer là public, không yêu cầu fake UUID.
  Future<void> cheerMatch(String matchId);

  /// Lấy số lượng cheer hiện tại — GET /matches/:id/cheer-count.
  Future<int> getCheerCount(String matchId);

  /// Thao tác đặc biệt lên trận đấu — PATCH /matches/:id/operation.
  /// action: WALKOVER | NO_SHOW | RETIREMENT | DISQUALIFICATION |
  /// OVERRIDE_RESULT | POSTPONE | ABANDON.
  /// Backend yêu cầu reason tối thiểu 5 ký tự.
  Future<void> matchOperation(
    String matchId, {
    required String action,
    required String reason,
    String? winnerId,
  });
}
