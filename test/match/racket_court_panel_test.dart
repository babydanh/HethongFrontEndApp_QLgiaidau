import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_racket.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/racket_court_panel.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

class _Writes extends Fake implements IMatchRepository {
  @override
  Future<void> updateScoreDetails(
    String tournamentId,
    String matchId, {
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    Map<String, dynamic>? scoreDetailsExtras,
    String? winnerId,
    String? overrideReason,
    int? expectedRevision,
    bool useLiteParticipantAccess = false,
    ({String date, String? time})? playedAt,
  }) async {}

  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async => _match(doubles: true);
}

/// The real score panel logic, started from a state the test chooses.
class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

MatchModel _match({required bool doubles}) => MatchModel(
  id: 'match-1',
  tournamentId: 'tournament-1',
  round: 1,
  matchNumber: 1,
  team1Id: 'team-1',
  team2Id: 'team-2',
  team1Name: 'Team A',
  team2Name: 'Team B',
  team1Members: doubles ? const ['An', 'Binh'] : const ['An'],
  team2Members: doubles ? const ['Chi', 'Dung'] : const ['Chi'],
  status: 'LIVE',
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 1),
);

ScorePanelState _badminton() => ScorePanelState(
  config: resolveSportConfig(null, SportRuleKind.badminton),
  rally: const RallySetState(),
);

ScorePanelState _tennis() => ScorePanelState(
  config: resolveSportConfig({
    'kind': 'TENNIS',
    'setsToWin': 2,
    'format': const <String, dynamic>{},
  }, SportRuleKind.tennis),
  tennis: const TennisGameState(),
);

ScorePanelState _tennisDoubles({
  Map<String, dynamic> format = const {},
  TennisGameState tennis = const TennisGameState(),
}) => ScorePanelState(
  config: resolveSportConfig({
    'kind': 'TENNIS',
    'setsToWin': 2,
    'format': format,
  }, SportRuleKind.tennis),
  tennis: tennis,
  tennisDoubles: true,
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  ScorePanelState state, {
  required bool doubles,
  bool readOnly = false,
  Size size = const Size(900, 420),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final match = _match(doubles: doubles);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(_Writes()),
        singleMatchProvider.overrideWith((ref, params) => Stream.value(match)),
        scorePanelNotifierProvider.overrideWith2((arg) => _Panel(arg, state)),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RacketCourtPanel(params: _params, isReadOnly: readOnly),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(
    tester.element(find.byType(RacketCourtPanel)),
  );
}

Future<void> _flush(WidgetTester tester) async {
  // Let the notifier's debounced live-score sync run while the tree is alive.
  await tester.pump(const Duration(seconds: 2));
}

ScorePanelState _read(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params));

