import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/bam_diem.dart';
import 'support/xem.dart';

/// Pickleball scoring through the real [PickleballCourtPanel]: every step is a
/// tap on a real button; the rules run in the real score panel logic.

/// Accepts score writes and echoes court-state writes like the server does.
class _PickleballWrites extends BamDiemWrites {
  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async => MatchModel.fromJson({
    'id': matchId,
    'tournamentId': 'tournament-1',
    'status': 'LIVE',
    'scoreDetails': {'courtState': courtState},
  }, matchId);
}

SportConfig _config({required bool lite}) => SportConfig(
  kind: SportRuleKind.pickleball,
  scoringModel: lite
      ? SportScoringModel.rallyPointSet
      : SportScoringModel.pickleballSideOut,
  isOpenScoring: lite,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 11,
  mustWinByTwo: true,
  maxPoints: 0,
  tiebreakAt: 0,
);

/// Team 1 serves as server 1; [openingDone] false = first serve of the game.
ScorePanelState _state({bool lite = false, bool openingDone = true}) =>
    ScorePanelState(
      config: _config(lite: lite),
      isLite: lite,
      pickleball: PickleballServeState(openingDone: openingDone),
      rally: const RallySetState(),
    );

Future<void> _pumpCourt(
  WidgetTester tester,
  ScorePanelState state, {
  required bool doubles,
}) => pumpPanel(
  tester,
  const PickleballCourtPanel(params: bamDiemParams, canScore: true),
  state,
  doubles: doubles,
  writes: _PickleballWrites(),
);

/// Taps "+" of [team], then waits out the sync debounce.
Future<void> _plus(WidgetTester tester, int team) async {
  await tapAndSettle(tester, find.byTooltip('Add point for team $team'));
  await tester.pump(const Duration(milliseconds: 600));
}

/// Scores, serving team and server number as the real panel holds them.
({int s1, int s2, int team, int server}) _read(WidgetTester tester) {
  final panel = ProviderScope.containerOf(
    tester.element(find.byType(PickleballCourtPanel)),
  ).read(scorePanelNotifierProvider(bamDiemParams));
  final rally = panel.rally!;
  final serve = panel.pickleball!;
  return (
    s1: rally.currentP1,
    s2: rally.currentP2,
    team: serve.isTeam1Serving ? 1 : 2,
    server: serve.serverNumber,
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A stuck test must fail with a stack trace instead of eating the 40 min job budget.
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 3));
  // Without fullyLive the emulator keeps showing "Test starting..." and the screen recording never shows the UI.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(initXem);

  testWidgets('TC-CBD-APP-01 doubles side-out: receiver plus = lose serve', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await _pumpCourt(tester, _state(), doubles: true);

    expect(find.text('0-0-1'), findsOneWidget);
    expect(find.text('LOSE SERVE'), findsOneWidget);
    expect(find.text('→ Serve 2'), findsOneWidget);
    await shooter.snap('doi-a-giao-0-0');

    // The serving team scores three times: the call follows the score.
    for (var i = 0; i < 3; i++) {
      await _plus(tester, 1);
    }
    expect(find.text('3-0-1'), findsOneWidget);
    expect(_read(tester), (s1: 3, s2: 0, team: 1, server: 1));
    await shooter.snap('doi-a-ghi-3-0');

    // Receiver plus (1): server 2 of the same team, nobody scores.
    await _plus(tester, 2);
    expect(find.textContaining('won the rally'), findsNothing);
    expect(find.text('3-0-2'), findsOneWidget);
    expect(_read(tester), (s1: 3, s2: 0, team: 1, server: 2));
    expect(find.text('→ Hand over'), findsOneWidget);
    await shooter.snap('doi-giao-2');

    // Receiver plus (2): the serve passes to team B, score still 3-0.
    await _plus(tester, 2);
    expect(find.textContaining('won the rally'), findsNothing);
    expect(find.text('0-3-1'), findsOneWidget);
    expect(_read(tester), (s1: 3, s2: 0, team: 2, server: 1));
    await shooter.snap('doi-doi-giao-sang-b');

    // Team B now serves and can score.
    await _plus(tester, 2);
    expect(find.text('1-3-1'), findsOneWidget);
    expect(_read(tester), (s1: 3, s2: 1, team: 2, server: 1));
    await shooter.snap('doi-b-ghi-diem');
  });

  testWidgets('TC-CBD-APP-01b singles: lose serve hands over, no server 2', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await _pumpCourt(tester, _state(), doubles: false);

    // Singles call has no server number.
    expect(find.text('0-0'), findsOneWidget);
    expect(find.text('→ Hand over'), findsOneWidget);
    expect(find.text('→ Serve 2'), findsNothing);

    await _plus(tester, 1);
    await _plus(tester, 1);
    expect(find.text('2-0'), findsOneWidget);
    expect(_read(tester), (s1: 2, s2: 0, team: 1, server: 1));
    await shooter.snap('don-a-ghi-2-0');

    // Receiver plus: the serve changes team at once, score unchanged.
    await _plus(tester, 2);
    expect(find.textContaining('won the rally'), findsNothing);
    expect(find.textContaining('server 2'), findsNothing);
    expect(find.text('0-2'), findsOneWidget);
    expect(_read(tester), (s1: 2, s2: 0, team: 2, server: 1));
    expect(find.text('→ Serve 2'), findsNothing);
    await shooter.snap('don-doi-giao-ngay');

    await _plus(tester, 2);
    expect(find.text('1-2'), findsOneWidget);
    expect(_read(tester), (s1: 2, s2: 1, team: 2, server: 1));
  });

  testWidgets('TC-CBD-APP-01c doubles opening serve: single fault hands over', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await _pumpCourt(tester, _state(openingDone: false), doubles: true);

    await _plus(tester, 1);
    expect(find.text('1-0-1'), findsOneWidget);
    expect(find.text('→ Hand over'), findsOneWidget);
    expect(find.text('→ Serve 2'), findsNothing);

    // The first fault of the game passes the serve straight to team B.
    await _plus(tester, 2);
    expect(find.textContaining('won the rally'), findsNothing);
    expect(find.textContaining('server 2'), findsNothing);
    expect(find.text('0-1-1'), findsOneWidget);
    expect(_read(tester), (s1: 1, s2: 0, team: 2, server: 1));
    await shooter.snap('doi-mo-man-mat-giao-sang-b');
  });

  testWidgets('TC-CBD-APP-02 Lite: receiver plus scores like a rally', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await _pumpCourt(tester, _state(lite: true), doubles: true);

    // Lite has no lose-serve preview, only the plain change-serve button.
    expect(find.text('CHANGE SERVE'), findsOneWidget);
    expect(find.text('→ Hand over'), findsNothing);
    await _plus(tester, 1);
    await _plus(tester, 1);
    expect(find.text('2-0-1'), findsOneWidget);
    await shooter.snap('lite-a-ghi-2-0');

    // The receiver wins the rally and scores; the serve goes to that team.
    await _plus(tester, 2);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining('won the rally'), findsNothing);
    expect(find.text('1-2-1'), findsOneWidget);
    expect(_read(tester), (s1: 2, s2: 1, team: 2, server: 1));
    await shooter.snap('lite-b-nhan-ghi-diem');

    // And back: team A is the receiver now and scores the same way.
    await _plus(tester, 1);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('3-1-1'), findsOneWidget);
    expect(_read(tester), (s1: 3, s2: 1, team: 1, server: 1));
  });
}
