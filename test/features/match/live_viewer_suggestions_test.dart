import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_viewer_suggestions.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-LIVEVIEW-04 pickLiveSuggestions puts live first and drops current',
      () {
    final picked = pickLiveSuggestions([
      _match('done', 'completed'),
      _match('soon', 'scheduled'),
      _match('now', 'in_progress'),
      _match('me', 'in_progress'),
    ], currentMatchId: 'me');

    expect(picked.map((m) => m.id), ['now', 'soon']);
  });

  test('TC-LIVEVIEW-05 pickLiveSuggestions returns empty when nothing to watch',
      () {
    expect(
      pickLiveSuggestions([
        _match('done', 'completed'),
      ], currentMatchId: 'x'),
      isEmpty,
    );
  });

  test('TC-LIVEVIEW-08 a PLAYING match counts as live like on the Web', () {
    final picked = pickLiveSuggestions([
      _match('soon', 'scheduled'),
      _match('now', 'playing'),
    ], currentMatchId: 'me');

    expect(picked.map((m) => m.id), ['now', 'soon']);
  });

  test('TC-LIVEVIEW-09 bye matches are never offered', () {
    final picked = pickLiveSuggestions([
      _match('bye-live', 'in_progress', isBye: true),
      _match('bye-soon', 'scheduled', isBye: true),
      _match('ok', 'scheduled'),
    ], currentMatchId: 'me');

    expect(picked.map((m) => m.id), ['ok']);
  });

  test('TC-LIVEVIEW-10 a match that already has a winner is not offered', () {
    final picked = pickLiveSuggestions([
      _match('won', 'in_progress', winnerId: 'a'),
      _match('ok', 'in_progress'),
    ], currentMatchId: 'me');

    expect(picked.map((m) => m.id), ['ok']);
  });

  testWidgets('TC-LIVEVIEW-06 renders cards and opens the tapped match', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      _app(
        matches: [_match('now', 'in_progress'), _match('soon', 'scheduled')],
        onOpen: (m) => opened = m.id,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LIVE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('live-suggestion-soon')));
    expect(opened, 'soon');
  });

  testWidgets('TC-LIVEVIEW-07 shows the empty message with no candidates', (
    tester,
  ) async {
    await tester.pumpWidget(_app(matches: const [], onOpen: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('No other matches to watch yet'), findsOneWidget);
  });

  testWidgets('loading shows card skeletons, not a spinner', (tester) async {
    final never = StreamController<List<MatchModel>>();
    addTearDown(never.close);
    await tester.pumpWidget(
      _app(matches: const [], onOpen: (_) {}, stream: never.stream),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

Widget _app({
  required List<MatchModel> matches,
  required void Function(MatchModel) onOpen,
  Stream<List<MatchModel>>? stream,
}) {
  return ProviderScope(
    overrides: [
      bracketMatchesProvider.overrideWith((ref, tournamentId) {
        return stream ?? Stream.value(matches);
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LiveViewerSuggestions(
          tournamentId: 't1',
          currentMatchId: 'me',
          onOpen: onOpen,
        ),
      ),
    ),
  );
}

MatchModel _match(
  String id,
  String status, {
  bool isBye = false,
  String winnerId = '',
}) => MatchModel(
  id: id,
  tournamentId: 't1',
  round: 1,
  matchNumber: 1,
  team1Id: 'a',
  team2Id: 'b',
  team1Name: 'Alpha $id',
  team2Name: 'Beta $id',
  status: status,
  isBye: isBye,
  winnerId: winnerId,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 1),
);