void main() {
  testWidgets('TC-RACKET-P-01 first server is picked by tapping a player', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final c = await _pump(tester, _badminton(), doubles: true);
    expect(
      find.text('Tap a player to choose who serves first.'),
      findsOneWidget,
    );
    // Team 1 serves by default until the referee taps someone else.
    expect(_read(c).racketServerTeam, 1);
    await tester.tap(find.text('Dung'));
    await tester.pump();
    expect(_read(c).racketServerTeam, 2);
    expect(_read(c).racketServerPlayerIndex(doubles: true), 1);
    expect(
      find.bySemanticsLabel(RegExp(r'^\w+: \w+, Serving')),
      findsOneWidget,
    );
    // Still 0-0, so the server can be changed again; the hint goes with the
    // first point.
    await tester.tap(find.byTooltip('Add point for team 2'));
    await tester.pump();
    expect(find.text('Tap a player to choose who serves first.'), findsNothing);
    await _flush(tester);
    semantics.dispose();
  });

  testWidgets('TC-RACKET-P-02 plus adds a point and moves the call', (
    tester,
  ) async {
    final c = await _pump(tester, _badminton(), doubles: true);
    await tester.tap(find.text('An'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add point for team 1'));
    await tester.pump();
    expect(_read(c).rally!.currentP1, 1);
    expect(find.text('1-0'), findsOneWidget);
    await _flush(tester);
  });

  testWidgets('TC-RACKET-P-03 undo restores the score and the server', (
    tester,
  ) async {
    final c = await _pump(tester, _badminton(), doubles: true);
    await tester.tap(find.text('An'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add point for team 2'));
    await tester.pump();
    expect(_read(c).racketServerTeam, 2);
    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(_read(c).rally!.currentP2, 0);
    expect(_read(c).racketServerTeam, 1);
    await _flush(tester);
  });

  testWidgets('TC-RACKET-P-04 tennis shows 15 after one point', (tester) async {
    final c = await _pump(tester, _tennis(), doubles: false);
    await tester.tap(find.text('An'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add point for team 1'));
    await tester.pump();
    expect(_read(c).tennis!.team1GamePoints, 1);
    expect(find.text('15-0'), findsOneWidget);
    await _flush(tester);
  });

  testWidgets('TC-RACKET-P-05 singles shows one name per side', (tester) async {
    await _pump(tester, _tennis(), doubles: false);
    expect(find.text('An'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);
    expect(find.text('Binh'), findsNothing);
  });

  testWidgets('TC-RACKET-P-06 menu lets the referee correct the server', (
    tester,
  ) async {
    final c = await _pump(tester, _badminton(), doubles: true);
    await tester.tap(find.text('An'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add point for team 1'));
    await tester.pump();
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose server'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tap the player who is serving to correct it.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Chi'));
    await tester.pump();
    expect(_read(c).racketServerTeam, 2);
    expect(
      find.text('Tap the player who is serving to correct it.'),
      findsNothing,
    );
    await _flush(tester);
  });

  testWidgets('TC-RACKET-P-07 a read-only panel has no score buttons', (
    tester,
  ) async {
    await _pump(tester, _badminton(), doubles: true, readOnly: true);
    expect(find.byTooltip('Add point for team 1'), findsNothing);
    expect(find.byTooltip('Undo'), findsNothing);
  });

  testWidgets('TC-RACKET-P-08 doubles after minus says the server is unknown', (
    tester,
  ) async {
    await _pump(tester, _badminton(), doubles: true);
    await tester.tap(find.text('An'));
    await tester.pump();
    for (final tip in [
      'Add point for team 1',
      'Add point for team 1',
      'Remove point for team 1',
    ]) {
      await tester.tap(find.byTooltip(tip));
      await tester.pump();
    }
    await tester.tap(find.byTooltip('Add point for team 1'));
    await tester.pump();
    expect(
      find.text('Server unknown. Undo, or ⋯ → Choose server.'),
      findsOneWidget,
    );
    await _flush(tester);
  });

  testWidgets(
    'TC-RACKET-P-09 tennis doubles: pick the server, receiver shows',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final c = await _pump(tester, _tennisDoubles(), doubles: true);
      expect(find.text('Tap a player to choose who serves.'), findsOneWidget);
      await tester.tap(find.text('Binh'));
      await tester.pump();
      expect(_read(c).racketServerPlayerIndex(doubles: true), 1);
      expect(
        find.bySemanticsLabel(RegExp(r'^\w+: \w+, Serving')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^\w+: \w+, RECEIVE')),
        findsOneWidget,
      );
      expect(find.text('Tap a receiver to swap who receives.'), findsOneWidget);
      await _flush(tester);
      semantics.dispose();
    },
  );

  testWidgets('TC-RACKET-P-10 locked receivers only get the correction', (
    tester,
  ) async {
    final c = await _pump(tester, _tennisDoubles(), doubles: true);
    await tester.tap(find.text('An'));
    await tester.pump();
    await tester.tap(find.text('Chi'));
    await tester.pumpAndSettle();
    expect(find.text('Swap right/left'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add point for team 1'));
    await tester.pump();
    await tester.tap(find.text('Chi'));
    await tester.pumpAndSettle();
    expect(find.text('Swap right/left'), findsNothing);
    await tester.tap(find.text('Correction: swap the receiver for this game'));
    await tester.pumpAndSettle();
    expect(_read(c).tennisCourt.gameFix?.playerIndex, 1);
    await _flush(tester);
  });

  testWidgets('TC-RACKET-P-12 picking the server twice moves nobody', (
    tester,
  ) async {
    final c = await _pump(tester, _tennisDoubles(), doubles: true);
    final an = tester.getCenter(find.text('An'));
    final binh = tester.getCenter(find.text('Binh'));
    await tester.tap(find.text('Binh'));
    await tester.pump();
    expect(_read(c).racketServerPlayerIndex(doubles: true), 1);
    expect(tester.getCenter(find.text('An')), an);
    expect(tester.getCenter(find.text('Binh')), binh);
    await tester.tap(find.text('An'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This player serves'));
    await tester.pumpAndSettle();
    expect(_read(c).racketServerPlayerIndex(doubles: true), 0);
    expect(tester.getCenter(find.text('An')), an);
    expect(tester.getCenter(find.text('Binh')), binh);
    await _flush(tester);
  });

  testWidgets('TC-RACKET-P-11 No-Ad 40-40 offers the deciding receiver', (
    tester,
  ) async {
    final state = _tennisDoubles(
      format: const {'noAd': true},
      tennis: const TennisGameState(team1GamePoints: 3, team2GamePoints: 3),
    );
    await _pump(tester, state, doubles: true);
    expect(
      find.text('Deciding point: tap a receiver to choose who returns.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Dung'));
    await tester.pumpAndSettle();
    expect(find.text('This player returns the deciding point'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  for (final size in const [Size(320, 640), Size(768, 1024)]) {
    testWidgets(
      'TC-RACKET-P-12 tennis doubles menu fits at ${size.width.toInt()} px',
      (tester) async {
        await _pump(tester, _tennisDoubles(), doubles: true, size: size);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('An'));
        await tester.pump();
        await tester.tap(find.byTooltip('Add point for team 1'));
        await tester.pump();
        await tester.tap(find.text('Binh'));
        await tester.pumpAndSettle();
        expect(find.text('Correction: this player is serving'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final button = tester.getSize(
          find.ancestor(
            of: find.text('Correction: this player is serving'),
            matching: find.byType(FilledButton),
          ),
        );
        expect(button.height, greaterThanOrEqualTo(44));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        await _flush(tester);
      },
    );
  }
}
