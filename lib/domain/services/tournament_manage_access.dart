import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';

/// Who sees the "Manage" button on a tournament.
///
/// Mirrors the Web rule: only tournaments the user organizes or co-organizes
/// (the workspace `organizedTournaments` / `coOrganizerTournaments` lists) get
/// a manage entry. A global ADMIN or ORGANIZER role alone does not, because the
/// backend only lets those roles in through other paths and the button would
/// otherwise show on tournaments the user does not run. The creator check keeps
/// the button available while the (paginated) workspace is still loading.
bool canManageTournament({
  required String tournamentId,
  required String? userId,
  required String creatorId,
  required Set<String> managedTournamentIds,
}) {
  final hasUser = userId != null && userId.isNotEmpty;
  if (hasUser && userId == creatorId) return true;
  return managedTournamentIds.contains(tournamentId);
}

/// Ids of tournaments where the user is invited staff who may score: an
/// invited co-organizer or an accepted referee (workspace
/// `coOrganizerTournaments` / `refereeTournaments`). Empty until it loads.
Set<String> scoringStaffTournamentIds(TournamentWorkspace? workspace) => {
  ...?workspace?.coOrganizerTournaments.map((t) => t.id),
  ...?workspace?.refereeTournaments.map((r) => r.tournamentId),
};
