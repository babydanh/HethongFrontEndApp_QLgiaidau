import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/features/social/models/activity_feed_item.dart';

void main() {
  test('maps club activity to the same feed shape used by web', () {
    final item = ActivityFeedItem.fromClubJson({
      'id': 'session-1',
      'type': 'CLUB_RECRUITING',
      'sport': 'pickleball',
      'sportTier': 'Mọi trình độ',
      'playDate': '2026-09-20',
      'startTime': '2026-09-20T08:30:00+07:00',
      'endTime': '2026-09-20T10:30:00+07:00',
      'location': 'Sân A',
      'title': 'Giao lưu cuối tuần',
      'description': '<p>Đăng ký <b>slot</b></p>',
      'community': {'id': 'club-1', 'name': 'CLB A', 'logoUrl': null},
      'host': {'id': 'u-1', 'name': 'Host'},
      'clubMatchSessionId': 'match-1',
      'slots': {
        'current': 2,
        'max': 8,
        'feePerSlot': 50000,
        'joinedPlayers': [
          {'userId': 'u-2', 'name': 'Minh'},
        ],
      },
    });

    expect(item.type, ActivityFeedType.clubRecruiting);
    expect(item.playDate, '2026-09-20');
    expect(item.startTime, '08:30');
    expect(item.description, 'Đăng ký slot');
    expect(item.slots?.current, 2);
    expect(item.feeLabel, '50.000đ/slot');
  });

  test('maps personal pickup time-only values and participation state', () {
    final item = ActivityFeedItem.fromPersonalJson({
      'id': 'pickup-1',
      'type': 'PERSONAL_PICKUP',
      'title': 'Tìm người đánh đôi',
      'playDate': '2026-09-21',
      'startTime': '18:00',
      'endTime': '20:00',
      'location': 'Quận 3',
      'sport': 'Tennis',
      'sportTier': 'Trình 3.0',
      'feePerSlot': 100000,
      'maxSlots': 4,
      'currentSlots': 1,
      'isJoined': true,
      'personalHost': {'id': 'u-1', 'name': 'An'},
      'joinedPlayers': [],
    });

    expect(item.type, ActivityFeedType.personalPickup);
    expect(item.playDate, '2026-09-21');
    expect(item.startTime, '18:00');
    expect(item.endTime, '20:00');
    expect(item.isJoined, isTrue);
    expect(item.slots?.max, 4);
  });
}
