import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/utils/match_code.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Pure helpers of the "Kết quả" tab, ported from the web `results.ts` so both
/// clients share one rule set. No Flutter, no providers, no network.

/// Bracket branch a round belongs to (Web `ResultsBranch`). [main] is a plain
/// single-elimination round; [winners] only exists inside double elimination.
enum ResultsBranch { main, winners, losers, grandFinal }

/// Row tone of a match (Web `matchTone`). A disputed match is closed, so it
/// reads as [done].
enum MatchTone { live, done, cancel, ready, wait }

/// One round of a division: real matches only (BYE excluded), in play order.
class ResultsRound {
  const ResultsRound({
    required this.key,
    required this.label,
    required this.matches,
    required this.pending,
    this.branch = ResultsBranch.main,
  });

  /// Round label, also the selector value.
  final String key;
  final String label;
  final List<MatchModel> matches;

  /// Matches that still wait for a score.
  final int pending;
  final ResultsBranch branch;
}

const _lockedStatuses = {'COMPLETED', 'FINISHED', 'DISPUTED', 'CANCELLED'};

bool _isClosed(MatchModel match) =>
    _lockedStatuses.contains(match.normalizedStatus);

/// A match whose result is final (completed, disputed or cancelled).
bool isMatchClosed(MatchModel match) => _isClosed(match);

/// A match whose result is under dispute (Web "Tranh chấp").
bool isDisputedMatch(MatchModel match) => match.normalizedStatus == 'DISPUTED';

/// Web "Trễ giờ" (`timingOf(...).late`): a real match still to be played, not
/// disputed, scheduled for today (Vietnam time) and at least one minute past
/// its start. Yesterday's unplayed matches are not "waiting to be called".
bool isLateMatch(MatchModel match, DateTime now) {
  final scheduled = match.scheduledTime;
  if (scheduled == null || match.isBye) return false;
  if (match.isLive || isMatchClosed(match)) return false;
  if (!_sameVietnamDay(scheduled, now)) return false;
  return now.difference(scheduled).inMinutes >= 1;
}

bool _sameVietnamDay(DateTime a, DateTime b) {
  const offset = Duration(hours: 7);
  final left = a.toUtc().add(offset);
  final right = b.toUtc().add(offset);
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

/// A match accepts a score when it is real, has both sides and is not closed.
bool canEnterScore(MatchModel match) {
  if (match.isBye) return false;
  if (!match.hasTeams) return false;
  return !_isClosed(match);
}

/// A match that is being played right now: live status, both sides, not a BYE
/// and not already closed by a winner or a completion time.
bool isLiveMatch(MatchModel match) =>
    match.isLive &&
    !match.isBye &&
    match.hasTeams &&
    match.completedAt == null &&
    match.winnerId.isEmpty;

bool _sideIsEmpty(MatchModel match, int side) =>
    matchSidePlayers(match, side).isEmpty &&
    matchSideTeamName(match, side) == null;

/// Code of the match whose winner will fill the empty [side] (1 | 2) of
/// [match], or null when that cannot be told for sure. Feeders are the matches
/// whose `nextMatchId` points at [match], in bracket order: two feeders fill
/// side 1 then side 2; a lone feeder only explains the single empty side.
String? waitingForCode(MatchModel match, int side, List<MatchModel> all) {
  if (!_sideIsEmpty(match, side)) return null;
  final feeders =
      all.where((m) => !m.isBye && m.nextMatchId == match.id).toList()..sort(
        (a, b) =>
            a.bracketPosition.position.compareTo(b.bracketPosition.position),
      );
  final MatchModel feeder;
  if (feeders.length == 2) {
    feeder = feeders[side - 1];
  } else if (feeders.length == 1 && !_sideIsEmpty(match, 3 - side)) {
    feeder = feeders.first;
  } else {
    return null;
  }
  return matchCodeOrNull(feeder);
}

/// Division a match belongs to. The API may only carry it inside the score or
/// tournament config payload, so every list that filters by division must use
/// this one lookup to stay consistent with the others.
String? matchDivisionId(MatchModel match) {
  final id =
      match.divisionId ??
      match.scoreDetails?['division_id']?.toString() ??
      match.tournamentConfig?['division_id']?.toString();
  return id == null || id.isEmpty ? null : id;
}

/// Branch of [match]. The bracket position folds MAIN and WINNERS into
/// `winners`, so the stage type tells a double-elimination winners round from a
/// plain single-elimination one.
ResultsBranch branchOfMatch(MatchModel match) {
  return switch (match.bracketPosition.bracket) {
    'losers' => ResultsBranch.losers,
    'grand_final' || 'grand_final_reset' => ResultsBranch.grandFinal,
    'winners' when _isDoubleElimination(match) => ResultsBranch.winners,
    _ => ResultsBranch.main,
  };
}

bool _isDoubleElimination(MatchModel match) =>
    (match.stageType ?? '').toUpperCase() == 'DOUBLE_ELIMINATION';

/// Colour role of a match row: live, cancelled, closed, ready for a score, or
/// still waiting for a side.
MatchTone matchTone(MatchModel match) {
  if (isLiveMatch(match)) return MatchTone.live;
  if (match.normalizedStatus == 'CANCELLED') return MatchTone.cancel;
  if (isMatchClosed(match)) return MatchTone.done;
  return canEnterScore(match) ? MatchTone.ready : MatchTone.wait;
}

/// Whether a round box is open: a viewer's [choice] wins, otherwise the
/// [isDefault] round is open and a search opens every box that still has a match.
bool isRoundBoxOpen({
  required bool? choice,
  required bool isDefault,
  required bool searching,
}) => choice ?? (searching || isDefault);

/// Box choices after "Tới vòng": [picked] is open and every other key folded.
Map<String, bool> openOnlyRound(Iterable<String> keys, String picked) => {
  for (final key in keys) key: key == picked,
};

/// Groups [all] by round label. [labelOf] sees every match (BYE included) so
/// the caller can count bracket slots correctly; BYE rows are dropped here.
List<ResultsRound> buildResultsRounds(
  List<MatchModel> all,
  String Function(MatchModel) labelOf,
) {
  final groups = <String, _RoundGroup>{};
  for (final match in all) {
    if (match.isBye) continue;
    final branch = branchOfMatch(match);
    final label = labelOf(match);
    // Two losers rounds can share a label, so each losers round is its own box.
    final key = branch == ResultsBranch.losers
        ? 'losers|${match.round}'
        : label;
    final group = groups.putIfAbsent(
      key,
      () => _RoundGroup(key, label, branch, match.round),
    );
    group.matches.add(match);
    if (match.round < group.order) group.order = match.round;
  }

  final sorted = groups.values.toList()
    ..sort((a, b) {
      final byBranch = _branchRank(a.branch).compareTo(_branchRank(b.branch));
      if (byBranch != 0) return byBranch;
      final byRound = a.order.compareTo(b.order);
      return byRound != 0 ? byRound : a.label.compareTo(b.label);
    });

  return [
    for (final group in sorted)
      ResultsRound(
        key: group.key,
        label: group.label,
        branch: group.branch,
        pending: group.matches.where(canEnterScore).length,
        matches: [...group.matches]
          ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber)),
      ),
  ];
}

