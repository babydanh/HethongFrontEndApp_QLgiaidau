import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/football_score_panel.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

const _config = SportConfig(
  kind: SportRuleKind.football,
  scoringModel: SportScoringModel.rallyPointSet,
  bestOf: 1,
  setsToWin: 1,
  pointsPerSet: 1,
  mustWinByTwo: false,
  maxPoints: 99,
  tiebreakAt: 90,
);

/// Real football notifier logic, seeded with a given state and without any
/// server: the match stream is empty so the delayed sync is a no-op.
class _SeededPanel extends ScorePanelNotifier {
  _SeededPanel(super.arg, this.seed);

  final FootballLiveState seed;

  @override
  ScorePanelState build() => ScorePanelState(config: _config, football: seed);
}

List<FootballEvent> _events(String type, int count, {bool isTeam1 = true}) => [
  for (var i = 0; i < count; i++)
    FootballEvent(type: type, isTeam1: isTeam1, minute: 10 + i),
];

Future<void> _pumpPanel(WidgetTester tester, FootballLiveState seed) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        singleMatchProvider.overrideWith((ref, params) => Stream.value(null)),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => _SeededPanel(arg, seed),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: FootballScorePanel(
            params: _params,
            team1Name: 'Alpha',
            team2Name: 'Beta',
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

FootballLiveState _football(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(FootballScorePanel)),
).read(scorePanelNotifierProvider(_params)).football!;

/// Taps an event button, then the team row in the team picker sheet.
Future<void> _pickEventTeam(
  WidgetTester tester,
  String event,
  String team,
) async {
  await tester.tap(find.text(event));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$event · $team'));
  await tester.pumpAndSettle();
}

/// Lets the 250 ms delayed sync timer fire so no timer is left pending.
Future<void> _drainSyncTimer(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 400));

void main() {
  testWidgets('TC-CBD-FB-09 a card asks for the shirt number and keeps it', (
    tester,
  ) async {
    await _pumpPanel(tester, const FootballLiveState());

    await _pickEventTeam(tester, 'Yellow card', 'Team 1');
    expect(find.text('Player shirt number'), findsOneWidget);
    expect(find.byKey(const Key('football-shirt-unknown')), findsOneWidget);
    await tester.tap(find.byKey(const Key('football-shirt-7')));
    await tester.pumpAndSettle();
    await _drainSyncTimer(tester);

    final events = _football(tester).events;
    expect(events, hasLength(1));
    expect(events.single.type, 'YELLOW_CARD');
    expect(events.single.isTeam1, isTrue);
    expect(events.single.shirt, 7);
  });

  testWidgets('TC-CBD-FB-10 "number unknown" still counts the card', (
    tester,
  ) async {
    await _pumpPanel(tester, const FootballLiveState());
    expect(find.text('11 players · subs 0/5'), findsNWidgets(2));

    await _pickEventTeam(tester, 'Red card', 'Team 2');
    await tester.tap(find.byKey(const Key('football-shirt-unknown')));
    await tester.pumpAndSettle();
    await _drainSyncTimer(tester);

    final events = _football(tester).events;
    expect(events.single.type, 'RED_CARD');
    expect(events.single.isTeam1, isFalse);
    expect(events.single.shirt, isNull);
    expect(
      tester.widget<Text>(find.byKey(const Key('football-onfield-team2'))).data,
      '10 players · subs 0/5',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('football-onfield-team1'))).data,
      '11 players · subs 0/5',
    );
  });

  testWidgets('TC-CBD-FB-11 a goal outside play is refused with a warning', (
    tester,
  ) async {
    await _pumpPanel(tester, const FootballLiveState(phase: 'HALFTIME'));

    await tester.tap(find.byIcon(Icons.add_circle).first);
    await tester.pump();

    expect(
      find.text('Goals can only be recorded while play is on'),
      findsOneWidget,
    );
    expect(_football(tester).team1Goals, 0);
    expect(_football(tester).events, isEmpty);
    await _drainSyncTimer(tester);
  });

  testWidgets('TC-CBD-FB-12 no substitution past the limit', (tester) async {
    await _pumpPanel(
      tester,
      FootballLiveState(events: _events('SUBSTITUTION', 5)),
    );
    expect(find.text('11 players · subs 5/5'), findsOneWidget);

    await _pickEventTeam(tester, 'Substitution', 'Team 1');
    await tester.pump();

    expect(find.text('This team has used all 5 substitutions'), findsOneWidget);
    expect(_football(tester).events, hasLength(5));
    await _drainSyncTimer(tester);
  });

  testWidgets('TC-CBD-FB-12 a team below 7 players stops the match', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      FootballLiveState(
        events: [
          for (var shirt = 1; shirt <= 4; shirt++)
            FootballEvent(
              type: 'RED_CARD',
              isTeam1: true,
              minute: 10 + shirt,
              shirt: shirt,
            ),
        ],
      ),
    );
    expect(find.text('7 players · subs 0/5'), findsOneWidget);

    await _pickEventTeam(tester, 'Red card', 'Team 1');
    await tester.tap(find.byKey(const Key('football-shirt-5')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A team has fewer than 7 players: match stopped, the other team wins',
      ),
      findsOneWidget,
    );
    expect(_football(tester).stoppedWinnerTeam, 2);
    await _drainSyncTimer(tester);
  });
}
