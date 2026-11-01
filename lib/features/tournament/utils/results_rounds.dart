import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Pure helpers of the "Kết quả" tab, ported from the web `results.ts` so both
/// clients share one rule set. No Flutter, no providers, no network.

/// One round of a division: real matches only (BYE excluded), in play order.
class ResultsRound {
  const ResultsRound({
    required this.key,
    required this.label,
    required this.matches,
    required this.pending,
  });

  /// Round label, also the selector value.
  final String key;
  final String label;
  final List<MatchModel> matches;

  /// Matches that still wait for a score.
  final int pending;
}

const _lockedStatuses = {'COMPLETED', 'FINISHED', 'DISPUTED', 'CANCELLED'};

bool _isClosed(MatchModel match) =>
    _lockedStatuses.contains(match.normalizedStatus);

/// A match whose result is final (completed, disputed or cancelled).
bool isMatchClosed(MatchModel match) => _isClosed(match);

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

/// Groups [all] by round label. [labelOf] sees every match (BYE included) so
/// the caller can count bracket slots correctly; BYE rows are dropped here.
List<ResultsRound> buildResultsRounds(
  List<MatchModel> all,
  String Function(MatchModel) labelOf,
) {
  final byLabel = <String, List<MatchModel>>{};
  final order = <String, int>{};
  for (final match in all) {
    if (match.isBye) continue;
    final label = labelOf(match);
    byLabel.putIfAbsent(label, () => []).add(match);
    final current = order[label];
    order[label] = current == null || match.round < current
        ? match.round
        : current;
  }

  final labels = byLabel.keys.toList()
    ..sort((a, b) {
      final byRound = order[a]!.compareTo(order[b]!);
      return byRound != 0 ? byRound : a.compareTo(b);
    });

  return [
    for (final label in labels)
      ResultsRound(
        key: label,
        label: label,
        pending: byLabel[label]!.where(canEnterScore).length,
        matches: [...byLabel[label]!]
          ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber)),
      ),
  ];
}

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
