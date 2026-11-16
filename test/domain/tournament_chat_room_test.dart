import 'package:app_quanly_giaidau/domain/entities/tournament_chat_room.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-ROOM-A01 OPEN reply maps to an open, writable room', () {
    final room = TournamentChatRoom.fromJson({
      'available': true,
      'roomId': 'r1',
      'status': 'OPEN',
      'canWrite': true,
      'role': 'ORGANIZER',
      'closesAt': null,
      'purgeAt': null,
    });
    expect(room.state, TournamentChatState.open);
    expect(room.canWrite, isTrue);
    expect(room.isOrganizer, isTrue);
    expect(room.roomId, 'r1');
  });

  test('TC-ROOM-A01 CLOSED reply maps to a read-only room', () {
    final room = TournamentChatRoom.fromJson({
      'available': true,
      'roomId': 'r1',
      'status': 'CLOSED',
      'canWrite': false,
      'role': 'MEMBER',
      'closesAt': '2026-11-01T00:00:00.000Z',
      'purgeAt': '2027-11-01T00:00:00.000Z',
    });
    expect(room.state, TournamentChatState.closed);
    expect(room.canWrite, isFalse);
    expect(room.isOrganizer, isFalse);
    expect(room.purgeAt, DateTime.utc(2027, 11, 1));
  });

  test('TC-ROOM-A01 unavailable replies map by reason', () {
    TournamentChatState of(String? reason) => TournamentChatRoom.fromJson({
      'available': false,
      'reason': ?reason,
    }).state;
    expect(of('KICKED'), TournamentChatState.kicked);
    expect(of('PURGED'), TournamentChatState.purged);
    expect(of('UNAVAILABLE'), TournamentChatState.purged);
    expect(of(null), TournamentChatState.purged);
  });
}
