/// Who stands where on a badminton or tennis court, who serves and who
/// receives. Pure: the caller passes what the rules already decided.
library;

enum CourtCellRole { none, server, receiver }

/// One cell of the court. [rightCourt] is the court side from the point of
/// view of the team facing the net. [playerIndex] is the index in the team
/// (0 or 1), null when nobody stands there (singles).
class RacketCourtCell {
  const RacketCourtCell({
    required this.team,
    required this.rightCourt,
    required this.playerIndex,
    required this.role,
  });

  final int team;
  final bool rightCourt;
  final int? playerIndex;
  final CourtCellRole role;
}

/// Always returns four cells in the order team 1 right, team 1 left, team 2
/// right, team 2 left.
///
/// The server stands in the [serverRight] cell of [serverTeam] and the
/// receiver in the diagonal (same side) cell of the other team. In doubles the
/// serving pair follows [serverPlayerIndex] (the partner takes the other cell);
/// the receiving pair uses [team1RightPlayer] / [team2RightPlayer] (default 0).
/// When [serverTeam] or the doubles server player is unknown, no role is set.
List<RacketCourtCell> racketCourtCells({
  required int? serverTeam,
  required bool serverRight,
  required int? serverPlayerIndex,
  required bool doubles,
  int team1RightPlayer = 0,
  int team2RightPlayer = 0,
}) {
  final hasRoles = serverTeam != null && (!doubles || serverPlayerIndex != null);
  int? rightOf(int team) {
    if (!doubles) return null;
    if (hasRoles && team == serverTeam) {
      return serverRight ? serverPlayerIndex : 1 - serverPlayerIndex!;
    }
    return team == 1 ? team1RightPlayer : team2RightPlayer;
  }

  int? playerAt(int team, bool right) {
    if (!doubles) {
      // Singles: the player stands on the serve side, or on the right when the
      // serve is unknown.
      final side = hasRoles ? serverRight : true;
      return right == side ? 0 : null;
    }
    final r = rightOf(team)!;
    return right ? r : 1 - r;
  }

  CourtCellRole roleAt(int team, bool right) {
    if (!hasRoles || right != serverRight) return CourtCellRole.none;
    return team == serverTeam ? CourtCellRole.server : CourtCellRole.receiver;
  }

  return [
    for (final team in const [1, 2])
      for (final right in const [true, false])
        RacketCourtCell(
          team: team,
          rightCourt: right,
          playerIndex: playerAt(team, right),
          role: roleAt(team, right),
        ),
  ];
}
