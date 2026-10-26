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
