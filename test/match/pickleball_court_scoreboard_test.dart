import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
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

// Team 1 serves. Player 0 stands in the right cell: team 1 = "Lan Anh"
// (right) and "Minh" (left); team 2 = "Bảo" (right) and "Hà" (left).
const _team1 = ['Lan Anh', 'Minh'];
const _team2 = ['Bảo', 'Hà'];

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData.light().copyWith(splashFactory: NoSplash.splashFactory),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

class _Spy {
  final calls = <String>[];
}

Widget _board(
  _Spy spy, {
  Axis axis = Axis.horizontal,
  bool interactive = true,
  bool isDoubles = true,
  bool finishSetEnabled = true,
  int score1 = 0,
  int score2 = 0,
  bool flipped = false,
  DateTime? startedAt,
  int? setNumber = 1,
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
    isDoubles: isDoubles,
    startedAt: startedAt,
    setNumber: setNumber,
    finishSetEnabled: finishSetEnabled,
    onScoreChange: interactive
        ? (team, increment) => spy.calls.add('score:$team:$increment')
        : null,
    onSetServingTeam: interactive
        ? (team) => spy.calls.add('serving:$team')
        : null,
    onDrop: interactive
        ? (action) => spy.calls.add(switch (action) {
            SwapPlaces(:final team) => 'swap:$team',
            SwitchEnds() => 'switchEndsDrop',
            SetServerNumber(:final number) => 'serverNumber:$number',
            SetServer(:final team, :final playerIndex) =>
              'server:$team:$playerIndex',
          })
        : null,
    onSwitchEnds: interactive ? () => spy.calls.add('switchEnds') : null,
    onUndo: interactive ? () => spy.calls.add('undo') : null,
    onRestoreAutomatic: interactive ? () => spy.calls.add('restore') : null,
    onToggleAutoSwitch: interactive ? () => spy.calls.add('auto') : null,
    onFinishSet: interactive ? () => spy.calls.add('finishSet') : null,
    onPickWinner: interactive ? () => spy.calls.add('pickWinner') : null,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget view, {
  Size size = const Size(844, 390),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(view));
  await tester.pumpAndSettle();
}

Offset _at(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text));

