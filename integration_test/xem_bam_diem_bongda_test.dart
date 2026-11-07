import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/football_score_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/bam_diem.dart';
import 'support/xem.dart';

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

/// Keeps every score write so a test can check what would reach the Backend.
class _RecordedWrites extends BamDiemWrites {
  final calls = <({String? winnerId, Map<String, dynamic>? extras})>[];

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
  }) async {
    calls.add((winnerId: winnerId, extras: scoreDetailsExtras));
  }
}

final _overrides = [
  tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
];

const _state = ScorePanelState(config: _config, football: FootballLiveState());

/// The real panel on its own, a fresh 0-0 match in the first half.
Future<void> _pumpFootball(WidgetTester tester) => pumpPanel(
  tester,
  const FootballScorePanel(
    params: bamDiemParams,
    team1Name: 'Đội A',
    team2Name: 'Đội B',
  ),
  _state,
  extra: _overrides,
);

FootballLiveState _football(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(FootballScorePanel)),
).read(scorePanelNotifierProvider(bamDiemParams)).football!;

/// Scrolls [target] into view, taps it and lets animations and the debounced
/// live sync finish.
Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tapAndSettle(tester, target);
  await tester.pumpAndSettle();
}

Future<void> _goal(WidgetTester tester, {required bool team1}) =>
    _tap(tester, find.byIcon(Icons.add_circle).at(team1 ? 0 : 1));

/// Event button, then the team row in the picker, then the shirt number for
/// cards (cards ask for one).
Future<void> _event(
  WidgetTester tester,
  String event,
  String team, {
  int? shirt,
}) async {
  await _tap(tester, find.text(event));
  await _tap(tester, find.text('$event · $team'));
  if (shirt != null) {
    await _tap(tester, find.byKey(Key('football-shirt-$shirt')));
  }
}

Future<void> _setPhase(WidgetTester tester, String label) async {
  await _tap(tester, find.byType(DropdownButtonFormField<String>));
  await _tap(tester, find.text(label).last);
}

String _onField(WidgetTester tester, {required bool team1}) => tester
    .widget<Text>(find.byKey(Key('football-onfield-team${team1 ? 1 : 2}')))
    .data!;

/// The scoring page's penalty tab puts a ListTile inside a coloured
/// DecoratedBox, which debug builds report on every layout. It is a visual
/// warning outside the football flow, so it is let through; every other
/// Flutter error still fails the test.
void _ignoreListTileInkWarning() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes may be invisible',
    )) {
      return;
    }
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

const _stoppedWarning =
    'A team has fewer than 7 players: match stopped, the other team wins';

