import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

typedef MatchControlParams = ({String tournamentId, String matchId});

class MatchController {
  static const _log = AppLogger('MatchController');

  final Ref ref;
  final String tournamentId;
  final String matchId;

  MatchController(this.ref, this.tournamentId, this.matchId);

  MatchModel? get match => ref
      .read(singleMatchProvider((tournamentId: tournamentId, matchId: matchId)))
      .value;

  /// Invalidate every surface that renders a match after an authoritative
  /// write. The live screen is backed by singleMatchProvider, while cards and
  /// bracket views use different tournament/division providers.
  void _invalidateMatchSurfaces(MatchModel? currentMatch) {
    ref.invalidate(
      singleMatchProvider((tournamentId: tournamentId, matchId: matchId)),
    );
    ref.invalidate(matchesProvider(tournamentId));
    ref.invalidate(liveMatchesProvider(tournamentId));
    ref.invalidate(bracketMatchesProvider(tournamentId));
    ref.invalidate(liteBracketMatchesProvider(tournamentId));
    ref.invalidate(tournamentProvider(tournamentId));

    final divisionId = currentMatch?.divisionId;
    if (divisionId == null || divisionId.isEmpty) return;
    final params = (tournamentId: tournamentId, divisionId: divisionId);
    ref.invalidate(matchesWithDivisionProvider(params));
    ref.invalidate(liteBracketMatchesWithDivisionProvider(params));
    ref.invalidate(bracketMatchesWithDivisionProvider(params));
  }

  Future<void> updateConfig({
    int? maxScore,
    bool? winByTwo,
    int? timeLimitMinutes,
  }) async {
    _log.warning(
      'updateConfig: Không có endpoint backend cho cập nhật cấu hình (maxScore/winByTwo/timeLimitMinutes). '
      'Các tham số này chỉ được thiết lập khi bắt đầu trận qua startMatch().',
    );
    throw UnsupportedError(
      'Backend không hỗ trợ cập nhật cấu hình trận đấu sau khi bắt đầu. '
      'Vui lòng thiết lập maxScore/timeLimitMinutes qua startMatch().',
    );
  }

  Future<void> startMatch({
    int? maxScore,
    int? timeLimitMinutes,
    String? refereeName,
  }) async {
    final currentMatch = match;
    final tournament = ref.read(tournamentProvider(tournamentId)).value;
    await ref
        .read(matchRepositoryProvider)
        .startMatch(
          tournamentId,
          matchId,
          maxScore: maxScore,
          timeLimitMinutes: timeLimitMinutes,
          refereeName: refereeName,
          useLiteParticipantAccess: isSuperLiteTournament(
            tournamentConfig: currentMatch?.tournamentConfig,
            tournamentIsLite: tournament?.isLite == true,
          ),
        );
    // Refresh all authoritative match surfaces even when the websocket echo
    // arrives late or is unavailable.
    _invalidateMatchSurfaces(currentMatch);
  }

  Future<void> addScore(bool isTeam1, int points) async {
    final m = match;
    if (m == null) return;

    _log.warning(
      'addScore: Chỉ có score1/score2 flat (không có scoreDetails) — '
      'backend PATCH /matches/:id/score yêu cầu p1SetsWon/p2SetsWon/scoreDetails. '
      'Sử dụng updateSetsWithDetails() với SetScoreData.',
    );
    throw UnsupportedError(
      'addScore() không được backend hỗ trợ. '
      'Sử dụng updateSetsWithDetails() với thông tin set đầy đủ.',
    );
  }

  Future<void> addFoul(
    bool isTeam1,
    MatchEventType type,
    String description,
  ) async {
    final m = match;
    if (m == null) return;

    final event = MatchEvent(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      teamId: isTeam1 ? m.team1Id : m.team2Id,
      type: type,
      description: description,
    );

    final updatedEvents = List<MatchEvent>.from(m.events)..add(event);

    await ref
        .read(matchRepositoryProvider)
        .updateLiveState(tournamentId, matchId, events: updatedEvents);
  }

  Future<void> addPenalty(
    bool isTeam1,
    String sportType,
    String penaltyId,
    String penaltyName,
    String reason,
  ) async {
    final m = match;
    if (m == null) return;

    final rawSets = m.scoreDetails?['sets'];
    final sets = rawSets is List
        ? rawSets
              .whereType<Map>()
              .map(
                (set) => SetScoreData.fromJson(Map<String, dynamic>.from(set)),
              )
              .toList()
        : m.sets
              .map(
                (set) => SetScoreData(
                  score1: set.score1,
                  score2: set.score2,
                  isFinished: true,
                ),
              )
              .toList();
    final (p1Sets, p2Sets) = computeMatchSetsWon(sets);
    final existingPenalties = m.scoreDetails?['penalties'];
    final penalties = existingPenalties is List
        ? existingPenalties
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    penalties.insert(0, {
      'id': const Uuid().v4(),
      'team': isTeam1 ? 1 : 2,
      'kind': penaltyId,
      'label': penaltyName,
      'note': reason.trim().isEmpty ? null : reason.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });

    await updateSetsWithDetails(
      p1SetsWon: p1Sets,
      p2SetsWon: p2Sets,
      scoreDetails: sets,
      scoreDetailsExtras: {'penalties': penalties},
    );
  }

  Future<void> undoLastEvent() async {
    final m = match;
    if (m == null || m.events.isEmpty) return;

    _log.warning(
      'undoLastEvent: Chỉ có score1/score2 flat (không có scoreDetails) — '
      'backend yêu cầu p1SetsWon/p2SetsWon/scoreDetails.',
    );
    throw UnsupportedError(
      'undoLastEvent() không được backend hỗ trợ. '
      'Cập nhật điểm qua scoreDetails đầy đủ.',
    );
  }

