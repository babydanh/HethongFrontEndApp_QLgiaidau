import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/data/models/penalty_model.dart';
import 'package:app_quanly_giaidau/core/services/penalty_service.dart';
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

  MatchModel? get match => ref.read(singleMatchProvider((tournamentId: tournamentId, matchId: matchId))).value;

  Future<void> updateConfig({int? maxScore, bool? winByTwo, int? timeLimitMinutes}) async {
    final m = match;
    if (m == null) return;
    
    await ref.read(matchRepositoryProvider).updateLiveState(
      tournamentId, 
      matchId,
      maxScore: maxScore,
      winByTwo: winByTwo,
      timeLimitMinutes: timeLimitMinutes,
    );
  }

  Future<void> startMatch({int? maxScore, int? timeLimitMinutes, String? refereeName}) async {
    await ref.read(matchRepositoryProvider).startMatch(
      tournamentId, 
      matchId,
      maxScore: maxScore,
      timeLimitMinutes: timeLimitMinutes,
      refereeName: refereeName,
    );
  }

  Future<void> addScore(bool isTeam1, int points) async {
    final m = match;
    if (m == null) return;

    final newScore1 = m.score1 + (isTeam1 ? points : 0);
    final newScore2 = m.score2 + (!isTeam1 ? points : 0);

    final event = MatchEvent(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      teamId: isTeam1 ? m.team1Id : m.team2Id,
      type: MatchEventType.score,
      pointsChange: points,
    );

    final updatedEvents = List<MatchEvent>.from(m.events)..add(event);

    await ref.read(matchRepositoryProvider).updateLiveState(
      tournamentId,
      matchId,
      score1: newScore1 < 0 ? 0 : newScore1,
      score2: newScore2 < 0 ? 0 : newScore2,
      events: updatedEvents,
    );
  }

  Future<void> addFoul(bool isTeam1, MatchEventType type, String description) async {
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

    await ref.read(matchRepositoryProvider).updateLiveState(
      tournamentId,
      matchId,
      events: updatedEvents,
    );
  }

  Future<void> addPenalty(bool isTeam1, String sportType, String penaltyId, String penaltyName, String reason) async {
    final m = match;
    if (m == null) return;

    final teamId = isTeam1 ? m.team1Id : m.team2Id;
    final description = '[$penaltyName] $reason';

    final penalty = Penalty(
      teamId: teamId,
      type: penaltyId,
      reason: reason,
      timestamp: DateTime.now(),
    );

    final event = MatchEvent(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      teamId: teamId,
      type: MatchEventType.penalty,
      description: description,
    );

    final updatedPenalties = List<Penalty>.from(m.penalties)..add(penalty);
    final updatedEvents = List<MatchEvent>.from(m.events)..add(event);

    int newScore1 = m.score1;
    int newScore2 = m.score2;

    // Tính toán điểm phạt cho ĐỐI PHƯƠNG
    final opponentPoints = PenaltyService.calculateOpponentPoints(sportType, penaltyId);
    if (opponentPoints > 0) {
      if (isTeam1) {
        newScore2 += opponentPoints;
      } else {
        newScore1 += opponentPoints;
      }
    }

    await ref.read(matchRepositoryProvider).updateLiveState(
      tournamentId,
      matchId,
      score1: newScore1,
      score2: newScore2,
      events: updatedEvents,
      penalties: updatedPenalties,
    );
  }

  Future<void> undoLastEvent() async {
    final m = match;
    if (m == null || m.events.isEmpty) return;

    final lastEvent = m.events.last;
    final updatedEvents = List<MatchEvent>.from(m.events)..removeLast();

    int score1 = m.score1;
    int score2 = m.score2;

    if (lastEvent.type == MatchEventType.score) {
      if (lastEvent.teamId == m.team1Id) {
        score1 -= lastEvent.pointsChange;
      } else if (lastEvent.teamId == m.team2Id) {
        score2 -= lastEvent.pointsChange;
      }
    }

    await ref.read(matchRepositoryProvider).updateLiveState(
      tournamentId,
      matchId,
      score1: score1 < 0 ? 0 : score1,
      score2: score2 < 0 ? 0 : score2,
      events: updatedEvents,
    );
  }

  Future<void> endMatch(String winnerId, String loserId) async {
    final m = match;
    if (m == null) return;

    await ref.read(matchRepositoryProvider).completeMatch(
      tournamentId,
      matchId,
      winnerId: winnerId,
      loserId: loserId,
      finalScore1: m.score1,
      finalScore2: m.score2,
    );
  }

  /// Gửi scoreDetails theo DTO backend: p1SetsWon, p2SetsWon, scoreDetails.sets.
  Future<void> updateSetsWithDetails({
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    String? winnerId,
    String? overrideReason,
  }) async {
    _log.info('updateSetsWithDetails: $p1SetsWon-$p2SetsWon, ${scoreDetails.length} sets');
    await ref.read(matchRepositoryProvider).updateScoreDetails(
      tournamentId,
      matchId,
      p1SetsWon: p1SetsWon,
      p2SetsWon: p2SetsWon,
      scoreDetails: scoreDetails,
      winnerId: winnerId,
      overrideReason: overrideReason,
    );
  }

  /// Kết thúc trận kèm scoreDetails đầy đủ (sets).
  /// Gọi updateScoreDetails + completeMatch.
  Future<void> completeMatchWithDetails({
    required String winnerId,
    required String loserId,
    required List<SetScoreData> finalSets,
    String? overrideReason,
  }) async {
    _log.info('completeMatchWithDetails: winner=$winnerId, ${finalSets.length} sets');
    final (p1Sets, p2Sets) = computeMatchSetsWon(finalSets);

    // 1. Gửi scoreDetails
    await updateSetsWithDetails(
      p1SetsWon: p1Sets,
      p2SetsWon: p2Sets,
      scoreDetails: finalSets,
      winnerId: winnerId,
      overrideReason: overrideReason,
    );

    // 2. Complete match
    final m = match;
    if (m != null) {
      await ref.read(matchRepositoryProvider).completeMatch(
        tournamentId,
        matchId,
        winnerId: winnerId,
        loserId: loserId,
        finalScore1: finalSets.isNotEmpty ? finalSets.last.score1 : 0,
        finalScore2: finalSets.isNotEmpty ? finalSets.last.score2 : 0,
      );
    }
  }

  Future<void> advanceWinner({
    required String nextMatchId,
    required String winnerId,
    required String winnerName,
    required bool isTeam1,
  }) async {
    await ref.read(matchRepositoryProvider).advanceWinner(
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

    // First update the live state scores
    await ref.read(matchRepositoryProvider).updateLiveState(
      tournamentId,
      matchId,
      score1: score1,
      score2: score2,
    );

    // Then update the completed state
    await ref.read(matchRepositoryProvider).completeMatch(
      tournamentId,
      matchId,
      winnerId: winnerId,
      loserId: loserId,
      finalScore1: score1,
      finalScore2: score2,
    );
  }
}

final matchControllerProvider = Provider.autoDispose.family<MatchController, MatchControlParams>((ref, arg) {
  return MatchController(ref, arg.tournamentId, arg.matchId);
});
