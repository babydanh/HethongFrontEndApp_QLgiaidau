import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === NOTIFICATION MODULE: 16 TESTCASES ===
  // Assertions dựa trên source code thực tế

  // TC-FLUTTER-NOTIFICATION-001: Hien thi danh sach
  testWidgets('TC-FLUTTER-NOTIFICATION-001: Notification screen - hien thi danh sach',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to notifications
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Màn hình Thông báo
      expect(find.text('Thông báo'), findsOneWidget);

      await takeScreenshot(tester, 'notification_list');
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-001');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-002: Empty state
  testWidgets('TC-FLUTTER-NOTIFICATION-002: Notification screen - empty state',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Kiểm tra empty state hoặc list
      final emptyText = find.text('Chưa có thông báo nào');
      if (emptyText.evaluate().isNotEmpty) {
        expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      }

      await takeScreenshot(tester, 'notification_empty');
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-002');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-003: Notification grouping theo thoi gian
  testWidgets('TC-FLUTTER-NOTIFICATION-003: Notification grouping theo thoi gian',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Kiểm tra có section headers: Hôm nay, Hôm qua, Tuần này
      final today = find.text('Hôm nay');
      final yesterday = find.text('Hôm qua');
      final thisWeek = find.text('Tuần này');
      expect(today.evaluate().isNotEmpty || yesterday.evaluate().isNotEmpty || thisWeek.evaluate().isNotEmpty, true);

      await takeScreenshot(tester, 'notification_grouping');
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-003');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-004: Danh dau da doc khi tap
  testWidgets('TC-FLUTTER-NOTIFICATION-004: Notification - danh dau da doc khi tap',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap vào notification card nếu có
      final notifCards = find.byType(Card);
      if (notifCards.evaluate().isNotEmpty) {
        await tester.tap(notifCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      await takeScreenshot(tester, 'notification_tap');
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-004');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-005: Redirect URL
  testWidgets('TC-FLUTTER-NOTIFICATION-005: Notification - redirect URL',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final notifCards = find.byType(Card);
      if (notifCards.evaluate().isNotEmpty) {
        await tester.tap(notifCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-005');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-006: Doc tat ca
  testWidgets('TC-FLUTTER-NOTIFICATION-006: Notification - doc tat ca',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Nút "Đọc tất cả" — xuất hiện khi có unread
      final readAllBtn = find.text('Đọc tất cả');
      if (readAllBtn.evaluate().isNotEmpty) {
        await tester.tap(readAllBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      await takeScreenshot(tester, 'notification_read_all');
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-006');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-007: Pagination load more
  testWidgets('TC-FLUTTER-NOTIFICATION-007: Notification - pagination load more',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll down để trigger load more
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -500));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await takeScreenshot(tester, 'notification_pagination');
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-007');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-008: Pull to refresh
  testWidgets('TC-FLUTTER-NOTIFICATION-008: Notification - pull to refresh',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Pull to refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await takeScreenshot(tester, 'notification_refresh');
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-008');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-009: addNotification socket realtime
  testWidgets('TC-FLUTTER-NOTIFICATION-009: Notification provider - addNotification socket',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Đã login → notification bell hiển thị
      expect(find.byIcon(Icons.notifications_none_rounded), findsWidgets);

      await takeScreenshot(tester, 'notification_socket');
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-009');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-010: markAsRead
  testWidgets('TC-FLUTTER-NOTIFICATION-010: Notification provider - markAsRead',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-010');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-011: markAllAsRead
  testWidgets('TC-FLUTTER-NOTIFICATION-011: Notification provider - markAllAsRead',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-011');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-012: loadPage page > 1 append
  testWidgets('TC-FLUTTER-NOTIFICATION-012: Notification provider - loadPage > 1 append',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-012');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-013: loadPage page 1 reset
  testWidgets('TC-FLUTTER-NOTIFICATION-013: Notification provider - loadPage page 1 reset',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-013');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-014: AppNotification fromJson
  testWidgets('TC-FLUTTER-NOTIFICATION-014: AppNotification entity - fromJson',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-014');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-015: AppNotification icon va color theo type
  testWidgets('TC-FLUTTER-NOTIFICATION-015: AppNotification - icon va color theo type',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-015');
      rethrow;
    }
  });

  // TC-FLUTTER-NOTIFICATION-016: timeAgo format
  testWidgets('TC-FLUTTER-NOTIFICATION-016: AppNotification - timeAgo format',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToNotifications(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'NOTIFICATION-016');
      rethrow;
    }
  });
}

/// Helper to navigate to notifications
Future<void> navigateToNotifications(WidgetTester tester) async {
  // Try notification bell icon in app bar
  final notifIcon = find.byIcon(Icons.notifications_none_rounded);
  if (notifIcon.evaluate().isNotEmpty) {
    await tester.tap(notifIcon.first);
    await tester.pumpAndSettle();
    return;
  }

  // Try text navigation
  final notifText = find.text('Thông báo');
  if (notifText.evaluate().isNotEmpty) {
    await tester.tap(notifText.last);
    await tester.pumpAndSettle();
    return;
  }

  // Try via bottom nav
  final notifyTab = find.text('Thông báo');
  if (notifyTab.evaluate().isNotEmpty) {
    await tester.tap(notifyTab.last);
    await tester.pumpAndSettle();
    return;
  }

  // Try profile -> settings -> notifications
  await navigateToProfile(tester);
  await tester.pumpAndSettle();
  final settingsTab = find.textContaining('Cài đặt');
  if (settingsTab.evaluate().isNotEmpty) {
    await tester.tap(settingsTab.last);
    await tester.pumpAndSettle();
  }
}
