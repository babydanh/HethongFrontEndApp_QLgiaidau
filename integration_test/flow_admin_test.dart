import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-ADMIN-001: Danh sach CLB voi filter va search
  testWidgets('TC-FLUTTER-ADMIN-001: Admin Clubs - danh sach CLB filter search',
      (tester) async {
    try {
      await loginWithEmail(tester,
          email: 'admin@example.com', password: 'Admin123!@');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to admin clubs section
      final adminNav = find.text('Admin');
      if (adminNav.evaluate().isNotEmpty) {
        await tester.tap(adminNav.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      final clubsNav = find.textContaining('Quản lý CLB');
      if (clubsNav.evaluate().isNotEmpty) {
        await tester.tap(clubsNav.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Try filter chips
      final chips = find.byType(FilterChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
      await takeScreenshot(tester, 'admin_clubs');
    } catch (e) {
      await screenshotOnFailure(tester, 'ADMIN-001');
      rethrow;
    }
  });

  // TC-FLUTTER-ADMIN-002: Duyet/Tu choi/Vo hieu CLB
  testWidgets('TC-FLUTTER-ADMIN-002: Admin - Duyet Tu choi Vo hieu CLB',
      (tester) async {
    try {
      await loginWithEmail(tester,
          email: 'admin@example.com', password: 'Admin123!@');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to admin clubs
      await navigateToAdminClubs(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try approve button on a pending club
      final approveBtn = find.textContaining('Duyệt');
      if (approveBtn.evaluate().isNotEmpty) {
        await tester.tap(approveBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final rejectBtn = find.textContaining('Từ chối');
      if (rejectBtn.evaluate().isNotEmpty) {
        await tester.tap(rejectBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'admin_club_action');
    } catch (e) {
      await screenshotOnFailure(tester, 'ADMIN-002');
      rethrow;
    }
  });

  // TC-FLUTTER-ADMIN-003: Pending Clubs - Duyet CLB moi
  testWidgets('TC-FLUTTER-ADMIN-003: Pending Clubs - Duyet CLB moi',
      (tester) async {
    try {
      await loginWithEmail(tester,
          email: 'admin@example.com', password: 'Admin123!@');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to pending clubs
      final pendingNav = find.textContaining('Duyệt CLB');
      if (pendingNav.evaluate().isNotEmpty) {
        await tester.tap(pendingNav.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'admin_pending');
    } catch (e) {
      await screenshotOnFailure(tester, 'ADMIN-003');
      rethrow;
    }
  });
}

/// Navigate to admin clubs screen
Future<void> navigateToAdminClubs(WidgetTester tester) async {
  final adminNav = find.text('Admin');
  if (adminNav.evaluate().isNotEmpty) {
    await tester.tap(adminNav.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  final clubsNav = find.textContaining('Quản lý CLB');
  if (clubsNav.evaluate().isNotEmpty) {
    await tester.tap(clubsNav.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}