class _RoundGroup {
  _RoundGroup(this.key, this.label, this.branch, this.order);

  final String key;
  final String label;
  final ResultsBranch branch;
  int order;
  final List<MatchModel> matches = [];
}

/// Winners and plain rounds first, then losers, then the grand final.
int _branchRank(ResultsBranch branch) => switch (branch) {
  ResultsBranch.main || ResultsBranch.winners => 0,
  ResultsBranch.losers => 1,
  ResultsBranch.grandFinal => 2,
};

int? _epoch(DateTime? value) => value?.millisecondsSinceEpoch;

/// Orders by [time] (ascending, or descending when [latestFirst]); matches
/// without a time go last and ties keep play order.
int Function(MatchModel, MatchModel) _byTime(
  DateTime? Function(MatchModel) time, {
  bool latestFirst = false,
}) {
  return (a, b) {
    final left = _epoch(time(a));
    final right = _epoch(time(b));
    if (left == right) return a.matchNumber.compareTo(b.matchNumber);
    if (left == null) return 1;
    if (right == null) return -1;
    return latestFirst ? right.compareTo(left) : left.compareTo(right);
  };
}

/// Splits one round into live, finished (closed, latest first) and upcoming
/// (the rest, earliest first, no time last). A live match is never upcoming.
({List<MatchModel> live, List<MatchModel> finished, List<MatchModel> upcoming})
splitResultsMatches(List<MatchModel> matches) {
  final live = matches.where(isLiveMatch).toList()
    ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));
  final finished = matches.where(_isClosed).toList()
    ..sort(_byTime((m) => m.completedAt ?? m.scheduledTime, latestFirst: true));
  final upcoming =
      matches.where((m) => !_isClosed(m) && !isLiveMatch(m)).toList()
        ..sort(_byTime((m) => m.scheduledTime));
  return (live: live, finished: finished, upcoming: upcoming);
}

/// Upcoming matches with a usable time vs. without one; keeps incoming order.
({List<MatchModel> timed, List<MatchModel> untimed}) splitUpcomingByTime(
  List<MatchModel> matches,
) {
  return (
    timed: matches.where((m) => m.scheduledTime != null).toList(),
    untimed: matches.where((m) => m.scheduledTime == null).toList(),
  );
}

/// First round that still needs scores, else the last round, else nothing.
String? defaultResultsRoundKey(List<ResultsRound> rounds) {
  if (rounds.isEmpty) return null;
  return (rounds.where((r) => r.pending > 0).firstOrNull ?? rounds.last).key;
}
