import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/match_status_filter.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/providers/home_match_feed_provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Only `getTournamentMatchesPaged` exists: any other repository call (for
/// example the old full `getMatches` read) throws, which fails the test.
class _FeedRepository extends Fake implements IMatchRepository {
  final calls = <String>[];
  final statuses = <String?>[];
  var inFlight = 0;
  var maxInFlight = 0;
  var latency = const Duration(milliseconds: 10);
  var matchStatus = 'scheduled';

  /// Tournament ids that have a match to show.
  Set<String> withMatch;
  Set<String> failing = {};

  /// Tournaments whose first pages are only placeholders (TBD) before a real
  /// match shows up on page [placeholderPages] + 1.
  final placeholderFirst = <String, int>{};
  final cursors = <String?>[];

  _FeedRepository({required this.withMatch});

  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getTournamentMatchesPaged({
    required String tournamentId,
    String? status,
    String? cursor,
    int limit = 4,
    String? trigger,
  }) async {
    calls.add(tournamentId);
    statuses.add(status);
    cursors.add(cursor);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    await Future<void>.delayed(latency);
    inFlight--;
    if (failing.contains(tournamentId)) throw StateError('boom');
    final skip = placeholderFirst[tournamentId];
    if (skip != null) {
      final page = cursor == null ? 0 : int.parse(cursor);
      final isLast = page >= skip;
      return (
        matches: [
          isLast ? _match(tournamentId, matchStatus) : _placeholder(tournamentId),
        ],
        nextCursor: isLast ? null : '${page + 1}',
        hasMore: !isLast,
        total: 1,
      );
    }
    final matches = withMatch.contains(tournamentId)
        ? [_match(tournamentId, matchStatus)]
        : <MatchModel>[];
    return (
      matches: matches,
      nextCursor: null,
      hasMore: false,
      total: matches.length,
    );
  }
}

MatchModel _match(String tournamentId, String status) => MatchModel(
  id: 'match-$tournamentId',
  tournamentId: tournamentId,
  round: 1,
  matchNumber: 1,
  team1Id: 'a-$tournamentId',
  team2Id: 'b-$tournamentId',
  team1Name: 'Team Alpha',
  team2Name: 'Team Beta',
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 1),
);

MatchModel _placeholder(String tournamentId) => MatchModel(
  id: 'ph-$tournamentId',
  tournamentId: tournamentId,
  round: 1,
  matchNumber: 1,
  team1Id: 'a-$tournamentId',
  team2Id: 'tbd',
  team1Name: 'Team Alpha',
  team2Name: 'TBD',
  status: 'scheduled',
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 1),
);

List<String> _ids(int n) => [for (var i = 0; i < n; i++) 't$i'];

HomeMatchFeedQuery _query(
  int n, [
  MatchStatusFilter status = MatchStatusFilter.scheduled,
]) => HomeMatchFeedQuery(status: status, tournamentIds: _ids(n));

