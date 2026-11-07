import 'package:app_quanly_giaidau/domain/services/tennis_rules.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';

/// Tennis rules applied to the live panel state. Shared by the notifier (to
/// score) and the tennis panel (to show serve, banner and DEUCE).
extension ScorePanelTennis on ScorePanelState {
  /// Plan for the set being played. Final-set options only apply to strict
  /// matches: an open (Lite) scorecard closes sets by hand.
  TennisSetPlan get tennisPlan => tennisSetPlan(
    finalSetMode: config.finalSetMode,
    tiebreakMode: config.tiebreakMode,
    tiebreakPoints: config.tiebreakPoints ?? 7,
    decidingSet:
        !isOpenScoring &&
        tennisIsDecidingSet(team1SetWins, team2SetWins, config.setsToWin),
  );

  /// True when a 10 point match tie-break is being played instead of the
  /// deciding set: no game has been played in the current set yet.
  bool get tennisMatchTiebreakDue {
    if (!tennisPlan.matchTiebreak) return false;
    final active = finishedSets.isNotEmpty && !finishedSets.last.isFinished
        ? finishedSets.last
        : null;
    return active == null || (active.score1 == 0 && active.score2 == 0);
  }

  /// Points are counted as a tie-break (normal or match tie-break).
  bool get tennisInTiebreak =>
      (tennis?.isTiebreak ?? false) || tennisMatchTiebreakDue;

  /// Team (1 or 2) serving now. Team 1 serves the first game of the match.
  int get tennisServerTeam => tennisServer(
    gamesPlayed: finishedSets.fold<int>(
      0,
      (total, set) => total + set.score1 + set.score2,
    ),
    tiebreak: tennisInTiebreak,
    tiebreakPoints:
        (tennis?.team1GamePoints ?? 0) + (tennis?.team2GamePoints ?? 0),
  );
}
