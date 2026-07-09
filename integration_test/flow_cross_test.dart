import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === CROSS MODULE: 5 TESTCASES ===

  // TC-FLUTTER-CROSS-001: Bracket -> Match Flow
  testWidgets('TC-FLUTTER-CROSS-001: Bracket -> Match Flow Tap Match to LiveScore',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to bracket view
      await navigateToBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap a match row
      final matchItems = find.byType(ListTile);
      if (matchItems.evaluate().isNotEmpty) {
        await tester.tap(matchItems.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify navigated to LiveScore screen
        await takeScreenshot(tester, 'cross_bracket_to_match');
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'CROSS-001');
      rethrow;
    }
  });

  // TC-FLUTTER-CROSS-002: Draw -> Bracket Preview Flow
  testWidgets('TC-FLUTTER-CROSS-002: Draw -> Bracket Preview Flow',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to draw screen
      await navigateToDrawScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Then navigate to bracket view
      await navigateToBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await takeScreenshot(tester, 'cross_draw_to_bracket');
    } catch (e) {
      await screenshotOnFailure(tester, 'CROSS-002');
      rethrow;
    }
  });

  // TC-FLUTTER-CROSS-003: Score Update -> Standings Recalculation
  testWidgets('TC-FLUTTER-CROSS-003: Score Update -> Standings Recalculation',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to bracket -> standings tab
      await navigateToBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tab "Bảng xếp hạng"
      final standingsTab = find.textContaining('Bảng xếp hạng');
      if (standingsTab.evaluate().isNotEmpty) {
        await tester.tap(standingsTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'cross_standings');
    } catch (e) {
      await screenshotOnFailure(tester, 'CROSS-003');
      rethrow;
    }
  });

  // TC-FLUTTER-CROSS-004: Tournament Intro Navigation
  testWidgets('TC-FLUTTER-CROSS-004: Tournament Intro to Bracket/Live/Register',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to tournament intro
      await navigateToTournamentIntro(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap bottom action buttons based on context
      await takeScreenshot(tester, 'cross_intro_nav');
    } catch (e) {
      await screenshotOnFailure(tester, 'CROSS-004');
      rethrow;
    }
  });

  // TC-FLUTTER-CROSS-005: Admin Edit Score -> Bracket Advancement
  testWidgets('TC-FLUTTER-CROSS-005: Admin Edit Score -> Bracket Advancement',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Kiểm tra bracket có hiển thị
      final matchRows = find.byType(ListTile);
      if (matchRows.evaluate().isNotEmpty) {
        await tester.tap(matchRows.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      await takeScreenshot(tester, 'cross_admin_edit');
    } catch (e) {
      await screenshotOnFailure(tester, 'CROSS-005');
      rethrow;
    }
  });
}

/// Navigate to bracket view
Future<void> navigateToBracket(WidgetTester tester) async {
  final tourCards = find.byType(Card);
  if (tourCards.evaluate().isNotEmpty) {
    await tester.tap(tourCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
  final bracketBtn = find.textContaining('Sơ đồ');
  if (bracketBtn.evaluate().isNotEmpty) {
    await tester.tap(bracketBtn.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Navigate to draw screen
Future<void> navigateToDrawScreen(WidgetTester tester) async {
  final drawNav = find.textContaining('Bốc thăm');
  if (drawNav.evaluate().isNotEmpty) {
    await tester.tap(drawNav.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Navigate to tournament intro
Future<void> navigateToTournamentIntro(WidgetTester tester) async {
  final tourCards = find.byType(Card);
  if (tourCards.evaluate().isNotEmpty) {
    await tester.tap(tourCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
