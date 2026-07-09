// Tests for AppNotification icon/color/timeAgo computed properties
// Covers: NOTIFICATION-015, 016

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';

void main() {
  group('AppNotification icon mapping', () {
    test('TOURNAMENT types return emoji_events icon', () {
      for (final type in [
        'TOURNAMENT', 'TOURNAMENT_REGISTER_PENDING',
        'TOURNAMENT_REGISTER_SUCCESS', 'TOURNAMENT_REGISTER_REJECTED',
        'TOURNAMENT_PARTICIPANT_NEW', 'TOURNAMENT_WITHDRAWN', 'TOURNAMENT_KICKED',
      ]) {
        final n = AppNotification(id: '1', type: type, title: 'T', createdAt: DateTime.now());
        expect(n.icon, Icons.emoji_events_rounded);
        expect(n.color, const Color(0xFFF59E0B));
      }
    });

    test('MATCH types return sports_tennis icon', () {
      for (final type in ['MATCH', 'MATCH_SCHEDULED', 'MATCH_COMPLETED']) {
        final n = AppNotification(id: '1', type: type, title: 'T', createdAt: DateTime.now());
        expect(n.icon, Icons.sports_tennis_rounded);
        expect(n.color, const Color(0xFF2979FF));
      }
    });

    test('PAYMENT types return payments icon', () {
      for (final type in ['PAYMENT', 'PAYOUT_APPROVED', 'PAYOUT_REJECTED']) {
        final n = AppNotification(id: '1', type: type, title: 'T', createdAt: DateTime.now());
        expect(n.icon, Icons.payments_rounded);
        expect(n.color, const Color(0xFF10B981));
      }
    });

    test('CHAT returns chat icon', () {
      final n = AppNotification(id: '1', type: 'CHAT', title: 'T', createdAt: DateTime.now());
      expect(n.icon, Icons.chat_rounded);
      expect(n.color, const Color(0xFF8B5CF6));
    });

    test('REMINDER returns notifications icon', () {
      final n = AppNotification(id: '1', type: 'REMINDER', title: 'T', createdAt: DateTime.now());
      expect(n.icon, Icons.notifications_rounded);
      expect(n.color, const Color(0xFF64748B));
    });

    test('unknown type returns notifications_outlined', () {
      final n = AppNotification(id: '1', type: 'UNKNOWN', title: 'T', createdAt: DateTime.now());
      expect(n.icon, Icons.notifications_outlined);
      expect(n.color, const Color(0xFF64748B));
    });
  });

  group('AppNotification timeAgo', () {
    test('returns "Vừa xong" for < 1 min', () {
      final n = AppNotification(id: '1', type: 'T', title: 'T',
          createdAt: DateTime.now().subtract(const Duration(seconds: 30)));
      expect(n.timeAgo, 'Vừa xong');
    });

    test('returns "X phút trước" for < 60 min', () {
      final n = AppNotification(id: '1', type: 'T', title: 'T',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)));
      expect(n.timeAgo, '5 phút trước');
    });

    test('returns "X giờ trước" for < 24h', () {
      final n = AppNotification(id: '1', type: 'T', title: 'T',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)));
      expect(n.timeAgo, '3 giờ trước');
    });

    test('returns "X ngày trước" for < 7 days', () {
      final n = AppNotification(id: '1', type: 'T', title: 'T',
          createdAt: DateTime.now().subtract(const Duration(days: 2)));
      expect(n.timeAgo, '2 ngày trước');
    });

    test('returns date for 7+ days', () {
      final d = DateTime(2026, 6, 1);
      final n = AppNotification(id: '1', type: 'T', title: 'T', createdAt: d);
      expect(n.timeAgo, '1/6/2026');
    });
  });
}
