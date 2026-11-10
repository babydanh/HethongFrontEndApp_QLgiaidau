import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_edge_pager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _data = BracketSlotDragData(
  matchId: 'm1',
  slot: 'participant1',
  participantId: 'p1',
  isBye: false,
  isLocked: false,
  label: 'Alpha',
);

// A 300x200 pager on top, a draggable chip below it.
Widget _app({
  bool enabled = true,
  VoidCallback? onPrev,
  VoidCallback? onNext,
  bool reduceMotion = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: 300,
          height: 200,
          child: BracketEdgePager(
            enabled: enabled,
            onPrev: onPrev,
            onNext: onNext,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
        const Positioned(
          left: 100,
          top: 300,
          child: Draggable<BracketSlotDragData>(
            data: _data,
            feedback: SizedBox(width: 40, height: 40),
            // Must paint: Draggable defers hit tests to its child, an empty box is missed.
            child: ColoredBox(
              key: Key('chip'),
              color: Colors.red,
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ],
    ),
  ),
);

Future<TestGesture> _lift(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const Key('chip'))),
  );
  await tester.pump(const Duration(milliseconds: 50));
  return gesture;
}

const _rightEdge = Offset(285, 100);
const _leftEdge = Offset(15, 100);
const _middle = Offset(150, 100);

void main() {
  testWidgets(
    'TC-BRK-EDGE-01 holding on the right edge turns to the next page',
    (tester) async {
      var next = 0;
      var prev = 0;
      await tester.pumpWidget(_app(onNext: () => next++, onPrev: () => prev++));

      final gesture = await _lift(tester);
      await gesture.moveTo(_rightEdge);
      await tester.pump(const Duration(milliseconds: 100));
      expect(next, 0, reason: 'not yet: under the hold time');
      await tester.pump(const Duration(milliseconds: 400));
      expect(next, 1);
      expect(prev, 0);
      await gesture.up();
    },
  );

  testWidgets('TC-BRK-EDGE-02 holding on the left edge turns back', (
    tester,
  ) async {
    var next = 0;
    var prev = 0;
    await tester.pumpWidget(_app(onNext: () => next++, onPrev: () => prev++));

    final gesture = await _lift(tester);
    await gesture.moveTo(_leftEdge);
    await tester.pump(const Duration(milliseconds: 500));

    expect(prev, 1);
    expect(next, 0);
    await gesture.up();
  });

  testWidgets('TC-BRK-EDGE-03 leaving the edge early cancels the turn', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(_app(onNext: () => next++));

    final gesture = await _lift(tester);
    await gesture.moveTo(_rightEdge);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(_middle);
    await tester.pump(const Duration(seconds: 1));

    expect(next, 0);
    await gesture.up();
  });

  testWidgets('TC-BRK-EDGE-04 no page that way: nothing is called', (
    tester,
  ) async {
    var prev = 0;
    await tester.pumpWidget(_app(onPrev: () => prev++)); // onNext is null

    final gesture = await _lift(tester);
    await gesture.moveTo(_rightEdge);
    await tester.pump(const Duration(seconds: 1));

    expect(prev, 0);
    await gesture.up();
  });

  testWidgets('TC-BRK-EDGE-05 keeps turning while held, stops after the drop', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(_app(onNext: () => next++));

    final gesture = await _lift(tester);
    await gesture.moveTo(_rightEdge);
    await tester.pump(const Duration(milliseconds: 950));
    expect(next, 2);
    await gesture.up();
    await tester.pump(const Duration(seconds: 2));

    expect(next, 2, reason: 'dropping on the edge stops the timer');
  });

  testWidgets('TC-BRK-EDGE-06 disabled: no edge zones are built', (
    tester,
  ) async {
    await tester.pumpWidget(_app(enabled: false, onNext: () {}));

    expect(find.byKey(const ValueKey('bracket-edge-next')), findsNothing);
    expect(find.byKey(const ValueKey('bracket-edge-prev')), findsNothing);
  });

  testWidgets('TC-BRK-EDGE-07 reduced motion still turns pages, no fade', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(_app(onNext: () => next++, reduceMotion: true));

    final gesture = await _lift(tester);
    await gesture.moveTo(_rightEdge);
    await tester.pump(const Duration(milliseconds: 500));

    expect(next, 1);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byKey(const ValueKey('bracket-edge-next')),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .duration,
      Duration.zero,
    );
    await gesture.up();
  });
}
