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

Offset _at(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('score sits in the kitchen strip of each half', () {
    testWidgets('horizontal: the number is between the cells and the net', (
      tester,
    ) async {
      await _pump(tester, _view(_Spy(), score1: 7, score2: 3));

      final court = tester.getRect(find.byKey(courtSurfaceKey));
      final net = tester.getCenter(find.byKey(courtNetKey)).dx;
      final score1 = _at(tester, '7');
      final score2 = _at(tester, '3');

      // Team 1 plays on the left: its score is right of its chips, before the net.
      expect(score1.dx, greaterThan(_at(tester, 'Minh').dx));
      expect(score1.dx, lessThan(net));
      // Team 2 plays on the right: its score is left of its chips, after the net.
      expect(score2.dx, lessThan(_at(tester, 'Hà').dx));
      expect(score2.dx, greaterThan(net));
      expect(court.width, greaterThan(0));
    });

    testWidgets('vertical: the number is between the cells and the net', (
      tester,
    ) async {
      await _pump(
        tester,
        _view(_Spy(), axis: Axis.vertical, score1: 7, score2: 3),
      );

      final net = tester.getCenter(find.byKey(courtNetKey)).dy;
      final score1 = _at(tester, '7');
      final score2 = _at(tester, '3');

      expect(score1.dy, lessThan(net));
      expect(score1.dy, greaterThan(_at(tester, 'Minh').dy));
      expect(score2.dy, greaterThan(net));
      expect(score2.dy, lessThan(_at(tester, 'Hà').dy));
    });

    testWidgets('no separate score bar above the court', (tester) async {
      await _pump(tester, _view(_Spy(), score1: 7, score2: 3));

      // Each score is drawn exactly once: no second bar and no big copy.
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(AspectRatio), findsNothing);
    });

    testWidgets('plus and minus are inside the court and keep their tooltips', (
      tester,
    ) async {
      final spy = _Spy();
      await _pump(tester, _view(spy, score1: 2));

      await tester.tap(find.byTooltip('Add point for team 1'));
      await tester.tap(find.byTooltip('Remove point for team 1'));

      expect(spy.calls, ['score:1:true', 'score:1:false']);
      final court = tester.getRect(find.byKey(courtSurfaceKey));
      expect(
        court.contains(
          tester.getCenter(find.byTooltip('Add point for team 1')),
        ),
        isTrue,
      );
    });
  });

  group('each team has its own color', () {
    Finder half(CourtTeamPalette palette) => find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == palette.court,
    );

    for (final axis in Axis.values) {
      testWidgets('team 1 blue, team 2 orange, before and after switching ends '
          '(${axis.name})', (tester) async {
        final size = axis == Axis.vertical
            ? const Size(360, 640)
            : const Size(800, 360);
        await _pump(tester, _view(_Spy(), axis: axis), size: size);

        double along(Finder f) => axis == Axis.vertical
            ? tester.getCenter(f).dy
            : tester.getCenter(f).dx;
        // Team 1 is first (top / left) at the start.
        expect(half(courtTeam1).evaluate(), hasLength(1));
        expect(half(courtTeam2).evaluate(), hasLength(1));
        expect(along(half(courtTeam1)), lessThan(along(half(courtTeam2))));

        await _pump(
          tester,
          _view(_Spy(), axis: axis, flipped: true),
          size: size,
        );
        // The colors follow the teams, not the sides.
        expect(along(half(courtTeam1)), greaterThan(along(half(courtTeam2))));
      });
    }

    testWidgets('the plus button takes the color of its team', (tester) async {
      await _pump(tester, _view(_Spy(), score1: 1));

      Color plusColor(int team) {
        final box = find.descendant(
          of: find.byTooltip('Add point for team $team'),
          matching: find.byType(Container),
        );
        final decoration =
            tester.widget<Container>(box.first).decoration! as BoxDecoration;
        return decoration.color!.withValues(alpha: 1);
      }

      expect(plusColor(1), courtTeam1.accent);
      expect(plusColor(2), courtTeam2.accent);
    });
  });

  group('cells face the net in both directions', () {
    testWidgets('horizontal: left half has the left cell on top', (
      tester,
    ) async {
      await _pump(tester, _view(_Spy()));

      // Team 1 (left half): left cell "Minh" above right cell "L. Anh".
      expect(_at(tester, 'Minh').dy, lessThan(_at(tester, 'L. Anh').dy));
      // Team 2 (right half): right cell "Bảo" above left cell "Hà".
      expect(_at(tester, 'Bảo').dy, lessThan(_at(tester, 'Hà').dy));
    });

    testWidgets(
      'vertical: team 1 on top, right cell on the left of the screen',
      (tester) async {
        await _pump(tester, _view(_Spy(), axis: Axis.vertical));

        final court = tester.getRect(find.byKey(courtSurfaceKey));
        expect(court.height, greaterThan(court.width));
        // Team 1 is above the net, team 2 below it.
        expect(_at(tester, 'Minh').dy, lessThan(_at(tester, 'Bảo').dy));
        // Top half faces down: its right cell ("L. Anh") is on the left.
        expect(_at(tester, 'L. Anh').dx, lessThan(_at(tester, 'Minh').dx));
        // Bottom half faces up: its right cell ("Bảo") is on the right.
        expect(_at(tester, 'Bảo').dx, greaterThan(_at(tester, 'Hà').dx));
      },
    );
  });

  group('net controls are icons only', () {
    testWidgets('read-only: no controls, the call stays', (tester) async {
      await _pump(tester, _view(_Spy(), interactive: false));

      expect(find.byTooltip('More actions'), findsNothing);
      expect(find.byTooltip('Finish set'), findsNothing);
      expect(find.byTooltip('Pick the winner'), findsNothing);
      expect(find.byTooltip('Lose serve'), findsNothing);
      expect(find.text('0-0-1'), findsOneWidget);
    });

    testWidgets('each icon calls its action', (tester) async {
      final spy = _Spy();
      await _pump(tester, _view(spy, score1: 5));

      await tester.tap(find.byTooltip('Finish set'));
      await tester.tap(find.byTooltip('Pick the winner'));
      await tester.tap(find.byTooltip('Lose serve'));

      expect(spy.calls, ['finishSet', 'pickWinner', 'loseServe']);
    });

    testWidgets('no text button in the net controls', (tester) async {
      await _pump(tester, _view(_Spy()));

      final net = find.byKey(courtNetControlsKey);
      expect(
        find.descendant(of: net, matching: find.byType(TextButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: net, matching: find.byType(FilledButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: net, matching: find.byType(OutlinedButton)),
        findsNothing,
      );
    });

    testWidgets('lose serve is hidden when the mode has no serve turns', (
      tester,
    ) async {
      await _pump(tester, _view(_Spy(), withLoseServe: false));

      expect(find.byTooltip('Lose serve'), findsNothing);
      expect(find.byTooltip('Pick the winner'), findsOneWidget);
    });

    testWidgets('finish set is disabled when the set cannot be finished', (
      tester,
    ) async {
      final spy = _Spy();
      await _pump(tester, _view(spy, finishSetEnabled: false));

      await tester.tap(find.byTooltip('Finish set'), warnIfMissed: false);

      expect(spy.calls, isEmpty);
    });

    // Measured with the painted size (FittedBox scaling included), in a slot
    // like the real one: a phone held upright, or held sideways.
    for (final entry in {
      Axis.vertical: const Size(360, 640),
      Axis.horizontal: const Size(800, 360),
    }.entries) {
      testWidgets('every control has a >= 40dp hit area (${entry.key.name})', (
        tester,
      ) async {
        await _pump(tester, _view(_Spy(), axis: entry.key), size: entry.value);
        // Upright the controls keep 44dp; a short sideways slot may scale
        // them down, never below 40dp.
        final min = entry.key == Axis.vertical ? 44.0 : 40.0;

        for (final tip in [
          'More actions',
          'Finish set',
          'Pick the winner',
          'Lose serve',
          'Add point for team 1',
          'Remove point for team 2',
        ]) {
          final finder = find.byTooltip(tip);
          final painted =
              tester.getBottomRight(finder) - tester.getTopLeft(finder);
          expect(painted.dx, greaterThanOrEqualTo(min), reason: '$tip width');
          expect(painted.dy, greaterThanOrEqualTo(min), reason: '$tip height');
        }
      });
    }
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
    testWidgets('vertical court fills a 360x640 portrait phone', (
      tester,
    ) async {
      await _pump(tester, _view(_Spy(), axis: Axis.vertical));

      expect(tester.takeException(), isNull);
      final court = tester.getRect(find.byKey(courtSurfaceKey));
      expect(court.height, greaterThan(400));
    });

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

    testWidgets('horizontal court fits an 800x300 landscape slot', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(height: 220, child: _view(_Spy())),
        size: const Size(800, 300),
      );

      expect(tester.takeException(), isNull);
      final court = tester.getRect(find.byKey(courtSurfaceKey));
      expect(court.height, lessThanOrEqualTo(220));
      expect(court.size, const Size(768, 220));
    });
  });

  group('the court fills its slot, no blank margin', () {
    testWidgets('horizontal on a landscape phone (844x390)', (tester) async {
      await _pump(tester, _view(_Spy()), size: const Size(844, 390));

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(courtSurfaceKey)),
        const Rect.fromLTWH(16, 16, 812, 358),
      );
    });

    testWidgets('vertical on a portrait phone (360x640)', (tester) async {
      await _pump(tester, _view(_Spy(), axis: Axis.vertical));

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(courtSurfaceKey)),
        const Rect.fromLTWH(16, 16, 328, 608),
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
        const Size(768, 568),
      );
    });
  });
}
