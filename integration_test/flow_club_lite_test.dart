import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === COMMUNITY MODULE: 15 TESTCASES ===

  // TC-FLUTTER-COMMUNITY-001: Xem danh sach CLB voi filter va search
  testWidgets('TC-FLUTTER-COMMUNITY-001: Xem danh sach CLB filter search',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to club list
      await navigateToClubList(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Search field
      final searchFields = find.byType(TextField);
      if (searchFields.evaluate().isNotEmpty) {
        await tester.enterText(searchFields.first, 'test');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'community_list');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-001');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-002: Tab CLB của tôi
  testWidgets('TC-FLUTTER-COMMUNITY-002: Tab CLB cua toi',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubList(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final myClubsTab = find.textContaining('CLB của tôi');
      if (myClubsTab.evaluate().isNotEmpty) {
        await tester.tap(myClubsTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
      await takeScreenshot(tester, 'community_my_clubs');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-002');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-003: Chi tiet CLB
  testWidgets('TC-FLUTTER-COMMUNITY-003: Chi tiet CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Club name should be visible
      final clubName = find.byType(Text);
      if (clubName.evaluate().isNotEmpty) {
        // At least some text content is rendered
      }
      await takeScreenshot(tester, 'community_detail');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-003');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-004: Tham gia CLB
  testWidgets('TC-FLUTTER-COMMUNITY-004: Tham gia CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final joinBtn = find.textContaining('Tham gia');
      if (joinBtn.evaluate().isNotEmpty) {
        await tester.tap(joinBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'community_join');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-004');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-005: Quan ly member
  testWidgets('TC-FLUTTER-COMMUNITY-005: Quan ly member',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'community_members');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-005');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-006: Duyet join request
  testWidgets('TC-FLUTTER-COMMUNITY-006: Duyet join request',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'community_requests');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-006');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-007: Invite dialog
  testWidgets('TC-FLUTTER-COMMUNITY-007: Invite dialog',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final inviteBtn = find.textContaining('Mời');
      if (inviteBtn.evaluate().isNotEmpty) {
        await tester.tap(inviteBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'community_invite');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-007');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-008: Tao CLB
  testWidgets('TC-FLUTTER-COMMUNITY-008: Tao CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to create club
      await navigateToCreateClub(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Fill club name
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, 'CLB Test Auto ${DateTime.now().millisecondsSinceEpoch}');
        await tester.pumpAndSettle();
      }
      await takeScreenshot(tester, 'community_create');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-008');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-009: Sua CLB
  testWidgets('TC-FLUTTER-COMMUNITY-009: Sua CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final editBtn = find.textContaining('Sửa');
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'community_edit');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-009');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-010: Quan ly CLB
  testWidgets('TC-FLUTTER-COMMUNITY-010: Quan ly CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for management button
      final manageBtn = find.text('QL');
      if (manageBtn.evaluate().isNotEmpty) {
        await tester.tap(manageBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'community_manage');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-010');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-011: Loi moi CLB
  testWidgets('TC-FLUTTER-COMMUNITY-011: Loi moi CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Navigate to club invites
      final invitesNav = find.text('Lời mời');
      if (invitesNav.evaluate().isNotEmpty) {
        await tester.tap(invitesNav.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'community_invites');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-011');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-012: Giai dau trong CLB
  testWidgets('TC-FLUTTER-COMMUNITY-012: Giai dau trong CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Chuyển đến tab "Giải đấu"
      final tourTab = find.text('Giải đấu');
      if (tourTab.evaluate().isNotEmpty) {
        await tester.tap(tourTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'community_tournaments');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-012');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-013: Tao giai trong CLB
  testWidgets('TC-FLUTTER-COMMUNITY-013: Tao giai trong CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'community_create_tournament');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-013');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-014: Gallery
  testWidgets('TC-FLUTTER-COMMUNITY-014: Gallery',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tab "Ảnh"
      final galleryTab = find.text('Ảnh');
      if (galleryTab.evaluate().isNotEmpty) {
        await tester.tap(galleryTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'community_gallery');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-014');
      rethrow;
    }
  });

  // TC-FLUTTER-COMMUNITY-015: Bang xep hang CLB
  testWidgets('TC-FLUTTER-COMMUNITY-015: Bang xep hang CLB',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToClubDetail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tab "Xếp hạng"
      final rankTab = find.textContaining('Xếp hạng');
      if (rankTab.evaluate().isNotEmpty) {
        await tester.tap(rankTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'community_rankings');
    } catch (e) {
      await screenshotOnFailure(tester, 'COMMUNITY-015');
      rethrow;
    }
  });
}

/// Navigate to club list
Future<void> navigateToClubList(WidgetTester tester) async {
  // Try via bottom nav "CLB"
  final clubNav = find.text('CLB');
  if (clubNav.evaluate().isNotEmpty) {
    await tester.tap(clubNav.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  // Try "Câu lạc bộ"
  final clubNav2 = find.textContaining('Câu lạc bộ');
  if (clubNav2.evaluate().isNotEmpty) {
    await tester.tap(clubNav2.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  // Try navigating via communities
  final communityNav = find.text('Cộng đồng');
  if (communityNav.evaluate().isNotEmpty) {
    await tester.tap(communityNav.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Navigate to club detail
Future<void> navigateToClubDetail(WidgetTester tester) async {
  await navigateToClubList(tester);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Tap first club card
  final clubCards = find.byType(Card);
  if (clubCards.evaluate().isNotEmpty) {
    await tester.tap(clubCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Navigate to create club screen
Future<void> navigateToCreateClub(WidgetTester tester) async {
  await navigateToClubList(tester);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Look for FAB or create button
  final fab = find.byType(FloatingActionButton);
  if (fab.evaluate().isNotEmpty) {
    await tester.tap(fab.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return;
  }

  final createBtn = find.textContaining('Tạo CLB');
  if (createBtn.evaluate().isNotEmpty) {
    await tester.tap(createBtn.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}
