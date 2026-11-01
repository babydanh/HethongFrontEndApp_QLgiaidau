import 'package:app_quanly_giaidau/core/config/app_theme.dart';
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
}

Widget _app({
  required List<MatchModel> matches,
  required void Function(MatchModel) onOpen,
}) {
  return ProviderScope(
    overrides: [
      matchesProvider.overrideWith((ref, tournamentId) {
        return Stream.value(matches);
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

MatchModel _match(String id, String status) => MatchModel(
  id: id,
  tournamentId: 't1',
  round: 1,
  matchNumber: 1,
  team1Id: 'a',
  team2Id: 'b',
  team1Name: 'Alpha $id',
  team2Name: 'Beta $id',
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 1),
);
