import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';

import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

abstract class ITournamentRepository {
  Future<Tournament> create(Tournament tournament);
  Future<Tournament?> getById(String id, {String? inviteCode});
  Future<Tournament?> getByInviteCode(String code);
  Future<List<TournamentSponsor>> getPublicSponsors(String tournamentId);

  Future<void> joinLite(String inviteCode);
  Future<TournamentWorkspace> getMyWorkspace();
  Future<void> respondToRefereeInvite({
    required String tournamentId,
    required String refereeId,
    required String action,
  });
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  });
  Future<List<OrganizerOpsReferee>> getTournamentReferees(String tournamentId);
  Future<List<OrganizerOpsAuditEntry>> getOpsAuditLogs(
    String tournamentId, {
    String? divisionId,
  });
  Future<void> kickParticipant({
    required String tournamentId,
    required String participantId,
    required String reason,
  });
  Future<List<TournamentDivisionOption>> getDivisions(String tournamentId);

  Future<TournamentRegistrationResult> registerParticipant({
    required String tournamentId,
    required String teamName,
    String? divisionId,
    String? inviteCode,
    String? partnerEmailOrPhone,
    String? footballTeamId,
    List<String>? memberIds,
    List<String>? reserveMemberIds,
    bool rankingConsent = false,
    Map<String, dynamic>? customResponses,
  });
  Future<FootballRosterStatus> getFootballRosterStatus({
    required String tournamentId,
    required String participantId,
  });
  Future<FootballRosterStatus> updateFootballRoster({
    required String tournamentId,
    required String participantId,
    required List<String> memberIds,
    required List<String> reserveMemberIds,
  });
  Future<void> respondFootballRoster({
    required String tournamentId,
    required String participantId,
    required String action,
  });
  Stream<Tournament?> watch(String id);
  Stream<List<Tournament>> watchAll();
  Future<({
    List<Tournament> tournaments,
    String? nextCursor,
    bool hasMore,
  })> getPublicTournamentsPaged({
    String? cursor,
    int limit = 6,
    String? sport,
    String? status,
    String? search,
    String? content,
    String? bracket,
    String? ranked,
    String? province,
    String? ward,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> updateStatus(String id, String status);
  Future<void> updateToken(String id, String role, String newToken);
  Future<void> delete(String id);

  // Group Standings
  Future<Map<String, dynamic>> getGroupStandings(
    String tournamentId, {
    String? divisionId,
  });

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
  Future<List<MatchModel>> getBracketMatches(
    String tournamentId, {
    String? divisionId,
  });
  Future<void> updateBracketSlots(
    String tournamentId, {
    String? divisionId,
    required List<Map<String, dynamic>> operations,
    bool isLite = false,
  });
  Stream<List<MatchModel>> watchBracketMatches(
    String tournamentId, {
    String? divisionId,
  });
}
