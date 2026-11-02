
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/match_status_filter.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/home_skeletons.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_section_list.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyMessage = 'nothing here';

void main() {
  testWidgets('first scan shows card skeletons, never a spinner', (tester) async {
    final repo = _Repository(withMatch: {for (var i = 0; i < 6; i++) 't$i'});

    await tester.pumpWidget(_app(repo, count: 6));
    await tester.pump();

    expect(find.byType(TournamentMatchesCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await _dispose(tester);
  });

  testWidgets('only tournaments that have a match get a card', (tester) async {
    final repo = _Repository(withMatch: {'t0', 't2', 't4'});

    await tester.pumpWidget(_app(repo, count: 6));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LiveTournamentWithMatchesCard), findsNWidgets(3));
    expect(find.byType(TournamentMatchesCardSkeleton), findsNothing);
    await _dispose(tester);
  });

  testWidgets('cards need no extra request: the feed already fetched page one', (
    tester,
  ) async {
    final repo = _Repository(withMatch: {for (var i = 0; i < 6; i++) 't$i'});

    await tester.pumpWidget(_app(repo, count: 6));
    await tester.pump(const Duration(seconds: 1));

    expect(repo.calls.toSet().length, 6);
    expect(repo.calls.length, 6, reason: 'one call per tournament in total');
    await _dispose(tester);
  });

  testWidgets('nothing matches: scans every tournament, then message only', (
    tester,
  ) async {
    final repo = _Repository(withMatch: {});

    await tester.pumpWidget(_app(repo, count: 30));
    await tester.pump(const Duration(seconds: 5));

    expect(find.text(_emptyMessage), findsOneWidget);
    expect(find.byType(TournamentMatchesCardSkeleton), findsNothing);
    expect(find.text('Load more results'), findsNothing);
    expect(repo.calls.toSet().length, 30);

    final before = repo.calls.length;
    await tester.pump(const Duration(seconds: 20));
    expect(repo.calls.length, before, reason: 'no background scanning');
    await _dispose(tester);
  });

  testWidgets('every tournament scanned and none matches: message only', (
    tester,
  ) async {
    final repo = _Repository(withMatch: {});

    await tester.pumpWidget(_app(repo, count: 5));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text(_emptyMessage), findsOneWidget);
    expect(find.text('Load more results'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('when every request fails the user can retry', (tester) async {
    final repo = _Repository(withMatch: {})
      ..failing = {for (var i = 0; i < 3; i++) 't$i'};

    await tester.pumpWidget(_app(repo, count: 3));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Unable to load match data. Please try again.'), findsOneWidget);
    expect(find.text(_emptyMessage), findsNothing);

    repo.failing = {};
    repo.withMatch = {'t0', 't1', 't2'};
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(LiveTournamentWithMatchesCard), findsNWidgets(3));
    await _dispose(tester);
  });

  testWidgets('scrolling to the end loads each remaining tournament once', (
    tester,
  ) async {
    // A short window so six one-match cards overflow it: the tail is only
    // built once the user scrolls near the end.
    tester.view.physicalSize = const Size(360, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repo = _Repository(withMatch: {for (var i = 0; i < 14; i++) 't$i'});

    await tester.pumpWidget(_app(repo, count: 14));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.calls.toSet().length, 6);

    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pump(const Duration(seconds: 1));
    }

    expect(repo.calls.toSet().length, 14);
    expect(repo.calls.length, 14, reason: 'never requests a tournament twice');
    await _dispose(tester);
  });

  testWidgets('resuming the app refreshes the cards already shown, once', (
    tester,
  ) async {
    final repo = _Repository(withMatch: {'t0', 't1', 't2'});

    await tester.pumpWidget(_app(repo, count: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.calls.length, 3);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));

    expect(repo.calls.length, 6, reason: 'one pass over the 3 shown tournaments');
    expect(find.byType(LiveTournamentWithMatchesCard), findsNWidgets(3));
    await _dispose(tester);
  });

  testWidgets('live filter with nothing live tells the screen to switch tab', (
    tester,
  ) async {
    final repo = _Repository(withMatch: {});
    var told = 0;

    await tester.pumpWidget(
      _app(
        repo,
        count: 4,
        filter: MatchStatusFilter.live,
        onNoLiveMatches: () => told++,
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    expect(told, greaterThan(0));
    await _dispose(tester);
  });

  testWidgets('TC-FEED-01 live tab finds a live match past the 24th tournament', (
    tester,
  ) async {
    // Only the 30th tournament has a live match: the scan must not give up
    // after 24 and tell the user nothing is live.
    final repo = _Repository(withMatch: {'t29'})..matchStatus = 'live';

    await tester.pumpWidget(
      _app(repo, count: 30, filter: MatchStatusFilter.live),
    );
    await tester.pump(const Duration(seconds: 5));
    // The list tail starts one more scan once built; let it settle.
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(LiveTournamentWithMatchesCard), findsOneWidget);
    expect(find.text(_emptyMessage), findsNothing);
    await _dispose(tester);
  });

  testWidgets('TC-FEED-02 a slow first tournament never makes cards jump above', (
    tester,
  ) async {
    final repo = _Repository(withMatch: {'t0', 't1', 't2'})
      ..latency = {'t0': const Duration(milliseconds: 400)};

    await tester.pumpWidget(_app(repo, count: 3));
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      find.byType(LiveTournamentWithMatchesCard),
      findsNothing,
      reason: 't1 and t2 wait for t0 so nothing is inserted above a shown card',
    );
    expect(find.byType(TournamentMatchesCardSkeleton), findsWidgets);

    await tester.pump(const Duration(seconds: 1));
    final titles = tester
        .widgetList<LiveTournamentWithMatchesCard>(
          find.byType(LiveTournamentWithMatchesCard),
        )
        .map((card) => card.tournament.id);
    expect(titles, ['t0', 't1', 't2']);
    await _dispose(tester);
  });

  testWidgets('TC-FEED-03 scanning the rest never flashes a Load more button', (
    tester,
  ) async {
    // One card on screen keeps the list tail visible while 29 more tournaments
    // are scanned batch after batch; the tail must stay one steady skeleton.
    final repo = _Repository(withMatch: {'t0'});

    await tester.pumpWidget(_app(repo, count: 30));
    var buttonFrames = 0;
    var skeletonlessFrames = 0;
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      if (find.text('Load more results').evaluate().isNotEmpty) buttonFrames++;
      final scanning = repo.calls.toSet().length < 30;
      final hasSkeleton = find
          .byType(TournamentMatchesCardSkeleton)
          .evaluate()
          .isNotEmpty;
      if (scanning &&
          !hasSkeleton &&
          find.byType(LiveTournamentWithMatchesCard).evaluate().isNotEmpty) {
        skeletonlessFrames++;
      }
    }

    expect(buttonFrames, 0, reason: 'no Load more button flashes in between');
    expect(skeletonlessFrames, 0, reason: 'tail never disappears mid-scan');
    expect(repo.calls.toSet().length, 30, reason: 'every tournament scanned');
    expect(find.byType(LiveTournamentWithMatchesCard), findsOneWidget);
    expect(find.byType(TournamentMatchesCardSkeleton), findsNothing);
    await _dispose(tester);
  });

  testWidgets('live filter with a live card does not switch tab', (tester) async {
    final repo = _Repository(withMatch: {'t0'})..matchStatus = 'live';
    var told = 0;

    await tester.pumpWidget(
      _app(
        repo,
        count: 4,
        filter: MatchStatusFilter.live,
        onNoLiveMatches: () => told++,
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    expect(told, 0);
    await _dispose(tester);
  });
}

/// Unmounting disposes the ProviderScope, which cancels the feed's timers.
Future<void> _dispose(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

Widget _app(
  _Repository repo, {
  required int count,
  MatchStatusFilter filter = MatchStatusFilter.scheduled,
  VoidCallback? onNoLiveMatches,
}) {
  return ProviderScope(
    overrides: [matchRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            TournamentSectionList(
              tournaments: [for (var i = 0; i < count; i++) _tournament('t$i')],
              filter: filter,
              emptyMessage: _emptyMessage,
              onNoLiveMatches: onNoLiveMatches,
            ),
          ],
        ),
      ),
    ),
  );
}

Tournament _tournament(String id) => Tournament(
  id: id,
  name: 'Tournament $id',
  sport: 'pickleball',
  format: 'single_elimination',
  bracketType: 'SINGLE_ELIMINATION',
  status: 'registration',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'synthetic-user',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  startDate: DateTime.utc(2026, 10, 1),
);

MatchModel _match(String tournamentId, String status) => MatchModel(
  id: 'match-$tournamentId',
  tournamentId: tournamentId,
  round: 1,
  matchNumber: 1,
  team1Id: 'team-alpha-id',
  team2Id: 'team-beta-id',
  team1Name: 'Team Alpha',
  team2Name: 'Team Beta',
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 9, 27),
);

/// Any call other than `getTournamentMatchesPaged` throws (it is a Fake).
class _Repository extends Fake implements IMatchRepository {
  _Repository({required this.withMatch});

  Set<String> withMatch;
  Set<String> failing = {};
  var matchStatus = 'scheduled';
  final calls = <String>[];

  /// Per-tournament response time; anything missing answers in 10 ms.
  Map<String, Duration> latency = {};

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
    await Future<void>.delayed(
      latency[tournamentId] ?? const Duration(milliseconds: 10),
    );
    if (failing.contains(tournamentId)) throw StateError('boom');
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
