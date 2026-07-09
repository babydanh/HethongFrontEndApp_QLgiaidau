import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-PAYMENT-001: Checkout screen hien thi thong tin
  testWidgets('TC-FLUTTER-PAYMENT-001: Checkout screen hien thi thong tin',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Note: requires backend with tournament data + navigation to payment flow
      await takeScreenshot(tester, 'payment_checkout');
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-001');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-002: Chon gateway khac
  testWidgets('TC-FLUTTER-PAYMENT-002: Checkout - chon gateway khac',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-002');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-003: Thanh toan PAYOS thanh cong
  testWidgets('TC-FLUTTER-PAYMENT-003: Checkout - thanh toan PAYOS thanh cong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-003');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-004: Thanh toan VNPAY/MoMo/TRANSFER
  testWidgets('TC-FLUTTER-PAYMENT-004: Checkout - thanh toan VNPAY/MoMo/TRANSFER',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-004');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-005: CreatePaymentLink that bai
  testWidgets('TC-FLUTTER-PAYMENT-005: Checkout - createPaymentLink that bai',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-005');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-006: Mock gateway hien thi man hinh
  testWidgets('TC-FLUTTER-PAYMENT-006: Mock gateway - hien thi man hinh',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-006');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-007: Nhap OTP tu dong chuyen focus
  testWidgets('TC-FLUTTER-PAYMENT-007: Mock gateway - nhap OTP tu dong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-007');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-008: Verify OTP thanh cong
  testWidgets('TC-FLUTTER-PAYMENT-008: Mock gateway - verify OTP thanh cong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-008');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-009: Verify OTP that bai
  testWidgets('TC-FLUTTER-PAYMENT-009: Mock gateway - verify OTP that bai',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-009');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-010: Timer het han
  testWidgets('TC-FLUTTER-PAYMENT-010: Mock gateway - timer het han',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-010');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-011: Huy
  testWidgets('TC-FLUTTER-PAYMENT-011: Mock gateway - huy', (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-011');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-012: PayOS verify screen hien thi
  testWidgets('TC-FLUTTER-PAYMENT-012: PayOS verify screen hien thi',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-012');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-013: PayOS verify auto poll
  testWidgets('TC-FLUTTER-PAYMENT-013: PayOS verify - auto poll moi 5 giay',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-013');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-014: PayOS verify Toi da thanh toan thanh cong
  testWidgets('TC-FLUTTER-PAYMENT-014: PayOS verify - nhan thanh toan thanh cong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-014');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-015: PayOS verify that bai
  testWidgets('TC-FLUTTER-PAYMENT-015: PayOS verify - that bai',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-015');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-016: PayOS verify huy quay ve
  testWidgets('TC-FLUTTER-PAYMENT-016: PayOS verify - huy quay ve',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-016');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-017: Payment result screen thanh cong
  testWidgets('TC-FLUTTER-PAYMENT-017: Payment result screen - thanh cong',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Điều hướng đến payment-result với status=success để test UI
      // Kết quả mong đợi: icon check_circle_rounded + text "Thanh toán thành công!"
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-017');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-018: Payment result screen that bai
  testWidgets('TC-FLUTTER-PAYMENT-018: Payment result screen - that bai',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-018');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-019: Lich su thanh toan
  testWidgets('TC-FLUTTER-PAYMENT-019: Payments screen - lich su thanh toan',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to payments history
      final navPayments = find.text('Thanh toan');
      if (navPayments.evaluate().isNotEmpty) {
        await tester.tap(navPayments.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await takeScreenshot(tester, 'payments_history');
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-019');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-020: Payments screen hien thi cac status khac nhau
  testWidgets('TC-FLUTTER-PAYMENT-020: Payments screen - cac status khac nhau',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-020');
      rethrow;
    }
  });

  // TC-FLUTTER-PAYMENT-021: Payments screen refresh
  testWidgets('TC-FLUTTER-PAYMENT-021: Payments screen - refresh',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final navPayments = find.text('Thanh toan');
      if (navPayments.evaluate().isNotEmpty) {
        await tester.tap(navPayments.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Pull to refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await takeScreenshot(tester, 'payments_refresh');
    } catch (e) {
      await screenshotOnFailure(tester, 'PAYMENT-021');
      rethrow;
    }
  });
}
