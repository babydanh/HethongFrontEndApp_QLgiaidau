import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/racket_court_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/bam_diem.dart';

/// Tennis scoring through the real [RacketCourtPanel]: every point is a tap on
/// a "+" button, and every check reads what the court shows or the live state.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A stuck test must fail with a stack trace instead of eating the 40 min job budget.
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 3));
  // Without fullyLive the emulator keeps showing "Test starting..." and the screen recording never shows the UI.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'TC-CBD-APP-05 tennis chuan: 15-30-40, Deuce, Advantage, doi giao',
    (tester) async {
      final shooter = BamDiemShooter(tester, binding);
      await pumpPanel(tester, _panel, _seed());
      await shooter.snap('tennis-chuan-0-0');
      _expectBoard(tester, '0', '0', serverIsB: false);

      await _point(tester, teamA: true);
      _expectBoard(tester, '15', '0', serverIsB: false);
      await _point(tester, teamA: true);
      _expectBoard(tester, '30', '0', serverIsB: false);
      await _point(tester, teamA: true);
      _expectBoard(tester, '40', '0', serverIsB: false);
      await shooter.snap('tennis-chuan-40-0');

      await _point(tester, teamA: false);
      _expectBoard(tester, '40', '15', serverIsB: false);
      await _point(tester, teamA: false);
      _expectBoard(tester, '40', '30', serverIsB: false);
      expect(find.text('Deuce'), findsNothing);

      await _point(tester, teamA: false);
      _expectBoard(tester, '40', '40', serverIsB: false);
      expect(find.text('Deuce'), findsOneWidget);
      await shooter.snap('tennis-chuan-deuce');

      await _point(tester, teamA: true);
      _expectBoard(tester, 'Ad', '40', serverIsB: false);
      expect(find.text('Deuce'), findsNothing);
      await shooter.snap('tennis-chuan-advantage-a');

      await _point(tester, teamA: false);
      _expectBoard(tester, '40', '40', serverIsB: false);
      expect(find.text('Deuce'), findsOneWidget);

      await _point(tester, teamA: false);
      _expectBoard(tester, '40', 'Ad', serverIsB: false);
      expect(_sets(tester), isEmpty);

      // Team B wins the game: games 0-1, points reset, the serve passes to B.
      await _point(tester, teamA: false);
      expect(_sets(tester), [(0, 1, false)]);
      _expectBoard(tester, '0', '0', serverIsB: true);
      expect(find.text('Deuce'), findsNothing);
      await shooter.snap('tennis-chuan-b-thang-game-doi-giao');

      // Team A takes the next game to love: games 1-1, the serve is back to A.
      for (var i = 0; i < 4; i++) {
        await _point(tester, teamA: true);
      }
      expect(_sets(tester), [(1, 1, false)]);
      _expectBoard(tester, '0', '0', serverIsB: false);
    },
  );

  testWidgets('TC-CBD-APP-05b tennis: 6-6 vao tie-break, doi giao, chot set', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await pumpPanel(
      tester,
      _panel,
      _seed(sets: const [SetScoreData(score1: 5, score2: 6)]),
    );
    _expectBoard(tester, '0', '0', serverIsB: true);
    expect(find.textContaining('Tie-break 7'), findsNothing);

    // Team A wins the 12th game: 6-6 and the tie-break starts.
    for (var i = 0; i < 4; i++) {
      await _point(tester, teamA: true);
    }
    expect(_sets(tester), [(6, 6, false)]);
    expect(find.textContaining('Tie-break 7'), findsOneWidget);
    _expectBoard(tester, '0', '0', serverIsB: false);
    await shooter.snap('tennis-tiebreak-bat-dau');

    // A serves point 1, then the serve changes every 2 points (B, B, A, A...).
    // Each step: team A scores?, then the expected A points, B points, server.
    const steps = [
      (true, '1', '0', true),
      (false, '1', '1', true),
      (true, '2', '1', false),
      (false, '2', '2', false),
      (true, '3', '2', true),
      (false, '3', '3', true),
      (true, '4', '3', false),
      (true, '5', '3', false),
      (true, '6', '3', true),
    ];
    for (final (teamA, a, b, serverIsB) in steps) {
      await _point(tester, teamA: teamA);
      _expectBoard(tester, a, b, serverIsB: serverIsB);
    }
    expect(_sets(tester), [(6, 6, false)]);
    await shooter.snap('tennis-tiebreak-6-3');

    // 7-3 reaches 7 points with a lead of 2: the set closes 7-6 for team A.
    await _point(tester, teamA: true);
    expect(_sets(tester), [(7, 6, true)]);
    _expectBoard(tester, '0', '0', serverIsB: true);
    expect(find.textContaining('Tie-break 7'), findsNothing);
    expect(_read(tester).team1SetWins, 1);
    await shooter.snap('tennis-tiebreak-chot-set');
  });

  testWidgets('TC-CBD-APP-06 tennis No-Ad: 40-40 diem ke thang game luon', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await pumpPanel(tester, _panel, _seed(format: {'noAd': true}));

    for (var i = 0; i < 3; i++) {
      await _point(tester, teamA: true);
      await _point(tester, teamA: false);
    }
    _expectBoard(tester, '40', '40', serverIsB: false);
    expect(find.text('Deuce'), findsNothing);
    expect(find.text('Ad'), findsNothing);
    expect(_sets(tester), isEmpty);
    await shooter.snap('tennis-no-ad-40-40');

    // The very next point decides the game: no advantage step.
    await _point(tester, teamA: false);
    expect(_sets(tester), [(0, 1, false)]);
    _expectBoard(tester, '0', '0', serverIsB: true);
    expect(find.text('Deuce'), findsNothing);
    expect(find.text('Ad'), findsNothing);
    await shooter.snap('tennis-no-ad-b-thang-game');
  });

  testWidgets('TC-CBD-APP-07 tennis set quyet dinh SUPER_TIEBREAK: 10-8', (
    tester,
  ) async {
    final shooter = BamDiemShooter(tester, binding);
    await pumpPanel(
      tester,
      _panel,
      _seed(
        format: {'finalSetMode': 'SUPER_TIEBREAK'},
        sets: const [
          SetScoreData(score1: 6, score2: 3, isFinished: true),
          SetScoreData(score1: 3, score2: 6, isFinished: true),
        ],
      ),
    );
    // One set each: a 10 point match tie-break replaces the deciding set.
    expect(find.textContaining('MATCH TIE-BREAK'), findsOneWidget);
    _expectBoard(tester, '0', '0', serverIsB: false);
    await shooter.snap('tennis-super-tiebreak-bat-dau');

    // A serves point 1, then the serve changes every 2 points (B, B, A, A...).
    const steps = [
      (true, '1', '0', true),
      (false, '1', '1', true),
      (true, '2', '1', false),
      (false, '2', '2', false),
    ];
    for (final (teamA, a, b, serverIsB) in steps) {
      await _point(tester, teamA: teamA);
      _expectBoard(tester, a, b, serverIsB: serverIsB);
    }

    // Level it up to 8-8.
    for (var i = 0; i < 6; i++) {
      await _point(tester, teamA: true);
      await _point(tester, teamA: false);
    }
    _expectBoard(tester, '8', '8', serverIsB: false);
    expect(_sets(tester), hasLength(2));
    await shooter.snap('tennis-super-tiebreak-8-8');

    // 9-8 is only a 1 point lead: the match goes on.
    await _point(tester, teamA: true);
    _expectBoard(tester, '9', '8', serverIsB: true);
    expect(_read(tester).isMatchComplete, isFalse);

    // 10-8 wins it. The App stores the match tie-break as the set 7-6.
    await _point(tester, teamA: true);
    expect(_sets(tester), hasLength(3));
    expect(_sets(tester).last, (7, 6, true));
    expect(_read(tester).isMatchComplete, isTrue);
    expect(_read(tester).winnerTeam, 1);
    await shooter.snap('tennis-super-tiebreak-10-8-thang');
  });
}

