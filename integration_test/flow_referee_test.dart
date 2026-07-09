import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-REFEREE-001: Xem danh sach loi moi trong tai
  testWidgets('TC-FLUTTER-REFEREE-001: Xem danh sach loi moi trong tai',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to referee invites
      final refTab = find.text('Trọng tài');
      if (refTab.evaluate().isNotEmpty) {
        await tester.tap(refTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Look for invite section
      final inviteNav = find.textContaining('Lời mời');
      if (inviteNav.evaluate().isNotEmpty) {
        await tester.tap(inviteNav.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Kiểm tra màn hình lời mời trọng tài
      expect(find.byType(ListView), findsWidgets);

      await takeScreenshot(tester, 'referee_invites');
    } catch (e) {
      await screenshotOnFailure(tester, 'REFEREE-001');
      rethrow;
    }
  });

  // TC-FLUTTER-REFEREE-002: Accept/Decline loi moi
  testWidgets('TC-FLUTTER-REFEREE-002: Accept Decline loi moi trong tai',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to referee invites
      await navigateToRefereeInvites(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap "Nhận nhiệm vụ" or "Từ chối" if exists
      final acceptBtn = find.textContaining('Nhận nhiệm vụ');
      if (acceptBtn.evaluate().isNotEmpty) {
        await tester.tap(acceptBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final declineBtn = find.text('Từ chối');
      if (declineBtn.evaluate().isNotEmpty) {
        await tester.tap(declineBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'referee_action');
    } catch (e) {
      await screenshotOnFailure(tester, 'REFEREE-002');
      rethrow;
    }
  });

  // TC-FLUTTER-REFEREE-003: Tournament Workspace Provider
  testWidgets('TC-FLUTTER-REFEREE-003: Tournament Workspace Provider',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToRefereeInvites(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'REFEREE-003');
      rethrow;
    }
  });
}

/// Navigate to referee invites screen
Future<void> navigateToRefereeInvites(WidgetTester tester) async {
  final refNav = find.textContaining('Trọng tài');
  if (refNav.evaluate().isNotEmpty) {
    await tester.tap(refNav.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  final invitesNav = find.textContaining('Lời mời');
  if (invitesNav.evaluate().isNotEmpty) {
    await tester.tap(invitesNav.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}
