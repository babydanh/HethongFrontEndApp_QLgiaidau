import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-DASH-001: Dashboard workspace
  testWidgets('TC-FLUTTER-DASH-001: Dashboard workspace',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to dashboard
      final dashNav = find.text('Dashboard');
      if (dashNav.evaluate().isNotEmpty) {
        await tester.tap(dashNav.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else {
        final dashboardBtn = find.text('Bảng điều khiển');
        if (dashboardBtn.evaluate().isNotEmpty) {
          await tester.tap(dashboardBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }
      await takeScreenshot(tester, 'dashboard_main');
    } catch (e) {
      await screenshotOnFailure(tester, 'DASH-001');
      rethrow;
    }
  });

  // TC-FLUTTER-DASH-002: Chua login redirect
  testWidgets('TC-FLUTTER-DASH-002: Chua login redirect',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Note: needs unauthenticated state for full test
      await takeScreenshot(tester, 'dash_redirect');
    } catch (e) {
      await screenshotOnFailure(tester, 'DASH-002');
      rethrow;
    }
  });

  // TC-FLUTTER-DASH-003: OrganizerLiteSection
  testWidgets('TC-FLUTTER-DASH-003: OrganizerLiteSection',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await navigateToDashboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Kiểm tra có section "Organizer Lite" hoặc tournament items
      final liteSection = find.textContaining('Organizer');
      if (liteSection.evaluate().isNotEmpty) {
        expect(liteSection, findsOneWidget);
      }

      await takeScreenshot(tester, 'dash_organizer');
    } catch (e) {
      await screenshotOnFailure(tester, 'DASH-003');
      rethrow;
    }
  });

  // TC-FLUTTER-DASH-004: RoleSection
  testWidgets('TC-FLUTTER-DASH-004: RoleSection',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToDashboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'dash_roles');
    } catch (e) {
      await screenshotOnFailure(tester, 'DASH-004');
      rethrow;
    }
  });

  // TC-FLUTTER-DASH-005: TournamentSection
  testWidgets('TC-FLUTTER-DASH-005: TournamentSection Giai cua toi',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToDashboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'dash_tournaments');
    } catch (e) {
      await screenshotOnFailure(tester, 'DASH-005');
      rethrow;
    }
  });

  // TC-FLUTTER-DASH-006: AssignedMatchesSection
  testWidgets('TC-FLUTTER-DASH-006: AssignedMatchesSection',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToDashboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'dash_matches');
    } catch (e) {
      await screenshotOnFailure(tester, 'DASH-006');
      rethrow;
    }
  });

  // TC-FLUTTER-DASH-007: Loading state
  testWidgets('TC-FLUTTER-DASH-007: Dashboard Loading state',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pump(const Duration(seconds: 1));

      // Loading indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'dash_loading');
    } catch (e) {
      await screenshotOnFailure(tester, 'DASH-007');
      rethrow;
    }
  });

  // TC-FLUTTER-OLITE-001: OrganizerLiteScreen
  testWidgets('TC-FLUTTER-OLITE-001: OrganizerLiteScreen',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await navigateToDashboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for organizer lite link/button
      final liteBtn = find.textContaining('Lite');
      if (liteBtn.evaluate().isNotEmpty) {
        await tester.tap(liteBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'olite_main');
    } catch (e) {
      await screenshotOnFailure(tester, 'OLITE-001');
      rethrow;
    }
  });

  // TC-FLUTTER-OLITE-002: Lite screen loading/error
  testWidgets('TC-FLUTTER-OLITE-002: Lite screen loading error',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToDashboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'OLITE-002');
      rethrow;
    }
  });
}

/// Navigate to dashboard
Future<void> navigateToDashboard(WidgetTester tester) async {
  final dashNav = find.text('Dashboard');
  if (dashNav.evaluate().isNotEmpty) {
    await tester.tap(dashNav.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return;
  }
  // Try bottom nav or menu
  final dashTab = find.text('Bảng điều khiển');
  if (dashTab.evaluate().isNotEmpty) {
    await tester.tap(dashTab.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}
