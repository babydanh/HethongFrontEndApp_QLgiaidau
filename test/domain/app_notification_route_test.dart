import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('match notification route keeps tournament context', () {
    final notification = AppNotification(
      id: 'notification-1',
      type: 'MATCH_LIVE',
      title: 'Trận đang diễn ra',
      createdAt: DateTime(2026, 9, 6),
      data: const {'matchId': 'match-1', 'tournamentId': 'tournament-1'},
    );

    expect(notification.routeTarget, '/live/match-1?tournamentId=tournament-1');
  });

  test('TC-SLM-APP-08 stale-live notification opens the match', () {
    final notification = AppNotification(
      id: 'notification-2',
      type: 'MATCH_STALE_LIVE',
      title: 'Trận chưa cập nhật',
      createdAt: DateTime(2026, 11, 8),
      data: const {'matchId': 'match-2', 'tournamentId': 'tournament-1'},
    );

    expect(notification.routeTarget, '/live/match-2?tournamentId=tournament-1');
    expect(notification.icon, isNot(Icons.notifications_outlined));
  });

  for (final type in const ['REFEREE_ADDED', 'REFEREE_REMOVED']) {
    test('TC-APP-REF-ADD-03 $type opens the tournament, no invite actions', () {
      final notification = AppNotification(
        id: 'notification-$type',
        type: type,
        title: 'Trọng tài',
        createdAt: DateTime(2026, 11, 11),
        redirectUrl: '/tournaments/t1',
      );

      expect(notification.isInvite, isFalse);
      expect(notification.routeTarget, '/intro/t1');
      expect(notification.icon, Icons.sports_rounded);
    });
  }
}
