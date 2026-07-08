import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

abstract class ITournamentRepository {
  Future<Tournament> create(Tournament tournament);
  Future<Tournament?> getById(String id);
  Future<TournamentWorkspace> getMyWorkspace();
  Future<void> respondToRefereeInvite({
    required String tournamentId,
    required String refereeId,
    required String action,
  });
  Stream<Tournament?> watch(String id);
  Stream<List<Tournament>> watchAll();
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> updateStatus(String id, String status);
  Future<void> updateToken(String id, String role, String newToken);
  Future<void> delete(String id);

  // Follow / Unfollow
  Future<void> followTournament(String id);
  Future<void> unfollowTournament(String id);
  Future<bool> isFollowing(String id);
  Future<List<Tournament>> getFollowedTournaments();

  // Bracket
  Future<List<MatchModel>> getBracketMatches(String tournamentId);
  Stream<List<MatchModel>> watchBracketMatches(String tournamentId);
}