/// Football flows on the real scoring panel, one tap at a time, with a fake
/// repository (no Backend, no network).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A stuck test must fail with a stack trace instead of eating the 40 min job budget.
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 3));
  // Without fullyLive the emulator keeps showing "Test starting..." and the screen recording never shows the UI.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(initXem);

  testWidgets('TC-CBD-APP-08 bong da: luong day du den chot tran', (
    tester,
  ) async {
    _ignoreListTileInkWarning();
    final writes = _RecordedWrites();
    final match = bamDiemMatch().copyWith(sportKey: 'football');
    // Open the full scoring page, which carries the "finish match" button.
    await pumpPanel(
      tester,
      Builder(
        builder: (context) => TextButton(
          key: const Key('open-score-page'),
          onPressed: () => showOfficialScoreModal(
            context,
            tournamentId: bamDiemParams.tournamentId,
            matchId: bamDiemParams.matchId,
            match: match,
          ),
          child: const Text('Open'),
        ),
      ),
      _state,
      writes: writes,
      extra: _overrides,
    );
    // The real notifier keeps the match stream alive by listening to it; the
    // seeded one does not, and "finish match" needs the match (team ids).
    ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    ).listen(singleMatchProvider(bamDiemParams), (_, _) {});
    final shooter = BamDiemShooter(tester, binding);
    await tester.tap(find.byKey(const Key('open-score-page')));
    await settle(tester);
    expect(find.byType(FootballScorePanel), findsOneWidget);
    await shooter.snap('bong-da-bat-dau');

    // Goals for each team: 2-1.
    await _goal(tester, team1: true);
    await _goal(tester, team1: false);
    await _goal(tester, team1: true);
    expect(_football(tester).team1Goals, 2);
    expect(_football(tester).team2Goals, 1);
    await shooter.snap('bong-da-ghi-ban');

    // A yellow card keeps the player on the field.
    await _event(tester, 'Yellow card', 'Team 1', shirt: 7);
    expect(_football(tester).events.last.type, 'YELLOW_CARD');
    expect(_football(tester).events.last.shirt, 7);
    expect(_onField(tester, team1: true), '11 players · subs 0/5');

    // The same shirt again: a second yellow becomes a red, team 1 plays on
    // with ten.
    await _event(tester, 'Yellow card', 'Team 1', shirt: 7);
    final cards = _football(tester).events.where((e) => e.shirt == 7);
    expect(cards.map((e) => e.type), [
      'YELLOW_CARD',
      'YELLOW_CARD',
      'RED_CARD',
    ]);
    expect(_onField(tester, team1: true), '10 players · subs 0/5');
    expect(_onField(tester, team1: false), '11 players · subs 0/5');
    await shooter.snap('bong-da-the-vang-thu-hai-thanh-do');

    // Foul, then half-time and the second half.
    await _event(tester, 'Foul', 'Team 2');
    expect(_football(tester).events.last.type, 'FOUL');
    await _setPhase(tester, 'Half-time');
    expect(_football(tester).phase, 'HALFTIME');
    await _setPhase(tester, 'Second half');
    expect(_football(tester).phase, 'SECOND_HALF');

    // Penalty and a substitution in the second half.
    await _event(tester, 'Penalty goal', 'Team 2');
    expect(_football(tester).events.last.type, 'PENALTY_GOAL');
    await _event(tester, 'Substitution', 'Team 1');
    expect(_onField(tester, team1: true), '10 players · subs 1/5');
    await shooter.snap('bong-da-hiep-hai');

    // Full time, then finish the match for the leader.
    await _setPhase(tester, 'Full time');
    expect(_football(tester).phase, 'FULL_TIME');
    await _tap(tester, find.text('FINISH MATCH'));
    await shooter.snap('bong-da-hoi-chot-tran');
    await _tap(tester, find.text('Confirm'));
    await settle(tester);

    final last = writes.calls.last;
    expect(last.winnerId, 'team-1');
    final football = last.extras!['football'] as Map<String, dynamic>;
    expect(football['phase'], 'COMPLETED');
    expect(football['team1Goals'], 2);
    expect(football['team2Goals'], 1);
    expect(find.byType(FootballScorePanel), findsNothing);
  });

  testWidgets('TC-CBD-APP-08b bong da: duoi 7 nguoi tren san thi dung tran', (
    tester,
  ) async {
    await _pumpFootball(tester);
    final shooter = BamDiemShooter(tester, binding);

    // Four reds leave seven players: still on.
    for (var shirt = 1; shirt <= 4; shirt++) {
      await _event(tester, 'Red card', 'Team 1', shirt: shirt);
    }
    expect(_onField(tester, team1: true), '7 players · subs 0/5');
    expect(_football(tester).stoppedWinnerTeam, 0);

    // The fifth drops team 1 to six: the match stops, team 2 wins.
    await _event(tester, 'Red card', 'Team 1', shirt: 5);
    expect(_onField(tester, team1: true), '6 players · subs 0/5');
    expect(find.text(_stoppedWarning), findsOneWidget);
    expect(_football(tester).stoppedWinnerTeam, 2);
    await shooter.snap('bong-da-duoi-7-nguoi-dung-tran');

    // Nothing more can be recorded.
    await _goal(tester, team1: false);
    expect(_football(tester).team2Goals, 0);
    expect(find.text(_stoppedWarning), findsOneWidget);
  });

  testWidgets('TC-CBD-APP-08c bong da: ghi ban ngoai hiep dang da bi chan', (
    tester,
  ) async {
    await _pumpFootball(tester);
    final shooter = BamDiemShooter(tester, binding);

    await _setPhase(tester, 'Half-time');
    await _goal(tester, team1: true);
    expect(
      find.text('Goals can only be recorded while play is on'),
      findsOneWidget,
    );
    expect(_football(tester).team1Goals, 0);
    expect(_football(tester).events, isEmpty);
    await shooter.snap('bong-da-ghi-ban-nghi-giua-hiep-bi-chan');

    // Back to play: the same tap now scores.
    await _setPhase(tester, 'Second half');
    await _goal(tester, team1: true);
    expect(_football(tester).team1Goals, 1);
  });

  testWidgets('TC-CBD-APP-08d bong da: het luot thay nguoi', (tester) async {
    await _pumpFootball(tester);
    final shooter = BamDiemShooter(tester, binding);

    for (var used = 1; used <= 5; used++) {
      await _event(tester, 'Substitution', 'Team 1');
      expect(_onField(tester, team1: true), '11 players · subs $used/5');
    }

    // The sixth is refused.
    await _event(tester, 'Substitution', 'Team 1');
    expect(find.text('This team has used all 5 substitutions'), findsOneWidget);
    expect(_onField(tester, team1: true), '11 players · subs 5/5');
    expect(_football(tester).events, hasLength(5));
    await shooter.snap('bong-da-het-luot-thay-nguoi');

    // The limit is per team: team 2 still has all five.
    await _event(tester, 'Substitution', 'Team 2');
    expect(_onField(tester, team1: false), '11 players · subs 1/5');
  });
}
