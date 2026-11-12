import 'package:app_quanly_giaidau/data/repositories/api/api_community_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

Map<String, dynamic> _club(
  String id, {
  String status = 'ACTIVE',
  String visibility = 'PUBLIC',
}) => {'id': id, 'name': 'CLB $id', 'status': status, 'visibility': visibility};

Map<String, dynamic> _tournament(String id, String name, String status) => {
  'id': id,
  'name': name,
  'status': status,
};

(ApiCommunityRepository, FakeApiAdapter) _setup(Map<String, FakeReply> routes) {
  final adapter = FakeApiAdapter(routes);
  return (ApiCommunityRepository(fakeDioClient(adapter)), adapter);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('getCommunities', () {
    test(
      'merges created+joined lists and hides non-ACTIVE and PRIVATE clubs',
      () async {
        final (repo, adapter) = _setup({
          'GET /communities': FakeReply(200, {
            'data': {
              'created': [_club('a'), _club('p', visibility: 'PRIVATE')],
              'joined': [
                _club('b', visibility: 'RESTRICTED'),
                _club('c', status: 'PENDING'),
              ],
            },
          }),
        });

        final result = await repo.getCommunities(
          search: 'abc',
          provinceCode: '',
        );

        expect(result.map((c) => c.id), ['a', 'b']);
        // Blank provinceCode must not be sent; non-blank search must.
        expect(adapter.requests.single.query, {'limit': 20, 'search': 'abc'});
      },
    );

    test('rethrows the DioException when the server answers 500', () async {
      final (repo, _) = _setup({
        'GET /communities': const FakeReply(500, {'message': 'boom'}),
      });

      await expectLater(repo.getCommunities(), throwsA(isA<DioException>()));
    });
  });

  group('getCommunitiesPaged', () {
    test(
      'reads items, meta cursor and total, and trims the search text',
      () async {
        final (repo, adapter) = _setup({
          'GET /communities': FakeReply(200, {
            'data': [_club('a'), _club('x', status: 'BANNED')],
            'meta': {'nextCursor': 'c2', 'hasMore': true, 'total': 40},
          }),
        });

        final page = await repo.getCommunitiesPaged(
          cursor: 'c1',
          search: '  vợt  ',
          categoryId: 'all',
          provinceCode: 'HCM',
        );

        expect(page.communities.map((c) => c.id), ['a']);
        expect(page.nextCursor, 'c2');
        expect(page.hasMore, isTrue);
        expect(page.total, 40);
        // categoryId "all" is a UI sentinel and must not reach the backend.
        expect(adapter.requests.single.query, {
          'limit': 6,
          'cursor': 'c1',
          'search': 'vợt',
          'provinceCode': 'HCM',
        });
      },
    );

    test(
      'treats a bare nextCursor as hasMore and falls back total to length',
      () async {
        final (repo, _) = _setup({
          'GET /communities': FakeReply(200, {
            'data': {
              'items': [_club('a'), _club('b')],
            },
            'nextCursor': 'zzz',
          }),
        });

        final page = await repo.getCommunitiesPaged(categoryId: 'cat-1');

        expect(page.communities, hasLength(2));
        expect(page.nextCursor, 'zzz');
        expect(page.hasMore, isTrue);
        expect(page.total, 2);
      },
    );

    test(
      'returns an empty page on error unless rethrowOnError is set',
      () async {
        final (repo, _) = _setup({
          'GET /communities': const FakeReply(500, {'message': 'boom'}),
        });

        final page = await repo.getCommunitiesPaged();
        expect(page.communities, isEmpty);
        expect(page.hasMore, isFalse);
        expect(page.total, 0);

        await expectLater(
          repo.getCommunitiesPaged(rethrowOnError: true),
          throwsA(isA<DioException>()),
        );
      },
    );
  });

  group('getMyCommunities / getCommunityById', () {
    test('getMyCommunities keeps every club (no status filter)', () async {
      final (repo, _) = _setup({
        'GET /communities/my': FakeReply(200, {
          'data': {
            'created': [_club('a', status: 'PENDING')],
            'joined': [_club('b', visibility: 'PRIVATE')],
          },
        }),
      });

      final result = await repo.getMyCommunities();

      expect(result.map((c) => c.id), ['a', 'b']);
    });

    test('getMyCommunities propagates a server error', () async {
      final (repo, _) = _setup({
        'GET /communities/my': const FakeReply(401, {'message': 'no'}),
      });

      await expectLater(repo.getMyCommunities(), throwsA(isA<DioException>()));
    });

    test('getCommunityById unwraps data and returns null on 404', () async {
      final (repo, _) = _setup({
        'GET /communities/c-1': FakeReply(200, {'data': _club('c-1')}),
      });

      expect((await repo.getCommunityById('c-1'))?.name, 'CLB c-1');
      expect(await repo.getCommunityById('missing'), isNull);
    });
  });

  group('members', () {
    test('getMembers sends only the filters that are set', () async {
      final (repo, adapter) = _setup({
        'GET /communities/c-1/members': const FakeReply(200, {
          'data': [
            {'id': 'm1', 'userId': 'u1', 'role': 'ADMIN'},
          ],
        }),
      });

      final members = await repo.getMembers(
        'c-1',
        status: 'JOINED',
        search: ' ann ',
        mentionableOnly: true,
      );
      await repo.getMembers('c-1', search: '   ');

      expect(members.single.role, 'ADMIN');
      expect(adapter.requests.first.query, {
        'limit': 50,
        'status': 'JOINED',
        'search': 'ann',
        'mentionable': true,
      });
      expect(adapter.requests.last.query, {'limit': 50});
    });

    test(
      'getMembersPaged exposes nextCursor only when hasMore is true',
      () async {
        final (repo, _) = _setup({
          'GET /communities/c-1/members': const FakeReply(200, {
            'data': [
              {'id': 'm1', 'userId': 'u1'},
              'not-a-map',
            ],
            'meta': {'nextCursor': 'n2', 'hasMore': true},
          }),
        });

        final page = await repo.getMembersPaged('c-1', cursor: 'n1');

        expect(page.items.single.userId, 'u1');
        expect(page.nextCursor, 'n2');
        expect(page.hasMore, isTrue);
      },
    );

    test('getMembersPaged stops when the cursor does not advance', () async {
      final (repo, _) = _setup({
        'GET /communities/c-1/members': const FakeReply(200, {
          'data': <dynamic>[],
          'meta': {'nextCursor': 'same', 'hasMore': true},
        }),
      });

      final page = await repo.getMembersPaged('c-1', cursor: 'same');

      expect(page.nextCursor, isNull);
      expect(page.hasMore, isFalse);
    });

    test('getMembersPaged tolerates a body without data/meta', () async {
      final (repo, _) = _setup({
        'GET /communities/c-1/members': const FakeReply(200, <dynamic>[]),
      });

      final page = await repo.getMembersPaged('c-1');

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  group('join / leave', () {
    test(
      'joinCommunity posts joinAnswers and defaults to an empty map',
      () async {
        final (repo, adapter) = _setup({
          'POST /communities/c-1/join': const FakeReply(201, {}),
        });

        expect(await repo.joinCommunity('c-1'), isTrue);
        expect(await repo.joinCommunity('c-1', answers: {'q': 'a'}), isTrue);

        final bodies = adapter.postsTo('/communities/c-1/join').toList();
        expect(bodies[0].body, {'joinAnswers': <String, dynamic>{}});
        expect(bodies[1].body, {
          'joinAnswers': {'q': 'a'},
        });
      },
    );

    test('joinCommunity surfaces the backend reason as an Exception', () async {
      final (repo, _) = _setup({
        'POST /communities/c-1/join': const FakeReply(403, {
          'message': 'Chỉ nhận thành viên qua lời mời riêng',
        }),
      });

      await expectLater(
        repo.joinCommunity('c-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('lời mời riêng'),
          ),
        ),
      );
    });

    test(
      'leaveCommunity returns true on success and false on failure',
      () async {
        final (repo, adapter) = _setup({
          'DELETE /communities/c-1/members/u-1': const FakeReply(204, {}),
        });

        expect(await repo.leaveCommunity('c-1', 'u-1'), isTrue);
        expect(await repo.leaveCommunity('c-1', 'u-2'), isFalse);
        expect(adapter.requests, hasLength(2));
      },
    );
  });

  group('tournaments', () {
    final routes = {
      'GET /communities/c-1/tournaments': FakeReply(200, {
        'data': [
          _tournament('t1', 'Cúp Mùa Xuân', 'OPEN'),
          _tournament('t2', 'Cúp Mùa Hè', 'ONGOING'),
          _tournament('t3', 'Giải Xuân Mới', 'OPEN'),
        ],
      }),
    };

    test('getTournaments parses the list', () async {
      final (repo, _) = _setup(routes);

      final list = await repo.getTournaments('c-1');

      expect(list.map((t) => t.id), ['t1', 't2', 't3']);
    });

    test(
      'getTournamentsPaged filters by status (case-insensitive) then pages',
      () async {
        final (repo, _) = _setup(routes);

        final first = await repo.getTournamentsPaged(
          'c-1',
          status: 'open',
          limit: 1,
        );
        final second = await repo.getTournamentsPaged(
          'c-1',
          status: 'OPEN',
          limit: 1,
          cursor: first.nextCursor,
        );

        expect(first.tournaments.map((t) => t.id), ['t1']);
        expect(first.hasMore, isTrue);
        expect(first.nextCursor, '1');
        expect(first.total, 2);
        expect(second.tournaments.map((t) => t.id), ['t3']);
        expect(second.hasMore, isFalse);
        expect(second.nextCursor, isNull);
      },
    );

    test(
      'getTournamentsPaged searches by name and ignores status ALL',
      () async {
        final (repo, _) = _setup(routes);

        final page = await repo.getTournamentsPaged(
          'c-1',
          status: 'ALL',
          search: ' MÙA ',
        );

        expect(page.tournaments.map((t) => t.id), ['t1', 't2']);
        expect(page.total, 2);
      },
    );

    test(
      'getTournamentsPaged returns an empty page when the load fails',
      () async {
        final (repo, _) = _setup({});

        final page = await repo.getTournamentsPaged('c-1');

        expect(page.tournaments, isEmpty);
        expect(page.hasMore, isFalse);
        expect(page.total, 0);
      },
    );
  });

  group('createCommunity', () {
    test('returns the created club only for HTTP 201', () async {
      final (repo, adapter) = _setup({
        'POST /communities': FakeReply(201, {'data': _club('new')}),
      });

      final created = await repo.createCommunity({'name': 'CLB new'});

      expect(created?.id, 'new');
      expect(adapter.postsTo('/communities').single.body, {'name': 'CLB new'});
    });

    test('returns null on HTTP 200 and on errors', () async {
      final (ok200, _) = _setup({
        'POST /communities': FakeReply(200, {'data': _club('x')}),
      });
      final (failing, _) = _setup({});

      expect(await ok200.createCommunity({}), isNull);
      expect(await failing.createCommunity({}), isNull);
    });
  });

  group('gallery', () {
    test('getGallery parses items and degrades to [] on error', () async {
      final (repo, _) = _setup({
        'GET /communities/c-1/gallery': const FakeReply(200, {
          'data': [
            {'id': 'g1', 'image_url': 'https://img/1.png', 'caption': 'hi'},
          ],
        }),
      });

      final items = await repo.getGallery('c-1');

      expect(items.single.imageUrl, 'https://img/1.png');
      expect(await repo.getGallery('other'), isEmpty);
    });

    test('addGalleryItem trims the caption and omits a blank one', () async {
      final (repo, adapter) = _setup({
        'POST /communities/c-1/gallery': const FakeReply(201, {
          'data': {'id': 'g1', 'imageUrl': 'https://img/1.png'},
        }),
      });

      final item = await repo.addGalleryItem(
        'c-1',
        imageUrl: 'https://img/1.png',
        caption: '  đẹp  ',
      );
      await repo.addGalleryItem('c-1', imageUrl: 'u', caption: '   ');

      expect(item?.id, 'g1');
      final bodies = adapter.postsTo('/communities/c-1/gallery').toList();
      expect(bodies[0].body, {
        'imageUrl': 'https://img/1.png',
        'caption': 'đẹp',
      });
      expect(bodies[1].body, {'imageUrl': 'u'});
    });

    test('addGalleryItem rethrows failures so the UI can show them', () async {
      final (repo, _) = _setup({});

      await expectLater(
        repo.addGalleryItem('c-1', imageUrl: 'u'),
        throwsA(isA<DioException>()),
      );
    });

    test(
      'removeGalleryItem is true for 200/204 and false on failure',
      () async {
        final (repo, _) = _setup({
          'DELETE /communities/c-1/gallery/g1': const FakeReply(204, {}),
        });

        expect(await repo.removeGalleryItem('c-1', 'g1'), isTrue);
        expect(await repo.removeGalleryItem('c-1', 'nope'), isFalse);
      },
    );
  });

  group('lists that degrade to empty on error', () {
    test('rankings, join requests and pending clubs', () async {
      final (repo, _) = _setup({});

      expect(await repo.getRankings('c-1'), isEmpty);
      expect(await repo.getJoinRequests('c-1'), isEmpty);
      expect(await repo.getPendingCommunities(), isEmpty);
    });

    test(
      'getPendingCommunities and getJoinRequests parse data lists',
      () async {
        final (repo, _) = _setup({
          'GET /communities/pending': FakeReply(200, {
            'data': [_club('p1', status: 'PENDING')],
          }),
          'GET /communities/c-1/join-requests': const FakeReply(200, {
            'data': [
              {'id': 'r1', 'userId': 'u1', 'status': 'PENDING'},
            ],
          }),
        });

        expect((await repo.getPendingCommunities()).single.status, 'PENDING');
        expect((await repo.getJoinRequests('c-1')).single.status, 'PENDING');
      },
    );
  });

  group('admin and member mutations', () {
    test('reviewCommunity sends rejectedReason only when provided', () async {
      final (repo, adapter) = _setup({
        'PATCH /communities/c-1/review': const FakeReply(200, {}),
      });

      await repo.reviewCommunity('c-1', 'APPROVED');
      await repo.reviewCommunity('c-1', 'REJECTED', rejectedReason: 'spam');

      final bodies = adapter.requests.map((r) => r.body).toList();
      expect(bodies[0], {'status': 'APPROVED'});
      expect(bodies[1], {'status': 'REJECTED', 'rejectedReason': 'spam'});
    });

    test(
      'reviewJoinRequest, role, ban and unban hit the documented routes',
      () async {
        final (repo, adapter) = _setup({
          'PATCH /communities/c-1/join-requests/m-1': const FakeReply(200, {}),
          'PATCH /communities/c-1/members/u-1': const FakeReply(200, {}),
          'DELETE /communities/c-1/members/u-1': const FakeReply(200, {}),
          'POST /communities/c-1/members/u-1/ban': const FakeReply(200, {}),
          'DELETE /communities/c-1/members/u-1/ban': const FakeReply(200, {}),
        });

        await repo.reviewJoinRequest('c-1', 'm-1', 'APPROVE');
        await repo.updateMemberRole('c-1', 'u-1', 'ADMIN');
        await repo.removeMember('c-1', 'u-1');
        await repo.banMember('c-1', 'u-1');
        await repo.unbanMember('c-1', 'u-1');

        expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
          'PATCH /communities/c-1/join-requests/m-1',
          'PATCH /communities/c-1/members/u-1',
          'DELETE /communities/c-1/members/u-1',
          'POST /communities/c-1/members/u-1/ban',
          'DELETE /communities/c-1/members/u-1/ban',
        ]);
        expect(adapter.requests[0].body, {'action': 'APPROVE'});
        expect(adapter.requests[1].body, {'role': 'ADMIN'});
      },
    );

    test(
      'mutations propagate server errors instead of swallowing them',
      () async {
        final (repo, _) = _setup({});

        await expectLater(
          repo.banMember('c-1', 'u-1'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test(
      'adjustMemberElo returns the data map, null when absent, and rethrows',
      () async {
        final (repo, adapter) = _setup({
          'POST /communities/c-1/members/u-1/elo': const FakeReply(200, {
            'data': {'elo': 1210},
          }),
          'POST /communities/c-1/members/u-2/elo': const FakeReply(200, {}),
        });

        final ok = await repo.adjustMemberElo(
          'c-1',
          userId: 'u-1',
          operation: 'ADD',
          points: 10,
          reason: 'thưởng',
        );
        final none = await repo.adjustMemberElo(
          'c-1',
          userId: 'u-2',
          operation: 'SUB',
          points: 5,
          reason: 'phạt',
        );

        expect(ok, {'elo': 1210});
        expect(none, isNull);
        expect(adapter.requests.first.body, {
          'operation': 'ADD',
          'points': 10,
          'reason': 'thưởng',
        });
        await expectLater(
          repo.adjustMemberElo(
            'c-1',
            userId: 'u-3',
            operation: 'ADD',
            points: 1,
            reason: 'x',
          ),
          throwsA(isA<DioException>()),
        );
      },
    );
  });
}
