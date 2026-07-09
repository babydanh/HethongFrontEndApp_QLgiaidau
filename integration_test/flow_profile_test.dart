import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === PROFILE MODULE: 7 TESTCASES (TC-FLUTTER-PROFILE-001 to 007) ===

  // TC-FLUTTER-PROFILE-001: Settings Tab Ho so
  testWidgets('TC-FLUTTER-PROFILE-001: Settings Tab Ho so',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to settings
      await navigateToSettings(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Màn hình Cài đặt với tab Hồ sơ
      expect(find.textContaining('Hồ sơ'), findsWidgets);

      await takeScreenshot(tester, 'profile_settings');
    } catch (e) {
      await screenshotOnFailure(tester, 'PROFILE-001');
      rethrow;
    }
  });

  // TC-FLUTTER-PROFILE-002: Settings Tab Ngan hang
  testWidgets('TC-FLUTTER-PROFILE-002: Settings Tab Ngan hang',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToSettings(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tab Ngân hàng
      final bankTab = find.textContaining('Ngân hàng');
      if (bankTab.evaluate().isNotEmpty) {
        await tester.tap(bankTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
      await takeScreenshot(tester, 'profile_bank');
    } catch (e) {
      await screenshotOnFailure(tester, 'PROFILE-002');
      rethrow;
    }
  });

  // TC-FLUTTER-PROFILE-003: Settings Tab Bao mat
  testWidgets('TC-FLUTTER-PROFILE-003: Settings Tab Bao mat',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToSettings(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tab Bảo mật
      final securityTab = find.textContaining('Bảo mật');
      if (securityTab.evaluate().isNotEmpty) {
        await tester.tap(securityTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Nút "Đổi mật khẩu"
      final changePwdBtn = find.textContaining('Đổi mật khẩu');
      if (changePwdBtn.evaluate().isNotEmpty) {
        await tester.tap(changePwdBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'profile_security');
    } catch (e) {
      await screenshotOnFailure(tester, 'PROFILE-003');
      rethrow;
    }
  });

  // TC-FLUTTER-PROFILE-004: Chinh sua thong tin ca nhan
  testWidgets('TC-FLUTTER-PROFILE-004: Chinh sua thong tin ca nhan',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to edit profile
      await navigateToProfile(tester);
      await tester.pumpAndSettle();

      // Look for edit button
      final editIcon = find.byIcon(Icons.edit);
      if (editIcon.evaluate().isNotEmpty) {
        await tester.tap(editIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Modify a field
      final nameField = find.byType(TextFormField);
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField.first, 'Test User Updated');
        await tester.pump();
      }

      // Try saving
      final saveBtn = find.textContaining('Lưu');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'profile_edit');
    } catch (e) {
      await screenshotOnFailure(tester, 'PROFILE-004');
      rethrow;
    }
  });

  // TC-FLUTTER-PROFILE-005: Doi mat khau
  testWidgets('TC-FLUTTER-PROFILE-005: Doi mat khau',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to change password
      await navigateToSettings(tester);
      await tester.pumpAndSettle();

      // Find change password option
      final changePwdBtn = find.textContaining('Đổi mật khẩu');
      if (changePwdBtn.evaluate().isNotEmpty) {
        await tester.tap(changePwdBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Màn hình đổi mật khẩu có các TextFormField
      expect(find.byType(TextFormField), findsWidgets);

      // Fill current password
      final pwdFields = find.byType(TextFormField);
      if (pwdFields.evaluate().isNotEmpty) {
        await tester.enterText(pwdFields.first, 'Demo123!@');
        await tester.pump();
      }
      if (pwdFields.evaluate().length > 1) {
        await tester.enterText(pwdFields.at(1), 'NewTest123!@');
        await tester.pump();
      }
      if (pwdFields.evaluate().length > 2) {
        await tester.enterText(pwdFields.last, 'NewTest123!@');
        await tester.pump();
      }

      final submitBtn = find.textContaining('Đổi mật khẩu');
      if (submitBtn.evaluate().isNotEmpty) {
        await tester.tap(submitBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'profile_change_password');
    } catch (e) {
      await screenshotOnFailure(tester, 'PROFILE-005');
      rethrow;
    }
  });

  // TC-FLUTTER-PROFILE-006: Xem ho so nguoi dung khac
  testWidgets('TC-FLUTTER-PROFILE-006: Xem ho so nguoi dung khac',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Navigate to another user's profile via /profile/user/:id
      await takeScreenshot(tester, 'profile_user');
    } catch (e) {
      await screenshotOnFailure(tester, 'PROFILE-006');
      rethrow;
    }
  });

  // TC-FLUTTER-PROFILE-007: QR Scanner
  testWidgets('TC-FLUTTER-PROFILE-007: QR Scanner',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to QR scanner
      final qrScan = find.byIcon(Icons.qr_code_scanner);
      if (qrScan.evaluate().isNotEmpty) {
        await tester.tap(qrScan.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'profile_qr_scan');
    } catch (e) {
      await screenshotOnFailure(tester, 'PROFILE-007');
      rethrow;
    }
  });
}

/// Navigate to settings screen
Future<void> navigateToSettings(WidgetTester tester) async {
  await navigateToProfile(tester);
  await tester.pumpAndSettle();

  // Look for settings option in profile
  final settingsText = find.textContaining('Cài đặt');
  if (settingsText.evaluate().isNotEmpty) {
    await tester.tap(settingsText.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return;
  }

  // Try settings icon
  final settingsIcon = find.byIcon(Icons.settings);
  if (settingsIcon.evaluate().isNotEmpty) {
    await tester.tap(settingsIcon.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}
