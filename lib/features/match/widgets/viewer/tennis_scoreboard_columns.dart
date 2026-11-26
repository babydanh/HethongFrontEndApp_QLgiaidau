import 'package:app_quanly_giaidau/core/utils/tennis_game_point_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/scoreboard_set_columns.dart';

/// Same sport fields as `readTennisGamePointDisplay` looks at.
bool isTennisScoreboardMatch(MatchModel match) => [
  match.sportKey,
  match.sportRules?['kind'],
  match.sportRules?['sport'],
  match.tournamentConfig?['sportKey'],
  match.tournamentConfig?['sport'],
].any((value) => value?.toString().trim().toLowerCase() == 'tennis');

/// Tennis columns: the games of every set that has started, oldest first.
/// Set 1 always shows; a later set shows once a game of it is played, or a
/// point of it when it is the set being played ([pointsInPlay]). Unlike
/// [scoreboardSetColumns], the set being played is a column too: the score
/// cell of the tennis board holds the point of the game.
List<SetColumn> tennisScoreboardSetColumns(
  List<SetScoreData> sets, {
  bool pointsInPlay = false,
  bool matchFinished = false,
}) {
  if (sets.isEmpty) {
    return matchFinished
        ? const []
        : const [
            SetColumn(
              setNumber: 1,
              team1: 0,
              team2: 0,
              state: SetColumnState.current,
              winner: null,
            ),
          ];
  }
  final active = activeSetIndex(sets);
  final columns = <SetColumn>[];
  for (var i = 0; i < sets.length; i++) {
    final set = sets[i];
    final current = !matchFinished && i == active && !set.isFinished;
    final started =
        i == 0 ||
        set.isFinished ||
        set.score1 + set.score2 > 0 ||
        (current && pointsInPlay);
    if (!started) continue;
    columns.add(
      SetColumn(
        setNumber: i + 1,
        team1: set.score1,
        team2: set.score2,
        state: current ? SetColumnState.current : SetColumnState.finished,
        winner: current || set.score1 == set.score2
            ? null
            : (set.score1 > set.score2 ? 1 : 2),
      ),
    );
  }
  final from = columns.length - maxScoreboardSetColumns;
  return from > 0 ? columns.sublist(from) : columns;
}

/// Point of the game in play as the board shows it: 0/15/30/40/AD (40-40 at
/// deuce), or tie-break points. Reads the App's int indexes and the Web's
/// strings. Null once the match is finished.
({String team1, String team2})? tennisScoreboardPoints(MatchModel match) {
  if (match.isCompleted) return null;
  final display = readTennisGamePointDisplay(match, isLive: true);
  if (display == null) return (team1: '0', team2: '0');
  String board(String point) => point == 'Ad' ? 'AD' : point;
  return (team1: board(display.team1), team2: board(display.team2));
}
