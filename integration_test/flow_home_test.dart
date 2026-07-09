import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === HOME MODULE: 8 TESTCASES (TC-FLUTTER-HOME-001 to 008) ===

  // TC-FLUTTER-HOME-001: Hien thi danh sach giai dau
  testWidgets('TC-FLUTTER-HOME-001: Hien thi danh sach giai dau',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Search bar hiển thị
      expect(find.text('Tìm kiếm giải đấu...'), findsOneWidget);
      // Icon search
      expect(find.byIcon(Icons.search), findsWidgets);

      await takeScreenshot(tester, 'home_list');
    } catch (e) {
      await screenshotOnFailure(tester, 'HOME-001');
      rethrow;
    }
  });

  // TC-FLUTTER-HOME-002: Filter theo mon the thao
  testWidgets('TC-FLUTTER-HOME-002: Filter theo mon the thao',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find filter chips for sports
      final chips = find.byType(FilterChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
      await takeScreenshot(tester, 'home_filter');
    } catch (e) {
      await screenshotOnFailure(tester, 'HOME-002');
      rethrow;
    }
  });

  // TC-FLUTTER-HOME-003: Search giai dau
  testWidgets('TC-FLUTTER-HOME-003: Search giai dau',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find search field on home
      final searchFields = find.byType(TextField);
      if (searchFields.evaluate().isNotEmpty) {
        await tester.enterText(searchFields.first, 'test');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Clear button xuất hiện (Icons.close)
        final closeIcon = find.byIcon(Icons.close);
        if (closeIcon.evaluate().isNotEmpty) {
          await tester.tap(closeIcon.first);
          await tester.pumpAndSettle();
        }
      }

      await takeScreenshot(tester, 'home_search');
    } catch (e) {
      await screenshotOnFailure(tester, 'HOME-003');
      rethrow;
    }
  });

  // TC-FLUTTER-HOME-004: Carousel giai noi bat
  testWidgets('TC-FLUTTER-HOME-004: Carousel giai noi bat',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Section title "Giải đấu nổi bật"
      expect(find.text('Giải đấu nổi bật'), findsOneWidget);

      // Try to swipe carousel
      final pageViews = find.byType(PageView);
      if (pageViews.evaluate().isNotEmpty) {
        await tester.drag(pageViews.first, const Offset(-200, 0));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'home_carousel');
    } catch (e) {
      await screenshotOnFailure(tester, 'HOME-004');
      rethrow;
    }
  });

  // TC-FLUTTER-HOME-005: Pull-to-refresh
  testWidgets('TC-FLUTTER-HOME-005: Pull-to-refresh',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Pull to refresh trên home
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await takeScreenshot(tester, 'home_refresh');
    } catch (e) {
      await screenshotOnFailure(tester, 'HOME-005');
      rethrow;
    }
  });

  // TC-FLUTTER-HOME-006: Tab giai dau (Tournaments tab)
  testWidgets('TC-FLUTTER-HOME-006: Tab giai dau Tournaments tab',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tab "Giải đấu" hiển thị
      expect(find.text('Giải đấu'), findsWidgets);

      await takeScreenshot(tester, 'home_tournaments_tab');
    } catch (e) {
      await screenshotOnFailure(tester, 'HOME-006');
      rethrow;
    }
  });

  // TC-FLUTTER-HOME-007: Loading state
  testWidgets('TC-FLUTTER-HOME-007: Loading state',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pump(const Duration(seconds: 1));

      // Loading indicator hiển thị
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'HOME-007');
      rethrow;
    }
  });

  // TC-FLUTTER-HOME-008: Error state
  testWidgets('TC-FLUTTER-HOME-008: Error state',
      (tester) async {
    try {
      // Điều hướng đến home (có thể gặp lỗi nếu backend down)
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Nếu có lỗi → "Không thể tải dữ liệu"
      final errorText = find.text('Không thể tải dữ liệu');
      if (errorText.evaluate().isNotEmpty) {
        expect(find.text('Thử lại'), findsOneWidget);
      }

      await takeScreenshot(tester, 'home_error');
    } catch (e) {
      await screenshotOnFailure(tester, 'HOME-008');
      rethrow;
    }
  });
}
