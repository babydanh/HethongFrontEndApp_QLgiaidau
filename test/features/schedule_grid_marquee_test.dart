import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 07:00-09:00 step 15 => 8 slots (0..7), 2 courts.
Future<List<ScheduleRange>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ranges = <ScheduleRange>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScheduleGrid(
            courts: const ['Sân 1', 'Sân 2'],
            matches: const [],
            startHour: 7,
            endHour: 9,
            day: DateTime(2026, 10, 24),
            onTapMatch: (_) {},
            onDropMatch: (_, _, _) {},
            onRangeSelected: ranges.add,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ranges;
}

void main() {
  testWidgets(
    'TC-APP-SCHED-MARQUEE-01 khung chữ nhật hiện khi kéo, mất khi nhả',
    (tester) async {
      await _pump(tester);
      final start = tester.getCenter(
        find.byKey(const ValueKey('schedule-slot-Sân 1-1')),
      );
      final end = tester.getCenter(
        find.byKey(const ValueKey('schedule-slot-Sân 2-3')),
      );
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveTo(end);
      await tester.pump(const Duration(milliseconds: 50));

      final marquee = find.byKey(const ValueKey('schedule-marquee'));
      expect(marquee, findsOneWidget);
      final rect = tester.getRect(marquee);
      expect(rect.topLeft.dx, closeTo(start.dx, 1));
      expect(rect.topLeft.dy, closeTo(start.dy, 1));
      expect(rect.bottomRight.dx, closeTo(end.dx, 1));
      expect(rect.bottomRight.dy, closeTo(end.dy, 1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(marquee, findsNothing);
    },
  );

  testWidgets('TC-APP-SCHED-HEADER-01 bấm tiêu đề sân chọn hết ô của sân đó', (
    tester,
  ) async {
    final ranges = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('schedule-court-header-Sân 2')));
    await tester.pumpAndSettle();
    expect(ranges, hasLength(1));
    expect(ranges.single, (
      firstCourt: 1,
      lastCourt: 1,
      firstSlot: 0,
      lastSlot: 7,
    ));
  });

  testWidgets(
    'TC-APP-SCHED-HEADER-02 bấm giờ chọn hết ô của giờ đó trên mọi sân',
    (tester) async {
      final ranges = await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('schedule-time-row-2')));
      await tester.pumpAndSettle();
      expect(ranges, hasLength(1));
      expect(ranges.single, (
        firstCourt: 0,
        lastCourt: 1,
        firstSlot: 2,
        lastSlot: 2,
      ));
    },
  );
}
