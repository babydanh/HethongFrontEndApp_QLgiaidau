import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
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
}
