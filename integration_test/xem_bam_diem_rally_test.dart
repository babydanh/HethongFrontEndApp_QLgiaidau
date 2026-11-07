import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/rally_score_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/bam_diem.dart';

/// Taps the real RallyScorePanel point by point, from 0-0, and checks the
/// serve line, the 60 second reminder and the end of a game after each tap.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A stuck test must fail with a stack trace instead of eating the 40 min job budget.
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 3));
  // Without fullyLive the emulator keeps showing "Test starting..." and the screen recording never shows the UI.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('TC-CBD-APP-03 cau long: giao theo doi thang pha va o san', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await pumpPanel(tester, _panel, _freshGame(SportRuleKind.badminton));
    expect(_scores(tester), (0, 0));
    expect(_serveTeam(tester), 1);
    expect(find.text('● SERVE · right court'), findsOneWidget);
    await shooter.snap('cau-long-0-0');

    // Team A reaches 11 on the 16th point, team B is on 5 at that moment.
    const rallies = 'ABBAAABABAABAAAAB';
    var a = 0;
    var b = 0;
    for (var i = 0; i < rallies.length; i++) {
      final aWon = rallies[i] == 'A';
      await tapAndSettle(tester, _plus(aWon ? 1 : 2));
      aWon ? a++ : b++;

      expect(_scores(tester), (a, b), reason: 'score after point ${i + 1}');
      expect(
        _serveTeam(tester),
        aWon ? 1 : 2,
        reason: 'server after point ${i + 1}',
      );
      final servingScore = aWon ? a : b;
      expect(
        find.text('● SERVE · ${servingScore.isEven ? 'right' : 'left'} court'),
        findsOneWidget,
        reason: 'court after point ${i + 1} ($a-$b)',
      );
      expect(
        find.text('60-second interval (leader reached 11)'),
        i == 15 ? findsOneWidget : findsNothing,
        reason: '60 s reminder after point ${i + 1} ($a-$b)',
      );
      if (i == 15) await shooter.snap('cau-long-nghi-60-giay-11-5');
    }
    await shooter.snap('cau-long-11-6');
  });

  testWidgets('TC-CBD-APP-03b cau long: 20-20 phai hon 2 diem moi het set', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await pumpPanel(tester, _panel, _freshGame(SportRuleKind.badminton));

    for (var i = 0; i < 20; i++) {
      await tapAndSettle(tester, _plus(1));
      await tapAndSettle(tester, _plus(2));
    }
    expect(_scores(tester), (20, 20));
    await shooter.snap('cau-long-20-20');

    // 21-20: one point ahead is not enough, the set stays open.
    await tapAndSettle(tester, _plus(1));
    expect(_scores(tester), (21, 20));
    await shooter.snap('cau-long-21-20-chua-het-set');

    await tapAndSettle(tester, _plus(2));
    expect(_scores(tester), (21, 21));
    await tapAndSettle(tester, _plus(1));
    expect(_scores(tester), (22, 21));

    // 23-21: two points ahead closes set 1 and opens set 2 at 0-0.
    await tapAndSettle(tester, _plus(1));
    expect(_scores(tester), (0, 0));
    expect(
      find.text('120-second rest between games, change ends'),
      findsOneWidget,
    );
    // The winner of the previous game serves first, from the right court.
    expect(_serveTeam(tester), 1);
    expect(find.text('● SERVE · right court'), findsOneWidget);
    await shooter.snap('cau-long-set-2-mo');

    // Set 2 is live: a point for B hands B the serve from the left court.
    await tapAndSettle(tester, _plus(2));
    expect(_scores(tester), (0, 1));
    expect(_serveTeam(tester), 2);
    expect(find.text('● SERVE · left court'), findsOneWidget);
  });

  testWidgets('TC-CBD-APP-04 bong ban: doi nguoi giao moi 2 diem tong', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await pumpPanel(tester, _panel, _freshGame(SportRuleKind.tableTennis));
    expect(_scores(tester), (0, 0));
    expect(_serveTeam(tester), 1);
    expect(find.text('● SERVE'), findsOneWidget);

    // Who wins each rally does not matter, only the total does. Ends 6-4.
    const rallies = 'ABBAAABABA';
    var a = 0;
    var b = 0;
    for (var i = 0; i < rallies.length; i++) {
      final aWon = rallies[i] == 'A';
      await tapAndSettle(tester, _plus(aWon ? 1 : 2));
      aWon ? a++ : b++;

      final total = a + b;
      expect(_scores(tester), (a, b));
      expect(
        _serveTeam(tester),
        (total ~/ 2).isEven ? 1 : 2,
        reason: 'server at total $total ($a-$b)',
      );
      expect(find.text('● SERVE'), findsOneWidget);
      if (total == 2) await shooter.snap('bong-ban-doi-giao-sau-2-diem');
    }
    await shooter.snap('bong-ban-6-4');
  });

  testWidgets('TC-CBD-APP-04b bong ban: 10-10 doi giao moi diem, game ke', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await pumpPanel(tester, _panel, _freshGame(SportRuleKind.tableTennis));

    for (var i = 0; i < 10; i++) {
      await tapAndSettle(tester, _plus(1));
      await tapAndSettle(tester, _plus(2));
    }
    expect(_scores(tester), (10, 10));
    expect(_serveTeam(tester), 1);
    await shooter.snap('bong-ban-10-10');

    // From 10-10 the server changes after every point; 11 is not enough.
    const afterTie = [
      (winner: 1, score: (11, 10), server: 2),
      (winner: 2, score: (11, 11), server: 1),
      (winner: 1, score: (12, 11), server: 2),
      (winner: 2, score: (12, 12), server: 1),
      (winner: 1, score: (13, 12), server: 2),
    ];
    for (final step in afterTie) {
      await tapAndSettle(tester, _plus(step.winner));
      expect(_scores(tester), step.score);
      expect(
        _serveTeam(tester),
        step.server,
        reason: 'server at ${step.score}',
      );
    }
    await shooter.snap('bong-ban-13-12-chua-het-game');

    // 14-12: two points ahead closes game 1; game 2 opens with B serving.
    await tapAndSettle(tester, _plus(1));
    expect(_scores(tester), (0, 0));
    expect(_serveTeam(tester), 2);
    await shooter.snap('bong-ban-game-2-B-giao-dau');

    // Game 2 follows the normal rhythm again: B serves points 1-2, then A.
    await tapAndSettle(tester, _plus(1));
    expect(_serveTeam(tester), 2);
    await tapAndSettle(tester, _plus(1));
    expect(_scores(tester), (2, 0));
    expect(_serveTeam(tester), 1);
  });
}

