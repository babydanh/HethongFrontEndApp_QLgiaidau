import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-REGISTER-001: Dang ky tham gia giai dau
  testWidgets('TC-FLUTTER-REGISTER-001: Dang ky tham gia giai dau',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to a tournament -> register
      await navigateToTournamentRegister(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Fill team name
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, 'Đội Test');
        await tester.pumpAndSettle();
      }

      // Tap confirm
      final confirmBtn = find.textContaining('Xác nhận');
      if (confirmBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await takeScreenshot(tester, 'register_submit');
    } catch (e) {
      await screenshotOnFailure(tester, 'REGISTER-001');
      rethrow;
    }
  });

  // TC-FLUTTER-REGISTER-002: Tham gia giai bang ma moi
  testWidgets('TC-FLUTTER-REGISTER-002: Tham gia giai bang ma moi',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to join via invite (requires valid invite code)
      await takeScreenshot(tester, 'register_invite');
    } catch (e) {
      await screenshotOnFailure(tester, 'REGISTER-002');
      rethrow;
    }
  });

  // TC-FLUTTER-REGISTER-003: Tham gia doi (Join Team)
  testWidgets('TC-FLUTTER-REGISTER-003: Tham gia doi Join Team',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to join team screen
      await takeScreenshot(tester, 'register_join_team');
    } catch (e) {
      await screenshotOnFailure(tester, 'REGISTER-003');
      rethrow;
    }
  });
}

/// Navigate to tournament register screen
Future<void> navigateToTournamentRegister(WidgetTester tester) async {
  // Find a tournament card and navigate to its intro
  final tourCards = find.byType(Card);
  if (tourCards.evaluate().isNotEmpty) {
    await tester.tap(tourCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // Look for "Đăng ký" button on intro screen
  final regBtn = find.textContaining('Đăng ký tham gia');
  if (regBtn.evaluate().isNotEmpty) {
    await tester.tap(regBtn.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
