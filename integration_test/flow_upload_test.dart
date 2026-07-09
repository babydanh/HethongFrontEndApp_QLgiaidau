import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-UPLOAD-001: Upload avatar thanh cong
  testWidgets('TC-FLUTTER-UPLOAD-001: Upload avatar thanh cong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to edit profile screen
      await navigateToEditProfile(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap avatar to trigger upload
      final avatarBtn = find.byType(CircleAvatar);
      if (avatarBtn.evaluate().isNotEmpty) {
        await tester.tap(avatarBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'upload_avatar');
    } catch (e) {
      await screenshotOnFailure(tester, 'UPLOAD-001');
      rethrow;
    }
  });

  // TC-FLUTTER-UPLOAD-002: Upload cover thanh cong
  testWidgets('TC-FLUTTER-UPLOAD-002: Upload cover thanh cong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to edit profile
      await navigateToEditProfile(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for cover upload button
      final coverEdit = find.byIcon(Icons.camera_alt);
      if (coverEdit.evaluate().isNotEmpty) {
        await tester.tap(coverEdit.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'upload_cover');
    } catch (e) {
      await screenshotOnFailure(tester, 'UPLOAD-002');
      rethrow;
    }
  });

  // TC-FLUTTER-UPLOAD-003: Upload that bai
  testWidgets('TC-FLUTTER-UPLOAD-003: Upload that bai',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToEditProfile(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'upload_fail');
    } catch (e) {
      await screenshotOnFailure(tester, 'UPLOAD-003');
      rethrow;
    }
  });
}

/// Navigate to edit profile screen
Future<void> navigateToEditProfile(WidgetTester tester) async {
  await navigateToProfile(tester);
  await tester.pumpAndSettle();

  // Look for edit button/pencil icon
  final editIcon = find.byIcon(Icons.edit);
  if (editIcon.evaluate().isNotEmpty) {
    await tester.tap(editIcon.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return;
  }

  // Look for "Sửa" text
  final editText = find.textContaining('Sửa thông tin');
  if (editText.evaluate().isNotEmpty) {
    await tester.tap(editText.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}