ProviderContainer _container(_FeedRepository repo) {
  final container = ProviderContainer(
    overrides: [matchRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Runs [body] under fake time and lets every pending timer/microtask finish.
void _run(
  void Function(FakeAsync async) body, {
  Duration settle = const Duration(seconds: 5),
}) {
  fakeAsync((async) {
    body(async);
    async.elapse(settle);
  });
}

void main() {
  test('opening 20 tournaments asks for the first 6 only, at most 3 at once', () {
    final repo = _FeedRepository(withMatch: _ids(20).toSet());
    _run((async) {
      final container = _container(repo);
      final query = _query(20);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));

      final state = container.read(homeMatchFeedProvider(query));
      expect(repo.calls, _ids(6));
      expect(repo.maxInFlight, lessThanOrEqualTo(3));
      expect(state.visibleIds, _ids(6));
      expect(state.isScanning, isFalse);
      expect(state.hasMore, isTrue);
    });
  });

  test('sends the server enum for the filter', () {
    final repo = _FeedRepository(withMatch: _ids(2).toSet());
    _run((async) {
      final container = _container(repo);
      final query = _query(2, MatchStatusFilter.live);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));

      expect(repo.statuses.toSet(), {'ONGOING'});
    });
  });

  test('a filter that matches nothing scans every tournament, then stops', () {
    final repo = _FeedRepository(withMatch: {});
    _run((async) {
      final container = _container(repo);
      final query = _query(30, MatchStatusFilter.live);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 10));

      final state = container.read(homeMatchFeedProvider(query));
      expect(repo.calls.toSet(), _ids(30).toSet());
      expect(state.isScanning, isFalse);
      expect(state.hasVisible, isFalse);
      expect(state.hasMore, isFalse);

      // No background work is left behind.
      final before = repo.calls.length;
      async.elapse(const Duration(seconds: 60));
      expect(repo.calls.length, before);
    });
  });

  test('keeps scanning past 24 tournaments until the first match shows up', () {
    final repo = _FeedRepository(withMatch: {'t29'})..matchStatus = 'live';
    _run((async) {
      final container = _container(repo);
      final query = _query(40, MatchStatusFilter.live);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 10));

      final state = container.read(homeMatchFeedProvider(query));
      expect(state.visibleIds, ['t29']);
      expect(state.isScanning, isFalse);
      expect(
        repo.calls.toSet(),
        _ids(30).toSet(),
        reason: 'stops at the step that found a card, not at the end',
      );
    });
  });

  test('reaching the end of the tournaments stops scanning', () {
    final repo = _FeedRepository(withMatch: {});
    _run((async) {
      final container = _container(repo);
      final query = _query(10, MatchStatusFilter.live);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 10));

      final state = container.read(homeMatchFeedProvider(query));
      expect(repo.calls.toSet(), _ids(10).toSet());
      expect(state.hasMore, isFalse);
      expect(state.hasVisible, isFalse);
      expect(state.isScanning, isFalse);
    });
  });

  test('two concurrent loadMore calls do not request a tournament twice', () {
    final repo = _FeedRepository(withMatch: _ids(20).toSet());
    _run((async) {
      final container = _container(repo);
      final query = _query(20);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));

      final notifier = container.read(homeMatchFeedProvider(query).notifier);
      unawaited(notifier.loadMore());
      unawaited(notifier.loadMore());
      async.elapse(const Duration(seconds: 2));

      expect(repo.calls, _ids(12), reason: 'each tournament exactly once');
    });
  });

  test('a failing tournament does not hide the others', () {
    final repo = _FeedRepository(withMatch: _ids(6).toSet())..failing = {'t2'};
    _run((async) {
      final container = _container(repo);
      final query = _query(6);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));

      final state = container.read(homeMatchFeedProvider(query));
      expect(state.pages['t2']?.status, FeedPageStatus.error);
      expect(state.visibleIds, ['t0', 't1', 't3', 't4', 't5']);
    });
  });

  test('retry reloads only the failed tournament', () {
    final repo = _FeedRepository(withMatch: _ids(6).toSet())..failing = {'t2'};
    _run((async) {
      final container = _container(repo);
      final query = _query(6);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));

      repo.failing = {};
      repo.calls.clear();
      unawaited(container.read(homeMatchFeedProvider(query).notifier).retry('t2'));
      async.elapse(const Duration(seconds: 1));

      expect(repo.calls, ['t2']);
      expect(
        container.read(homeMatchFeedProvider(query)).pages['t2']?.status,
        FeedPageStatus.ready,
      );
    });
  });

  test('a failed refresh keeps the cards already shown', () {
    final repo = _FeedRepository(withMatch: _ids(3).toSet());
    _run((async) {
      final container = _container(repo);
      final query = _query(3);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));

      repo.failing = _ids(3).toSet();
      unawaited(
        container.read(homeMatchFeedProvider(query).notifier).refresh(force: true),
      );
      async.elapse(const Duration(seconds: 2));

      final state = container.read(homeMatchFeedProvider(query));
      expect(state.visibleIds, _ids(3));
    });
  });

  test('refresh triggers inside 1.5s collapse into one pass', () {
    final repo = _FeedRepository(withMatch: _ids(3).toSet());
    _run((async) {
      final container = _container(repo);
      final query = _query(3);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));
      repo.calls.clear();

      final notifier = container.read(homeMatchFeedProvider(query).notifier);
      unawaited(notifier.refresh());
      unawaited(notifier.refresh());
      async.elapse(const Duration(seconds: 1));

      expect(repo.calls.length, lessThanOrEqualTo(3));
    });
  });

  test('refreshes every 120 seconds, not every 15', () {
    final repo = _FeedRepository(withMatch: _ids(3).toSet());
    _run((async) {
      final container = _container(repo);
      final query = _query(3);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));
      repo.calls.clear();

      async.elapse(const Duration(seconds: 100));
      expect(repo.calls, isEmpty, reason: 'no per-tournament 15s polling');

      async.elapse(const Duration(seconds: 40));
      expect(repo.calls.toSet(), _ids(3).toSet());
    });
  });

  test('the live filter with a live card refreshes every 30 seconds', () {
    final repo = _FeedRepository(withMatch: _ids(2).toSet())
      ..matchStatus = 'live';
    _run((async) {
      final container = _container(repo);
      final query = _query(2, MatchStatusFilter.live);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));
      repo.calls.clear();

      async.elapse(const Duration(seconds: 35));
      expect(repo.calls, isNotEmpty);
    });
  });

  test('changing the filter 3 times quickly scans only the last one', () {
    final repo = _FeedRepository(withMatch: _ids(10).toSet());
    _run((async) {
      final container = _container(repo);
      final a = _query(10, MatchStatusFilter.live);
      final b = _query(10, MatchStatusFilter.completed);
      final c = _query(10, MatchStatusFilter.scheduled);
      container.listen(homeMatchFeedProvider(a), (_, _) {}).close();
      async.elapse(const Duration(milliseconds: 20));
      container.listen(homeMatchFeedProvider(b), (_, _) {}).close();
      async.elapse(const Duration(milliseconds: 20));
      container.listen(homeMatchFeedProvider(c), (_, _) {});
      async.elapse(const Duration(seconds: 3));

      expect(repo.statuses.toSet(), {'SCHEDULED'});
    });
  });

  test('skips pages that only hold placeholders to find a real match', () {
    final repo = _FeedRepository(withMatch: {})..placeholderFirst['t0'] = 2;
    _run((async) {
      final container = _container(repo);
      final query = _query(1);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));

      final state = container.read(homeMatchFeedProvider(query));
      expect(repo.cursors, [null, '1', '2']);
      expect(state.visibleIds, ['t0']);
    });
  });

  test('a tournament whose pages are all placeholders ends up empty', () {
    final repo = _FeedRepository(withMatch: {})..placeholderFirst['t0'] = 99;
    _run((async) {
      final container = _container(repo);
      final query = _query(1);
      container.listen(homeMatchFeedProvider(query), (_, _) {});
      async.elapse(const Duration(seconds: 2));

      final state = container.read(homeMatchFeedProvider(query));
      expect(repo.calls.length, 6, reason: 'first page + 5 extra pages');
      expect(state.pages['t0']?.status, FeedPageStatus.empty);
      expect(state.visibleIds, isEmpty);
    });
  });
}
