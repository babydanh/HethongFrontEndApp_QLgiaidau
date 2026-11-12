import 'dart:async';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

/// Socket giả: test tự đẩy sự kiện qua các controller.
class _FakeSocket extends Fake implements MatchSocketService {
  final score = StreamController<Map<String, dynamic>>.broadcast();
  final status = StreamController<Map<String, dynamic>>.broadcast();
  final tournament = StreamController<Map<String, dynamic>>.broadcast();
  final visibility = StreamController<Map<String, dynamic>>.broadcast();
  final overlay = StreamController<Map<String, dynamic>>.broadcast();
  final calls = <String>[];

  @override
  Future<void> connect(String? matchId, {bool joinMatch = true}) async =>
      calls.add('connect:$matchId');

  @override
  void leave(String matchId) => calls.add('leave:$matchId');

  @override
  void joinTournament(String tournamentId) => calls.add('join:$tournamentId');

  @override
  void leaveTournament(String tournamentId) =>
      calls.add('leaveTournament:$tournamentId');

  @override
  Stream<Map<String, dynamic>> get onScoreUpdate => score.stream;

  @override
  Stream<Map<String, dynamic>> get onMatchStatus => status.stream;

  @override
  Stream<Map<String, dynamic>> get onTournamentMatchUpdate => tournament.stream;

  @override
  Stream<Map<String, dynamic>> get onScoreboardVisibility => visibility.stream;

  @override
  Stream<Map<String, dynamic>> get onOverlayVisibility => overlay.stream;
}

/// Trả trang theo `cursor` của request (null = trang đầu).
class _CursorAdapter extends FakeApiAdapter {
  _CursorAdapter(this.pages) : super({});

  final Map<Object?, FakeReply> pages;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    routes['GET /matches'] =
        pages[options.queryParameters['cursor']] ??
        const FakeReply(200, {'data': <dynamic>[]});
    return super.fetch(options, requestStream, cancelFuture);
  }
}

Map<String, dynamic> _match(String id, [Map<String, dynamic>? extra]) => {
  'id': id,
  'status': 'SCHEDULED',
  'participant1': {'id': 'a', 'teamName': 'Đội A'},
  'participant2': {'id': 'b', 'teamName': 'Đội B'},
  ...?extra,
};

