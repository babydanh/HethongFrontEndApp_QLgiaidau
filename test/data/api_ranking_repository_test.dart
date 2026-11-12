import 'dart:typed_data';

import 'package:app_quanly_giaidau/data/repositories/api/api_ranking_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

Map<String, dynamic> _row(String id, int elo, {String category = 'cat-1'}) => {
  'id': id,
  'userId': 'u-$id',
  'fullName': 'VĐV $id',
  'eloPoints': elo,
  'categoryId': category,
  'tier': {'name': 'Hạng $elo'},
};

/// Serves `/rankings` pages keyed by the request cursor (null = first page).
class _CursorAdapter extends FakeApiAdapter {
  _CursorAdapter(this.pages) : super({});

  final Map<Object?, FakeReply> pages;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    routes['GET /rankings'] =
        pages[options.queryParameters['cursor']] ??
        const FakeReply(200, {'data': <dynamic>[]});
    return super.fetch(options, requestStream, cancelFuture);
  }
}

(ApiRankingRepository, FakeApiAdapter) _setup(Map<String, FakeReply> routes) {
  final adapter = FakeApiAdapter(routes);
  return (ApiRankingRepository(fakeDioClient(adapter)), adapter);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('getRankings', () {
    test('numbers rows from 1 in server order across pages', () async {
      final adapter = _CursorAdapter({
        null: FakeReply(200, {
          'data': [_row('a', 1500), _row('b', 1400)],
          'meta': {'hasMore': true, 'nextCursor': 'c2'},
        }),
        'c2': FakeReply(200, {
          'data': [_row('c', 1300)],
          'meta': {'hasMore': false},
        }),
      });
      final repo = ApiRankingRepository(fakeDioClient(adapter));

      final rankings = await repo.getRankings(
        categoryId: 'cat-1',
        matchType: 'doubles',
        provinceCode: '79',
      );

      expect(rankings.map((r) => (r.id, r.rank)), [('a', 1), ('b', 2), ('c', 3)]);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.first.query['categoryId'], 'cat-1');
      expect(adapter.requests.first.query['limit'], 100);
      expect(adapter.requests.last.query['cursor'], 'c2');
    });

    test('stops on a repeated cursor, an empty page or hasMore false',
        () async {
      final repeating = _CursorAdapter({
        null: FakeReply(200, {
          'data': [_row('a', 1)],
          'meta': {'hasMore': true, 'nextCursor': 'same'},
        }),
        'same': FakeReply(200, {
          'data': [_row('b', 1)],
          'meta': {'hasMore': true, 'nextCursor': 'same'},
        }),
      });

      final rankings = await ApiRankingRepository(
        fakeDioClient(repeating),
      ).getRankings();

      expect(rankings.map((r) => r.id), ['a', 'b']);
      expect(repeating.requests, hasLength(2));
    });

    test('accepts a bare list and rethrows server errors', () async {
      final (bare, _) = _setup({
        'GET /rankings': FakeReply(200, [_row('a', 1)]),
      });
      final (failing, _) = _setup({});

      expect((await bare.getRankings()).single.rank, 1);
      await expectLater(failing.getRankings(), throwsA(isA<DioException>()));
    });
  });

  group('getRankingsPaged', () {
    test('returns the page with its cursor and hasMore', () async {
      final (repo, adapter) = _setup({
        'GET /rankings': FakeReply(200, {
          'data': [_row('a', 1500), 'junk'],
          'meta': {'nextCursor': 'n2', 'hasMore': true},
        }),
      });

      final page = await repo.getRankingsPaged(
        categoryId: 'cat-1',
        cursor: 'c1',
        limit: 5,
      );

      expect(page.rankings.map((r) => r.id), ['a']);
      expect(page.nextCursor, 'n2');
      expect(page.hasMore, isTrue);
      expect(adapter.requests.single.query['cursor'], 'c1');
      expect(adapter.requests.single.query['limit'], 5);
    });

    test('an empty nextCursor means no more pages', () async {
      final (repo, _) = _setup({
        'GET /rankings': const FakeReply(200, {
          'data': <dynamic>[],
          'meta': {'nextCursor': '', 'hasMore': false},
        }),
      });

      final page = await repo.getRankingsPaged(categoryId: 'cat-1');

      expect(page.nextCursor, isNull);
      expect(page.hasMore, isFalse);
    });

    test('a failure is rethrown', () async {
      final (repo, _) = _setup({});

      await expectLater(
        repo.getRankingsPaged(categoryId: 'cat-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('football team rankings', () {
    test('sends the category, default limit and optional community',
        () async {
      final (repo, adapter) = _setup({
        'GET /rankings/football-teams': const FakeReply(200, {
          'data': [
            {'id': 'r1', 'teamId': 't1', 'teamName': 'FC A', 'eloPoints': 1200},
          ],
        }),
      });

      final teams = await repo.getFootballTeamRankings(
        categoryId: 'cat-fb',
        communityId: 'club-1',
      );
      await repo.getFootballTeamRankings(
        categoryId: 'cat-fb',
        communityId: '',
        limit: 10,
      );

      expect(teams.single.teamName, 'FC A');
      expect(teams.single.eloPoints, 1200);
      expect(adapter.requests[0].query, {
        'categoryId': 'cat-fb',
        'limit': 100,
        'communityId': 'club-1',
      });
      expect(adapter.requests[1].query, {'categoryId': 'cat-fb', 'limit': 10});
    });
  });

  group('getEloTiers', () {
    test('sorts tiers by minElo and accepts a bare list', () async {
      final (wrapped, _) = _setup({
        'GET /categories/cat-1/elo-tiers': const FakeReply(200, {
          'data': [
            {'id': 't3', 'name': 'Vàng', 'minElo': 1800, 'maxElo': 2200},
            {'id': 't1', 'name': 'Đồng', 'minElo': 0, 'maxElo': 1200},
            {'id': 't2', 'name': 'Bạc', 'min_elo': 1200, 'max_elo': 1800},
          ],
        }),
      });
      final (bare, _) = _setup({
        'GET /categories/cat-1/elo-tiers': const FakeReply(200, [
          {'id': 'x', 'name': 'X', 'minElo': 5, 'maxElo': 9},
        ]),
      });

      expect(
        (await wrapped.getEloTiers('cat-1')).map((t) => t.name),
        ['Đồng', 'Bạc', 'Vàng'],
      );
      expect((await bare.getEloTiers('cat-1')).single.id, 'x');
    });

    test('a failure is rethrown', () async {
      final (repo, _) = _setup({});

      await expectLater(
        repo.getEloTiers('cat-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('getUserRank', () {
    test('returns the public rank of the requested category', () async {
      final (repo, adapter) = _setup({
        'GET /rankings/user/u1': FakeReply(200, {
          'data': {
            'publicRanks': [
              _row('r1', 1111, category: 'cat-other'),
              _row('r2', 1650, category: 'cat-1'),
            ],
          },
        }),
      });

      final rank = await repo.getUserRank('u1', 'cat-1');

      expect(rank.eloPoints, 1650);
      expect(rank.tierName, 'Hạng 1650');
      expect(rank.categoryId, 'cat-1');
      expect(adapter.requests.single.query, {'categoryId': 'cat-1'});
    });

    test('an empty category takes the first rank and sends no filter',
        () async {
      final (repo, adapter) = _setup({
        'GET /rankings/user/u1': FakeReply(200, {
          'publicRanks': [_row('r1', 1111, category: 'cat-x')],
        }),
      });

      final rank = await repo.getUserRank('u1', '');

      expect(rank.eloPoints, 1111);
      expect(adapter.requests.single.query, isEmpty);
    });

    test('an unranked user gets the default 1000 ELO and a fallback tier',
        () async {
      final (repo, _) = _setup({
        'GET /rankings/user/u1': const FakeReply(200, {
          'data': {'publicRanks': <dynamic>[]},
        }),
      });

      final rank = await repo.getUserRank('u1', 'cat-1');

      expect(rank.eloPoints, 1000);
      expect(rank.tierName, isNotEmpty);
      expect(rank.categoryId, 'cat-1');
    });

    test('a failure is rethrown', () async {
      final (repo, _) = _setup({});

      await expectLater(
        repo.getUserRank('u1', 'cat-1'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