const _panel = RallyScorePanel(params: bamDiemParams);

/// A game at 0-0 on a strict (not Lite) match of [kind].
ScorePanelState _freshGame(SportRuleKind kind) {
  final base = resolveSportConfig(null, kind);
  return ScorePanelState(
    config: SportConfig(
      kind: kind,
      scoringModel: base.scoringModel,
      isOpenScoring: false,
      bestOf: base.bestOf,
      setsToWin: base.setsToWin,
      pointsPerSet: base.pointsPerSet,
      mustWinByTwo: base.mustWinByTwo,
      maxPoints: base.maxPoints,
      tiebreakAt: base.tiebreakAt,
    ),
    isLite: false,
    finishedSets: const [],
    rally: const RallySetState(),
  );
}

/// The "+" button of team 1 (A, top card) or team 2 (B, bottom card).
Finder _plus(int team) => team == 1
    ? find.byIcon(Icons.add_rounded).first
    : find.byIcon(Icons.add_rounded).last;

/// Current score as shown by the two big numbers (team A, team B).
(int, int) _scores(WidgetTester tester) {
  final numbers = find
      .byWidgetPredicate((w) => w is Text && w.style?.fontSize == 84)
      .evaluate()
      .map((e) => int.parse((e.widget as Text).data!))
      .toList();
  return (numbers[0], numbers[1]);
}

/// Team (1 = A, 2 = B) whose card shows the "● SERVE" line, null if none.
int? _serveTeam(WidgetTester tester) {
  final serve = find.textContaining('● SERVE');
  if (serve.evaluate().isEmpty) return null;
  final above =
      tester.getCenter(serve).dy < tester.getCenter(find.text('Đội B')).dy;
  return above ? 1 : 2;
}
