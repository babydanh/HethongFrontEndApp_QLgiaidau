import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_slot_row.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

BracketSlotDragData _data(String id) => BracketSlotDragData(
  matchId: 'm1',
  slot: 'participant1',
  participantId: id,
  isBye: false,
  isLocked: false,
  label: id,
);

Widget _row(String id, {bool reduceMotion = false}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 200,
        child: BracketSlotRow(
          data: _data(id),
          selected: false,
          onTap: (_) {},
          onDrop: (_, _) async {},
          child: Padding(padding: const EdgeInsets.all(12), child: Text(id)),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('TC-BRK-MOT-01 a new name fades in while the old one fades out', (
    tester,
  ) async {
    await tester.pumpWidget(_row('Alpha'));
    await tester.pumpWidget(_row('Bravo'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Alpha'), findsOneWidget, reason: 'still leaving');
    expect(find.text('Bravo'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Bravo'), findsOneWidget);
  });

  testWidgets('TC-BRK-MOT-02 reduced motion swaps the name at once', (
    tester,
  ) async {
    await tester.pumpWidget(_row('Alpha', reduceMotion: true));
    await tester.pumpWidget(_row('Bravo', reduceMotion: true));
    await tester.pump();

    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Bravo'), findsOneWidget);
  });

  testWidgets(
    'TC-BRK-MOT-03 lifting a participant gives exactly one haptic tick',
    (tester) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate')
            haptics.add(call.arguments);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(_row('Alpha'));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Alpha')),
      );
      await tester.pump(kLongPressTimeout);
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();

      expect(haptics, ['HapticFeedbackType.selectionClick']);
      await gesture.up();
      await tester.pumpAndSettle();
    },
  );
}