(ApiMatchRepository, FakeApiAdapter, _FakeSocket) _setup(
  Map<String, FakeReply> routes,
) {
  final adapter = FakeApiAdapter(routes);
  final socket = _FakeSocket();
  return (ApiMatchRepository(fakeDioClient(adapter), socket), adapter, socket);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('updateLiveState', () {
    test(
      'status-only goes to /status with a normalised backend status',
      () async {
        final (repo, adapter, _) = _setup({
          'PATCH /matches/m1/status': const FakeReply(200, {}),
        });

        Future<Object?> sent(String status) async {
          adapter.requests.clear();
          await repo.updateLiveState('t', 'm1', status: status);
          return adapter.requests.single.body!['status'];
        }

        expect(await sent('live'), 'ONGOING');
        expect(await sent('in_progress'), 'ONGOING');
        expect(await sent('finished'), 'COMPLETED');
        expect(await sent('pending'), 'SCHEDULED');
        expect(await sent('custom'), 'CUSTOM');
      },
    );

    test(
      'flat scores and config-only updates are rejected without a request',
      () async {
        final (repo, adapter, _) = _setup({});

        await expectLater(
          repo.updateLiveState('t', 'm1', score1: 1),
          throwsA(isA<UnsupportedError>()),
        );
        await expectLater(
          repo.updateLiveState('t', 'm1', status: 'live', score2: 3),
          throwsA(isA<UnsupportedError>()),
        );
        await expectLater(
          repo.updateLiveState('t', 'm1', maxScore: 11),
          throwsA(isA<UnsupportedError>()),
        );
        expect(adapter.requests, isEmpty);
      },
    );

    test('events-only updates are ignored silently', () async {
      final (repo, adapter, _) = _setup({});

      await repo.updateLiveState('t', 'm1', events: const []);

      expect(adapter.requests, isEmpty);
    });
  });

  group('start / unsupported operations', () {
    test('startMatch picks the club, lite or tournament endpoint', () async {
      final (repo, adapter, _) = _setup({
        'POST /club-match-sessions/matches/m1/start': const FakeReply(200, {}),
        'PATCH /matches/m1/lite-status': const FakeReply(200, {}),
        'PATCH /matches/m1/status': const FakeReply(200, {}),
      });

      await repo.startMatch('', 'm1');
      await repo.startMatch('t', 'm1', useLiteParticipantAccess: true);
      await repo.startMatch('t', 'm1');

      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /club-match-sessions/matches/m1/start',
        'PATCH /matches/m1/lite-status',
        'PATCH /matches/m1/status',
      ]);
      expect(adapter.requests[0].body, isEmpty);
      expect(adapter.requests[1].body, {'status': 'ONGOING'});
      expect(adapter.requests[2].body, {'status': 'ONGOING'});
    });

    test(
      'operations the backend owns throw instead of silently no-op',
      () async {
        final (repo, adapter, _) = _setup({});

        await expectLater(
          repo.completeMatch(
            't',
            'm1',
            winnerId: 'a',
            loserId: 'b',
            finalScore1: 11,
            finalScore2: 5,
          ),
          throwsA(isA<UnsupportedError>()),
        );
        await expectLater(
          repo.advanceWinner(
            't',
            'm2',
            winnerId: 'a',
            winnerName: 'A',
            isTeam1: true,
          ),
          throwsA(isA<UnimplementedError>()),
        );
        await expectLater(
          repo.deleteAll('t'),
          throwsA(isA<UnimplementedError>()),
        );
        expect(adapter.requests, isEmpty);
      },
    );
  });

  group('updateScoreDetails', () {
    const sets = [
      SetScoreData(score1: 11, score2: 7, isFinished: true),
      SetScoreData(score1: 9, score2: 11, isFinished: true),
    ];

    test(
      'builds the payload with extras, winner, revision and played time',
      () async {
        final (repo, adapter, _) = _setup({
          'PATCH /matches/m1/score': const FakeReply(200, {}),
        });

        await repo.updateScoreDetails(
          't',
          'm1',
          p1SetsWon: 1,
          p2SetsWon: 1,
          scoreDetails: sets,
          scoreDetailsExtras: const {'courtState': 'x'},
          winnerId: 'a',
          overrideReason: 'sửa',
          expectedRevision: 4,
          playedAt: (date: '2026-06-01', time: '10:30'),
        );

        final body = adapter.requests.single.body!;
        expect(adapter.requests.single.method, 'PATCH');
        expect(body['p1SetsWon'], 1);
        expect(body['winnerId'], 'a');
        expect(body['overrideReason'], 'sửa');
        expect(body['expectedRevision'], 4);
        expect(body['playedDate'], '2026-06-01');
        expect(body['playedTime'], '10:30');
        final details = body['scoreDetails'] as Map;
        expect(details['courtState'], 'x');
        expect((details['sets'] as List), hasLength(2));
      },
    );

    test(
      'omits optional fields, and club sessions never send played time',
      () async {
        final (repo, adapter, _) = _setup({
          'PATCH /club-match-sessions/matches/m1/score': const FakeReply(
            200,
            {},
          ),
          'POST /club-match-sessions/matches/m1/complete': const FakeReply(
            200,
            {},
          ),
          'PATCH /matches/m1/lite-score': const FakeReply(200, {}),
        });

        await repo.updateScoreDetails(
          '',
          'm1',
          p1SetsWon: 0,
          p2SetsWon: 0,
          scoreDetails: const [],
          playedAt: (date: '2026-06-01', time: null),
        );
        await repo.updateScoreDetails(
          '',
          'm1',
          p1SetsWon: 2,
          p2SetsWon: 0,
          scoreDetails: sets,
          winnerId: 'a',
        );
        await repo.updateScoreDetails(
          't',
          'm1',
          p1SetsWon: 0,
          p2SetsWon: 0,
          scoreDetails: const [],
          useLiteParticipantAccess: true,
        );

        expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
          'PATCH /club-match-sessions/matches/m1/score',
          'POST /club-match-sessions/matches/m1/complete',
          'PATCH /matches/m1/lite-score',
        ]);
        final first = adapter.requests.first.body!;
        expect(first.containsKey('playedDate'), isFalse);
        expect(first.containsKey('winnerId'), isFalse);
        expect(first.containsKey('expectedRevision'), isFalse);
      },
    );

    test(
      'TOURNAMENT_NOT_STARTED becomes a typed exception (tournament only)',
      () async {
        final (repo, _, _) = _setup({
          'PATCH /matches/m1/score': const FakeReply(409, {
            'code': 'TOURNAMENT_NOT_STARTED',
            'message': 'chưa bắt đầu',
          }),
          'PATCH /club-match-sessions/matches/m1/score': const FakeReply(409, {
            'code': 'TOURNAMENT_NOT_STARTED',
            'message': 'chưa bắt đầu',
          }),
        });

        await expectLater(
          repo.updateScoreDetails(
            't',
            'm1',
            p1SetsWon: 0,
            p2SetsWon: 0,
            scoreDetails: const [],
          ),
          throwsA(isA<TournamentNotStartedException>()),
        );
        // A club session has no tournament, so the code is shown as a message.
        await expectLater(
          repo.updateScoreDetails(
            '',
            'm1',
            p1SetsWon: 0,
            p2SetsWon: 0,
            scoreDetails: const [],
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('chưa bắt đầu'),
            ),
          ),
        );
      },
    );

    test(
      'joins a list of validation messages and falls back when empty',
      () async {
        final (repo, _, _) = _setup({
          'PATCH /matches/m1/score': const FakeReply(400, {
            'message': ['Điểm sai', 'Thiếu set'],
          }),
          'PATCH /matches/m2/score': const FakeReply(400, {'message': '  '}),
        });

        await expectLater(
          repo.updateScoreDetails(
            't',
            'm1',
            p1SetsWon: 0,
            p2SetsWon: 0,
            scoreDetails: const [],
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Điểm sai\nThiếu set'),
            ),
          ),
        );
        // A blank server message must not be shown: the localized fallback is.
        await expectLater(
          repo.updateScoreDetails(
            't',
            'm2',
            p1SetsWon: 0,
            p2SetsWon: 0,
            scoreDetails: const [],
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString().trim().isNotEmpty,
              'has a message',
              isTrue,
            ),
          ),
        );
      },
    );
  });

  group('court state and pickleball scoring', () {
    test('updateCourtState sends courtState and parses the match', () async {
      final (repo, adapter, _) = _setup({
        'PATCH /matches/m1/court-state': FakeReply(200, {
          'data': _match('m1', {'revision': 3}),
        }),
      });

      final m = await repo.updateCourtState('m1', {'server': 1});

      expect(adapter.requests.single.body, {
        'courtState': {'server': 1},
      });
      expect(m.id, 'm1');
      expect(m.revision, 3);
    });

    test('setPickleballScoring maps side-out vs rally', () async {
      final (repo, adapter, _) = _setup({
        'PATCH /matches/m1/pickleball-scoring': FakeReply(200, _match('m1')),
      });

      await repo.setPickleballScoring(
        'm1',
        SportScoringModel.pickleballSideOut,
      );
      await repo.setPickleballScoring('m1', SportScoringModel.rallyPointSet);

      expect(adapter.requests.map((r) => r.body!['scoring']), [
        'SIDE_OUT',
        'RALLY',
      ]);
    });

    test('a non-object body or an HTTP error becomes an Exception', () async {
      final (repo, _, _) = _setup({
        'PATCH /matches/m1/court-state': const FakeReply(200, 'oops'),
        'PATCH /matches/m2/court-state': const FakeReply(400, {
          'message': ['Sân không hợp lệ'],
        }),
        'PATCH /matches/m1/pickleball-scoring': const FakeReply(200, 'oops'),
      });

      await expectLater(
        repo.updateCourtState('m1', {}),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repo.updateCourtState('m2', {}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sân không hợp lệ'),
          ),
        ),
      );
      await expectLater(
        repo.setPickleballScoring('m1', SportScoringModel.rallyPointSet),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('loading matches', () {
    test(
      'getAllByTournament scopes by division and follows nextCursor',
      () async {
        final adapter = _CursorAdapter({
          null: FakeReply(200, {
            'data': [_match('m1')],
            'meta': {'nextCursor': 'c2'},
          }),
          'c2': FakeReply(200, {
            'data': [_match('m2')],
          }),
        });
        final repo = ApiMatchRepository(fakeDioClient(adapter), _FakeSocket());

        final matches = await repo.getAllByTournament('t', divisionId: 'd1');

        expect(matches.map((m) => m.id), ['m1', 'm2']);
        expect(adapter.requests, hasLength(2));
        expect(adapter.requests[0].query, {
          'tournamentId': 't',
          'publicOnly': true,
          'divisionId': 'd1',
          'strictDivisionScope': true,
          'limit': 100,
        });
        expect(adapter.requests[1].query['cursor'], 'c2');
      },
    );

    test('paging stops when the cursor repeats or the page is empty', () async {
      final adapter = _CursorAdapter({
        null: FakeReply(200, {
          'data': [_match('m1')],
          'meta': {'nextCursor': 'same'},
        }),
        'same': FakeReply(200, {
          'data': [_match('m2')],
          'meta': {'nextCursor': 'same'},
        }),
      });
      final repo = ApiMatchRepository(fakeDioClient(adapter), _FakeSocket());

      final matches = await repo.getMatches(status: 'LIVE', publicOnly: false);

      expect(matches.map((m) => m.id), ['m1', 'm2']);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.first.query['status'], 'LIVE');
      expect(adapter.requests.first.query['publicOnly'], false);
    });

    test(
      'concurrent loads for the same tournament share one request',
      () async {
        final (repo, adapter, _) = _setup({
          'GET /matches': FakeReply(200, {
            'data': [_match('m1')],
          }),
        });

        final results = await Future.wait([
          repo.getAllByTournament('t'),
          repo.getAllByTournament('t'),
        ]);
        await repo.getAllByTournament('t'); // after completion: a fresh request

        expect(results[0].single.id, 'm1');
        expect(adapter.requests, hasLength(2));
      },
    );

    test('a failed load rethrows and is not cached as in-flight', () async {
      final adapter = FakeApiAdapter({
        'GET /matches': const FakeReply(500, {'message': 'x'}),
      });
      final repo = ApiMatchRepository(fakeDioClient(adapter), _FakeSocket());

      await expectLater(
        repo.getAllByTournament('t'),
        throwsA(isA<DioException>()),
      );
      adapter.routes['GET /matches'] = FakeReply(200, {
        'data': [_match('m1')],
      });

      expect((await repo.getAllByTournament('t')).single.id, 'm1');
    });

    test('getPublicMatchesPaged builds the query and reads meta', () async {
      final (repo, adapter, _) = _setup({
        'GET /matches': FakeReply(200, {
          'data': [_match('m1')],
          'meta': {'total': 12, 'hasMore': true, 'nextCursor': 'n2'},
        }),
      });

      final page = await repo.getPublicMatchesPaged(
        cursor: 'c1',
        limit: 5,
        search: '  an  ',
        categoryId: 'cat',
        status: 'live',
        startDate: DateTime.utc(2026, 6, 1, 15),
        endDate: DateTime.utc(2026, 6, 2),
      );

      expect(adapter.requests.single.query, {
        'publicOnly': true,
        'limit': 5,
        'cursor': 'c1',
        'search': 'an',
        'categoryId': 'cat',
        'status': 'LIVE',
        'startDate': '2026-06-01',
        'endDate': '2026-06-02',
      });
      expect(page.matches.single.id, 'm1');
      expect(page.total, 12);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'n2');
    });

    test('getPublicMatchesPaged falls back total to the item count and '
        'rethrows failures', () async {
      final (repo, _, _) = _setup({
        'GET /matches': FakeReply(200, [_match('m1'), _match('m2')]),
      });
      final (failing, _, _) = _setup({});

      final page = await repo.getPublicMatchesPaged();

      expect(page.total, 2);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
      await expectLater(
        failing.getPublicMatchesPaged(),
        throwsA(isA<DioException>()),
      );
    });

    test('getTournamentMatchesPaged supports totalCount and cursor-derived '
        'hasMore', () async {
      final (repo, adapter, _) = _setup({
        'GET /matches': FakeReply(200, {
          'data': [_match('m1')],
          'meta': {'totalCount': 9, 'nextCursor': 'n'},
        }),
      });

      final page = await repo.getTournamentMatchesPaged(
        tournamentId: 't',
        status: 'completed',
        cursor: 'c',
        limit: 2,
      );

      expect(adapter.requests.single.query, {
        'tournamentId': 't',
        'limit': 2,
        'status': 'COMPLETED',
        'cursor': 'c',
      });
      expect(page.total, 9);
      expect(page.hasMore, isTrue);
    });
  });

  group('cheer, operations and visibility', () {
    test(
      'getCheerCount reads int, count/cheerCount maps and degrades to 0',
      () async {
        final (repo, _, _) = _setup({
          'GET /matches/a/cheer-count': const FakeReply(200, {'data': 5}),
          'GET /matches/b/cheer-count': const FakeReply(200, {
            'data': {'count': 7},
          }),
          'GET /matches/c/cheer-count': const FakeReply(200, {
            'data': {'cheerCount': 9},
          }),
          'GET /matches/d/cheer-count': const FakeReply(200, {
            'data': {'other': 1},
          }),
        });

        expect(await repo.getCheerCount('a'), 5);
        expect(await repo.getCheerCount('b'), 7);
        expect(await repo.getCheerCount('c'), 9);
        expect(await repo.getCheerCount('d'), 0);
        expect(await repo.getCheerCount('missing'), 0);
      },
    );

    test('cheerMatch posts to the cheer route', () async {
      final (repo, adapter, _) = _setup({
        'POST /matches/m1/cheer': const FakeReply(200, {}),
      });

      await repo.cheerMatch('m1');

      expect(adapter.requests.single.path, '/matches/m1/cheer');
    });

    test(
      'matchOperation sends winnerId only when given; walkover wraps it',
      () async {
        final (repo, adapter, _) = _setup({
          'PATCH /matches/m1/operation': const FakeReply(200, {}),
        });

        await repo.matchOperation('m1', action: 'RESET', reason: 'nhầm');
        await repo.walkover('t', 'm1', winnerId: 'a', loserId: 'b');

        expect(adapter.requests[0].body, {'action': 'RESET', 'reason': 'nhầm'});
        expect(adapter.requests[1].body, {
          'action': 'WALKOVER',
          'reason': 'Đội đối thủ bỏ cuộc',
          'winnerId': 'a',
        });
      },
    );

    test(
      'scoreboard and overlay visibility use club vs tournament routes',
      () async {
        final (repo, adapter, _) = _setup({
          'PATCH /club-match-sessions/matches/m1/scoreboard-visibility':
              const FakeReply(200, {}),
          'PATCH /matches/m1/scoreboard-visibility': const FakeReply(200, {}),
          'PATCH /matches/m1/overlay-visibility': const FakeReply(200, {
            'data': {'h2hOverlayVisible': true},
          }),
          'PATCH /club-match-sessions/matches/m2/overlay-visibility':
              const FakeReply(200, {'data': <dynamic, dynamic>{}}),
        });

        await repo.setScoreboardVisibility(
          'm1',
          visible: false,
          isClubMatch: true,
        );
        await repo.setScoreboardVisibility(
          'm1',
          visible: true,
          isClubMatch: false,
        );
        final overlay = await repo.setOverlayVisibility(
          'm1',
          kind: LiveOverlayKind.h2h,
          visible: true,
          isClubMatch: false,
        );
        final club = await repo.setOverlayVisibility(
          'm2',
          kind: LiveOverlayKind.bracket,
          visible: false,
          isClubMatch: true,
        );

        expect(adapter.requests[0].body, {'visible': false});
        expect(adapter.requests[1].path, '/matches/m1/scoreboard-visibility');
        expect(adapter.requests[2].body, {'kind': 'H2H', 'visible': true});
        expect(overlay.h2hOverlayVisible, isTrue);
        expect(overlay.bracketOverlayVisible, isFalse);
        expect(adapter.requests[3].body, {'kind': 'BRACKET', 'visible': false});
        expect(club.h2hOverlayVisible, isFalse);
      },
    );

    test('setOverlayVisibility rejects a response without data', () async {
      final (repo, _, _) = _setup({
        'PATCH /matches/m1/overlay-visibility': const FakeReply(200, {}),
      });

      await expectLater(
        repo.setOverlayVisibility(
          'm1',
          kind: LiveOverlayKind.h2h,
          visible: true,
          isClubMatch: false,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('mergeCourtState', () {
    test('keeps the previous court state when the payload has none', () {
      final merged = mergeCourtState(
        selected: {'sets': 1},
        incoming: {'sets': 2},
        previous: {'courtState': 'old'},
      );

      expect(merged, {'sets': 1, 'courtState': 'old'});
    });

    test('an incoming court state wins, even when it is explicitly null', () {
      expect(
        mergeCourtState(
          selected: {'a': 1},
          incoming: {'courtState': 'new'},
          previous: {'courtState': 'old'},
        ),
        {'a': 1, 'courtState': 'new'},
      );
      expect(
        mergeCourtState(
          selected: {'a': 1},
          incoming: {'courtState': null},
          previous: {'courtState': 'old'},
        ),
        {'a': 1},
      );
    });

    test('returns null when nothing is selected and no court state exists', () {
      expect(
        mergeCourtState(selected: null, incoming: null, previous: null),
        isNull,
      );
      expect(
        mergeCourtState(
          selected: null,
          incoming: null,
          previous: {'courtState': 'only'},
        ),
        {'courtState': 'only'},
      );
    });
  });

  group('watchMatch', () {
    test('emits the seeded card first, then the fetched match', () async {
      final (repo, _, socket) = _setup({
        'GET /matches/m1': FakeReply(200, {
          'data': _match('m1', {'revision': 2}),
        }),
      });
      repo.primeMatch(
        MatchModel(
          id: 'm1',
          team1Id: 'a',
          team1Name: 'Seed A',
          team2Id: 'b',
          team2Name: 'Seed B',
          round: 1,
          matchNumber: 1,
          bracketPosition: const BracketPosition(
            bracket: 'winners',
            round: 1,
            position: 1,
          ),
          updatedAt: DateTime(2026),
        ),
      );

      final emitted = await repo.watchMatch('t', 'm1').take(2).toList();

      expect(emitted.first?.team1Name, 'Seed A');
      expect(emitted.last?.team1Name, 'Đội A');
      expect(emitted.last?.revision, 2);
      expect(socket.calls, contains('connect:m1'));
      await Future<void>.delayed(Duration.zero);
      expect(socket.calls, containsAll(['leave:m1', 'leaveTournament:t']));
    });

    test('score socket updates merge: keep known names, take new revision and '
        'score', () async {
      final (repo, _, socket) = _setup({
        'GET /matches/m1': FakeReply(200, {
          'data': _match('m1', {'revision': 1, 'score1': 3, 'score2': 2}),
        }),
      });
      final events = <MatchModel?>[];
      final sub = repo.watchMatch('t', 'm1').listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      socket.score.add({
        'id': 'm1',
        'status': 'ONGOING',
        'revision': 5,
        'score1': 8,
        'score2': 6,
      });
      await Future<void>.delayed(Duration.zero);
      // Another match's event is ignored.
      socket.score.add({'id': 'other', 'score1': 99});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, hasLength(2));
      final merged = events.last!;
      expect(merged.team1Name, 'Đội A'); // payload had no team → TBD → kept
      expect(merged.revision, 5);
      expect(merged.score1, 8);
      expect(merged.score2, 6);
      expect(merged.status, 'live');
    });

    test(
      'a status-only payload keeps the previous score and visibility',
      () async {
        final (repo, _, socket) = _setup({
          'GET /matches/m1': FakeReply(200, {
            'data': _match('m1', {
              'score1': 4,
              'score2': 3,
              'scoreboardVisible': false,
            }),
          }),
        });
        final events = <MatchModel?>[];
        final sub = repo.watchMatch('t', 'm1').listen(events.add);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        socket.status.add({'id': 'm1', 'status': 'COMPLETED'});
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        final merged = events.last!;
        expect(merged.status, 'completed');
        expect(merged.score1, 4); // no score fields in payload → previous kept
        expect(merged.score2, 3);
        expect(merged.scoreboardVisible, isFalse);
      },
    );

    test('visibility socket events update only the flags they carry', () async {
      final (repo, _, socket) = _setup({
        'GET /matches/m1': FakeReply(200, {'data': _match('m1')}),
      });
      final events = <MatchModel?>[];
      final sub = repo.watchMatch('t', 'm1').listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      socket.visibility.add({'id': 'm1', 'scoreboardVisible': false});
      socket.visibility.add({'id': 'm1', 'scoreboardVisible': 'no'}); // ignored
      socket.overlay.add({
        'matchId': 'm1',
        'h2hOverlayVisible': true,
        'bracketOverlayVisible': false,
      });
      socket.overlay.add({
        'matchId': 'm1',
        'h2hOverlayVisible': true,
      }); // ignored
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // initial + visibility + overlay; the two malformed payloads add nothing.
      expect(events, hasLength(3));
      expect(events[1]!.scoreboardVisible, isFalse);
      expect(events[2]!.h2hOverlayVisible, isTrue);
      expect(events[2]!.bracketOverlayVisible, isFalse);
      expect(events[2]!.scoreboardVisible, isFalse); // earlier flag preserved
    });

    test('a club-session match (empty tournament id) is read from the club '
        'endpoint first', () async {
      final (repo, adapter, _) = _setup({
        'GET /club-match-sessions/matches/m1': FakeReply(200, {
          'data': _match('m1'),
        }),
      });

      final first = await repo.watchMatch('', 'm1').first;

      expect(first?.id, 'm1');
      expect(adapter.requests.first.path, '/club-match-sessions/matches/m1');
    });
  });
}
