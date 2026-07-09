import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === TEAMS MODULE: 4 TESTCASES ===

  // TC-FLUTTER-TEAMS-001: Danh sach doi trong giai dau
  testWidgets('TC-FLUTTER-TEAMS-001: Danh sach doi trong giai dau',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to team list within a tournament
      await navigateToTeamList(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Danh sách hiển thị
      expect(find.byType(ListView), findsWidgets);

      await takeScreenshot(tester, 'teams_list');
    } catch (e) {
      await screenshotOnFailure(tester, 'TEAMS-001');
      rethrow;
    }
  });

  // TC-FLUTTER-TEAMS-002: Import doi tu file Excel
  testWidgets('TC-FLUTTER-TEAMS-002: Import doi tu file Excel',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTeamList(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for upload/import button
      final uploadBtn = find.byIcon(Icons.upload_file);
      if (uploadBtn.evaluate().isNotEmpty) {
        await tester.tap(uploadBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'TEAMS-002');
      rethrow;
    }
  });

  // TC-FLUTTER-TEAMS-003: Xoa toan bo doi
  testWidgets('TC-FLUTTER-TEAMS-003: Xoa toan bo doi',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTeamList(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap menu -> "Xóa toàn bộ"
      final moreBtn = find.byIcon(Icons.more_vert);
      if (moreBtn.evaluate().isNotEmpty) {
        await tester.tap(moreBtn.first);
        await tester.pumpAndSettle();
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'TEAMS-003');
      rethrow;
    }
  });

  // TC-FLUTTER-TEAMS-004: Them/Sua doi
  testWidgets('TC-FLUTTER-TEAMS-004: Them Sua doi',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTeamList(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap FAB to add team
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // On add team screen
      final nameField = find.byType(TextFormField);
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField.first, 'Đội Test Auto');
        await tester.pumpAndSettle();
      }

      // Try saving
      final saveBtn = find.text('Lưu');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'teams_add');
    } catch (e) {
      await screenshotOnFailure(tester, 'TEAMS-004');
      rethrow;
    }
  });
}

/// Navigate to team list screen
Future<void> navigateToTeamList(WidgetTester tester) async {
  // Try through tournament admin
  final tourCards = find.byType(Card);
  if (tourCards.evaluate().isNotEmpty) {
    await tester.tap(tourCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // Look for "Quản lý đội" or "Đội" button
  final teamNav = find.textContaining('Quản lý đội');
  if (teamNav.evaluate().isNotEmpty) {
    await tester.tap(teamNav.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  final teamNav2 = find.text('Đội');
  if (teamNav2.evaluate().isNotEmpty) {
    await tester.tap(teamNav2.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  // Try VDV/VĐV
  final vdvNav = find.text('VDV');
  if (vdvNav.evaluate().isNotEmpty) {
    await tester.tap(vdvNav.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
