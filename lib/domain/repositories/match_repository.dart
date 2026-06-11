import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/data/models/penalty_model.dart';

abstract class IMatchRepository {
  Future<MatchModel> create(String tournamentId, MatchModel match);
  Future<void> createBatch(String tournamentId, List<MatchModel> matches);
  Stream<List<MatchModel>> watchByTournament(String tournamentId);
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

  Future<List<MatchModel>> getAllByTournament(String tournamentId);
  Future<void> deleteAll(String tournamentId);
}
