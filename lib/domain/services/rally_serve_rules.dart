import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

/// Who serves in a rally-point game, derived from the score (plus a little
/// history the score cannot tell). Teams are numbered 1 and 2. A null field
/// means "unknown or not applicable": the UI shows nothing rather than guess.
class RallyServe {
  const RallyServe({this.serverTeam, this.rightCourt, this.serverPlayer});

  final int? serverTeam;

  /// Badminton only: the server stands in the right court (even score).
  final bool? rightCourt;

  /// Badminton doubles only: 1 or 2, the player who serves.
  final int? serverPlayer;
}

/// A reminder the scorer should see next to the score.
enum RallyBreak {
  none,
  interval60,
  interval60ChangeEnds,
  betweenGames,
  changeEnds,
}

/// Team that serves first in game [gameIndex] (0-based), or null if unknown.
/// Badminton: the winner of the previous game. Table tennis: alternates.
int? rallyGameFirstServer({
  required SportRuleKind kind,
  required int gameIndex,
  int firstServer = 1,
  int? prevGameWinner,
}) {
  switch (kind) {
    case SportRuleKind.badminton:
      return gameIndex == 0 ? firstServer : prevGameWinner;
    case SportRuleKind.tableTennis:
      return gameIndex.isEven ? firstServer : 3 - firstServer;
    default:
      return null;
  }
}

/// Serve state for badminton and table tennis; empty for any other sport.
///
/// [firstServer] is the team that serves first in game 1. [lastWinner] is the
/// team that won the previous rally of this game, and [swaps1]/[swaps2] count
/// how often each team won a rally while serving (badminton doubles: each win
/// swaps the pair). Pass null for what the caller does not track.
RallyServe rallyServe({
  required SportRuleKind kind,
  required int p1,
  required int p2,
  required int gameIndex,
  required bool doubles,
  int firstServer = 1,
  int? lastWinner,
  int? prevGameWinner,
  int? swaps1,
  int? swaps2,
}) {
  final first = rallyGameFirstServer(
    kind: kind,
    gameIndex: gameIndex,
    firstServer: firstServer,
    prevGameWinner: prevGameWinner,
  );
  switch (kind) {
    case SportRuleKind.tableTennis:
      if (first == null) return const RallyServe();
      final total = p1 + p2;
      final turns = p1 >= 10 && p2 >= 10 ? total - 20 : total ~/ 2;
      return RallyServe(serverTeam: turns.isEven ? first : 3 - first);
    case SportRuleKind.badminton:
      final server = _isOpening(p1, p2) ? first : lastWinner;
      if (server == null) return const RallyServe();
      final score = server == 1 ? p1 : p2;
      final swaps = server == 1 ? swaps1 : swaps2;
      final onRight = score.isEven;
      return RallyServe(
        serverTeam: server,
        rightCourt: onRight,
        // Player 1 starts on the right; the pair swaps after each win on serve.
        serverPlayer: doubles && swaps != null
            ? ((swaps.isEven == onRight) ? 1 : 2)
            : null,
      );
    default:
      return const RallyServe();
  }
}

bool _isOpening(int p1, int p2) => p1 == 0 && p2 == 0;

/// The reminder to show for the current score. [lastWinner] is the team that
/// won the last rally; without it nothing is shown, because the score alone
/// cannot tell whether a leader has *just* reached the mark.
RallyBreak rallyServeBanner({
  required SportRuleKind kind,
  required int p1,
  required int p2,
  required int gameIndex,
  int bestOf = 3,
  int? lastWinner,
}) {
  final isDeciding = bestOf > 1 && gameIndex == bestOf - 1;
  final justReached = lastWinner == null
      ? null
      : (lastWinner == 1 ? (p1, p2) : (p2, p1));
  switch (kind) {
    case SportRuleKind.badminton:
      if (_isOpening(p1, p2) && gameIndex > 0) return RallyBreak.betweenGames;
      if (justReached != null && justReached.$1 == 11 && justReached.$2 < 11) {
        return isDeciding
            ? RallyBreak.interval60ChangeEnds
            : RallyBreak.interval60;
      }
      return RallyBreak.none;
    case SportRuleKind.tableTennis:
      if (isDeciding &&
          justReached != null &&
          justReached.$1 == 5 &&
          justReached.$2 < 5) {
        return RallyBreak.changeEnds;
      }
      return RallyBreak.none;
    default:
      return RallyBreak.none;
  }
}
