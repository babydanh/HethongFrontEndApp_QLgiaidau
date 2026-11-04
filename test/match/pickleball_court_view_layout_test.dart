import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_palette.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sideOutContext = CourtContext(
  score1: 0,
  score2: 0,
  isDoubles: true,
  team1PlayerCount: 2,
  team2PlayerCount: 2,
  servingTeam: 1,
  serverNumber: 1,
  scoringMode: CourtScoringMode.sideOut,
  setIndex: 0,
  targetPoints: 11,
  isDecidingSet: false,
);

// Score 0-0, team 1 first and serving. Player 0 stands in the right cell:
// team 1 = "Lan Anh" (right) and "Minh" (left); team 2 = "Bảo" (right) and
// "Hà" (left).
const _team1 = ['Lan Anh', 'Minh'];
const _team2 = ['Bảo', 'Hà'];

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData.dark().copyWith(splashFactory: NoSplash.splashFactory),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

class _Spy {
  final calls = <String>[];
}

Widget _view(
  _Spy spy, {
  Axis axis = Axis.horizontal,
  bool interactive = true,
  bool withLoseServe = true,
  bool withOverride = false,
  bool withForceWin = false,
  bool finishSetEnabled = true,
  bool canUndo = true,
  int score1 = 0,
  int score2 = 0,
  bool flipped = false,
}) {
  return PickleballCourtView(
    layout: resolveCourtLayout(
      CourtState(endsOverride: flipped ? true : null),
      _sideOutContext,
    ),
    team1Players: _team1,
    team2Players: _team2,
    team1Score: score1,
    team2Score: score2,
    axis: axis,
    isSideOut: true,
    finishSetEnabled: finishSetEnabled,
    onScoreChange: interactive
        ? (team, increment) => spy.calls.add('score:$team:$increment')
        : null,
    onDrop: interactive ? (action) => spy.calls.add('drop') : null,
    onSwitchEnds: interactive ? () => spy.calls.add('switchEnds') : null,
    onUndo: interactive && canUndo ? () => spy.calls.add('undo') : null,
    onRestoreAutomatic: interactive ? () => spy.calls.add('restore') : null,
    onToggleAutoSwitch: interactive ? () => spy.calls.add('auto') : null,
    onFinishSet: interactive ? () => spy.calls.add('finishSet') : null,
    onPickWinner: interactive ? () => spy.calls.add('pickWinner') : null,
    onLoseServe: interactive && withLoseServe
        ? () => spy.calls.add('loseServe')
        : null,
    onToggleOverride: interactive && withOverride
        ? () => spy.calls.add('override')
        : null,
    onForceWin: interactive && withForceWin
        ? () => spy.calls.add('forceWin')
        : null,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget view, {
  Size size = const Size(360, 640),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(view));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('score sits in the kitchen strip of each half', () {
    testWidgets('no separate score bar above the court', (tester) async {
      await _pump(tester, _view(_Spy(), score1: 7, score2: 3));

      // Each score is drawn exactly once: no second bar and no big copy.
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(AspectRatio), findsNothing);
    });
  });

  group('each team has its own color', () {
    test('TC-COURT-01 team 1 is orange and team 2 is blue', () {
      expect(courtTeam1.accent, const Color(0xFFEA580C));
      expect(courtTeam2.accent, const Color(0xFF2979FF));
      expect(courtTeam1.court, const Color(0xFFF6C3A1));
      expect(courtTeam2.court, const Color(0xFF8EBDF0));
    });
  });

  group('menu', () {
    testWidgets('lists the court actions and runs the chosen one', (
      tester,
    ) async {
      final spy = _Spy();
      await _pump(tester, _view(spy));

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();

      expect(find.text('Switch ends'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Restore automatic'), findsOneWidget);
      expect(find.text('Auto switch ends'), findsOneWidget);
      expect(find.text('Override'), findsNothing);
      expect(find.text('Force win'), findsNothing);

      await tester.tap(find.text('Switch ends'));
      await tester.pumpAndSettle();
      expect(spy.calls, ['switchEnds']);
    });

    testWidgets('undo is disabled when there is nothing to undo', (
      tester,
    ) async {
      final spy = _Spy();
      await _pump(tester, _view(spy, canUndo: false));

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(spy.calls, isEmpty);
    });

    testWidgets('override and force win appear only when provided', (
      tester,
    ) async {
      final spy = _Spy();
      await _pump(tester, _view(spy, withOverride: true, withForceWin: true));

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      expect(find.text('Override'), findsOneWidget);
      expect(find.text('Force win'), findsOneWidget);

      await tester.tap(find.text('Override'));
      await tester.pumpAndSettle();
      expect(spy.calls, ['override']);
    });

    testWidgets('read-only has no menu', (tester) async {
      await _pump(tester, _view(_Spy(), interactive: false));

      expect(find.byTooltip('More actions'), findsNothing);
    });
  });

  group('drag and drop works in both directions', () {
    for (final axis in Axis.values) {
      testWidgets(
        'a chip dragged onto the other half calls drop (${axis.name})',
        (tester) async {
          final spy = _Spy();
          await _pump(
            tester,
            _view(spy, axis: axis),
            size: axis == Axis.vertical
                ? const Size(360, 640)
                : const Size(800, 360),
          );

          final start = tester.getCenter(find.text('Minh'));
          final end = tester.getCenter(find.text('Bảo'));
          final gesture = await tester.startGesture(start);
          await tester.pump(const Duration(milliseconds: 400));
          await gesture.moveBy(const Offset(4, 4));
          await tester.pump();
          await gesture.moveTo(end);
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(spy.calls, ['drop']);
        },
      );
    }
  });

  group('fits the screen', () {
    for (final axis in Axis.values) {
      testWidgets(
        'no layout error in the smallest slot, 240x80 (${axis.name})',
        (tester) async {
          await _pump(
            tester,
            SizedBox(width: 240, height: 80, child: _view(_Spy(), axis: axis)),
            size: const Size(320, 200),
          );

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('horizontal scoreboard fits an 800x300 landscape slot', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(height: 220, child: _view(_Spy())),
        size: const Size(800, 300),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('the court fills its slot, no blank margin', () {
    testWidgets('horizontal on a landscape phone (844x390)', (tester) async {
      await _pump(tester, _view(_Spy()), size: const Size(844, 390));

      expect(tester.takeException(), isNull);
      // Between the top row (56dp) and the bottom bar (64dp), edge to edge.
      expect(
        tester.getRect(find.byKey(courtSurfaceKey)),
        const Rect.fromLTWH(16, 72, 812, 238),
      );
    });

    testWidgets('vertical on a portrait phone (360x640)', (tester) async {
      await _pump(tester, _view(_Spy(), axis: Axis.vertical));

      expect(tester.takeException(), isNull);
      // Between the top row (56dp) and the bottom bar (64dp), edge to edge.
      expect(
        tester.getRect(find.byKey(courtSurfaceKey)),
        const Rect.fromLTWH(16, 72, 328, 488),
      );
    });

    testWidgets('vertical in a wide, short slot (800x600)', (tester) async {
      await _pump(
        tester,
        _view(_Spy(), axis: Axis.vertical),
        size: const Size(800, 600),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(courtSurfaceKey)).size,
        const Size(768, 448),
      );
    });
  });
}
