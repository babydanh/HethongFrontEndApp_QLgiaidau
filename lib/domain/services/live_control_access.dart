/// Who may open the scoring controls for a tournament match.
///
/// Mirrors the Web rule `canControlTournamentLive`: the tournament creator and
/// the referee assigned to the match always can; any other admin cannot (a
/// global ADMIN role must not leak scoring rights across tournaments); everyone
/// else follows the backend `score-access` answer. A null answer (loading or
/// failed) is treated as "no". A missing [userId] (profile still loading) only
/// drops the creator/referee shortcut; it never blocks the backend verdict.
/// [isTournamentStaff] (invited co-organizer or accepted tournament referee)
/// counts like the creator, so an ADMIN who is also staff keeps the button.
bool canControlTournamentLive({
  required String? userId,
  required bool isAdmin,
  required String? createdBy,
  String? refereeId,
  bool isTournamentStaff = false,
  required bool? scoreAccess,
}) {
  final hasUser = userId != null && userId.isNotEmpty;
  if (hasUser &&
      (userId == createdBy || userId == refereeId || isTournamentStaff)) {
    return true;
  }
  if (isAdmin) return false;
  return scoreAccess == true;
}

/// True when a signed-in admin must not score on a whole screen: the
/// tournament is not theirs. Fails closed while the creator is unknown. A
/// referee-only exception is per match, so callers keep `isReferee` separate.
/// Mirrors the Web rule `isAdminScoringLocked`; invited staff of the
/// tournament ([isTournamentStaff]) is never locked.
bool isAdminScoringLocked({
  required String? userId,
  required bool isAdmin,
  required String? createdBy,
  bool isTournamentStaff = false,
}) {
  if (userId == null || userId.isEmpty || !isAdmin) return false;
  return userId != createdBy && !isTournamentStaff;
}
