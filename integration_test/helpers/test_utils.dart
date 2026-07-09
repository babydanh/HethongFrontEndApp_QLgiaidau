import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Helper functions cho integration tests (chạy với backend thật)
/// KHÔNG mock, test thật qua real API

final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
final screenshotDir = Directory('test_screenshots');
int screenshotIndex = 0;

/// Chụp ảnh màn hình
Future<void> takeScreenshot(WidgetTester tester, String name) async {
  try {
    screenshotIndex++;
    final path = '${screenshotIndex.toString().padLeft(3, '0')}_$name';
    await binding.takeScreenshot(path);
    debugPrint('[SCREENSHOT] $path');
  } catch (e) {
    debugPrint('[SCREENSHOT WARNING] Could not save screenshot: $e');
  }
}

/// Chụp ảnh khi test fail
Future<void> screenshotOnFailure(WidgetTester tester, String testName) async {
  await takeScreenshot(tester, 'FAIL_${testName.replaceAll(' ', '_')}');
}

/// Đăng nhập bằng email/password
Future<void> loginWithEmail(WidgetTester tester,
    {String email = 'demo@example.com', String password = 'Demo123!@'}) async {
  await takeScreenshot(tester, 'login_screen');

  final emailFields = find.byType(TextFormField);
  if (emailFields.evaluate().isNotEmpty) {
    await tester.enterText(emailFields.first, email);
    await tester.pump();
  }

  final passFields = find.byType(TextFormField);
  if (passFields.evaluate().length > 1) {
    await tester.enterText(passFields.last, password);
    await tester.pump();
  }

  final loginBtn = find.text('Đăng nhập');
  if (loginBtn.evaluate().isNotEmpty) {
    await tester.tap(loginBtn.first);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  await takeScreenshot(tester, 'after_login');
}

/// Navigate đến profile
Future<void> navigateToProfile(WidgetTester tester) async {
  final profileBtns = find.byIcon(Icons.person_rounded);
  if (profileBtns.evaluate().isNotEmpty) {
    await tester.tap(profileBtns.last);
    await tester.pumpAndSettle();
  }
  await takeScreenshot(tester, 'profile_screen');
}

/// Navigate đến notifications
Future<void> navigateToNotifications(WidgetTester tester) async {
  // Try via notification bell icon
  final notifIcon = find.byIcon(Icons.notifications_none_rounded);
  if (notifIcon.evaluate().isNotEmpty) {
    await tester.tap(notifIcon.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return;
  }
  // Try via bottom nav
  final notifyTab = find.text('Thông báo');
  if (notifyTab.evaluate().isNotEmpty) {
    await tester.tap(notifyTab.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return;
  }
  // Try via settings
  await navigateToProfile(tester);
  await tester.pumpAndSettle();
  final settingsTab = find.textContaining('Cài đặt');
  if (settingsTab.evaluate().isNotEmpty) {
    await tester.tap(settingsTab.last);
    await tester.pumpAndSettle();
  }
}

/// Navigate đến dashboard
Future<void> navigateToDashboard(WidgetTester tester) async {
  final dashNav = find.text('Dashboard');
  if (dashNav.evaluate().isNotEmpty) {
    await tester.tap(dashNav.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return;
  }
  final dashTab = find.text('Bảng điều khiển');
  if (dashTab.evaluate().isNotEmpty) {
    await tester.tap(dashTab.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}

/// Navigate đến settings
Future<void> navigateToSettings(WidgetTester tester) async {
  await navigateToProfile(tester);
  await tester.pumpAndSettle();
  final settingsText = find.textContaining('Cài đặt');
  if (settingsText.evaluate().isNotEmpty) {
    await tester.tap(settingsText.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    return;
  }
  final settingsIcon = find.byIcon(Icons.settings);
  if (settingsIcon.evaluate().isNotEmpty) {
    await tester.tap(settingsIcon.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}

/// Logout
Future<void> logout(WidgetTester tester) async {
  await navigateToProfile(tester);

  final settingsTab = find.textContaining('Cài đặt');
  if (settingsTab.evaluate().isNotEmpty) {
    await tester.tap(settingsTab.last);
    await tester.pumpAndSettle();
  }

  final logoutBtn = find.text('Đăng xuất');
  if (logoutBtn.evaluate().isNotEmpty) {
    await tester.tap(logoutBtn.last);
    await tester.pumpAndSettle();
  }
  await takeScreenshot(tester, 'after_logout');
}

/// Đọc kết quả test từ machine output và trả về map
Map<String, String> parseTestResult(String testId, bool passed) {
  return {
    'id': testId,
    'status': passed ? 'Pass' : 'Fail',
    'timestamp': DateTime.now().toIso8601String(),
  };
}
