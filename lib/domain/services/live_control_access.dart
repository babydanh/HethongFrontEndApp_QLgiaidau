/// Who may open the scoring controls for a tournament match.
///
/// Mirrors the Web rule `canControlTournamentLive`: the tournament creator and
/// the referee assigned to the match always can; any other admin cannot (a
/// global ADMIN role must not leak scoring rights across tournaments); everyone
/// else follows the backend `score-access` answer. A null answer (loading or
/// failed) is treated as "no". A missing [userId] (profile still loading) only
/// drops the creator/referee shortcut; it never blocks the backend verdict.
bool canControlTournamentLive({
  required String? userId,
  required bool isAdmin,
  required String? createdBy,
  String? refereeId,
  required bool? scoreAccess,
}) {
  final hasUser = userId != null && userId.isNotEmpty;
  if (hasUser && (userId == createdBy || userId == refereeId)) return true;
  if (isAdmin) return false;
  return scoreAccess == true;
}
