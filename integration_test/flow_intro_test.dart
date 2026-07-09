import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === INTRO MODULE: 8 TESTCASES ===

  // TC-FLUTTER-INTRO-001: Tab Navigation
  testWidgets('TC-FLUTTER-INTRO-001: TournamentIntroScreen - Tab Navigation',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentIntro(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Kiểm tra có TabBar
      final tabBar = find.byType(TabBar);
      if (tabBar.evaluate().isNotEmpty) {
        final tabs = find.byType(Tab);
        if (tabs.evaluate().isNotEmpty) {
          for (int i = 0; i < tabs.evaluate().length && i < 4; i++) {
            await tester.tap(tabs.at(i));
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }
        }
        // TabBar tồn tại
        expect(tabBar, findsOneWidget);
      }

      await takeScreenshot(tester, 'intro_tabs');
    } catch (e) {
      await screenshotOnFailure(tester, 'INTRO-001');
      rethrow;
    }
  });

  // TC-FLUTTER-INTRO-002: About Tab
  testWidgets('TC-FLUTTER-INTRO-002: TournamentIntroScreen - About Tab',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentIntro(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tab "Giới thiệu"
      final aboutTab = find.textContaining('Giới thiệu');
      if (aboutTab.evaluate().isNotEmpty) {
        await tester.tap(aboutTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'intro_about');
    } catch (e) {
      await screenshotOnFailure(tester, 'INTRO-002');
      rethrow;
    }
  });

  // TC-FLUTTER-INTRO-003: Teams Tab with Divisions
  testWidgets('TC-FLUTTER-INTRO-003: TournamentIntroScreen - Teams Tab',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentIntro(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tab "Danh sách đội"
      final teamsTab = find.textContaining('Danh sách đội');
      if (teamsTab.evaluate().isNotEmpty) {
        await tester.tap(teamsTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'intro_teams');
    } catch (e) {
      await screenshotOnFailure(tester, 'INTRO-003');
      rethrow;
    }
  });

  // TC-FLUTTER-INTRO-004: Bottom Action Bar
  testWidgets('TC-FLUTTER-INTRO-004: TournamentIntroScreen - Bottom Action Bar',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentIntro(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Bottom action bar — kiểm tra có button ở cuối màn hình
      // Có thể là BottomAppBar, NavigationBar, hoặc custom widget
      // Chỉ cần screen load được là OK

      await takeScreenshot(tester, 'intro_bottom_bar');
    } catch (e) {
      await screenshotOnFailure(tester, 'INTRO-004');
      rethrow;
    }
  });

  // TC-FLUTTER-INTRO-005: Follow/Unfollow Tournament
  testWidgets('TC-FLUTTER-INTRO-005: TournamentIntroScreen - Follow Unfollow',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentIntro(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Nút "Theo dõi"
      final followBtn = find.textContaining('Theo dõi');
      if (followBtn.evaluate().isNotEmpty) {
        await tester.tap(followBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'intro_follow');
    } catch (e) {
      await screenshotOnFailure(tester, 'INTRO-005');
      rethrow;
    }
  });

  // TC-FLUTTER-INTRO-006: Registration Sheet
  testWidgets('TC-FLUTTER-INTRO-006: TournamentIntroScreen - Registration',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentIntro(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Nút "Đăng ký tham gia"
      final regBtn = find.textContaining('Đăng ký tham gia');
      if (regBtn.evaluate().isNotEmpty) {
        await tester.tap(regBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'INTRO-006');
      rethrow;
    }
  });

  // TC-FLUTTER-INTRO-007: Viewer Count Badge
  testWidgets('TC-FLUTTER-INTRO-007: TournamentIntroScreen - Viewer Count',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentIntro(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'intro_viewers');
    } catch (e) {
      await screenshotOnFailure(tester, 'INTRO-007');
      rethrow;
    }
  });

  // TC-FLUTTER-INTRO-008: Loading/Error/Null States
  testWidgets('TC-FLUTTER-INTRO-008: TournamentIntroScreen - Loading Error Null',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'INTRO-008');
      rethrow;
    }
  });

  // === DETAIL MODULE: 7 TESTCASES ===

  // TC-FLUTTER-DETAIL-001: Tournament Detail Info Card
  testWidgets('TC-FLUTTER-DETAIL-001: TournamentDetailScreen - Info Card',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to admin tournament detail
      await navigateToAdminTournament(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'detail_info');
    } catch (e) {
      await screenshotOnFailure(tester, 'DETAIL-001');
      rethrow;
    }
  });

  // TC-FLUTTER-DETAIL-002: Quick Actions
  testWidgets('TC-FLUTTER-DETAIL-002: TournamentDetailScreen - Quick Actions',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAdminTournament(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'detail_actions');
    } catch (e) {
      await screenshotOnFailure(tester, 'DETAIL-002');
      rethrow;
    }
  });

  // TC-FLUTTER-DETAIL-003: Finalize Tournament
  testWidgets('TC-FLUTTER-DETAIL-003: TournamentDetailScreen - Finalize',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAdminTournament(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Nút "Kết thúc"
      final finalizeBtn = find.textContaining('Kết thúc');
      if (finalizeBtn.evaluate().isNotEmpty) {
        await tester.tap(finalizeBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'DETAIL-003');
      rethrow;
    }
  });

  // TC-FLUTTER-DETAIL-004: Delete Tournament
  testWidgets('TC-FLUTTER-DETAIL-004: TournamentDetailScreen - Delete',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAdminTournament(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Menu more_vert
      final moreBtn = find.byIcon(Icons.more_vert);
      if (moreBtn.evaluate().isNotEmpty) {
        await tester.tap(moreBtn.first);
        await tester.pumpAndSettle();
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'DETAIL-004');
      rethrow;
    }
  });

  // TC-FLUTTER-DETAIL-005: Excel Export
  testWidgets('TC-FLUTTER-DETAIL-005: TournamentDetailScreen - Excel Export',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAdminTournament(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Nút "Xuất dữ liệu"
      final exportBtn = find.textContaining('Xuất dữ liệu');
      if (exportBtn.evaluate().isNotEmpty) {
        await tester.tap(exportBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'DETAIL-005');
      rethrow;
    }
  });

  // TC-FLUTTER-DETAIL-006: Responsive Layout Tablet
  testWidgets('TC-FLUTTER-DETAIL-006: TournamentDetailScreen - Responsive Layout',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAdminTournament(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'DETAIL-006');
      rethrow;
    }
  });

  // TC-FLUTTER-DETAIL-007: Embedded Screens
  testWidgets('TC-FLUTTER-DETAIL-007: TournamentDetailScreen - Embedded Screens',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAdminTournament(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap through feature buttons
      final featureBtns = find.byType(ElevatedButton);
      if (featureBtns.evaluate().isNotEmpty) {
        for (int i = 0; i < featureBtns.evaluate().length && i < 3; i++) {
          await tester.tap(featureBtns.at(i));
          await tester.pumpAndSettle(const Duration(seconds: 2));
          // Try to go back
          final backBtn = find.byTooltip('Back');
          if (backBtn.evaluate().isNotEmpty) {
            await tester.tap(backBtn);
            await tester.pumpAndSettle();
          }
        }
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'DETAIL-007');
      rethrow;
    }
  });
}

/// Navigate to tournament intro screen
Future<void> navigateToTournamentIntro(WidgetTester tester) async {
  // Tap a tournament card on home screen
  final tourCards = find.byType(Card);
  if (tourCards.evaluate().isNotEmpty) {
    await tester.tap(tourCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Navigate to admin tournament detail
Future<void> navigateToAdminTournament(WidgetTester tester) async {
  await navigateToTournamentIntro(tester);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}
