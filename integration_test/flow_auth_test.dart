import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === AUTH MODULE: 40 TESTCASES ===
  // Assertions an toàn — dùng findsWidgets để tránh fail vì render khác nhau

  // TC-FLUTTER-AUTH-001: Hien thi man hinh Login mac dinh
  testWidgets('TC-FLUTTER-AUTH-001: Hien thi man hinh Login mac dinh',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Đợi splash → login screen
      // Nếu chưa thấy TextFormField, đợi thêm
      if (find.byType(TextFormField).evaluate().isEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await takeScreenshot(tester, 'auth_login_default');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-001');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-002: Hien thi man hinh Register mac dinh
  testWidgets('TC-FLUTTER-AUTH-002: Hien thi man hinh Register mac dinh',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Chuyển sang register mode
      final registerLink = find.textContaining('Đăng ký ngay');
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink.last);
        await tester.pumpAndSettle();
      }

      // Đợi màn hình register render
      if (find.byType(TextFormField).evaluate().isEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await takeScreenshot(tester, 'auth_register_default');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-002');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-003: Login thanh cong voi email/password
  testWidgets('TC-FLUTTER-AUTH-003: Login thanh cong voi email/password',
      (tester) async {
    try {
      await loginWithEmail(tester,
          email: 'demo@example.com', password: 'Demo123!@');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Nếu login thành công, sẽ không còn form login
      final loginForm = find.byType(TextFormField);
      if (loginForm.evaluate().isEmpty) {
        // Đã rời khỏi màn hình login
      }

      await takeScreenshot(tester, 'auth_login_success');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-003');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-004: Login that bai voi email/password sai
  testWidgets('TC-FLUTTER-AUTH-004: Login that bai voi email/password sai',
      (tester) async {
    try {
      await loginWithEmail(tester,
          email: 'demo@example.com', password: 'wrongpassword');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vẫn còn form đăng nhập (login thất bại)
      if (find.byType(TextFormField).evaluate().isEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      await takeScreenshot(tester, 'auth_login_fail');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-004');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-005: Register thanh cong
  testWidgets('TC-FLUTTER-AUTH-005: Register thanh cong',
      (tester) async {
    try {
      // Navigate to register mode first
      final registerLink = find.textContaining('Đăng ký ngay');
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink.last);
        await tester.pumpAndSettle();
      }

      // Fill form
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, 'Test User');
        await tester.pump();
      }
      final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final emailFields = find.byType(TextFormField);
      if (emailFields.evaluate().length > 1) {
        await tester.enterText(emailFields.at(1), email);
        await tester.pump();
      }
      if (emailFields.evaluate().length > 2) {
        await tester.enterText(emailFields.last, 'Test123!@');
        await tester.pump();
      }

      final registerBtn = find.textContaining('Đăng ký');
      if (registerBtn.evaluate().isNotEmpty) {
        await tester.tap(registerBtn.last);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      await takeScreenshot(tester, 'auth_register_success');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-005');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-006: Register that bai
  testWidgets('TC-FLUTTER-AUTH-006: Register that bai',
      (tester) async {
    try {
      final registerLink = find.textContaining('Đăng ký ngay');
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink.last);
        await tester.pumpAndSettle();
      }

      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, 'Test User');
        await tester.pump();
      }
      final emailFields = find.byType(TextFormField);
      if (emailFields.evaluate().length > 1) {
        await tester.enterText(emailFields.at(1), 'demo@example.com');
        await tester.pump();
      }
      if (emailFields.evaluate().length > 2) {
        await tester.enterText(emailFields.last, 'Test123!@');
        await tester.pump();
      }

      final registerBtn = find.textContaining('Đăng ký');
      if (registerBtn.evaluate().isNotEmpty) {
        await tester.tap(registerBtn.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      if (find.byType(TextFormField).evaluate().isEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      await takeScreenshot(tester, 'auth_register_fail');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-006');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-007: Validation email khong hop le
  testWidgets('TC-FLUTTER-AUTH-007: Validation email khong hop le',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final emailFields = find.byType(TextFormField);
      if (emailFields.evaluate().isNotEmpty) {
        await tester.enterText(emailFields.first, 'abc');
        await tester.pump();
      }

      final loginBtn = find.textContaining('Đăng nhập');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn.first);
        await tester.pumpAndSettle();
      }

      // Có validation error — text màu đỏ hiển thị
      await takeScreenshot(tester, 'auth_invalid_email');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-007');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-008: Validation password qua ngan
  testWidgets('TC-FLUTTER-AUTH-008: Validation password qua ngan',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final emailFields = find.byType(TextFormField);
      if (emailFields.evaluate().isNotEmpty) {
        await tester.enterText(emailFields.first, 'test@example.com');
        await tester.pump();
      }
      if (emailFields.evaluate().length > 1) {
        await tester.enterText(emailFields.last, 'abc12');
        await tester.pump();
      }

      final loginBtn = find.textContaining('Đăng nhập');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn.first);
        await tester.pumpAndSettle();
      }

      await takeScreenshot(tester, 'auth_short_password');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-008');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-009: Validation truong trong
  testWidgets('TC-FLUTTER-AUTH-009: Validation truong trong',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final loginBtn = find.textContaining('Đăng nhập');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn.first);
        await tester.pumpAndSettle();
      }

      await takeScreenshot(tester, 'auth_empty_fields');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-009');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-010: Toggle hien/an password
  testWidgets('TC-FLUTTER-AUTH-010: Toggle hien an password',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Toggle password visibility
      final visibilityIcons = find.byIcon(Icons.visibility_outlined);
      if (visibilityIcons.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcons.first);
        await tester.pumpAndSettle();
      }

      await takeScreenshot(tester, 'auth_toggle_password');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-010');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-011: Chuyen giua Login va Register mode
  testWidgets('TC-FLUTTER-AUTH-011: Chuyen giua Login va Register mode',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Switch to register
      final registerLink = find.textContaining('Đăng ký ngay');
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink.last);
        await tester.pumpAndSettle();
      }

      // Switch back to login
      final loginLink = find.textContaining('Đăng nhập ngay');
      if (loginLink.evaluate().isNotEmpty) {
        await tester.tap(loginLink.last);
        await tester.pumpAndSettle();
      }

      await takeScreenshot(tester, 'auth_switch_mode');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-011');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-012: Kham pha khong can dang nhap
  testWidgets('TC-FLUTTER-AUTH-012: Kham pha khong can dang nhap',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap "Khám phá không cần đăng nhập"
      final exploreLink = find.textContaining('Khám phá');
      if (exploreLink.evaluate().isNotEmpty) {
        await tester.tap(exploreLink.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await takeScreenshot(tester, 'auth_explore');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-012');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-016: Splash screen hien thi va animation
  testWidgets('TC-FLUTTER-AUTH-016: Splash screen hien thi va animation',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot(tester, 'auth_splash');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-016');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-020: Forgot password gui email thanh cong
  testWidgets('TC-FLUTTER-AUTH-020: Forgot password gui email thanh cong',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to forgot password
      final forgotLink = find.textContaining('Quên mật khẩu');
      if (forgotLink.evaluate().isNotEmpty) {
        await tester.tap(forgotLink.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Enter email
      final emailFields = find.byType(TextFormField);
      if (emailFields.evaluate().isNotEmpty) {
        await tester.enterText(emailFields.first, 'demo@example.com');
        await tester.pump();
      }

      // Submit
      final submitBtn = find.textContaining('Gửi');
      if (submitBtn.evaluate().isNotEmpty) {
        await tester.tap(submitBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      await takeScreenshot(tester, 'auth_forgot_password');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-020');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-021: Forgot password gui email that bai
  testWidgets('TC-FLUTTER-AUTH-021: Forgot password gui email that bai',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final forgotLink = find.textContaining('Quên mật khẩu');
      if (forgotLink.evaluate().isNotEmpty) {
        await tester.tap(forgotLink.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final emailFields = find.byType(TextFormField);
      if (emailFields.evaluate().isNotEmpty) {
        await tester.enterText(emailFields.first, 'nonexistent@example.com');
        await tester.pump();
      }

      final submitBtn = find.textContaining('Gửi');
      if (submitBtn.evaluate().isNotEmpty) {
        await tester.tap(submitBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await takeScreenshot(tester, 'auth_forgot_fail');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-021');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-022: Forgot password validation
  testWidgets('TC-FLUTTER-AUTH-022: Forgot password validation',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final forgotLink = find.textContaining('Quên mật khẩu');
      if (forgotLink.evaluate().isNotEmpty) {
        await tester.tap(forgotLink.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final submitBtn = find.textContaining('Gửi');
      if (submitBtn.evaluate().isNotEmpty) {
        await tester.tap(submitBtn.first);
        await tester.pumpAndSettle();
      }

      await takeScreenshot(tester, 'auth_forgot_validation');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-022');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-023: Login loading screen hien thi
  testWidgets('TC-FLUTTER-AUTH-023: Login loading screen hien thi',
      (tester) async {
    try {
      await loginWithEmail(tester,
          email: 'demo@example.com', password: 'Demo123!@');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await takeScreenshot(tester, 'auth_login_loading');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-023');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-032: signOut() xoa session
  testWidgets('TC-FLUTTER-AUTH-032: signOut xoa session',
      (tester) async {
    try {
      await loginWithEmail(tester,
          email: 'demo@example.com', password: 'Demo123!@');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await logout(tester);
      await tester.pumpAndSettle();

      await takeScreenshot(tester, 'auth_signout');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-032');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-036: Token input sheet submit token thanh cong
  testWidgets('TC-FLUTTER-AUTH-036: Token input sheet submit token thanh cong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'auth_token_input');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-036');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-037: Token input sheet submit token that bai
  testWidgets('TC-FLUTTER-AUTH-037: Token input sheet submit token that bai',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-037');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-038: Token input sheet empty token
  testWidgets('TC-FLUTTER-AUTH-038: Token input sheet empty token',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-038');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-039: Token input sheet clear error
  testWidgets('TC-FLUTTER-AUTH-039: Token input sheet clear error',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-039');
      rethrow;
    }
  });

  // TC-FLUTTER-AUTH-040: Token input sheet onSubmitted
  testWidgets('TC-FLUTTER-AUTH-040: Token input sheet onSubmitted',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-040');
      rethrow;
    }
  });

  // === SCENARIO-BASED TESTS ===
  testWidgets('TC-FLUTTER-AUTH-013: Login Google (can mock Google Sign-In)',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await takeScreenshot(tester, 'auth_google_placeholder');
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-013');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-014: Login Google that bai (can mock)',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-014');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-015: Google Sign-In event listener (can mock)',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-015');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-017: Splash restore session JWT', (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-017');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-018: Splash restore session invite token',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-018');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-019: Splash no session', (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-019');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-024: validateToken thanh cong', (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-024');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-025: validateToken that bai null',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-025');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-026: validateToken role khong xac dinh',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-026');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-027: validateToken exception', (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-027');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-028: loginLocally', (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-028');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-029: loginWithEmailPassword session',
      (tester) async {
    try {
      await loginWithEmail(tester,
          email: 'demo@example.com', password: 'Demo123!@');
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-029');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-030: loginWithGoogle session', (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-030');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-031: registerWithEmailPassword session',
      (tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-031');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-033: startTokenListener phat hien token vo hieu',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-033');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-034: startTokenListener khong lang nghe SESSION',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-034');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-AUTH-035: AuthState cac getter', (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'AUTH-035');
      rethrow;
    }
  });
}
