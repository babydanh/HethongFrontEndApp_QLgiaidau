import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ScheduleRange?> _dragRange(
  WidgetTester tester, {
  required String fromCourt,
  required int fromSlot,
  required String toCourt,
  required int toSlot,
}) async {
  ScheduleRange? captured;
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
            onRangeSelected: (range) => captured = range,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final start = tester.getCenter(
    find.byKey(ValueKey('schedule-slot-$fromCourt-$fromSlot')),
  );
  final end = tester.getCenter(
    find.byKey(ValueKey('schedule-slot-$toCourt-$toSlot')),
  );

  final gesture = await tester.startGesture(start);
  // Giữ đủ lâu để cử chỉ chọn vùng bắt đầu.
  await tester.pump(const Duration(milliseconds: 700));
  await gesture.moveTo(end);
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('long-press drag reports the selected grid of cells', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final range = await _dragRange(
      tester,
      fromCourt: 'Sân 1',
      fromSlot: 1,
      toCourt: 'Sân 2',
      toSlot: 3,
    );

    expect(range, isNotNull);
    expect(range!.firstCourt, 0);
    expect(range.lastCourt, 1);
    expect(range.firstSlot, 1);
    expect(range.lastSlot, 3);
  });

  testWidgets('dragging backwards reports the same rectangle, normalized', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final range = await _dragRange(
      tester,
      fromCourt: 'Sân 2',
      fromSlot: 3,
      toCourt: 'Sân 1',
      toSlot: 1,
    );

    expect(range, isNotNull);
    expect(range!.firstCourt, 0);
    expect(range.lastCourt, 1);
    expect(range.firstSlot, 1);
    expect(range.lastSlot, 3);
  });
}
