import 'dart:typed_data';

import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_club_match_session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

/// Serves one list route page by page, keyed by the request cursor.
class _PagedAdapter extends FakeApiAdapter {
  _PagedAdapter(this.route, this.pages) : super({});

  final String route;
  final Map<Object?, FakeReply> pages;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    routes[route] =
        pages[options.queryParameters['cursor']] ??
        const FakeReply(200, {'data': <dynamic>[]});
    return super.fetch(options, requestStream, cancelFuture);
  }
}

(ApiClubMatchSessionRepository, FakeApiAdapter) _setup(
  Map<String, FakeReply> routes,
) {
  final adapter = FakeApiAdapter(routes);
  return (ApiClubMatchSessionRepository(fakeDioClient(adapter)), adapter);
}

Map<String, dynamic> _session(String id) => {
  'id': id,
  'communityId': 'c1',
  'name': 'Buổi $id',
  'version': 3,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('cursor paging', () {
    test(
      'listPage returns the safe next cursor only when hasMore is true',
      () async {
        final (repo, adapter) = _setup({
          'GET /club-match-sessions': FakeReply(200, {
            'data': [_session('s1'), 'junk'],
            'meta': {'hasMore': true, 'nextCursor': 'n2'},
          }),
        });

        final page = await repo.listPage('c1', cursor: 'n1', limit: 3);

        expect(page.data.map((s) => s.id), ['s1']);
        expect(page.nextCursor, 'n2');
        expect(page.hasMore, isTrue);
        expect(adapter.requests.single.query, {
          'communityId': 'c1',
          'limit': 3,
          'cursor': 'n1',
        });
      },
    );

    test('a repeated cursor or hasMore=false ends the paging', () async {
      final (repeat, _) = _setup({
        'GET /club-match-sessions': const FakeReply(200, {
          'data': <dynamic>[],
          'meta': {'hasMore': true, 'nextCursor': 'same'},
        }),
      });
      final (done, _) = _setup({
        'GET /club-match-sessions': const FakeReply(200, {
          'data': <dynamic>[],
          'meta': {'hasMore': false, 'nextCursor': 'more'},
        }),
      });

      final a = await repeat.listPage('c1', cursor: 'same');
      final b = await done.listPage('c1');

      expect(a.hasMore, isFalse);
      expect(a.nextCursor, isNull);
      expect(b.hasMore, isFalse);
      expect(b.nextCursor, isNull);
    });

    test('a body without data/meta yields an empty page', () async {
      final (repo, _) = _setup({
        'GET /club-match-sessions': const FakeReply(200, 'oops'),
      });

      final page = await repo.listPage('c1');

      expect(page.data, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('list walks every page until the cursor runs out', () async {
      final adapter = _PagedAdapter('GET /club-match-sessions', {
        null: FakeReply(200, {
          'data': [_session('s1')],
          'meta': {'hasMore': true, 'nextCursor': 'c2'},
        }),
        'c2': FakeReply(200, {
          'data': [_session('s2')],
          'meta': {'hasMore': false},
        }),
      });
      final repo = ApiClubMatchSessionRepository(fakeDioClient(adapter));

      final sessions = await repo.list('c1');

      expect(sessions.map((s) => s.id), ['s1', 's2']);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.query['cursor'], 'c2');
    });

    test(
      'participants ask for ACTIVE ones and match lists page through',
      () async {
        final (repo, adapter) = _setup({
          'GET /club-match-sessions/s1/participants': const FakeReply(200, {
            'data': [
              {
                'participant': {'id': 'p1', 'userId': 'u1'},
                'fullName': 'An',
              },
            ],
          }),
          'GET /club-match-sessions/s1/matches': const FakeReply(200, {
            'data': [
              {'id': 'm1'},
            ],
          }),
        });

        final participants = await repo.participants('s1');
        final matches = await repo.matches('s1');
        final matchPage = await repo.matchesPage('s1', cursor: 'c', limit: 5);

        expect(participants.single.displayName, 'An');
        expect(matches.single.id, 'm1');
        expect(matchPage.data.single.id, 'm1');
        expect(adapter.requests[0].query['status'], 'ACTIVE');
        expect(adapter.requests[2].query, {'limit': 5, 'cursor': 'c'});
      },
    );
  });

  group('session read and create', () {
    test('get unwraps data or reads a bare session', () async {
      final (repo, _) = _setup({
        'GET /club-match-sessions/s1': FakeReply(200, {'data': _session('s1')}),
        'GET /club-match-sessions/s2': FakeReply(200, _session('s2')),
      });

      expect((await repo.get('s1')).resolvedName, 'Buổi s1');
      expect((await repo.get('s2')).id, 's2');
      await expectLater(repo.get('missing'), throwsA(isA<DioException>()));
    });

    test('create sends only meaningful fields for a one-off session', () async {
      final (repo, adapter) = _setup({
        'POST /club-match-sessions': FakeReply(201, {'data': _session('new')}),
      });

      final created = await repo.create(
        communityId: 'c1',
        name: '  Giao lưu  ',
        description: '   ',
        registrationMode: 'OPEN',
        isRanked: true,
        startAt: DateTime.utc(2026, 6, 1, 10),
      );

      expect(created.id, 'new');
      expect(adapter.requests.single.body, {
        'communityId': 'c1',
        'name': 'Giao lưu',
        'registrationMode': 'OPEN',
        'isRanked': true,
        'maxParticipants': 16,
        'startAt': '2026-06-01T10:00:00.000Z',
        'isRecurring': false,
      });
    });

    test('a recurring session adds its schedule fields', () async {
      final (repo, adapter) = _setup({
        'POST /club-match-sessions': FakeReply(201, {'data': _session('new')}),
      });

      await repo.create(
        communityId: 'c1',
        registrationMode: 'MIXED',
        isRanked: false,
        isRecurring: true,
        recurringDaysOfWeek: const [2, 4],
      );

      final body = adapter.requests.single.body!;
      expect(body['isRecurring'], isTrue);
      expect(body['recurringFrequency'], 'WEEKLY');
      expect(body['recurringDaysOfWeek'], [2, 4]);
      expect(body['recurringTimeOfDay'], '18:00');
      expect(body['recurringAdvanceDays'], 3);
      expect(body.containsKey('name'), isFalse);
    });
  });

  group('standalone matches', () {
    test('the owner is exactly one of community or social session', () async {
      final (repo, adapter) = _setup({
        'GET /club-match-sessions/standalone-matches': const FakeReply(200, {
          'data': <dynamic>[],
        }),
      });

      await repo.standaloneMatches('c1');
      await repo.standaloneMatches(null, socialSessionId: 's9');
      await repo.standaloneMatchesPage('c1', cursor: 'x');

      expect(adapter.requests[0].query['communityId'], 'c1');
      expect(adapter.requests[1].query['socialSessionId'], 's9');
      expect(adapter.requests[1].query.containsKey('communityId'), isFalse);
      expect(adapter.requests[2].query['cursor'], 'x');
      await expectLater(repo.standaloneMatches(null), throwsArgumentError);
      await expectLater(
        repo.standaloneMatches('c1', socialSessionId: 's1'),
        throwsArgumentError,
      );
    });

    test('createStandaloneMatch sends the owner, sides, idempotency key and '
        'reads a nested match', () async {
      final (repo, adapter) = _setup({
        'POST /club-match-sessions/standalone-matches': const FakeReply(201, {
          'data': {
            'match': {'id': 'm7'},
          },
        }),
      });

      final match = await repo.createStandaloneMatch(
        communityId: 'c1',
        sideA: const ['a1', 'a2'],
        sideB: const ['b1', 'b2'],
        key: 'key-1',
        isRanked: false,
        matchType: 'DOUBLES',
      );

      expect(match.id, 'm7');
      expect(adapter.requests.single.body, {
        'communityId': 'c1',
        'sideAUserIds': ['a1', 'a2'],
        'sideBUserIds': ['b1', 'b2'],
        'isRanked': false,
        'matchType': 'DOUBLES',
      });
      expect(adapter.requests.single.headers['Idempotency-Key'], 'key-1');
    });

    test(
      'createStandaloneMatch accepts a flat payload and omits matchType',
      () async {
        final (repo, adapter) = _setup({
          'POST /club-match-sessions/standalone-matches': const FakeReply(201, {
            'data': {'id': 'm8'},
          }),
        });

        final match = await repo.createStandaloneMatch(
          socialSessionId: 's1',
          sideA: const ['a'],
          sideB: const ['b'],
          key: 'k',
          isRanked: true,
        );

        expect(match.id, 'm8');
        expect(adapter.requests.single.body!.containsKey('matchType'), isFalse);
        expect(adapter.requests.single.body!['socialSessionId'], 's1');
      },
    );

    test(
      'createStandaloneMatch needs an owner before it calls the network',
      () async {
        final (repo, adapter) = _setup({});

        await expectLater(
          repo.createStandaloneMatch(
            sideA: const [],
            sideB: const [],
            key: 'k',
            isRanked: true,
          ),
          throwsArgumentError,
        );
        expect(adapter.requests, isEmpty);
      },
    );

    test('deleteStandaloneMatch calls DELETE', () async {
      final (repo, adapter) = _setup({
        'DELETE /club-match-sessions/standalone-matches/m1': const FakeReply(
          204,
          {},
        ),
      });

      await repo.deleteStandaloneMatch('m1');

      expect(adapter.requests.single.method, 'DELETE');
    });
  });

  group('participation and match actions', () {
    test('join, withdraw, remove, transition, force, mock and preferences use '
        'the documented routes and payloads', () async {
      final (repo, adapter) = _setup({
        'POST /club-match-sessions/s1/participants/self': const FakeReply(
          200,
          {},
        ),
        'POST /club-match-sessions/s1/participants/self/withdraw':
            const FakeReply(200, {}),
        'PATCH /club-match-sessions/s1/participants/u1/remove': const FakeReply(
          200,
          {},
        ),
        'POST /club-match-sessions/s1/transition': const FakeReply(200, {}),
        'POST /club-match-sessions/s1/participants/force': const FakeReply(
          200,
          {},
        ),
        'POST /club-match-sessions/s1/participants/mock': const FakeReply(
          200,
          {},
        ),
        'PATCH /club-match-sessions/s1/preferences/me': const FakeReply(
          200,
          {},
        ),
      });

      await repo.selfJoin('s1');
      await repo.withdraw('s1');
      await repo.removeParticipant('s1', 'u1', 4);
      await repo.transition('s1', 'START', 5);
      await repo.forceParticipants('s1', const ['u2'], 'force-key');
      await repo.createMockParticipant('s1', 'VĐV ảo');
      await repo.updatePreferences(
        's1',
        preferredPartners: const ['p'],
        preferredOpponents: const ['o'],
        avoidedPlayers: const ['x'],
        version: 6,
      );

      final bodies = adapter.requests.map((r) => r.body).toList();
      expect(bodies[0], isNull);
      expect(bodies[2], {'version': 4});
      expect(bodies[3], {'action': 'START', 'version': 5});
      expect(bodies[4], {
        'userIds': ['u2'],
      });
      expect(adapter.requests[4].headers['Idempotency-Key'], 'force-key');
      expect(bodies[5], {'name': 'VĐV ảo'});
      expect(bodies[6], {
        'preferredPartnerUserIds': ['p'],
        'preferredOpponentUserIds': ['o'],
        'avoidUserIds': ['x'],
        'version': 6,
      });
    });

    test('createMatch sends sides, warnings flag and the key; matchType only '
        'when given', () async {
      final (repo, adapter) = _setup({
        'POST /club-match-sessions/s1/matches': const FakeReply(201, {}),
      });

      await repo.createMatch('s1', const ['a'], const ['b'], 'k1');
      await repo.createMatch(
        's1',
        const ['a'],
        const ['b'],
        'k2',
        matchType: 'SINGLES',
        confirmWarnings: true,
      );

      expect(adapter.requests[0].body, {
        'sideAUserIds': ['a'],
        'sideBUserIds': ['b'],
        'confirmWarnings': false,
      });
      expect(adapter.requests[1].body!['matchType'], 'SINGLES');
      expect(adapter.requests[1].body!['confirmWarnings'], isTrue);
      expect(adapter.requests[1].headers['Idempotency-Key'], 'k2');
    });

    test('updateScore patches progress or posts the completion with the '
        'expected revision', () async {
      final (repo, adapter) = _setup({
        'PATCH /club-match-sessions/matches/m1/score': const FakeReply(200, {}),
        'POST /club-match-sessions/matches/m1/complete': const FakeReply(
          200,
          {},
        ),
      });
      final match = ClubSessionMatchModel.fromJson({
        'id': 'm1',
        'revision': 4,
        'scoreDetails': {'sets': []},
      });

      await repo.updateScore(match, 1, 0);
      await repo.updateScore(match, 2, 1, complete: true);

      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'PATCH /club-match-sessions/matches/m1/score',
        'POST /club-match-sessions/matches/m1/complete',
      ]);
      expect(adapter.requests[0].body, {
        'p1SetsWon': 1,
        'p2SetsWon': 0,
        'expectedRevision': 4,
        'scoreDetails': {'sets': []},
      });
      expect(adapter.requests[1].body!['p1SetsWon'], 2);
      expect(adapter.requests[1].body!['expectedRevision'], 4);
    });
  });
}
