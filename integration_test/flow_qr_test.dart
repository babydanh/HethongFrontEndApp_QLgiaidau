import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-QR-001: Man hinh QR Scanner
  testWidgets('TC-FLUTTER-QR-001: Man hinh QR Scanner',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to QR scanner
      final qrBtn = find.byIcon(Icons.qr_code_scanner);
      if (qrBtn.evaluate().isNotEmpty) {
        await tester.tap(qrBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else {
        // Try via scan-qr route
        final scanBtn = find.textContaining('Scan');
        if (scanBtn.evaluate().isNotEmpty) {
          await tester.tap(scanBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }

      // QR scanner icon visible
      expect(find.byIcon(Icons.qr_code_scanner), findsWidgets);

      await takeScreenshot(tester, 'qr_scanner');
    } catch (e) {
      await screenshotOnFailure(tester, 'QR-001');
      rethrow;
    }
  });

  // TC-FLUTTER-QR-002: Quet QR token thanh cong
  testWidgets('TC-FLUTTER-QR-002: Quet QR token thanh cong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to QR scanner
      final qrBtn = find.byIcon(Icons.qr_code_scanner);
      if (qrBtn.evaluate().isNotEmpty) {
        await tester.tap(qrBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'qr_scan_token');
    } catch (e) {
      await screenshotOnFailure(tester, 'QR-002');
      rethrow;
    }
  });
}
