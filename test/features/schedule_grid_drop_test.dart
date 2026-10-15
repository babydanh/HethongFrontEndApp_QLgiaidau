import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Drop = ({String matchId, String court, DateTime at});

Future<_Drop?> _dragToSlot(
  WidgetTester tester, {
  required int slotIndex,
  required String court,
}) async {
  _Drop? captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              LongPressDraggable<String>(
                key: const ValueKey('tray-item'),
                data: 'm-new',
                feedback: const Material(child: Text('Đội X')),
                child: const SizedBox(
                  width: 200,
                  height: 40,
                  child: ColoredBox(color: Colors.amber),
                ),
              ),
              ScheduleGrid(
                courts: [court],
                matches: const [],
                startHour: 7,
                endHour: 9,
                day: DateTime(2026, 10, 24),
                onTapMatch: (_) {},
                onDropMatch: (matchId, droppedCourt, at) =>
                    captured = (matchId: matchId, court: droppedCourt, at: at),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final target = find.byKey(ValueKey('schedule-slot-$court-$slotIndex'));
  expect(target, findsOneWidget);

  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const ValueKey('tray-item'))),
  );
  // Giữ đủ lâu để LongPressDraggable bắt đầu kéo.
  await tester.pump(const Duration(milliseconds: 700));
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('dropping a match reports its court and slot time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Ô thứ 3 = 07:00 + 45 phút.
    final captured = await _dragToSlot(tester, slotIndex: 3, court: 'Sân 1');

    expect(captured, isNotNull);
    expect(captured!.matchId, 'm-new');
    expect(captured.court, 'Sân 1');
    expect(captured.at, DateTime(2026, 10, 24, 7, 45));
  });

  testWidgets('slot 0 is the opening time of the operating window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final captured = await _dragToSlot(tester, slotIndex: 0, court: 'Sân 1');

    expect(captured, isNotNull);
    expect(captured!.at, DateTime(2026, 10, 24, 7));
  });

  testWidgets('no drop targets at all when the grid is read-only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScheduleGrid(
              courts: const ['Sân 1'],
              matches: const [],
              startHour: 7,
              endHour: 9,
              onTapMatch: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('schedule-slot-Sân 1-0')), findsNothing);
  });
}
