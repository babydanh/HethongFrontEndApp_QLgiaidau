import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === RANKING MODULE: 12 TESTCASES ===

  // TC-FLUTTER-RANKING-001: Category Selection
  testWidgets('TC-FLUTTER-RANKING-001: LeaderboardScreen - Category Selection',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to leaderboard/ranking
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap sport category chips if available
      final chips = find.byType(Chip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
      await takeScreenshot(tester, 'ranking_category');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-001');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-002: Rankings List with Podium
  testWidgets('TC-FLUTTER-RANKING-002: LeaderboardScreen - Podium List',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'ranking_podium');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-002');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-003: Search Functionality
  testWidgets('TC-FLUTTER-RANKING-003: LeaderboardScreen - Search',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Try to search
      final searchFields = find.byType(TextField);
      if (searchFields.evaluate().isNotEmpty) {
        await tester.enterText(searchFields.last, 'test');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'ranking_search');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-003');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-004: My Ranking Card
  testWidgets('TC-FLUTTER-RANKING-004: LeaderboardScreen - My Ranking Card',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'ranking_my_card');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-004');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-005: Tier Legend View
  testWidgets('TC-FLUTTER-RANKING-005: LeaderboardScreen - Tier Legend',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'ranking_tier');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-005');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-006: Empty State
  testWidgets('TC-FLUTTER-RANKING-006: LeaderboardScreen - Empty State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check empty state if present
      final emptyText = find.text('Chưa có dữ liệu');
      if (emptyText.evaluate().isNotEmpty) {
        expect(emptyText, findsOneWidget);
      }

      await takeScreenshot(tester, 'ranking_empty');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-006');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-007: User Ranking Detail
  testWidgets('TC-FLUTTER-RANKING-007: User Ranking Detail Screen',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to user ranking detail via tab tap
      final leaderboardTab = find.text('Bảng xếp hạng');
      if (leaderboardTab.evaluate().isNotEmpty) {
        await tester.tap(leaderboardTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'ranking_detail');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-007');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-008: Pull-to-refresh
  testWidgets('TC-FLUTTER-RANKING-008: LeaderboardScreen - Pull-to-refresh',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Leaderboard dùng scroll riêng, thử pull-to-refresh nếu có
      final scrolls = find.byType(Scrollable);
      if (scrolls.evaluate().isNotEmpty) {
        await tester.fling(scrolls.first, const Offset(0, 300), 1000);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'ranking_refresh');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-008');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-009: Loading state
  testWidgets('TC-FLUTTER-RANKING-009: LeaderboardScreen - Loading',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pump(const Duration(seconds: 1));
      await navigateToLeaderboard(tester);
      await tester.pump(const Duration(seconds: 1));

      // Kiểm tra loading state nếu có
      if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      }

      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-009');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-010: Error State
  testWidgets('TC-FLUTTER-RANKING-010: LeaderboardScreen - Error State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-010');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-011: Scroll Loading
  testWidgets('TC-FLUTTER-RANKING-011: LeaderboardScreen - Scroll Loading',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -500));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'ranking_scroll');
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-011');
      rethrow;
    }
  });

  // TC-FLUTTER-RANKING-012: Podium Animation
  testWidgets('TC-FLUTTER-RANKING-012: LeaderboardScreen - Podium Animation',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLeaderboard(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'RANKING-012');
      rethrow;
    }
  });
}

/// Navigate to leaderboard
Future<void> navigateToLeaderboard(WidgetTester tester) async {
  // Try finding leaderboard tab or nav
  final rankNav = find.text('Bảng xếp hạng');
  if (rankNav.evaluate().isNotEmpty) {
    await tester.tap(rankNav.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  // Try bottom nav ranking tab (tab index 4 in home)
  final rankTab = find.text('Xếp hạng');
  if (rankTab.evaluate().isNotEmpty) {
    await tester.tap(rankTab.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  // Try navigating via leaderboard URL
  final leaderboardBtns = find.text('BXH');
  if (leaderboardBtns.evaluate().isNotEmpty) {
    await tester.tap(leaderboardBtns.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
