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

  test('TC-CHAT-UI-A-01 NOT_REGISTERED reply maps by registrationOpen', () {
    TournamentChatRoom of(Map<String, dynamic> extra) =>
        TournamentChatRoom.fromJson({
          'available': false,
          'reason': 'NOT_REGISTERED',
          ...extra,
        });
    final open = of({'registrationOpen': true});
    expect(open.state, TournamentChatState.needsRegistration);
    expect(open.registrationOpen, isTrue);
    expect(
      of({'registrationOpen': false}).state,
      TournamentChatState.registrationClosed,
    );
    // Missing flag: assume registration is still open.
    expect(of({}).state, TournamentChatState.needsRegistration);
  });

  test('TC-CHAT-UI-A-02 registration, name and logoUrl are parsed', () {
    final room = TournamentChatRoom.fromJson({
      'available': true,
      'roomId': 'r1',
      'status': 'OPEN',
      'canWrite': false,
      'role': 'MEMBER',
      'registration': 'PENDING',
      'name': 'Chat Cup',
      'logoUrl': 'https://cdn.example.test/logo.png',
    });
    expect(room.state, TournamentChatState.pending);
    expect(room.registration, 'PENDING');
    expect(room.name, 'Chat Cup');
    expect(room.logoUrl, 'https://cdn.example.test/logo.png');
    expect(room.canWrite, isFalse);

    final approved = TournamentChatRoom.fromJson({
      'available': true,
      'roomId': 'r1',
      'status': 'OPEN',
      'canWrite': true,
      'registration': 'APPROVED',
      'logoUrl': null,
    });
    expect(approved.state, TournamentChatState.open);
    expect(approved.logoUrl, isNull);
  });

  test('TC-CHAT-UI-A-03 old payloads without the new fields still parse', () {
    final room = TournamentChatRoom.fromJson({
      'available': true,
      'roomId': 'r1',
      'status': 'OPEN',
      'canWrite': true,
      'role': 'MEMBER',
    });
    expect(room.state, TournamentChatState.open);
    expect(room.registration, isNull);
    expect(room.name, isNull);
    expect(room.logoUrl, isNull);
    expect(room.registrationOpen, isNull);
  });

  test('TC-CHAT-UI-M-01 canModerate is parsed; admin moderates without ORGANIZER', () {
    final admin = TournamentChatRoom.fromJson({
      'available': true,
      'roomId': 'r1',
      'status': 'OPEN',
      'canWrite': true,
      'role': 'MEMBER',
      'registration': 'STAFF',
      'canModerate': true,
    });
    expect(admin.canModerate, isTrue);
    expect(admin.isOrganizer, isFalse);

    final member = TournamentChatRoom.fromJson({
      'available': true,
      'roomId': 'r1',
      'role': 'MEMBER',
      'canModerate': false,
    });
    expect(member.canModerate, isFalse);
  });

  test('TC-CHAT-UI-M-01 old server without canModerate falls back to ORGANIZER role', () {
    TournamentChatRoom of(String role) => TournamentChatRoom.fromJson({
      'available': true,
      'roomId': 'r1',
      'role': role,
    });
    expect(of('ORGANIZER').canModerate, isTrue);
    expect(of('MEMBER').canModerate, isFalse);
  });
}
