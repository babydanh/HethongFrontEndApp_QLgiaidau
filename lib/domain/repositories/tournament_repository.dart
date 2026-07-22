import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';

abstract class ITournamentRepository {
  Future<Tournament> create(Tournament tournament);
  Future<Tournament?> getById(String id);
  Future<TournamentWorkspace> getMyWorkspace();
  Future<void> respondToRefereeInvite({
    required String tournamentId,
    required String refereeId,
    required String action,
  });
  Future<List<TournamentDivisionOption>> getDivisions(String tournamentId);
  Future<TournamentRegistrationResult> registerParticipant({
    required String tournamentId,
    required String teamName,
    String? divisionId,
    String? inviteCode,
    String? partnerEmailOrPhone,
  });
  Stream<Tournament?> watch(String id);
  Stream<List<Tournament>> watchAll();
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> updateStatus(String id, String status);
  Future<void> updateToken(String id, String role, String newToken);
  Future<void> delete(String id);

  // Group Standings
  Future<Map<String, dynamic>> getGroupStandings(String tournamentId, {String? divisionId});

  // Follow / Unfollow
  Future<void> followTournament(String id);
  Future<void> unfollowTournament(String id);
  Future<bool> isFollowing(String id);
  Future<List<Tournament>> getFollowedTournaments();

  // Withdraw
  Future<Map<String, dynamic>> withdraw({
    required String tournamentId,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? divisionId,
  });

  // Bracket
  Future<List<MatchModel>> getBracketMatches(String tournamentId);
  Stream<List<MatchModel>> watchBracketMatches(String tournamentId);
}
