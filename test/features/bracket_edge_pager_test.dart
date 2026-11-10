import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_edge_pager.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_slot_row.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_double_elim_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// 8 teams, 3 rounds: the window shows rounds 1-2 until the page is turned.
MatchModel _match(
  String id,
  int round,
  int position, {
  String? t1,
  String? t2,
  String next = '',
}) => MatchModel.fromJson({
  'tournamentId': 't-1',
  'round': round,
  'matchNumber': position + 1,
  'status': 'SCHEDULED',
  'team1Id': t1 == null ? '' : 'id-$t1',
  'team2Id': t2 == null ? '' : 'id-$t2',
  'team1Name': t1 ?? '',
  'team2Name': t2 ?? '',
  'nextMatchId': next,
  'bracketPosition': {
    'bracket': 'winners',
    'round': round,
    'position': position,
  },
}, id);

List<MatchModel> _threeRounds() => [
  _match('m1', 1, 0, t1: 'Alpha', t2: 'Bravo', next: 's1'),
  _match('m2', 1, 1, t1: 'Charlie', t2: 'Delta', next: 's1'),
  _match('m3', 1, 2, t1: 'Echo', t2: 'Foxtrot', next: 's2'),
  _match('m4', 1, 3, t1: 'Golf', t2: 'Hotel', next: 's2'),
  _match('s1', 2, 0, next: 'f'),
  _match('s2', 2, 1, next: 'f'),
  _match('f', 3, 0),
];

Finder _slot(String matchId, int side) =>
    find.byKey(ValueKey('bracket-slot-$matchId-participant$side'));

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

  group('BracketEdgePager inside PlayoffDoubleElimView', () {
    late List<(BracketSlotDragData, BracketSlotDragData)> drops;

    Future<void> pumpView(WidgetTester tester, {required double width}) async {
      drops = [];
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PlayoffDoubleElimView(
                  matches: _threeRounds(),
                  tournamentId: 't-1',
                  onSlotDrop: (s, t) async => drops.add((s, t)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Offset rightEdge(WidgetTester tester) {
      final pager = tester.getRect(find.byType(BracketEdgePager));
      // Level with a round-2 slot, so a slot lies under the edge zone.
      return Offset(pager.right - 10, tester.getCenter(_slot('s1', 1)).dy);
    }

    Future<TestGesture> lift(WidgetTester tester, Finder slot) async {
      final gesture = await tester.startGesture(tester.getCenter(slot));
      await tester.pump(kLongPressTimeout);
      return gesture;
    }

    testWidgets('TC-BRK-EDGE-08 holding at the edge turns the round window '
        'so a team can be dropped into the next round', (tester) async {
      await pumpView(tester, width: 800);
      expect(_slot('f', 1), findsNothing, reason: 'final is off the window');

      final gesture = await lift(tester, _slot('m1', 1));
      await gesture.moveTo(rightEdge(tester));
      await tester.pump(bracketEdgeHold + const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_slot('f', 1), findsOneWidget, reason: 'window turned to 2-3');

      await gesture.moveTo(tester.getCenter(_slot('f', 1)));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(drops, hasLength(1));
      final (source, target) = drops.single;
      expect(source.matchId, 'm1');
      expect(source.participantId, 'id-Alpha');
      expect(target.matchId, 'f');
    });

    testWidgets('TC-BRK-EDGE-09 dropping on the edge changes nothing', (
      tester,
    ) async {
      await pumpView(tester, width: 380);
      final edge = rightEdge(tester);
      final covered = find.byType(BracketSlotRow).evaluate().where((e) {
        final box = e.renderObject! as RenderBox;
        return (box.localToGlobal(Offset.zero) & box.size).contains(edge);
      });
      expect(covered, isNotEmpty, reason: 'a slot sits under the edge zone');

      final gesture = await lift(tester, _slot('m1', 1));
      await gesture.moveTo(edge);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(drops, isEmpty);
    });
  });
}