  Future<void> endMatch(String winnerId, String loserId) async {
    final m = match;
    if (m == null) return;

    _log.warning(
      'endMatch: Không có scoreDetails — backend yêu cầu p1SetsWon/p2SetsWon/scoreDetails. '
      'Sử dụng completeMatchWithDetails() thay thế.',
    );
    throw UnsupportedError(
      'endMatch() không được backend hỗ trợ. '
      'Sử dụng completeMatchWithDetails() với danh sách set đầy đủ.',
    );
  }

  /// Gửi scoreDetails theo DTO backend: p1SetsWon, p2SetsWon, scoreDetails.sets.
  Future<void> updateSetsWithDetails({
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    Map<String, dynamic>? scoreDetailsExtras,
    String? winnerId,
    String? overrideReason,
    int? expectedRevision,
    bool refreshSurfaces = true,
  }) async {
    _log.info(
      'updateSetsWithDetails: $p1SetsWon-$p2SetsWon, ${scoreDetails.length} sets',
    );
    final currentMatch = match;
    final tournament = ref.read(tournamentProvider(tournamentId)).value;
    await ref
        .read(matchRepositoryProvider)
        .updateScoreDetails(
          tournamentId,
          matchId,
          p1SetsWon: p1SetsWon,
          p2SetsWon: p2SetsWon,
          scoreDetails: scoreDetails,
          scoreDetailsExtras: scoreDetailsExtras,
          winnerId: winnerId,
          overrideReason: overrideReason,
          expectedRevision: expectedRevision,
          useLiteParticipantAccess: isSuperLiteTournament(
            tournamentConfig: currentMatch?.tournamentConfig,
            tournamentIsLite: tournament?.isLite == true,
          ),
        );
    // A live point write is deliberately optimistic: the score panel already
    // rendered the local state and the socket updates other viewers. Refreshing
    // every match/list/bracket provider on every tap makes the scorer see a
    // loading flicker and can re-apply an older snapshot. Callers that close a
    // set or finalize a match keep the durable surface refresh enabled.
    if (refreshSurfaces) {
      _invalidateMatchSurfaces(currentMatch);
    }
  }

  /// Kết thúc trận kèm scoreDetails đầy đủ (sets).
  /// Chỉ gửi updateScoreDetails kèm winnerId để backend finalize.
  Future<void> completeMatchWithDetails({
    required String winnerId,
    required String loserId,
    required List<SetScoreData> finalSets,
    String? overrideReason,
    int? expectedRevision,
  }) async {
    _log.info(
      'completeMatchWithDetails: winner=$winnerId, ${finalSets.length} sets',
    );
    final (p1Sets, p2Sets) = computeMatchSetsWon(finalSets);

    // Gửi scoreDetails kèm winnerId. Backend sẽ tự finalize trận,
    // advance bracket và cập nhật ELO trong cùng workflow.
    // Không gọi legacy completion thêm lần nữa để tránh double update.
    await updateSetsWithDetails(
      p1SetsWon: p1Sets,
      p2SetsWon: p2Sets,
      scoreDetails: finalSets,
      winnerId: winnerId,
      overrideReason: overrideReason,
      expectedRevision: expectedRevision,
    );
  }

  Future<void> advanceWinner({
    required String nextMatchId,
    required String winnerId,
    required String winnerName,
    required bool isTeam1,
  }) async {
    await ref
        .read(matchRepositoryProvider)
        .advanceWinner(
          tournamentId,
          nextMatchId,
          winnerId: winnerId,
          winnerName: winnerName,
          isTeam1: isTeam1,
        );
  }

  Future<void> updateMatchResultByAdmin({
    required int score1,
    required int score2,
    required String winnerId,
    required String loserId,
  }) async {
    final m = match;
    if (m == null) return;

    _log.warning(
      'ADMIN OVERRIDE: Admin đang sửa kết quả trận $matchId từ ${m.score1}-${m.score2} thành $score1-$score2, Người thắng: $winnerId',
    );

    _log.warning(
      'updateMatchResultByAdmin: Admin override chỉ có score1/score2 flat (không có scoreDetails) — '
      'backend yêu cầu p1SetsWon/p2SetsWon/scoreDetails. Chuyển sang applyOperation(action: OVERRIDE_RESULT) hoặc updateSetsWithDetails().',
    );
    throw UnsupportedError(
      'updateMatchResultByAdmin() không được backend hỗ trợ với flat score. '
      'Sử dụng updateSetsWithDetails() hoặc applyOperation(action: OVERRIDE_RESULT).',
    );
  }

  /// Áp dụng thao tác đặc biệt lên trận đấu qua PATCH /matches/:id/operation.
  /// action: WALKOVER | NO_SHOW | RETIREMENT | DISQUALIFICATION |
  /// OVERRIDE_RESULT | POSTPONE | ABANDON
  Future<void> applyOperation({
    required String action,
    required String reason,
    String? winnerId,
  }) async {
    _log.info('Applying operation $action to match $matchId');
    await ref
        .read(matchRepositoryProvider)
        .matchOperation(
          matchId,
          action: action,
          reason: reason,
          winnerId: winnerId,
        );
  }
}

final matchControllerProvider = Provider.autoDispose
    .family<MatchController, MatchControlParams>((ref, arg) {
      return MatchController(ref, arg.tournamentId, arg.matchId);
    });
