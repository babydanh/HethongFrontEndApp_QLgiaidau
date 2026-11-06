import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_accordion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TC-BRACKET-FULLBLEED-01/02: the Bảng đấu tab opens its content edge to edge,
// while the division row itself keeps the 16px side inset.
const _contentKey = ValueKey('accordion-content');

Future<void> _pump(WidgetTester tester, {required bool fullBleed}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      home: Scaffold(
        body: DivisionAccordion(
          divisions: const [
            TournamentDivision(
              id: 'd1',
              name: 'Đơn Nam',
              matchType: 'SINGLES',
              participantCount: 8,
            ),
          ],
          selectedDivisionId: 'd1',
          expanded: true,
          fullBleedContent: fullBleed,
          onTapDivision: (_) {},
          contentBuilder: (_) => const SizedBox(key: _contentKey, height: 40),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('TC-BRACKET-FULLBLEED-01 content spans the full screen width', (
    tester,
  ) async {
    await _pump(tester, fullBleed: true);

    expect(tester.getSize(find.byKey(_contentKey)).width, 390);
    expect(tester.getTopLeft(find.byKey(_contentKey)).dx, 0);
    // The row label stays inside the 16px inset.
    expect(tester.getTopLeft(find.text('Đơn Nam')).dx, greaterThan(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-BRACKET-FULLBLEED-02 default keeps the 16px side inset', (
    tester,
  ) async {
    await _pump(tester, fullBleed: false);

    expect(tester.getSize(find.byKey(_contentKey)).width, 358);
    expect(tester.getTopLeft(find.byKey(_contentKey)).dx, 16);
    expect(tester.takeException(), isNull);
  });
}
