import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/data/models/match_suggestion_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_playback_repository.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_viewer_suggestions.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-LIVEVIEW-04 a live video always counts, a replay needs 180 s', () {
    expect(isSuggestable(_item('a', live: true, durationSec: null)), isTrue);
    expect(isSuggestable(_item('b', durationSec: 180)), isTrue);
    expect(isSuggestable(_item('c', durationSec: 179)), isFalse);
    expect(isSuggestable(_item('d', durationSec: null)), isFalse);
  });

  test('TC-LIVEVIEW-05 filters keep the server order', () {
    final items = [
      _item('live', live: true, same: true),
      _item('replay', durationSec: 600),
      _item('same-replay', durationSec: 600, same: true),
    ];
    List<String> ids(SuggestionFilter f) =>
        filterSuggestions(items, f).map((e) => e.matchId).toList();

    expect(ids(SuggestionFilter.all), ['live', 'replay', 'same-replay']);
    expect(ids(SuggestionFilter.live), ['live']);
    expect(ids(SuggestionFilter.replay), ['replay', 'same-replay']);
    expect(ids(SuggestionFilter.sameTournament), ['live', 'same-replay']);
  });

  test('TC-LIVEVIEW-08 merging pages keeps the first copy of a match', () {
    final merged = mergeSuggestionPages(
      [_item('a', score1: 1), _item('b')],
      [_item('b', score1: 9), _item('c')],
    );

    expect(merged.map((e) => e.matchId), ['a', 'b', 'c']);
    expect(merged[1].team1Score, 0);
  });

  test('TC-LIVEVIEW-09 duration reads m:ss or h:mm:ss, empty when unknown', () {
    expect(formatSuggestionDuration(null), '');
    expect(formatSuggestionDuration(-1), '');
    expect(formatSuggestionDuration(125), '2:05');
    expect(formatSuggestionDuration(3725), '1:02:05');
  });

  test('TC-LIVEVIEW-10 the thumbnail hue is stable per tournament', () {
    final hue = suggestionThumbHue('tournament-1');

    expect(hue, suggestionThumbHue('tournament-1'));
    expect(hue, inInclusiveRange(0, 359));
  });

  test('TC-LIVEVIEW-15 parses a suggestion and rejects broken rows', () {
    final ok = MatchSuggestion.tryParse({
      'matchId': 'm1',
      'kind': 'REPLAY',
      'tournamentId': 't1',
      'tournamentName': 'Giai A',
      'roundLabel': 'Vong 1',
      'team1Name': 'A',
      'team2Name': 'B',
      'team1Score': 11,
      'team2Score': 7,
      'durationSec': 725,
      'sameTournament': true,
    });

    expect(ok?.matchId, 'm1');
    expect(ok?.kind, SuggestionKind.replay);
    expect(ok?.team1Score, 11);
    expect(ok?.durationSec, 725);
    expect(ok?.sameTournament, isTrue);
    expect(MatchSuggestion.tryParse({'matchId': 'm', 'kind': 'X'}), isNull);
    expect(MatchSuggestion.tryParse({'kind': 'LIVE'}), isNull);
  });

  testWidgets('TC-LIVEVIEW-06 renders cards and opens the tapped match', (
    tester,
  ) async {
    MatchSuggestion? opened;
    await _pump(
      tester,
      _FakeRepo([
        _page([_item('now', live: true), _item('old', durationSec: 600)]),
      ]),
      onOpen: (m) => opened = m,
    );

    await tester.tap(find.byKey(const ValueKey('live-suggestion-old')));

    expect(opened?.matchId, 'old');
    await _dispose(tester);
  });

  testWidgets('TC-LIVEVIEW-12 every card has a thumbnail, names and details', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeRepo([
        _page([
          _item('now', live: true, score1: 3, score2: 1),
          _item('old', durationSec: 725),
        ]),
      ]),
    );

    for (final id in ['now', 'old']) {
      expect(find.byKey(ValueKey('live-suggestion-thumb-$id')), findsOneWidget);
      expect(find.textContaining('Alpha $id'), findsOneWidget);
      expect(find.textContaining('Beta $id'), findsOneWidget);
    }
    expect(find.text('3 – 1'), findsOneWidget);
    expect(find.text('12:05'), findsOneWidget);
    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Giai A · Vong 1'), findsNWidgets(2));
    await _dispose(tester);
  });

  testWidgets('TC-LIVEVIEW-13 filter pills narrow the list', (tester) async {
    await _pump(
      tester,
      _FakeRepo([
        _page([
          _item('now', live: true, same: true),
          _item('old', durationSec: 600),
        ]),
      ]),
    );
    final now = find.byKey(const ValueKey('live-suggestion-now'));
    final old = find.byKey(const ValueKey('live-suggestion-old'));

    Future<void> pick(String name) async {
      await tester.tap(find.byKey(ValueKey('live-suggestion-filter-$name')));
      await tester.pump();
    }

    await pick('live');
    expect([now.evaluate().length, old.evaluate().length], [1, 0]);
    await pick('replay');
    expect([now.evaluate().length, old.evaluate().length], [0, 1]);
    await pick('sameTournament');
    expect([now.evaluate().length, old.evaluate().length], [1, 0]);
    await pick('all');
    expect([now.evaluate().length, old.evaluate().length], [1, 1]);
    await _dispose(tester);
  });

  testWidgets('TC-LIVEVIEW-14 an empty filter shows its message, pills stay', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo([_page([_item('old', durationSec: 600)])]));

    await tester.tap(find.byKey(const ValueKey('live-suggestion-filter-live')));
    await tester.pump();

    expect(find.text('No videos in this section.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('live-suggestion-filter-all')),
      findsOneWidget,
    );
    await _dispose(tester);
  });

  testWidgets('TC-LIVEVIEW-07 shows the empty message with no videos', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo([_page(const [])]));

    expect(find.text('No other matches to watch yet'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('TC-LIVEVIEW-16 a short list pulls the next page by cursor', (
    tester,
  ) async {
    final repo = _FakeRepo([
      _page([_item('a', live: true)], next: 'c2'),
      _page([_item('b', live: true)]),
    ]);
    await _pump(tester, repo);

    expect(repo.cursors, [null, 'c2']);
    expect(find.byKey(const ValueKey('live-suggestion-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('live-suggestion-b')), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('TC-LIVEVIEW-17 short replays from the API are not listed', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeRepo([
        _page([_item('short', durationSec: 60), _item('ok', live: true)]),
      ]),
    );

    expect(find.byKey(const ValueKey('live-suggestion-short')), findsNothing);
    expect(find.byKey(const ValueKey('live-suggestion-ok')), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('TC-LIVEVIEW-18 a first page filtered out still pulls the next', (
    tester,
  ) async {
    final repo = _FakeRepo([
      _page([_item('short', durationSec: 60)], next: 'c2'),
      _page([_item('ok', durationSec: 600)]),
    ]);
    await _pump(tester, repo);

    expect(repo.cursors, [null, 'c2']);
    expect(find.byKey(const ValueKey('live-suggestion-ok')), findsOneWidget);
    expect(find.text('No other matches to watch yet'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('TC-LIVEVIEW-19 all pages filtered out shows the empty message', (
    tester,
  ) async {
    final repo = _FakeRepo([
      _page([_item('short', durationSec: 60)], next: 'c2'),
      _page([_item('short2', durationSec: null)]),
    ]);
    await _pump(tester, repo);

    expect(repo.cursors, [null, 'c2']);
    expect(find.text('No other matches to watch yet'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('a failed first load shows the error text', (tester) async {
    await _pump(tester, _FakeRepo(const [], error: Exception('boom')));

    expect(
      find.text('Unable to load match data. Please try again.'),
      findsOneWidget,
    );
    await _dispose(tester);
  });

  testWidgets('loading shows card skeletons, not a spinner', (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await _pump(
      tester,
      _FakeRepo([
        _page(const []),
      ], gate: gate),
      settle: false,
    );

    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    gate.complete();
    await tester.pump();
    await _dispose(tester);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  void Function(MatchSuggestion)? onOpen,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [matchPlaybackRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LiveViewerSuggestions(
            currentMatchId: 'me',
            onOpen: onOpen ?? (_) {},
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _dispose(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
}

class _FakeRepo extends Fake implements IMatchPlaybackRepository {
  _FakeRepo(this.pages, {this.error, this.gate});

  final List<MatchSuggestionsPage> pages;
  final Object? error;
  final Completer<void>? gate;
  final cursors = <String?>[];

  @override
  Future<MatchSuggestionsPage> getMatchSuggestions(
    String matchId, {
    String? cursor,
  }) async {
    cursors.add(cursor);
    await gate?.future;
    if (error != null) throw error!;
    return pages[cursor == null ? 0 : 1];
  }
}

MatchSuggestionsPage _page(List<MatchSuggestion> items, {String? next}) =>
    MatchSuggestionsPage(items: items, nextCursor: next);

MatchSuggestion _item(
  String id, {
  bool live = false,
  bool same = false,
  int? durationSec = 600,
  int score1 = 0,
  int score2 = 0,
}) => MatchSuggestion(
  matchId: id,
  kind: live ? SuggestionKind.live : SuggestionKind.replay,
  tournamentId: 't1',
  tournamentName: 'Giai A',
  roundLabel: 'Vong 1',
  team1Name: 'Alpha $id',
  team2Name: 'Beta $id',
  team1Score: score1,
  team2Score: score2,
  durationSec: live ? null : durationSec,
  sameTournament: same,
);
