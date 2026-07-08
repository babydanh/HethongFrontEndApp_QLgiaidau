import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/match_event.dart';
import 'package:app_quanly_giaidau/domain/entities/penalty.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

abstract class IMatchRepository {
  Future<MatchModel> create(String tournamentId, MatchModel match);
  Future<void> createBatch(String tournamentId, List<MatchModel> matches);
  Stream<List<MatchModel>> watchByTournament(String tournamentId, {String? divisionId});
  Stream<List<MatchModel>> watchLive(String tournamentId);
  Stream<MatchModel?> watchMatch(String tournamentId, String matchId);

  Future<void> updateScore(
    String tournamentId,
    String matchId, {
    required int score1,
    required int score2,
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
  });

  Future<void> completeMatch(
    String tournamentId,
    String matchId, {
    required String winnerId,
    required String loserId,
    required int finalScore1,
    required int finalScore2,
  });

  Future<void> updateSets(
    String tournamentId,
    String matchId,
    List<SetScore> sets,
  );

  /// Cập nhật scoreDetails theo đúng backend DTO.
  /// Gửi p1SetsWon, p2SetsWon, scoreDetails.sets, winnerId, overrideReason.
  Future<void> updateScoreDetails(
    String tournamentId,
    String matchId, {
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    String? winnerId,
    String? overrideReason,
  });

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

  Future<List<MatchModel>> getAllByTournament(String tournamentId, {String? divisionId});
  Future<void> deleteAll(String tournamentId);
  Future<List<MatchModel>> getMatches({String? status, bool? publicOnly});
}
