import 'package:app_quanly_giaidau/data/models/social_bracket_model.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_social_session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

(ApiSocialSessionRepository, FakeApiAdapter) _setup(
  Map<String, FakeReply> routes,
) {
  final adapter = FakeApiAdapter(routes);
  return (ApiSocialSessionRepository(fakeDioClient(adapter)), adapter);
}

Map<String, dynamic> _session(String id) => {
  'id': id,
  'title': 'Kèo $id',
  'startAt': '2026-06-01T10:00:00Z',
};

CreateSocialSessionRequest _request({String title = 'Kèo tối'}) =>
    CreateSocialSessionRequest(
      sport: 'pickleball',
      title: title,
      startAt: DateTime.utc(2026, 6, 1, 10),
      venueName: 'Sân A',
      venueAddress: '1 Lê Lợi',
      latitude: 10.1,
      longitude: 106.2,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('SocialApiException.fromDioException', () {
    SocialApiException fromReply(int status, Map<String, dynamic> body) {
      final options = RequestOptions(path: '/x');
      return SocialApiException.fromDioException(
        DioException.badResponse(
          statusCode: status,
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: status,
            data: body,
          ),
        ),
      );
    }

    test('maps known backend codes to Vietnamese messages', () {
      expect(
        fromReply(409, {'code': 'SESSION_FULL', 'message': 'raw'}).message,
        'Kèo đã đủ người',
      );
      expect(
        fromReply(409, {'code': 'ALREADY_JOINED'}).message,
        'Bạn đã tham gia kèo này',
      );
      expect(
        fromReply(400, {'code': 'INVALID_START_AT'}).message,
        fromReply(400, {'code': 'INVALID_DATE'}).message,
      );
    });

    test('keeps code, status and details from the response', () {
      final error = fromReply(422, {
        'code': 'MAX_SLOTS_BELOW_CURRENT',
        'details': {'current': 5},
      });

      expect(error.code, 'MAX_SLOTS_BELOW_CURRENT');
      expect(error.statusCode, 422);
      expect(error.details, {'current': 5});
    });

    test('unknown code: 401 is a session-expired message', () {
      expect(
        fromReply(401, {'message': 'Unauthorized'}).message,
        'Phiên đăng nhập đã hết hạn, vui lòng thử lại',
      );
    });

    test('unknown code: 5xx prefers the server message, else a busy text', () {
      expect(fromReply(503, {'message': 'bảo trì'}).message, 'bảo trì');
      expect(
        fromReply(500, {'message': ''}).message,
        'Hệ thống đang bận, vui lòng thử lại sau',
      );
    });

    test('unknown code: 4xx shows the server message or a generic one', () {
      expect(fromReply(400, {'message': 'Sai dữ liệu'}).message, 'Sai dữ liệu');
      expect(
        fromReply(400, {}).message,
        'Đã có lỗi xảy ra, vui lòng thử lại sau',
      );
    });

    test('transport errors without a body become a network message', () {
      final error = SocialApiException.fromDioException(
        DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: RequestOptions(path: '/x'),
        ),
      );

      expect(error.message, 'Lỗi kết nối mạng, vui lòng kiểm tra đường truyền');
      expect(error.statusCode, isNull);
      expect(error.toString(), error.message);
    });
  });

  group('listByDate', () {
    test('builds the query: skips blank filters, "all" sport and no-geo',
        () async {
      final (repo, adapter) = _setup({
        'GET /social-sessions': FakeReply(200, {
          'data': [_session('a')],
          'meta': {'page': 2, 'limit': 10, 'total': 31},
        }),
      });

      final result = await repo.listByDate(
        date: '',
        sport: 'ALL',
        communityId: '',
        search: '  kèo  ',
        page: 2,
        limit: 10,
        lat: 10.5,
        sortBy: 'distance',
      );

      expect(result.items.single.id, 'a');
      expect(result.page, 2);
      expect(result.limit, 10);
      expect(result.total, 31);
      // lat without lng disables geo filtering entirely.
      expect(adapter.requests.single.query, {
        'page': 2,
        'limit': 10,
        'search': 'kèo',
      });
    });

    test('adds geo params when both coordinates are present', () async {
      final (repo, adapter) = _setup({
        'GET /social-sessions': const FakeReply(200, {'data': <dynamic>[]}),
      });

      await repo.listByDate(
        date: '2026-06-01',
        sport: 'tennis',
        communityId: 'c1',
        lat: 10.5,
        lng: 106.7,
        radiusKm: 5,
        sortBy: '',
      );

      expect(adapter.requests.single.query, {
        'date': '2026-06-01',
        'page': 1,
        'limit': 20,
        'sport': 'tennis',
        'communityId': 'c1',
        'lat': 10.5,
        'lng': 106.7,
        'radiusKm': 5.0,
      });
    });

    test('merges a sibling meta into an enveloped map payload', () async {
      final (repo, _) = _setup({
        'GET /social-sessions': FakeReply(200, {
          'data': {
            'items': [_session('a'), _session('b')],
          },
          'meta': {'total': 9},
        }),
      });

      final result = await repo.listByDate(date: '2026-06-01');

      expect(result.items, hasLength(2));
      expect(result.total, 9);
    });

    test('returns an empty list when offline but throws on an HTTP error',
        () async {
      final (offline, _) = _setup({
        'GET /social-sessions': const FakeReply.networkError(),
      });
      final (failing, _) = _setup({
        'GET /social-sessions': const FakeReply(500, {'message': 'boom'}),
      });

      final result = await offline.listByDate(date: '2026-06-01');

      expect(result.items, isEmpty);
      await expectLater(
        failing.listByDate(date: '2026-06-01'),
        throwsA(
          isA<SocialApiException>().having((e) => e.statusCode, 'status', 500),
        ),
      );
    });
  });

  group('listNearby', () {
    test('clamps limit and radius into the supported range', () async {
      final (repo, adapter) = _setup({
        'GET /social-sessions/nearby': FakeReply(200, {
          'data': {
            'items': [_session('n1')],
            'meta': {'page': 1, 'limit': 1, 'total': 3},
          },
        }),
      });

      final result = await repo.listNearby(
        lat: 1,
        lng: 2,
        radiusKm: 500,
        limit: 500,
      );
      await repo.listNearby(lat: 1, lng: 2, radiusKm: 0.1, limit: 0);

      expect(adapter.requests[0].query['limit'], 50);
      expect(adapter.requests[0].query['radiusKm'], 50);
      expect(adapter.requests[1].query['limit'], 1);
      expect(adapter.requests[1].query['radiusKm'], 0.5);
      expect(result.items.single.id, 'n1');
      expect(result.hasMore, isTrue);
    });

    test('wraps failures into SocialApiException', () async {
      final (repo, _) = _setup({});

      await expectLater(
        repo.listNearby(lat: 1, lng: 2),
        throwsA(isA<SocialApiException>()),
      );
    });
  });

  group('detail and writes', () {
    test('getDetail unwraps data or reads the bare body', () async {
      final (repo, _) = _setup({
        'GET /social-sessions/s1': FakeReply(200, {'data': _session('s1')}),
        'GET /social-sessions/s2': FakeReply(200, _session('s2')),
      });

      expect((await repo.getDetail('s1')).title, 'Kèo s1');
      expect((await repo.getDetail('s2')).title, 'Kèo s2');
      await expectLater(
        repo.getDetail('missing'),
        throwsA(isA<SocialApiException>()),
      );
    });

    test('create reuses one Idempotency-Key per payload until it succeeds',
        () async {
      final (repo, adapter) = _setup({
        'POST /social-sessions': FakeReply(201, {'data': _session('new')}),
      });
      final (flaky, flakyAdapter) = _setup({
        'POST /social-sessions': const FakeReply(500, {'message': 'x'}),
      });

      // A failed attempt keeps its key, so a retry of the same intent reuses it.
      for (var i = 0; i < 2; i++) {
        await expectLater(
          flaky.create(_request()),
          throwsA(isA<SocialApiException>()),
        );
      }
      await expectLater(
        flaky.create(_request(title: 'Khác')),
        throwsA(isA<SocialApiException>()),
      );

      final keys = flakyAdapter.requests
          .map((r) => r.headers['Idempotency-Key'])
          .toList();
      expect(keys[0], isNotNull);
      expect(keys[0], keys[1]);
      expect(keys[2], isNot(keys[0]));

      // A success drops the key, so the next identical request gets a new one.
      await repo.create(_request());
      await repo.create(_request());
      final okKeys = adapter.requests
          .map((r) => r.headers['Idempotency-Key'])
          .toList();
      expect(okKeys[0], isNot(okKeys[1]));
      expect(adapter.requests.first.body!['title'], 'Kèo tối');
    });

    test('update patches only the given fields and parses the result',
        () async {
      final (repo, adapter) = _setup({
        'PATCH /social-sessions/s1': FakeReply(200, {'data': _session('s1')}),
      });

      final updated = await repo.update('s1', {'title': 'Mới'});

      expect(updated.id, 's1');
      expect(adapter.requests.single.body, {'title': 'Mới'});
    });

    test('update, cancel and delete map errors to SocialApiException',
        () async {
      final (repo, _) = _setup({});

      await expectLater(
        repo.update('s1', {}),
        throwsA(isA<SocialApiException>()),
      );
      await expectLater(repo.cancel('s1'), throwsA(isA<SocialApiException>()));
      await expectLater(repo.delete('s1'), throwsA(isA<SocialApiException>()));
    });

    test('cancel PATCHes and delete DELETEs the session', () async {
      final (repo, adapter) = _setup({
        'PATCH /social-sessions/s1/cancel': const FakeReply(200, {}),
        'DELETE /social-sessions/s1': const FakeReply(200, {}),
      });

      await repo.cancel('s1');
      await repo.delete('s1');

      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'PATCH /social-sessions/s1/cancel',
        'DELETE /social-sessions/s1',
      ]);
    });
  });

  group('listByCommunity', () {
    test('trims status/search and skips blank range and "all" sport', () async {
      final (repo, adapter) = _setup({
        'GET /social-sessions/by-community/c1': FakeReply(200, {
          'data': [_session('a')],
        }),
      });

      final result = await repo.listByCommunity(
        communityId: 'c1',
        status: ' OPEN ',
        sport: 'all',
        search: '  ',
        from: '',
        to: '2026-07-01',
        lat: 1,
        lng: 2,
      );

      expect(result.items.single.id, 'a');
      expect(adapter.requests.single.query, {
        'page': 1,
        'limit': 20,
        'status': 'OPEN',
        'to': '2026-07-01',
        'lat': 1.0,
        'lng': 2.0,
      });
    });

    test('throws SocialApiException on failure', () async {
      final (repo, _) = _setup({});

      await expectLater(
        repo.listByCommunity(communityId: 'c1'),
        throwsA(isA<SocialApiException>()),
      );
    });
  });

  group('join requests', () {
    test('requestJoin sends ticketCount; approve/reject post without body',
        () async {
      final (repo, adapter) = _setup({
        'POST /social-sessions/s1/requests': const FakeReply(201, {}),
        'POST /social-sessions/s1/requests/p1/approve':
            const FakeReply(200, {}),
        'POST /social-sessions/s1/requests/p1/reject': const FakeReply(200, {}),
        'DELETE /social-sessions/s1/requests/self': const FakeReply(200, {}),
      });

      await repo.requestJoin('s1', ticketCount: 2);
      await repo.approveJoinRequest('s1', 'p1');
      await repo.rejectJoinRequest('s1', 'p1');
      await repo.withdrawJoinRequest('s1');

      expect(adapter.requests[0].body, {'ticketCount': 2});
      expect(adapter.requests[1].body, isNull);
      expect(adapter.requests.map((r) => r.method), [
        'POST',
        'POST',
        'POST',
        'DELETE',
      ]);
    });

    test('actions surface backend codes as SocialApiException', () async {
      final (repo, _) = _setup({
        'POST /social-sessions/s1/requests': const FakeReply(409, {
          'code': 'SESSION_FULL',
        }),
        'DELETE /social-sessions/s1/requests/self': const FakeReply(404, {
          'code': 'SESSION_NOT_FOUND',
        }),
      });

      await expectLater(
        repo.requestJoin('s1'),
        throwsA(
          isA<SocialApiException>().having(
            (e) => e.message,
            'message',
            'Kèo đã đủ người',
          ),
        ),
      );
      await expectLater(
        repo.withdrawJoinRequest('s1'),
        throwsA(
          isA<SocialApiException>().having(
            (e) => e.code,
            'code',
            'SESSION_NOT_FOUND',
          ),
        ),
      );
    });

    test('listJoinRequests walks every page, dedupes by id and keeps only '
        'requested rows', () async {
      // One static route answers both pages; total 51 > limit 50 forces page 2.
      final (repo, adapter) = _setup({
        'GET /social-sessions/s1/requests': const FakeReply(200, {
          'data': {
            'items': [
              {
                'participant': {'id': 'r1', 'status': 'REQUESTED'},
                'fullName': 'An',
              },
              {'id': 'r2', 'status': 'PENDING', 'fullName': 'Bình'},
              {'id': 'j1', 'status': 'JOINED'},
            ],
            'meta': {'total': 51},
          },
        }),
      });

      final result = await repo.listJoinRequests('s1');

      expect(adapter.requests.map((r) => r.query['page']), [1, 2]);
      expect(result.map((p) => p.id), ['r1', 'r2']);
      expect(result.first.fullName, 'An'); // merged from the wrapper row
    });

    test('listJoinRequests rejects malformed pages', () async {
      final (noMeta, _) = _setup({
        'GET /social-sessions/s1/requests': const FakeReply(200, {
          'data': {'items': <dynamic>[]},
        }),
      });
      final (noId, _) = _setup({
        'GET /social-sessions/s1/requests': const FakeReply(200, {
          'data': {
            'items': [
              {'status': 'REQUESTED'},
            ],
            'meta': {'total': 1},
          },
        }),
      });
      final (emptyButMore, _) = _setup({
        'GET /social-sessions/s1/requests': const FakeReply(200, {
          'data': {'items': <dynamic>[], 'meta': {'total': 99}},
        }),
      });

      await expectLater(
        noMeta.listJoinRequests('s1'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        noId.listJoinRequests('s1'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        emptyButMore.listJoinRequests('s1'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('messages and participants', () {
    test('getMessages reads data, items or messages and ignores junk',
        () async {
      final (repo, adapter) = _setup({
        'GET /social-sessions/s1/messages': const FakeReply(200, {
          'items': [
            {'id': 'm1', 'messageText': 'hi'},
            'junk',
          ],
        }),
        'GET /social-sessions/s2/messages': const FakeReply(200, {'data': 5}),
      });

      final messages = await repo.getMessages('s1', limit: 5);

      expect(messages, hasLength(1));
      expect(adapter.requests.single.query, {'limit': 5});
      expect(await repo.getMessages('s2'), isEmpty);
    });

    test('sendMessage trims the text', () async {
      final (repo, adapter) = _setup({
        'POST /social-sessions/s1/messages': const FakeReply(201, {}),
      });

      await repo.sendMessage('s1', '  chào  ');

      expect(adapter.requests.single.body, {'messageText': 'chào'});
    });

    test('join parses the response and defaults currentSlots/status',
        () async {
      final (repo, adapter) = _setup({
        'POST /social-sessions/s1/join': const FakeReply(200, {
          'data': {
            'ok': true,
            'currentSlots': 4,
            'status': 'FULL',
            'participant': {'id': 'p1', 'userId': 'u1'},
          },
        }),
        'POST /social-sessions/s2/join': const FakeReply(200, {'ok': true}),
      });

      final full = await repo.join('s1', ticketCount: 2);
      final bare = await repo.join('s2');

      expect(full.ok, isTrue);
      expect(full.currentSlots, 4);
      expect(full.status, 'FULL');
      expect(full.participant?.id, 'p1');
      expect(adapter.requests.first.body, {'ticketCount': 2});
      expect(bare.currentSlots, 1);
      expect(bare.status, 'OPEN');
      expect(bare.participant, isNull);
    });

    test('addParticipant and addGuestParticipant send different identities',
        () async {
      final (repo, adapter) = _setup({
        'POST /social-sessions/s1/participants': const FakeReply(201, {}),
      });

      await repo.addParticipant('s1', userId: 'u1', ticketCount: 2);
      await repo.addGuestParticipant('s1', guestName: '  Khách  ');

      expect(adapter.requests[0].body, {'userId': 'u1', 'ticketCount': 2});
      expect(adapter.requests[1].body, {'guestName': 'Khách', 'ticketCount': 1});
    });

    test('addParticipantsBatch parses added/skipped and falls back counts',
        () async {
      final (repo, adapter) = _setup({
        'POST /social-sessions/s1/participants/batch': const FakeReply(200, {
          'data': {
            'added': [
              {'id': 'p1', 'userId': 'u1'},
              'junk',
            ],
            'skipped': ['u2', 7],
          },
        }),
      });

      final result = await repo.addParticipantsBatch(
        's1',
        userIds: ['u1', 'u2'],
      );

      expect(result.added.single.id, 'p1');
      expect(result.skipped, ['u2', '7']);
      expect(result.currentSlots, 1); // falls back to the added count
      expect(result.status, 'OPEN');
      expect(adapter.requests.single.body, {
        'userIds': ['u1', 'u2'],
        'ticketCount': 1,
      });
    });

    test('removeParticipant and updatePaymentStatus call their routes',
        () async {
      final (repo, adapter) = _setup({
        'DELETE /social-sessions/s1/participants/u1': const FakeReply(200, {}),
        'PATCH /social-sessions/s1/participants/u1/payment':
            const FakeReply(200, {}),
      });

      await repo.removeParticipant('s1', 'u1');
      await repo.updatePaymentStatus('s1', 'u1', paymentStatus: 'PAID');

      expect(adapter.requests[1].body, {'paymentStatus': 'PAID'});
      await expectLater(
        repo.removeParticipant('s1', 'nope'),
        throwsA(isA<SocialApiException>()),
      );
      await expectLater(
        repo.updatePaymentStatus('s1', 'nope', paymentStatus: 'PAID'),
        throwsA(isA<SocialApiException>()),
      );
    });

    test('addParticipant, batch and join map backend failures', () async {
      final (repo, _) = _setup({
        'POST /social-sessions/s1/participants': const FakeReply(400, {
          'code': 'USER_OR_GUEST_REQUIRED',
        }),
      });

      await expectLater(
        repo.addGuestParticipant('s1', guestName: ''),
        throwsA(
          isA<SocialApiException>().having(
            (e) => e.message,
            'message',
            'Vui lòng nhập tên khách hoặc chọn thành viên',
          ),
        ),
      );
      await expectLater(
        repo.addParticipant('s1', userId: 'u'),
        throwsA(isA<SocialApiException>()),
      );
      await expectLater(
        repo.addParticipantsBatch('s1', userIds: ['u']),
        throwsA(isA<SocialApiException>()),
      );
      await expectLater(repo.join('s1'), throwsA(isA<SocialApiException>()));
      await expectLater(
        repo.sendMessage('s1', 'x'),
        throwsA(isA<SocialApiException>()),
      );
      await expectLater(
        repo.getMessages('s1'),
        throwsA(isA<SocialApiException>()),
      );
    });
  });

  group('createBracket', () {
    test('turns 409 SOCIAL_BRACKET_EXISTS into SocialBracketExistsException',
        () async {
      final (repo, _) = _setup({
        'POST /social-sessions/s1/bracket': const FakeReply(409, {
          'code': 'SOCIAL_BRACKET_EXISTS',
          'tournamentId': 't-old',
        }),
      });

      await expectLater(
        repo.createBracket(
          's1',
          bracketType: 'SINGLE_ELIMINATION',
          matchType: 'SINGLES',
          participantUserIds: ['u1', 'u2'],
        ),
        throwsA(isA<SocialBracketExistsException>()),
      );
    });

    test('a 409 without a tournamentId stays a normal SocialApiException',
        () async {
      final (repo, _) = _setup({
        'POST /social-sessions/s1/bracket': const FakeReply(409, {
          'code': 'SOCIAL_BRACKET_EXISTS',
          'message': 'đã có',
        }),
      });

      await expectLater(
        repo.createBracket(
          's1',
          bracketType: 'X',
          matchType: 'Y',
          participantUserIds: [],
        ),
        throwsA(isA<SocialApiException>()),
      );
    });
  });
}
