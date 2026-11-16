import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_chat_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

const _room = 'room-1';

(ApiTournamentChatRepository, FakeApiAdapter) _setup(
  Map<String, FakeReply> routes,
) {
  final adapter = FakeApiAdapter(routes);
  return (ApiTournamentChatRepository(fakeDioClient(adapter)), adapter);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test('TC-CHAT-UI-M-01 listParticipants parses items and the next cursor', () async {
    final (repo, adapter) = _setup({
      'GET /chat/rooms/$_room/participants': const FakeReply(200, {
        'data': {
          'items': [
            {
              'userId': 'u1',
              'fullName': 'An',
              'avatarUrl': null,
              'registration': 'APPROVED',
              'online': true,
              'kicked': false,
              'mutedUntil': '2026-11-16T11:00:00.000Z',
            },
            {'userId': 'u2', 'registration': 'PENDING'},
          ],
          'nextCursor': 'c2',
        },
      }),
    });

    final page = await repo.listParticipants(_room, cursor: 'c1');

    expect(adapter.requests.single.query, {'limit': 50, 'cursor': 'c1'});
    expect(page.nextCursor, 'c2');
    expect(page.items, hasLength(2));
    final an = page.items.first;
    expect(an.userId, 'u1');
    expect(an.fullName, 'An');
    expect(an.online, isTrue);
    expect(an.kicked, isFalse);
    expect(an.mutedUntil, DateTime.utc(2026, 11, 16, 11));
    expect(page.items.last.registration, 'PENDING');
    expect(page.items.last.online, isFalse);
    expect(page.items.last.mutedUntil, isNull);
  });

  test('TC-CHAT-UI-M-01 listKicks reads new and old field names', () async {
    final (repo, _) = _setup({
      'GET /chat/rooms/$_room/kicks': const FakeReply(200, {
        'data': [
          {
            'userId': 'u1',
            'fullName': 'An',
            'kickedByName': 'BTC Bình',
            'kickedAt': '2026-11-16T09:00:00.000Z',
          },
          {'userId': 'u2', 'kickedBy': 'x', 'createdAt': '2026-11-15T09:00:00.000Z'},
        ],
      }),
    });

    final kicks = await repo.listKicks(_room);

    expect(kicks.map((k) => k.userId), ['u1', 'u2']);
    expect(kicks.first.kickedByName, 'BTC Bình');
    expect(kicks.first.kickedAt, DateTime.utc(2026, 11, 16, 9));
    expect(kicks.last.kickedByName, isNull);
    expect(kicks.last.kickedAt, DateTime.utc(2026, 11, 15, 9));
  });

  test('TC-CHAT-UI-M-01 mute, unmute and settings hit the contract routes', () async {
    final (repo, adapter) = _setup({
      'POST /chat/rooms/$_room/mutes': const FakeReply(201, {'data': {}}),
      'DELETE /chat/rooms/$_room/mutes/u1': const FakeReply(200, {'data': {}}),
      'PATCH /chat/rooms/$_room/settings': const FakeReply(200, {'data': {}}),
    });

    await repo.muteUser(_room, 'u1', 60);
    await repo.unmuteUser(_room, 'u1');
    await repo.updateSettings(_room, slowModeSeconds: 10);
    await repo.updateSettings(_room, locked: true);

    final r = adapter.requests;
    expect(r[0].method, 'POST');
    expect(r[0].body, {'userId': 'u1', 'minutes': 60});
    expect(r[1].method, 'DELETE');
    expect(r[2].body, {'slowModeSeconds': 10});
    expect(r[3].body, {'locked': true});
  });
}
