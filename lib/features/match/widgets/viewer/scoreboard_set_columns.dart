import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

/// Most set columns drawn on the live scoreboard; older sets are dropped.
const maxScoreboardSetColumns = 10;

enum SetColumnState { finished, current }

/// One set drawn next to the live scoreboard (mirror of the Web
/// `ScoreboardSetColumn`).
class SetColumn {
  const SetColumn({
    required this.setNumber,
    required this.team1,
    required this.team2,
    required this.state,
    required this.winner,
  });

  /// 1-based set number.
  final int setNumber;
  final int team1;
  final int team2;
  final SetColumnState state;

  /// Winning side (1 or 2) of a finished set; null while playing or when tied.
  final int? winner;
}

/// First unfinished set, or the last one when every set is finished.
int activeSetIndex(List<SetScoreData> sets) {
  final open = sets.indexWhere((set) => !set.isFinished);
  if (open >= 0) return open;
  return sets.isEmpty ? 0 : sets.length - 1;
}

/// Columns for the scoreboard, oldest first and the current set last. Empty for
/// a single set, so the board keeps its original look (same rule as the Web).
List<SetColumn> scoreboardSetColumns(List<SetScoreData> sets, int activeIdx) {
  if (activeIdx <= 0 || sets.length < 2) return const [];
  final visible = sets.take(activeIdx + 1).toList();
  final columns = [
    for (var i = 0; i < visible.length; i++)
      SetColumn(
        setNumber: i + 1,
        team1: visible[i].score1,
        team2: visible[i].score2,
        state: i == activeIdx
            ? SetColumnState.current
            : SetColumnState.finished,
        winner: i == activeIdx ? null : _winner(visible[i]),
      ),
  ];
  final from = columns.length - maxScoreboardSetColumns;
  return from > 0 ? columns.sublist(from) : columns;
}

int? _winner(SetScoreData set) {
  if (set.score1 == set.score2) return null;
  return set.score1 > set.score2 ? 1 : 2;
}