Color _fill(WidgetTester tester, String tooltip) {
  final material = find.descendant(
    of: find.byTooltip(tooltip),
    matching: find.byType(Material),
  );
  return tester.widget<Material>(material.first).color!.withValues(alpha: 1);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-COURT-02 scoreboard layout (horizontal)', () {
    testWidgets('call and both scores sit in the middle column', (
      tester,
    ) async {
      await _pump(tester, _board(_Spy(), score1: 7, score2: 3));

      final court = tester.getRect(find.byKey(courtSurfaceKey));
      final third = court.width / 3;
      final middle = Rect.fromLTRB(
        court.left + third,
        court.top,
        court.right - third,
        court.bottom,
      );
      expect(middle.contains(_at(tester, '7')), isTrue);
      expect(middle.contains(_at(tester, '3')), isTrue);
      expect(middle.contains(_at(tester, '0-0-1')), isTrue);
      // Team 1 plays on the left, so its score is the left one.
      expect(_at(tester, '7').dx, lessThan(_at(tester, '3').dx));
      // Each score is drawn once.
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('players stand in the side columns, left team on the left', (
      tester,
    ) async {
      await _pump(tester, _board(_Spy()));

      final court = tester.getRect(find.byKey(courtSurfaceKey));
      final third = court.width / 3;
      expect(_at(tester, 'Minh').dx, lessThan(court.left + third));
      expect(_at(tester, 'L. Anh').dx, lessThan(court.left + third));
      expect(_at(tester, 'Bảo').dx, greaterThan(court.right - third));
      expect(_at(tester, 'Hà').dx, greaterThan(court.right - third));
      // Cells face the net: the left half has its right-hand cell at the bottom.
      expect(_at(tester, 'Minh').dy, lessThan(_at(tester, 'L. Anh').dy));
      expect(_at(tester, 'Bảo').dy, lessThan(_at(tester, 'Hà').dy));
    });

    testWidgets('each player cell fills its whole side column', (tester) async {
      await _pump(tester, _board(_Spy()));

      final court = tester.getRect(find.byKey(courtSurfaceKey));
      for (final name in ['Minh', 'L. Anh', 'Bảo', 'Hà']) {
        final cell = tester.getRect(
          find
              .ancestor(of: find.text(name), matching: find.byType(ColoredBox))
              .first,
        );
        // The side column is 35% of the court; the fill must not shrink to the
        // name label.
        expect(
          cell.width,
          greaterThan(court.width * 0.3),
          reason: '$name cell is only ${cell.width}px wide',
        );
      }
    });

    testWidgets('switching ends moves the scores with the teams', (
      tester,
    ) async {
      await _pump(tester, _board(_Spy(), score1: 7, score2: 3, flipped: true));

      expect(_at(tester, '3').dx, lessThan(_at(tester, '7').dx));
    });

    testWidgets('shows the set number; the sport is an icon in the corner', (
      tester,
    ) async {
      await _pump(tester, _board(_Spy(), setNumber: 2));

      expect(find.text('pickleball'), findsNothing);
      expect(find.text('Set 2'), findsOneWidget);
      final icon = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/icons/pickleball.png',
      );
      expect(icon, findsOneWidget);
      expect(tester.getTopLeft(icon).dx, lessThan(40));
      expect(tester.getTopLeft(icon).dy, lessThan(56));
    });

    testWidgets(
      'the serving cell carries the SERVE tag with the server number',
      (tester) async {
        await _pump(tester, _board(_Spy()));

        expect(find.text('SERVE 1'), findsOneWidget);
      },
    );

    testWidgets('the clock is hidden without a start time and shown with one', (
      tester,
    ) async {
      await _pump(tester, _board(_Spy()));
      expect(find.byIcon(Icons.timer_outlined), findsNothing);

      await _pump(
        tester,
        _board(
          _Spy(),
          startedAt: DateTime.now().subtract(const Duration(seconds: 3)),
        ),
      );
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d\d:\d\d')), findsOneWidget);
    });
  });

  group('TC-COURT-03 bottom bar', () {
    testWidgets('plus and minus call their actions', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy, score1: 2, score2: 1));

      await tester.tap(find.byTooltip('Add point for team 1'));
      await tester.tap(find.byTooltip('Remove point for team 1'));
      await tester.tap(find.byTooltip('Remove point for team 2'));

      expect(spy.calls, [
        'score:1:true',
        'score:1:false',
        'score:2:false',
      ]);
    });

    testWidgets('the receiver plus is locked in side-out', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      await tester.tap(
        find.byTooltip('Add point for team 2'),
        warnIfMissed: false,
      );

      expect(spy.calls, isEmpty);
    });

    testWidgets('there is no change-serve button: the receiver plus does it', (
      tester,
    ) async {
      await _pump(tester, _board(_Spy()));

      expect(find.text('CHANGE SERVE'), findsNothing);
      expect(find.text('LOSE SERVE'), findsNothing);
    });

    testWidgets('team 1 buttons are orange, team 2 blue, also after the swap', (
      tester,
    ) async {
      for (final flipped in [false, true]) {
        await _pump(tester, _board(_Spy(), score1: 1, flipped: flipped));

        expect(_fill(tester, 'Add point for team 1'), courtTeam1.accent);
        expect(_fill(tester, 'Add point for team 2'), courtTeam2.accent);
      }
    });

    testWidgets('left team buttons are on the left of the bar', (tester) async {
      await _pump(tester, _board(_Spy(), score1: 1));
      final left = tester.getCenter(find.byTooltip('Add point for team 1')).dx;
      final right = tester.getCenter(find.byTooltip('Add point for team 2')).dx;
      expect(left, lessThan(right));

      await _pump(tester, _board(_Spy(), score1: 1, flipped: true));
      final left2 = tester.getCenter(find.byTooltip('Add point for team 1')).dx;
      final right2 = tester
          .getCenter(find.byTooltip('Add point for team 2'))
          .dx;
      expect(left2, greaterThan(right2));
    });
  });

  group('TC-COURT-04 END opens the finish dialog', () {
    testWidgets('lists finish set and pick winner, each runs its action', (
      tester,
    ) async {
      final spy = _Spy();
      await _pump(tester, _board(spy, score1: 11));

      await tester.tap(find.text('END'));
      await tester.pumpAndSettle();
      expect(find.text('Finish set'), findsOneWidget);
      expect(find.text('Pick the winner'), findsOneWidget);

      await tester.tap(find.text('Finish set'));
      await tester.pumpAndSettle();
      expect(spy.calls, ['finishSet']);
      expect(find.text('Pick the winner'), findsNothing);

      await tester.tap(find.text('END'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick the winner'));
      await tester.pumpAndSettle();
      expect(spy.calls, ['finishSet', 'pickWinner']);
    });

    testWidgets('finish set is locked when the set cannot be finished', (
      tester,
    ) async {
      final spy = _Spy();
      await _pump(tester, _board(spy, finishSetEnabled: false));

      await tester.tap(find.text('END'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish set'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(spy.calls, isEmpty);
      // Picking a winner stays available.
      expect(find.text('Pick the winner'), findsOneWidget);
    });

    testWidgets('close dismisses the dialog and does nothing', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      await tester.tap(find.text('END'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Pick the winner'), findsNothing);
      expect(spy.calls, isEmpty);
    });
  });

  group('TC-COURT-05 swap, switch ends and menu', () {
    testWidgets('each half has its own swap button', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      final swaps = find.byTooltip('Swap left and right');
      expect(swaps, findsNWidgets(2));
      // Left button belongs to the left team (team 1), right to team 2.
      final sorted = swaps.evaluate().toList()
        ..sort(
          (a, b) => tester
              .getCenter(find.byWidget(a.widget))
              .dx
              .compareTo(tester.getCenter(find.byWidget(b.widget)).dx),
        );
      await tester.tap(find.byWidget(sorted.first.widget));
      await tester.tap(find.byWidget(sorted.last.widget));

      expect(spy.calls, ['swap:1', 'swap:2']);
    });

    testWidgets('singles have no swap button', (tester) async {
      await _pump(tester, _board(_Spy(), isDoubles: false));

      expect(find.byTooltip('Swap left and right'), findsNothing);
    });

    testWidgets('the centre button switches ends', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      await tester.tap(find.byTooltip('Switch ends'));

      expect(spy.calls, ['switchEnds']);
    });

    testWidgets('the ⋯ menu lists the court actions', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Restore automatic'), findsOneWidget);
      expect(find.text('Auto switch ends'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(spy.calls, ['undo']);
    });
  });

  group('TC-COURT-06 read-only', () {
    testWidgets('no controls, the call and the scores stay', (tester) async {
      await _pump(tester, _board(_Spy(), interactive: false, score1: 4));

      for (final tip in [
        'More actions',
        'Swap left and right',
        'Switch ends',
        'Add point for team 1',
        'Remove point for team 2',
      ]) {
        expect(find.byTooltip(tip), findsNothing, reason: tip);
      }
      expect(find.text('END'), findsNothing);
      expect(find.text('CHANGE SERVE'), findsNothing);
      expect(find.text('0-0-1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('TC-COURT-07 drag, long press and tap on a player', () {
    testWidgets('a chip dragged onto the other half calls drop', (
      tester,
    ) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      final gesture = await tester.startGesture(_at(tester, 'Minh'));
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.moveBy(const Offset(4, 4));
      await tester.pump();
      await gesture.moveTo(_at(tester, 'Bảo'));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(spy.calls, ['switchEndsDrop']);
    });

    testWidgets('the whole cell drags, not only the name', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      // A spot well left of the name, still inside the same cell.
      final start = _at(tester, 'Minh') - const Offset(110, 0);
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.moveBy(const Offset(4, 4));
      await tester.pump();
      await gesture.moveTo(_at(tester, 'Bảo'));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(spy.calls, ['switchEndsDrop']);
    });

    testWidgets('tapping a player offers swap and give-serve', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      await tester.tap(find.text('Bảo'));
      await tester.pumpAndSettle();
      expect(find.text('Swap left and right'), findsWidgets);
      expect(find.text('Give serve here'), findsOneWidget);

      await tester.tap(find.text('Give serve here'));
      await tester.pumpAndSettle();

      expect(spy.calls, ['serving:2', 'server:2:0']);
    });

    testWidgets('TC-SERVE-APP-03 tapping the server offers the other serve '
        'number', (tester) async {
      final spy = _Spy();
      await _pump(tester, _board(spy));

      // Team 1 serves as server 1: Lan Anh ("L. Anh") is the server.
      await tester.tap(find.text('L. Anh'));
      await tester.pumpAndSettle();
      expect(find.text('Make server 2'), findsOneWidget);
      expect(find.text('Make server 1'), findsNothing);

      await tester.tap(find.text('Make server 2'));
      await tester.pumpAndSettle();

      expect(spy.calls, ['serverNumber:2']);
    });

    testWidgets('TC-SERVE-APP-04 only the server offers a serve number', (
      tester,
    ) async {
      await _pump(tester, _board(_Spy()));

      await tester.tap(find.text('Minh'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Make server'), findsNothing);
    });

    testWidgets('a viewer tapping a player gets nothing', (tester) async {
      await _pump(tester, _board(_Spy(), interactive: false));

      await tester.tap(find.text('Bảo'));
      await tester.pumpAndSettle();

      expect(find.text('Give serve here'), findsNothing);
    });
  });

  group('TC-COURT-08 fits the screen', () {
    for (final size in [
      const Size(844, 390),
      const Size(640, 300),
      const Size(568, 280),
    ]) {
      testWidgets('no layout error at ${size.width}x${size.height}', (
        tester,
      ) async {
        await _pump(
          tester,
          _board(
            _Spy(),
            score1: 11,
            score2: 9,
            startedAt: DateTime.now().subtract(const Duration(minutes: 70)),
          ),
          size: size,
        );

        expect(tester.takeException(), isNull);
        // Every control keeps a >= 40dp hit area.
        for (final tip in [
          'Add point for team 1',
          'Remove point for team 2',
          'More actions',
        ]) {
          final finder = find.byTooltip(tip);
          final painted =
              tester.getBottomRight(finder) - tester.getTopLeft(finder);
          expect(painted.dx, greaterThanOrEqualTo(40), reason: '$tip width');
          expect(painted.dy, greaterThanOrEqualTo(40), reason: '$tip height');
        }
      });
    }
  });

  group('TC-COURT-09 the same scoreboard on an upright phone', () {
    const phone = Size(360, 640);
    Future<void> pumpUpright(
      WidgetTester tester,
      _Spy spy, {
      int score1 = 0,
      int score2 = 0,
      DateTime? startedAt,
      Size size = phone,
    }) => _pump(
      tester,
      _board(
        spy,
        axis: Axis.vertical,
        score1: score1,
        score2: score2,
        startedAt: startedAt,
      ),
      size: size,
    );

    testWidgets('fills the screen edge to edge', (tester) async {
      await pumpUpright(tester, _Spy());

      expect(tester.takeException(), isNull);
      final court = tester.getRect(find.byKey(courtSurfaceKey));
      expect(court.left, 0);
      expect(court.right, phone.width);
      // The finish dialog opens from the same red END row.
      expect(find.text('END'), findsOneWidget);
    });

    testWidgets('team 1 on top, team 2 below, scores in the band between', (
      tester,
    ) async {
      await pumpUpright(tester, _Spy(), score1: 7, score2: 3);

      expect(_at(tester, 'Minh').dy, lessThan(_at(tester, 'Bảo').dy));
      expect(_at(tester, '7').dy, greaterThan(_at(tester, 'Minh').dy));
      expect(_at(tester, '3').dy, lessThan(_at(tester, 'Bảo').dy));
      // Team 1's score is the left one, like the left team on the sideways board.
      expect(_at(tester, '7').dx, lessThan(_at(tester, '3').dx));
      expect(_at(tester, '0-0-1').dy, greaterThan(_at(tester, 'Minh').dy));
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('cells face the net: top half right cell on the screen left', (
      tester,
    ) async {
      await pumpUpright(tester, _Spy());

      // Top half faces down: its right cell ("L. Anh") is on the screen left.
      expect(_at(tester, 'L. Anh').dx, lessThan(_at(tester, 'Minh').dx));
      // Bottom half faces up: its right cell ("Bảo") is on the screen right.
      expect(_at(tester, 'Bảo').dx, greaterThan(_at(tester, 'Hà').dx));
    });

    testWidgets('each team keeps its colour, also after switching ends', (
      tester,
    ) async {
      await pumpUpright(tester, _Spy());
      expect(_fill(tester, 'Add point for team 1'), courtTeam1.accent);
      expect(_fill(tester, 'Add point for team 2'), courtTeam2.accent);

      await _pump(
        tester,
        _board(_Spy(), axis: Axis.vertical, flipped: true),
        size: phone,
      );
      final one = tester.getTopLeft(find.byTooltip('Add point for team 1'));
      final two = tester.getTopLeft(find.byTooltip('Add point for team 2'));
      expect(_fill(tester, 'Add point for team 1'), courtTeam1.accent);
      // Team 1 now plays below, so team 2's buttons come first in the bar.
      expect(one.dx, greaterThan(two.dx));
    });

    testWidgets('bar and END dialog call their actions', (tester) async {
      final spy = _Spy();
      await pumpUpright(tester, spy, score1: 11);

      await tester.tap(find.byTooltip('Add point for team 1'));
      await tester.tap(find.byTooltip('Remove point for team 1'));
      await tester.tap(find.text('END'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish set'));
      await tester.pumpAndSettle();

      expect(spy.calls, [
        'score:1:true',
        'score:1:false',
        'finishSet',
      ]);
    });

    testWidgets(
      'the +/- buttons are spread to both edges',
      (tester) async {
        await _pump(
          tester,
          _board(_Spy(), axis: Axis.vertical),
          size: phone,
        );

        final left = tester.getTopLeft(find.byTooltip('Add point for team 1'));
        final right = tester.getTopRight(
          find.byTooltip('Add point for team 2'),
        );
        expect(left.dx, lessThan(16), reason: 'left edge');
        expect(phone.width - right.dx, lessThan(16), reason: 'right edge');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the clock sits at the top right, not in the bar', (
      tester,
    ) async {
      await pumpUpright(
        tester,
        _Spy(),
        startedAt: DateTime.now().subtract(const Duration(minutes: 70)),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('1:10'), findsOneWidget);
      final court = tester.getRect(find.byKey(courtSurfaceKey));
      final clock = tester.getCenter(find.textContaining('1:10'));
      expect(clock.dy, lessThan(court.top));
      expect(clock.dx, greaterThan(phone.width / 2));
    });

    testWidgets('the whole cell drags to the other half', (tester) async {
      final spy = _Spy();
      await pumpUpright(tester, spy);

      // A spot below the name, still inside the same cell.
      final start = _at(tester, 'Minh') + const Offset(0, 30);
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.moveBy(const Offset(4, 4));
      await tester.pump();
      await gesture.moveTo(_at(tester, 'Bảo'));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(spy.calls, ['switchEndsDrop']);
    });

    for (final size in [
      const Size(360, 640),
      const Size(390, 800),
      const Size(320, 480),
    ]) {
      testWidgets('no layout error at ${size.width}x${size.height}', (
        tester,
      ) async {
        await pumpUpright(
          tester,
          _Spy(),
          score1: 11,
          score2: 9,
          startedAt: DateTime.now().subtract(const Duration(minutes: 70)),
          size: size,
        );

        expect(tester.takeException(), isNull);
        for (final tip in [
          'Add point for team 1',
          'Remove point for team 2',
          'Undo',
          'More actions',
        ]) {
          final finder = find.byTooltip(tip);
          final painted =
              tester.getBottomRight(finder) - tester.getTopLeft(finder);
          expect(painted.dy, greaterThanOrEqualTo(40), reason: '$tip height');
          expect(painted.dx, greaterThanOrEqualTo(40), reason: '$tip width');
        }
      });
    }
  });

  group('TC-COURT-11 undo button sits at the top centre of the court', () {
    for (final upright in [false, true]) {
      testWidgets(upright ? 'upright' : 'sideways', (tester) async {
        final spy = _Spy();
        final size = upright ? const Size(360, 640) : const Size(844, 390);
        await _pump(
          tester,
          _board(
            spy,
            axis: upright ? Axis.vertical : Axis.horizontal,
            score1: 3,
            score2: 2,
          ),
          size: size,
        );

        final undo = tester.getCenter(find.byTooltip('Undo'));
        final minus1 = tester.getCenter(
          find.byTooltip('Remove point for team 1'),
        );
        // Over the court, next to END and the menu, never in the bottom bar.
        expect(undo.dy, lessThan(70));
        expect(undo.dy, lessThan(minus1.dy));
        expect((undo.dx - size.width / 2).abs(), lessThan(size.width / 4));
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Undo'));
        expect(spy.calls, ['undo']);
      });
    }

    testWidgets('a viewer without edit rights has no undo button', (
      tester,
    ) async {
      await _pump(tester, _board(_Spy(), interactive: false));

      expect(find.byTooltip('Undo'), findsNothing);
    });
  });
}
