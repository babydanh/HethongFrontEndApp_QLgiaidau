import 'package:app_quanly_giaidau/domain/services/racket_court_layout.dart';
import 'package:app_quanly_giaidau/domain/services/rally_serve_rules.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/services/tennis_rules.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_tennis.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_undo.dart';

/// Badminton and tennis court state derived from the panel state: who serves,
/// who stands where, and what Undo can take back. Used by the notifier (to
/// act) and by the court panel (to draw).
extension ScorePanelRacket on ScorePanelState {
  bool get isRacket =>
      config.kind == SportRuleKind.badminton ||
      config.kind == SportRuleKind.tennis;

  bool get _isTennis => config.kind == SportRuleKind.tennis;

  /// Sets closed so far. Tennis keeps the live set in the same list.
  int get racketClosedSetCount =>
      config.scoringModel == SportScoringModel.tennisSet
      ? finishedSets.where((set) => set.isFinished).length
      : finishedSets.length;

  /// The newest step can be taken back while no set was closed since.
  bool get canRacketUndo =>
      racketUndo.isNotEmpty &&
      racketUndo.last.closedSetCount == racketClosedSetCount;

  /// The first server can be picked only before any point of the match.
  bool get racketCanPickFirstServer =>
      isRacket &&
      hasNoPoints &&
      (tennis?.team1GamePoints ?? 0) == 0 &&
      (tennis?.team2GamePoints ?? 0) == 0;

  int get _tennisGamesPlayed => finishedSets.fold<int>(
    0,
    (total, set) => total + set.score1 + set.score2,
  );

  int get _tennisPointsInGame =>
      (tennis?.team1GamePoints ?? 0) + (tennis?.team2GamePoints ?? 0);

  RallyServe _badmintonServe(bool doubles) {
    final r = rally ?? const RallySetState();
    final prev = finishedSets.isEmpty ? null : finishedSets.last;
    return rallyServe(
      kind: SportRuleKind.badminton,
      p1: r.currentP1,
      p2: r.currentP2,
      gameIndex: finishedSets.length,
      doubles: doubles,
      firstServer: racketPick.firstTeam,
      lastWinner: r.lastWinner,
      prevGameWinner: prev == null ? null : (prev.score1 > prev.score2 ? 1 : 2),
      swaps1: r.swaps1,
      swaps2: r.swaps2,
    );
  }

  /// Team serving now, null when badminton cannot tell (after a correction).
  int? get racketServerTeam {
    if (_isTennis) return tennisServerTeam;
    if (!isRacket) return null;
    return _badmintonServe(false).serverTeam;
  }

  /// The server stands in the right cell of its team.
  bool get racketServerRight {
    if (_isTennis) return tennisServeRight(_tennisPointsInGame);
    return _badmintonServe(false).rightCourt ?? true;
  }

  /// Doubles only: index (0 or 1) of the serving player, null when unknown.
  int? racketServerPlayerIndex({required bool doubles}) {
    if (!doubles) return racketServerTeam == null ? null : 0;
    if (_isTennis) {
      final team = tennisServerTeam;
      final inTiebreak = tennisInTiebreak;
      return tennisServerPlayerIndex(
        teamServiceGames: tennisTeamServiceGames(
          gamesPlayed: _tennisGamesPlayed,
          team: team,
          firstServer: racketPick.firstTeam,
        ),
        firstPlayer: racketPick.firstPlayerOf(team),
        tiebreakTurnsServed: inTiebreak
            ? tennisTiebreakTurnsServed(
                tiebreakPoints: _tennisPointsInGame,
                isGameServer: team == _tennisGameServer,
              )
            : 0,
      );
    }
    final serve = _badmintonServe(true);
    final player = serve.serverPlayer;
    final team = serve.serverTeam;
    if (player == null || team == null) return null;
    final starter = racketPick.rightStarterOf(team);
    return player == 1 ? starter : 1 - starter;
  }

  int get _tennisGameServer => tennisServer(
    gamesPlayed: _tennisGamesPlayed,
    tiebreak: false,
    firstServer: racketPick.firstTeam,
  );

  /// Player index standing in the right cell of [team] when it does not serve.
  int _rightPlayerOf(int team) {
    final starter = racketPick.rightStarterOf(team);
    if (_isTennis) return starter;
    final r = rally ?? const RallySetState();
    final opening = r.currentP1 + r.currentP2 == 0;
    final swaps = opening ? 0 : (team == 1 ? r.swaps1 : r.swaps2);
    if (swaps == null) return starter;
    return swaps.isEven ? starter : 1 - starter;
  }

  /// The four court cells for the current score.
  List<RacketCourtCell> racketCells({required bool doubles}) =>
      racketCourtCells(
        serverTeam: racketServerTeam,
        serverRight: racketServerRight,
        serverPlayerIndex: racketServerPlayerIndex(doubles: doubles),
        doubles: doubles,
        team1RightPlayer: _rightPlayerOf(1),
        team2RightPlayer: _rightPlayerOf(2),
      );
}

/// Appends [step] and drops the oldest beyond [undoStepLimit].
List<RacketUndoStep> pushRacketUndo(
  List<RacketUndoStep> stack,
  RacketUndoStep step,
) {
  final next = [...stack, step];
  return next.length > undoStepLimit
      ? next.sublist(next.length - undoStepLimit)
      : next;
}
