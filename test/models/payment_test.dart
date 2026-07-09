// Tests for PaymentModel entity
// Covers: PAYMENT-001, PAYMENT-006, PAYMENT-019, PAYMENT-020

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';

void main() {
  group('TC-FLUTTER-PAYMENT-001: PaymentModel.fromJson', () {
    test('TC-FLUTTER-PAYMENT-001: should parse full payment JSON', () {
      final json = {
        'id': 'pay-1',
        'amount': '100000',
        'gateway': 'PAYOS',
        'paymentGateway': 'PAYOS',
        'status': 'COMPLETED',
        'tournamentId': 'tour-1',
        'tournamentName': 'Giai Cau Long',
        'tournament': {'name': 'Giai Cau Long'},
        'participantId': 'part-1',
        'transactionReference': 'GD-001',
        'createdAt': '2026-07-07T10:00:00Z',
        'updatedAt': '2026-07-07T10:05:00Z',
      };

      final payment = PaymentModel.fromJson(json);

      expect(payment.id, 'pay-1');
      expect(payment.amount, 100000.0);
      expect(payment.gateway, 'PAYOS');
      expect(payment.status, 'COMPLETED');
      expect(payment.tournamentName, 'Giai Cau Long');
      expect(payment.transactionReference, 'GD-001');
    });

    test('TC-FLUTTER-PAYMENT-020: should handle completed status', () {
      final p = PaymentModel.fromJson({
        'id': '1', 'amount': '50000', 'status': 'COMPLETED', 'gateway': 'MOMO',
        'createdAt': '2026-07-07T10:00:00Z',
      });
      expect(p.isCompleted, true);
      expect(p.isPending, false);
      expect(p.isFailed, false);
    });

    test('TC-FLUTTER-PAYMENT-020: should handle pending status', () {
      final p = PaymentModel.fromJson({
        'id': '1', 'amount': '50000', 'status': 'PENDING', 'gateway': 'VNPAY',
        'createdAt': '2026-07-07T10:00:00Z',
      });
      expect(p.isCompleted, false);
      expect(p.isPending, true);
      expect(p.isFailed, false);
    });

    test('TC-FLUTTER-PAYMENT-020: should handle failed status', () {
      final p = PaymentModel.fromJson({
        'id': '1', 'amount': '50000', 'status': 'FAILED', 'gateway': 'TRANSFER',
        'createdAt': '2026-07-07T10:00:00Z',
      });
      expect(p.isCompleted, false);
      expect(p.isPending, false);
      expect(p.isFailed, true);
    });

    test('TC-FLUTTER-PAYMENT-001: should fallback gateway from paymentGateway', () {
      final p = PaymentModel.fromJson({
        'id': '1', 'amount': '0', 'paymentGateway': 'MOMO',
        'createdAt': '2026-07-07T10:00:00Z',
      });
      expect(p.gateway, 'MOMO');
    });

    test('TC-FLUTTER-PAYMENT-001: should use defaults for missing fields', () {
      final p = PaymentModel.fromJson({
        'id': '', 'amount': '0',
        'createdAt': '2026-07-07T10:00:00Z',
      });
      expect(p.gateway, 'VNPAY');
      expect(p.status, 'PENDING');
      expect(p.tournamentName, null);
    });
  });
}
