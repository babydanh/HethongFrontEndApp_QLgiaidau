// Tests for AppNotification entity
// Covers: TC-FLUTTER-NOTIFICATION-014, 015, 016
// Status tracking: checked via test names for update-results.py

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';

void main() {
  group('TC-FLUTTER-NOTIFICATION-014: AppNotification.fromJson', () {
    test('should parse full JSON correctly', () {
      final json = {
        'id': 'notif-1',
        'type': 'MATCH',
        'title': 'Tran dau sap dien ra',
        'content': 'Noi dung chi tiet',
        'isRead': true,
        'redirectUrl': '/intro/tour-1',
        'createdAt': '2026-07-07T10:00:00Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, 'notif-1');
      expect(notification.type, 'MATCH');
      expect(notification.title, 'Tran dau sap dien ra');
      expect(notification.body, 'Noi dung chi tiet');
      expect(notification.isRead, true);
      expect(notification.redirectUrl, '/intro/tour-1');
      expect(notification.createdAt.isUtc, true);
      expect(notification.createdAt.year, 2026);
      expect(notification.createdAt.month, 7);
      expect(notification.createdAt.day, 7);
      expect(notification.createdAt.hour, 10);
    });

    test('should fallback body from content field', () {
      final json = {
        'id': '1',
        'type': 'SYSTEM',
        'title': 'Test',
        'content': 'Body text',
        'createdAt': '2026-07-07T10:00:00Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.body, 'Body text');
    });

    test('should read isRead from is_read fallback', () {
      final json = {
        'id': '1',
        'type': 'SYSTEM',
        'title': 'Test',
        'is_read': true,
        'createdAt': '2026-07-07T10:00:00Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.isRead, true);
    });

    test('should use defaults for missing fields', () {
      final json = {
        'id': '',
        'createdAt': '2026-07-07T10:00:00Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, '');
      expect(notification.type, 'SYSTEM');
      expect(notification.title, '');
      expect(notification.body, null);
      expect(notification.isRead, false);
      expect(notification.redirectUrl, null);
    });

    test('should handle null createdAt', () {
      final json = {
        'id': '1',
        'type': 'SYSTEM',
        'title': 'Test',
        'createdAt': null,
      };

      final notification = AppNotification.fromJson(json);

      // Should use DateTime.now() fallback — just verify it's a valid DateTime
      expect(notification.createdAt, isA<DateTime>());
    });
  });

  group('TC-FLUTTER-NOTIFICATION-015: AppNotification icon & color by type', () {
    test('TOURNAMENT types return emoji_events icon and gold color', () {
      const tournamentTypes = [
        'TOURNAMENT',
        'TOURNAMENT_REGISTER_PENDING',
        'TOURNAMENT_REGISTER_SUCCESS',
        'TOURNAMENT_REGISTER_REJECTED',
        'TOURNAMENT_PARTICIPANT_NEW',
        'TOURNAMENT_WITHDRAWN',
        'TOURNAMENT_KICKED',
      ];

      for (final type in tournamentTypes) {
        final notif = AppNotification(
          id: '1', type: type, title: 'Test', createdAt: DateTime.now(),
        );
        expect(notif.icon, Icons.emoji_events_rounded,
            reason: 'Type $type should have emoji_events icon');
        expect(notif.color, const Color(0xFFF59E0B),
            reason: 'Type $type should have gold color');
      }
    });

    test('MATCH types return sports_tennis icon and blue color', () {
      const matchTypes = ['MATCH', 'MATCH_SCHEDULED', 'MATCH_COMPLETED'];

      for (final type in matchTypes) {
        final notif = AppNotification(
          id: '1', type: type, title: 'Test', createdAt: DateTime.now(),
        );
        expect(notif.icon, Icons.sports_tennis_rounded);
        expect(notif.color, const Color(0xFF2979FF));
      }
    });

    test('PAYMENT types return payments icon and green color', () {
      const paymentTypes = ['PAYMENT', 'PAYOUT_APPROVED', 'PAYOUT_REJECTED'];

      for (final type in paymentTypes) {
        final notif = AppNotification(
          id: '1', type: type, title: 'Test', createdAt: DateTime.now(),
        );
        expect(notif.icon, Icons.payments_rounded);
        expect(notif.color, const Color(0xFF10B981));
      }
    });

    test('CHAT type returns chat icon and purple color', () {
      final notif = AppNotification(
        id: '1', type: 'CHAT', title: 'Test', createdAt: DateTime.now(),
      );
      expect(notif.icon, Icons.chat_rounded);
      expect(notif.color, const Color(0xFF8B5CF6));
    });

    test('REMINDER type returns notifications icon and gray color', () {
      final notif = AppNotification(
        id: '1', type: 'REMINDER', title: 'Test', createdAt: DateTime.now(),
      );
      expect(notif.icon, Icons.notifications_rounded);
      expect(notif.color, const Color(0xFF64748B));
    });

    test('unknown type defaults to notifications_outlined and gray', () {
      final notif = AppNotification(
        id: '1', type: 'UNKNOWN', title: 'Test', createdAt: DateTime.now(),
      );
      expect(notif.icon, Icons.notifications_outlined);
      expect(notif.color, const Color(0xFF64748B));
    });
  });

  group('TC-FLUTTER-NOTIFICATION-016: AppNotification.timeAgo', () {
    test('returns "Vua xong" for less than 1 minute', () {
      final notif = AppNotification(
        id: '1', type: 'SYSTEM', title: 'Test',
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(notif.timeAgo, 'Vừa xong');
    });

    test('returns "X phut truoc" for less than 60 minutes', () {
      final notif = AppNotification(
        id: '1', type: 'SYSTEM', title: 'Test',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(notif.timeAgo, '15 phút trước');
    });

    test('returns "X gio truoc" for less than 24 hours', () {
      final notif = AppNotification(
        id: '1', type: 'SYSTEM', title: 'Test',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(notif.timeAgo, '3 giờ trước');
    });

    test('returns "X ngay truoc" for less than 7 days', () {
      final notif = AppNotification(
        id: '1', type: 'SYSTEM', title: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(notif.timeAgo, '5 ngày trước');
    });

    test('returns date format for 7+ days', () {
      final date = DateTime(2026, 6, 1);
      final notif = AppNotification(
        id: '1', type: 'SYSTEM', title: 'Test',
        createdAt: date,
      );
      expect(notif.timeAgo, '1/6/2026');
    });
  });
}
