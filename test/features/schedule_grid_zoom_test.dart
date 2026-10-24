import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kéo tay nắm đổi thang giờ rồi trả về chiều cao ô ghi nhận được.
Future<double?> _dragScaleHandle(WidgetTester tester, double dy) async {
  double? captured;
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
            endHour: 10,
            onTapMatch: (_) {},
            onSlotHeightChanged: (height) => captured = height,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final handle = find.byKey(const ValueKey('schedule-scale-handle'));
  expect(handle, findsOneWidget);

  final gesture = await tester.startGesture(tester.getCenter(handle));
  await gesture.moveBy(Offset(0, dy));
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('dragging the grip down grows the hour rows', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final captured = await _dragScaleHandle(tester, 40);

    expect(captured, isNotNull);
    expect(captured!, greaterThan(112));
  });

  testWidgets('dragging the grip up shrinks the hour rows', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final captured = await _dragScaleHandle(tester, -40);

    expect(captured, isNotNull);
    expect(captured!, lessThan(112));
  });
}
