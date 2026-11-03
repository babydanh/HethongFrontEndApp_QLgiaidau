import 'dart:math' as math;

import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Rounds shown side by side, like the Web `PagedDoubleElimView`.
const int kBracketVisibleRounds = 3;

/// Vertical gap between two cards of one column.
const double kBracketRowGap = 10;

/// First visible round so that the active one sits in the middle of the window
/// (Web: `activeRoundIndex - 1`, clamped so the window never runs off the end).
int bracketWindowStart(int active, int roundCount) {
  final maxStart = math.max(0, roundCount - kBracketVisibleRounds);
  return (active - 1).clamp(0, maxStart);
}

bool _isOpen(MatchModel m) => !m.isCompleted && m.status != 'cancelled';

/// First round that still has an unfinished match; the last round when
/// everything is done.
int defaultActiveRound(List<List<MatchModel>> rounds) {
  if (rounds.isEmpty) return 0;
  final open = rounds.indexWhere((matches) => matches.any(_isOpen));
  return open == -1 ? rounds.length - 1 : open;
}

/// Open on the losers branch only when it is the only branch left to play.
bool defaultLosersBranch(
  List<List<MatchModel>> winners,
  List<List<MatchModel>> losers,
) =>
    !winners.any((r) => r.any(_isOpen)) && losers.any((r) => r.any(_isOpen));

/// Top offset of every card. The first column is stacked; each next column
/// centres a card on its already-placed feeders (`nextMatchId` /
/// `loserNextMatchId`) and is pushed down when that would overlap its sibling.
Map<String, double> computeBracketTops(
  List<List<MatchModel>> columns,
  double cardHeight,
) {
  final step = cardHeight + kBracketRowGap;
  final tops = <String, double>{};
  final placed = <MatchModel>[];
  for (final column in columns) {
    var floor = 0.0;
    for (var i = 0; i < column.length; i++) {
      final m = column[i];
      final feederTops = [
        for (final p in placed)
          if (m.id.isNotEmpty &&
              (p.nextMatchId == m.id || p.loserNextMatchId == m.id))
            tops[p.id]!,
      ];
      final wanted = feederTops.isEmpty
          ? i * step
          : feederTops.reduce((a, b) => a + b) / feederTops.length;
      final top = math.max(wanted, floor);
      tops[m.id] = top;
      floor = top + step;
    }
    placed.addAll(column);
  }
  return tops;
}

/// Total height of the bracket body.
double bracketHeight(Map<String, double> tops, double cardHeight) =>
    tops.isEmpty ? 0 : tops.values.reduce(math.max) + cardHeight;

/// A line from one card to a later visible card.
class BracketLink {
  const BracketLink({
    required this.fromId,
    required this.toId,
    required this.fromColumn,
    required this.toColumn,
    required this.completed,
  });

  final String fromId;
  final String toId;
  final int fromColumn;
  final int toColumn;

  /// Source match finished: drawn in the accent colour.
  final bool completed;
}

/// Links whose target is visible in a later column; links to the other branch
/// or to rounds outside the window are not drawn.
List<BracketLink> computeBracketLinks(List<List<MatchModel>> columns) {
  final columnOf = <String, int>{
    for (var c = 0; c < columns.length; c++)
      for (final m in columns[c]) m.id: c,
  };
  final links = <BracketLink>[];
  for (var c = 0; c < columns.length; c++) {
    for (final m in columns[c]) {
      for (final target in {m.nextMatchId, m.loserNextMatchId}) {
        final toColumn = columnOf[target];
        if (target.isEmpty || toColumn == null || toColumn <= c) continue;
        links.add(
          BracketLink(
            fromId: m.id,
            toId: target,
            fromColumn: c,
            toColumn: toColumn,
            completed: m.isCompleted,
          ),
        );
      }
    }
  }
  return links;
}

/// A match that sends its winner or loser into another match.
typedef BracketFeeder = ({String code, bool loser});

/// Who feeds each match, in bracket order, so an empty side can say
/// "Thắng W4" / "Thua W6".
Map<String, List<BracketFeeder>> buildFeeders(List<MatchModel> matches) {
  final ordered = [...matches.where((m) => m.status != 'cancelled')]
    ..sort((a, b) {
      final byRound = a.round.compareTo(b.round);
      if (byRound != 0) return byRound;
      return a.bracketPosition.position.compareTo(b.bracketPosition.position);
    });
  final feeders = <String, List<BracketFeeder>>{};
  void add(String target, MatchModel from, {required bool loser}) {
    if (target.isEmpty) return;
    final code = (from.matchCode ?? '').trim();
    feeders.putIfAbsent(target, () => []).add((
      code: code.isEmpty ? '#${from.matchNumber}' : code,
      loser: loser,
    ));
  }

  for (final m in ordered) {
    add(m.nextMatchId, m, loser: false);
    add(m.loserNextMatchId, m, loser: true);
  }
  return feeders;
}
