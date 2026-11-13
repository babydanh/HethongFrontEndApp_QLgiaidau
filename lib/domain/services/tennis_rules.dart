/// Pure tennis rules: game result, tie-break plan and who serves.
///
/// Rules follow the Backend `sportRules.format` keys (`noAd`, `finalSetMode`,
/// `tiebreakMode`, `tiebreakAtGames`, `tiebreakPoints`) and the reference engine
/// in openspec/changes/cach-bam-diem-cac-mon/reference/scoring-engine.js.
/// Teams are 1 and 2; points are raw counts (0,1,2,3 = 0,15,30,40).
library;

/// What happens in the deciding set (both sides one set short of the match).
enum TennisFinalSetMode {
  /// Normal set with the usual tie-break.
  standard,

  /// Normal set, but its tie-break is played to 10.
  tb10Final,

  /// Play on until a 2 game lead, no tie-break.
  noTiebreak,

  /// A 10 point match tie-break replaces the deciding set.
  matchTiebreak,
}

enum TennisTiebreakMode { standard, super10, none }

/// Accepts the Backend values (STANDARD, SUPER_TIEBREAK, NO_TIEBREAK) and the
/// short names of the design (TB7, TB10_FINAL, NO_TB_FINAL, MATCH_TB10).
TennisFinalSetMode? parseTennisFinalSetMode(Object? raw) {
  switch (raw?.toString().trim().toUpperCase()) {
    case 'STANDARD':
    case 'TB7':
      return TennisFinalSetMode.standard;
    case 'TB10_FINAL':
      return TennisFinalSetMode.tb10Final;
    case 'NO_TIEBREAK':
    case 'NO_TB_FINAL':
      return TennisFinalSetMode.noTiebreak;
    case 'SUPER_TIEBREAK':
    case 'MATCH_TB10':
      return TennisFinalSetMode.matchTiebreak;
    default:
      return null;
  }
}

TennisTiebreakMode? parseTennisTiebreakMode(Object? raw) {
  switch (raw?.toString().trim().toUpperCase()) {
    case 'STANDARD_7':
      return TennisTiebreakMode.standard;
    case 'SUPER_10':
      return TennisTiebreakMode.super10;
    case 'NONE':
      return TennisTiebreakMode.none;
    default:
      return null;
  }
}

/// Whether the player with [a] points just won the game against [b].
/// No-Ad: the first point after 40-40 decides. A tie-break needs
/// [tiebreakTarget] points and a 2 point lead.
bool tennisGameWon({
  required int a,
  required int b,
  required bool noAd,
  required bool tiebreak,
  int tiebreakTarget = 7,
}) {
  if (tiebreak) return a >= tiebreakTarget && a - b >= 2;
  return noAd ? a >= 4 : a >= 4 && a - b >= 2;
}

/// True when both sides are one set short of winning the match.
bool tennisIsDecidingSet(int team1Sets, int team2Sets, int setsToWin) =>
    setsToWin >= 2 && team1Sets == setsToWin - 1 && team2Sets == setsToWin - 1;

/// How the set being played ends in a tie.
class TennisSetPlan {
  const TennisSetPlan({
    required this.tiebreakEnabled,
    required this.tiebreakTarget,
    required this.matchTiebreak,
  });

  final bool tiebreakEnabled;
  final int tiebreakTarget;

  /// The set is a 10 point match tie-break played from 0-0.
  final bool matchTiebreak;
}

const _matchTiebreakPoints = 10;

TennisSetPlan tennisSetPlan({
  required TennisFinalSetMode finalSetMode,
  required TennisTiebreakMode tiebreakMode,
  required int tiebreakPoints,
  required bool decidingSet,
}) {
  final matchTiebreak =
      decidingSet && finalSetMode == TennisFinalSetMode.matchTiebreak;
  final noTiebreak =
      tiebreakMode == TennisTiebreakMode.none ||
      (decidingSet && finalSetMode == TennisFinalSetMode.noTiebreak);
  final ten =
      matchTiebreak ||
      tiebreakMode == TennisTiebreakMode.super10 ||
      (decidingSet && finalSetMode == TennisFinalSetMode.tb10Final);
  return TennisSetPlan(
    tiebreakEnabled: matchTiebreak || !noTiebreak,
    tiebreakTarget: ten ? _matchTiebreakPoints : tiebreakPoints,
    matchTiebreak: matchTiebreak,
  );
}

/// Team (1 or 2) serving the current game. A tie-break counts as one game, so
/// [gamesPlayed] (all games of all sets, played before the current game) keeps
/// the alternation across sets. In a tie-break the first point is served by the
/// game server, then the serve changes every 2 points; [tiebreakPoints] is the
/// number of tie-break points played so far.
int tennisServer({
  required int gamesPlayed,
  required bool tiebreak,
  int tiebreakPoints = 0,
  int firstServer = 1,
}) {
  final gameServer = gamesPlayed.isEven ? firstServer : 3 - firstServer;
  if (!tiebreak) return gameServer;
  return ((tiebreakPoints + 1) ~/ 2).isEven ? gameServer : 3 - gameServer;
}

/// The server stands in the right (deuce) court when the points played in the
/// current game (or tie-break) are even, and in the left (ad) court when odd.
bool tennisServeRight(int pointsInGame) => pointsInGame.isEven;

/// The team (1 or 2) that wins the current game with the next point, or 0 when
/// no team is one point from the game. With advantage rules at 40-40 neither
/// team is; No-Ad makes both teams one point away, which this returns as 0
/// because the next point decides for whoever wins it.
int tennisGamePointTeam({
  required int p1,
  required int p2,
  required bool noAd,
  required bool tiebreak,
  int tiebreakTarget = 7,
}) {
  bool wins(int a, int b) => tennisGameWon(
    a: a + 1,
    b: b,
    noAd: noAd,
    tiebreak: tiebreak,
    tiebreakTarget: tiebreakTarget,
  );
  final one = wins(p1, p2);
  final two = wins(p2, p1);
  if (one == two) return 0;
  return one ? 1 : 2;
}

/// Players change ends after every odd numbered game of a set.
bool tennisChangeEndsAfterGame(int gamesInSet) => gamesInSet.isOdd;

/// In a tie-break players change ends every 6 points.
bool tennisTiebreakChangeEnds(int tiebreakPoints) =>
    tiebreakPoints > 0 && tiebreakPoints % 6 == 0;

/// How many service games [team] already served, out of [gamesPlayed] games
/// played before the current one (a tie-break counts as one game).
int tennisTeamServiceGames({
  required int gamesPlayed,
  required int team,
  int firstServer = 1,
}) {
  final firstGames = (gamesPlayed + 1) ~/ 2;
  return team == firstServer ? firstGames : gamesPlayed ~/ 2;
}

/// Doubles: index (0 or 1) of the player who serves. Partners alternate every
/// service game of the team, starting from [firstPlayer]; inside a tie-break
/// they alternate every serving turn ([tiebreakTurnsServed]).
int tennisServerPlayerIndex({
  required int teamServiceGames,
  int firstPlayer = 0,
  int tiebreakTurnsServed = 0,
}) => (firstPlayer + teamServiceGames + tiebreakTurnsServed) % 2;

/// Serving turns the team already had in the current tie-break. The game
/// server serves turn 0 (one point), then the teams take turns of two points.
int tennisTiebreakTurnsServed({
  required int tiebreakPoints,
  required bool isGameServer,
}) {
  final turn = (tiebreakPoints + 1) ~/ 2;
  final served = isGameServer ? turn ~/ 2 : (turn - 1) ~/ 2;
  return served < 0 ? 0 : served;
}
