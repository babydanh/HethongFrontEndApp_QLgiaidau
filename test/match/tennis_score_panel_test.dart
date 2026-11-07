import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/tennis_score_panel.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

class _Writes extends Fake implements IMatchRepository {}

/// The real score panel logic, started from a state the test chooses.
class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

MatchModel _match() => MatchModel(
  id: 'match-1',
  tournamentId: 'tournament-1',
  round: 1,
  matchNumber: 1,
  team1Id: 'team-1',
  team2Id: 'team-2',
  team1Name: 'Team A',
  team2Name: 'Team B',
  status: 'LIVE',
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 10, 19),
);

ScorePanelState _state({
  Map<String, dynamic> format = const {},
  bool lite = false,
  List<SetScoreData> sets = const [],
  TennisGameState? tennis,
}) => ScorePanelState(
  config: resolveSportConfig({
    'kind': 'TENNIS',
    'setsToWin': 2,
    'format': format,
    if (lite) 'mode': 'LITE',
  }, SportRuleKind.tennis),
  isLite: lite,
  finishedSets: sets,
  tennis: tennis,
);

Future<void> _pump(WidgetTester tester, ScorePanelState state) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final match = _match();
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
        home: const Scaffold(body: TennisScorePanel(params: _params)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder get _serve => find.text('● SERVE');

/// True when the serve line sits in the card of team B (the lower one).
bool _serveIsTeamB(WidgetTester tester) =>
    tester.getCenter(_serve).dy > tester.getCenter(find.text('Team B')).dy;

const _matchTiebreakText =
    'MATCH TIE-BREAK · first to 10, win by 2, decides the match '
    '(replaces the deciding set)';

const _level = [
  SetScoreData(score1: 6, score2: 3, isFinished: true),
  SetScoreData(score1: 3, score2: 6, isFinished: true),
];

void main() {
  group('TC-CBD-TN-09 shows who serves', () {
    testWidgets('team A serves the first game', (tester) async {
      await _pump(tester, _state());
      expect(_serve, findsOneWidget);
      expect(_serveIsTeamB(tester), isFalse);
    });

    testWidgets('the serve passes to team B after one game', (tester) async {
      await _pump(
        tester,
        _state(sets: const [SetScoreData(score1: 1, score2: 0)]),
      );
      expect(_serveIsTeamB(tester), isTrue);
    });

    testWidgets('in a tie-break team B serves the second point', (
      tester,
    ) async {
      await _pump(
        tester,
        _state(
          sets: const [SetScoreData(score1: 6, score2: 6)],
          tennis: const TennisGameState(team1GamePoints: 1, isTiebreak: true),
        ),
      );
      expect(_serveIsTeamB(tester), isTrue);
    });

    testWidgets('Lite scorecards show no serve line', (tester) async {
      await _pump(tester, _state(lite: true));
      expect(_serve, findsNothing);
    });
  });

  group('TC-CBD-TN-10 tie-break banners', () {
    testWidgets('a normal tie-break keeps its own banner', (tester) async {
      await _pump(
        tester,
        _state(
          sets: const [SetScoreData(score1: 6, score2: 6)],
          tennis: const TennisGameState(isTiebreak: true),
        ),
      );
      expect(find.textContaining('TIEBREAK · Each rally'), findsOneWidget);
      expect(find.text(_matchTiebreakText), findsNothing);
    });

    testWidgets('the match tie-break banner replaces the deciding set', (
      tester,
    ) async {
      await _pump(
        tester,
        _state(format: {'finalSetMode': 'SUPER_TIEBREAK'}, sets: _level),
      );
      expect(find.text(_matchTiebreakText), findsOneWidget);
      expect(find.textContaining('TIEBREAK · Each rally'), findsNothing);
    });

    testWidgets('without the option the deciding set has no banner', (
      tester,
    ) async {
      await _pump(tester, _state(sets: _level));
      expect(find.text(_matchTiebreakText), findsNothing);
    });
  });

  group('TC-CBD-TN-11 DEUCE chip', () {
    const deuce = TennisGameState(team1GamePoints: 3, team2GamePoints: 3);

    testWidgets('shows at 40-40 with advantage rules', (tester) async {
      await _pump(tester, _state(tennis: deuce));
      expect(find.text('Deuce'), findsOneWidget);
    });

    testWidgets('is hidden at 40-40 when No-Ad is on', (tester) async {
      await _pump(tester, _state(format: {'noAd': true}, tennis: deuce));
      expect(find.text('Deuce'), findsNothing);
    });
  });
}