const _panel = RacketCourtPanel(params: bamDiemParams);

/// Best of 3 sets, the setup the panel tests use.
ScorePanelState _seed({
  Map<String, dynamic> format = const {},
  List<SetScoreData> sets = const [],
}) => ScorePanelState(
  config: resolveSportConfig({
    'kind': 'TENNIS',
    'setsToWin': 2,
    'format': format,
  }, SportRuleKind.tennis),
  finishedSets: sets,
);

/// Taps the "+" of team A or team B.
Future<void> _point(WidgetTester tester, {required bool teamA}) => tapAndSettle(
  tester,
  find.byKey(ValueKey('racketPlus${teamA ? 1 : 2}')),
);

/// The two big scores, team A first. The middle strip lists the team on the
/// first half first, and the halves swap when the teams change ends.
List<String> _scores(WidgetTester tester) {
  final texts = find
      .byWidgetPredicate((w) => w is Text && w.style?.fontSize == 40)
      .evaluate()
      .map((e) => (e.widget as Text).data!)
      .toList();
  return _read(tester).racketPick.endsFlipped
      ? [texts[1], texts[0]]
      : texts;
}

/// Checks both big scores and which side the "● SERVE" chip is on: team A is
/// "An", team B is "Chi", and the chip sits in the server's cell.
void _expectBoard(
  WidgetTester tester,
  String a,
  String b, {
  required bool serverIsB,
}) {
  expect(_scores(tester), [a, b]);
  final serve = find.text('● SERVE');
  expect(serve, findsOneWidget);
  final at = tester.getCenter(serve);
  final distanceA = (at - tester.getCenter(find.text('An'))).distance;
  final distanceB = (at - tester.getCenter(find.text('Chi'))).distance;
  expect(
    distanceB < distanceA,
    serverIsB,
    reason: 'serve chip is in the wrong cell',
  );
}

/// The live panel state behind the widget.
ScorePanelState _read(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(RacketCourtPanel)),
).read(scorePanelNotifierProvider(bamDiemParams));

/// Games of each set as (team A, team B, finished).
List<(int, int, bool)> _sets(WidgetTester tester) => _read(
  tester,
).finishedSets.map((s) => (s.score1, s.score2, s.isFinished)).toList();
