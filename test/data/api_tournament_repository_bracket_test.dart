import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_api_adapter.dart';

Map<String, dynamic> _tournament(String id, {String status = 'in_progress'}) =>
    {
      'id': id,
      'name': 'Giải $id',
      'sport': 'pickleball',
      'format': 'singles',
      'status': status,
      'maxTeams': 8,
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    };

Map<String, dynamic> _match(
  String id, {
  int round = 1,
  int order = 1,
  String status = 'SCHEDULED',
  String? branch,
  Map<String, dynamic>? extra,
}) => {
  'id': id,
  'roundNumber': round,
  'matchOrder': order,
  'status': status,
  'bracketBranch': ?branch,
  'participant1': {'id': 'a-$id', 'teamName': 'Đội A'},
  'participant2': {'id': 'b-$id', 'teamName': 'Đội B'},
  ...?extra,
};

Map<String, dynamic> _bracket(List<Map<String, dynamic>> matches) => {
  'data': {
    'stages': [
      {
        'name': 'Vòng loại',
        'type': 'KNOCKOUT',
        'tournamentDivisionId': 'd-stage',
        'groups': [
          {'name': 'Bảng X', 'matches': matches},
        ],
      },
    ],
  },
};

(ApiTournamentRepository, FakeApiAdapter) _setup(
  Map<String, FakeReply> routes,
) {
  final adapter = FakeApiAdapter(routes);
  return (ApiTournamentRepository(fakeDioClient(adapter)), adapter);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
    );
    SharedPreferences.setMockInitialValues({});
  });

  group('getPublicTournamentsPaged', () {
    test('maps UI statuses to backend filters and sends only set filters',
        () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/public': const FakeReply(200, {'data': <dynamic>[]}),
      });

      Future<Object?> statusFor(String status) async {
        adapter.requests.clear();
        await repo.getPublicTournamentsPaged(status: status);
        return adapter.requests.single.query['status'];
      }

      expect(await statusFor('registration'), 'REGISTRATION');
      expect(await statusFor('UPCOMING'), 'UPCOMING,REGISTRATION_CLOSED');
      expect(await statusFor('in_progress'), 'IN_PROGRESS');
      expect(await statusFor('completed'), 'COMPLETED');
      expect(await statusFor('draft'), 'DRAFT');
      expect(await statusFor('all'), isNull);
    });

    test('builds the full query and upper-cases the bracket type', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/public': const FakeReply(200, {'data': <dynamic>[]}),
      });

      await repo.getPublicTournamentsPaged(
        cursor: 'c1',
        limit: 3,
        categoryId: 'cat',
        search: 'xuân',
        bracketType: 'single_elimination',
        isRanked: false,
        region: 'HCM',
        startDate: DateTime.utc(2026, 1, 2),
        endDate: DateTime.utc(2026, 1, 3),
      );

      expect(adapter.requests.single.query, {
        'limit': 3,
        'cursor': 'c1',
        'categoryId': 'cat',
        'search': 'xuân',
        'bracketType': 'SINGLE_ELIMINATION',
        'isRanked': false,
        'region': 'HCM',
        'startDate': '2026-01-02T00:00:00.000Z',
        'endDate': '2026-01-03T00:00:00.000Z',
      });
    });

    test('COMPLETED filter drops items that are not completed and reads the '
        'cursor', () async {
      final (repo, _) = _setup({
        'GET /tournaments/public': FakeReply(200, {
          'data': [
            _tournament('a', status: 'COMPLETED'),
            _tournament('b', status: 'IN_PROGRESS'),
          ],
          'meta': {'nextCursor': 'n2'},
        }),
      });

      final page = await repo.getPublicTournamentsPaged(status: 'completed');

      expect(page.tournaments.map((t) => t.id), ['a']);
      expect(page.nextCursor, 'n2');
      expect(page.hasMore, isTrue);
    });

    test('hasMore is true for meta.hasNext and for a top-level cursor',
        () async {
      final (viaMeta, _) = _setup({
        'GET /tournaments/public': const FakeReply(200, {
          'data': <dynamic>[],
          'meta': {'hasNext': true},
        }),
      });
      final (viaRoot, _) = _setup({
        'GET /tournaments/public': const FakeReply(200, {
          'data': <dynamic>[],
          'nextCursor': 'root',
        }),
      });

      expect((await viaMeta.getPublicTournamentsPaged()).hasMore, isTrue);
      final root = await viaRoot.getPublicTournamentsPaged();
      expect(root.nextCursor, 'root');
      expect(root.hasMore, isTrue);
    });

    test('falls back to /tournaments when /public fails', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments': FakeReply(200, {
          'data': [_tournament('fallback')],
        }),
      });

      final page = await repo.getPublicTournamentsPaged();

      expect(page.tournaments.single.id, 'fallback');
      expect(adapter.requests.map((r) => r.path), [
        '/tournaments/public',
        '/tournaments',
      ]);
    });

    test('rethrowOnError skips the fallback and surfaces the failure',
        () async {
      final (repo, adapter) = _setup({});

      await expectLater(
        repo.getPublicTournamentsPaged(rethrowOnError: true),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.map((r) => r.path), ['/tournaments/public']);

      final page = await _setup({}).$1.getPublicTournamentsPaged();
      expect(page.tournaments, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('skips malformed tournament items instead of failing the page',
        () async {
      final (repo, _) = _setup({
        'GET /tournaments/public': FakeReply(200, {
          'data': [
            _tournament('ok'),
            'junk',
          ],
        }),
      });

      expect(
        (await repo.getPublicTournamentsPaged()).tournaments.map((t) => t.id),
        ['ok'],
      );
    });
  });

  group('simple tournament mutations and follow', () {
    test('update, updateStatus, delete, follow and unfollow hit their routes',
        () async {
      final (repo, adapter) = _setup({
        'PATCH /tournaments/t-1': const FakeReply(200, {}),
        'DELETE /tournaments/t-1': const FakeReply(200, {}),
        'POST /tournaments/t-1/follow': const FakeReply(200, {}),
        'DELETE /tournaments/t-1/follow': const FakeReply(200, {}),
      });

      await repo.update('t-1', {'name': 'Mới'});
      await repo.updateStatus('t-1', 'COMPLETED');
      await repo.delete('t-1');
      await repo.followTournament('t-1');
      await repo.unfollowTournament('t-1');
      await repo.updateToken('t-1', 'REFEREE', 'tok'); // intentionally a no-op

      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'PATCH /tournaments/t-1',
        'PATCH /tournaments/t-1',
        'DELETE /tournaments/t-1',
        'POST /tournaments/t-1/follow',
        'DELETE /tournaments/t-1/follow',
      ]);
      expect(adapter.requests[0].body, {'name': 'Mới'});
      expect(adapter.requests[1].body, {'status': 'COMPLETED'});
    });

    test('followed list and isFollowing degrade to empty/false on failure',
        () async {
      final (repo, _) = _setup({
        'GET /tournaments/my/followed': FakeReply(200, {
          'data': [_tournament('f1')],
        }),
      });
      final (failing, _) = _setup({});

      expect((await repo.getFollowedTournaments()).single.id, 'f1');
      expect(await repo.isFollowing('f1'), isTrue);
      expect(await repo.isFollowing('other'), isFalse);
      expect(await failing.getFollowedTournaments(), isEmpty);
      expect(await failing.isFollowing('f1'), isFalse);
    });

    test('getGroupStandings unwraps data, filters division, returns {} on '
        'error', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/t-1/standings': const FakeReply(200, {
          'data': {'groups': <dynamic>[]},
        }),
      });

      final standings = await repo.getGroupStandings('t-1', divisionId: 'd1');
      await repo.getGroupStandings('t-1', divisionId: '');

      expect(standings, {'groups': <dynamic>[]});
      expect(adapter.requests[0].query, {'divisionId': 'd1'});
      expect(adapter.requests[1].query, isEmpty);
      expect(await _setup({}).$1.getGroupStandings('t-1'), isEmpty);
    });
  });

  group('getBracketMatches', () {
    test('flattens stages and groups, maps status/branch and sorts', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1/bracket': FakeReply(
          200,
          _bracket([
            _match('m2', round: 2, order: 1, status: 'COMPLETED'),
            _match('m1', round: 1, order: 2, status: 'IN_PROGRESS'),
            _match('m0', round: 1, order: 1, status: 'WALKOVER', branch: 'LOSERS'),
            _match('mc', round: 3, order: 1, status: 'CANCELLED', branch: 'GRAND_FINALS'),
            _match('mp', round: 3, order: 2, branch: 'PLAYOFF'),
          ]),
        ),
      });

      final matches = await repo.getBracketMatches('t-1');

      expect(matches.map((m) => m.id), ['m0', 'm1', 'm2', 'mc', 'mp']);
      expect(matches.map((m) => m.status), [
        'walkover',
        'live',
        'completed',
        'cancelled',
        'scheduled',
      ]);
      expect(matches.map((m) => m.bracketPosition.bracket), [
        'losers',
        'winners',
        'winners',
        'grand_final',
        'playoff',
      ]);
      expect(matches.first.groupName, 'Bảng X');
      expect(matches.first.stageName, 'Vòng loại');
      expect(matches.first.stageType, 'KNOCKOUT');
      expect(matches.first.divisionId, 'd-stage');
    });

    test('parses scores, sets, court display and team names', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1/bracket': FakeReply(
          200,
          _bracket([
            _match(
              'm1',
              extra: {
                'p1SetsWon': 2,
                'p2SetsWon': '1',
                'divisionId': 'd-own',
                'courtName': 'Sân 1',
                'courtAddress': '1 Lê Lợi',
                'scoreDetails': {
                  'sets': [
                    {'team1Score': 11, 'team2Score': 7},
                    {'score1': '5', 'p2': 11},
                  ],
                },
                'participant2': {'id': 'b'},
                'nextMatchId': 'n1',
                'isBye': true,
                'setsToWin': 2,
              },
            ),
          ]),
        ),
      });

      final m = (await repo.getBracketMatches('t-1')).single;

      expect(m.score1, 2);
      expect(m.score2, 1);
      expect(m.sets.map((s) => (s.score1, s.score2)), [(11, 7), (5, 11)]);
      expect(m.court, 'Sân 1 - 1 Lê Lợi');
      expect(m.divisionId, 'd-own'); // the match's own id beats the stage's
      expect(m.team1Name, 'Đội A');
      expect(m.team2Name, 'TBD'); // no team name and no players
      expect(m.nextMatchId, 'n1');
      expect(m.isBye, isTrue);
      expect(m.setsToWin, 2);
    });

    test('a specific division with no matches returns [] without fallback',
        () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/t-1/bracket': const FakeReply(200, {'data': {}}),
      });

      expect(await repo.getBracketMatches('t-1', divisionId: 'd1'), isEmpty);
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.query, {'divisionId': 'd1'});
    });

    test('with no matches for "all divisions" it queries every division once '
        'and does not recurse', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/t-1/divisions': const FakeReply(200, {
          'data': [
            {'id': 'd1', 'name': 'A'},
            {'id': 'd2', 'name': 'B'},
          ],
        }),
        'GET /tournaments/t-1/bracket': const FakeReply(200, {
          'data': {'stages': <dynamic>[]},
        }),
      });

      expect(await repo.getBracketMatches('t-1'), isEmpty);

      final bracketCalls = adapter.requests
          .where((r) => r.path == '/tournaments/t-1/bracket')
          .map((r) => r.query['divisionId'])
          .toList();
      expect(bracketCalls, [null, 'd1', 'd2']);
    });

    test('allowAggregateFallback false skips the division lookup', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/t-1/bracket': const FakeReply(200, {
          'data': {'stages': <dynamic>[]},
        }),
      });

      final matches = await repo.getBracketMatches(
        't-1',
        allowAggregateFallback: false,
      );

      expect(matches, isEmpty);
      expect(adapter.requests.map((r) => r.path), ['/tournaments/t-1/bracket']);
    });

    test('a request failure returns an empty list', () async {
      final (repo, _) = _setup({});

      expect(await repo.getBracketMatches('t-1', divisionId: 'd1'), isEmpty);
    });
  });

  group('bracket editing', () {
    test('updateBracketSlots uses the lite route when asked', () async {
      final (repo, adapter) = _setup({
        'PATCH /tournaments/t-1/divisions/d1/bracket/slots':
            const FakeReply(200, {}),
        'PATCH /tournaments/lite/t-1/divisions/d1/bracket/slots':
            const FakeReply(200, {}),
      });
      final ops = [
        {'type': 'SWAP'},
      ];

      await repo.updateBracketSlots('t-1', divisionId: 'd1', operations: ops);
      await repo.updateBracketSlots(
        't-1',
        divisionId: 'd1',
        operations: ops,
        isLite: true,
      );

      expect(adapter.requests.map((r) => r.path), [
        '/tournaments/t-1/divisions/d1/bracket/slots',
        '/tournaments/lite/t-1/divisions/d1/bracket/slots',
      ]);
      expect(adapter.requests.first.body, {'operations': ops});
    });

    test('updateBracketSlots requires a division and surfaces HTTP errors',
        () async {
      final (repo, adapter) = _setup({});

      await expectLater(
        repo.updateBracketSlots('t-1', operations: const []),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.updateBracketSlots('t-1', divisionId: '', operations: const []),
        throwsA(isA<ArgumentError>()),
      );
      expect(adapter.requests, isEmpty);
      await expectLater(
        repo.updateBracketSlots('t-1', divisionId: 'd1', operations: const []),
        throwsA(isA<DioException>()),
      );
    });

    test('seed order and stage round config use the documented routes',
        () async {
      final (repo, adapter) = _setup({
        'PATCH /tournaments/t-1/divisions/d1/bracket/seed-order':
            const FakeReply(200, {}),
        'PATCH /tournaments/stages/s1': const FakeReply(200, {}),
      });

      await repo.updateSeedOrder(
        't-1',
        divisionId: 'd1',
        stageId: 's1',
        slotOrder: const [
          {'slot': 1},
        ],
      );
      await repo.updateStageRoundConfig('t-1', 's1', {'rounds': 3});

      expect(adapter.requests[0].body, {
        'stageId': 's1',
        'slotOrder': [
          {'slot': 1},
        ],
      });
      expect(adapter.requests[1].path, '/tournaments/stages/s1');
      expect(adapter.requests[1].body, {
        'roundConfig': {'rounds': 3},
      });
    });

    test('generateBracket omits a blank division and tolerates odd bodies',
        () async {
      final (repo, adapter) = _setup({
        'POST /tournaments/t-1/generate-bracket': const FakeReply(200, {
          'data': {'created': 7},
        }),
      });
      final (odd, _) = _setup({
        'POST /tournaments/t-1/generate-bracket': const FakeReply(200, 'x'),
      });

      final result = await repo.generateBracket(
        't-1',
        divisionId: '',
        seedingType: 'RANDOM',
        allowReset: true,
      );

      expect(result, {'created': 7});
      expect(adapter.requests.single.body, {
        'seedingType': 'RANDOM',
        'allowReset': true,
      });
      expect(
        await odd.generateBracket('t-1', seedingType: 'RANDOM'),
        isEmpty,
      );
    });
  });

  group('swiss and stage lookups', () {
    test('getSwissStage returns the SWISS stage only', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/t-1/bracket': const FakeReply(200, {
          'data': {
            'stages': [
              {'id': 'ko', 'type': 'KNOCKOUT'},
              {
                'id': 'sw',
                'type': 'swiss',
                'roundConfig': {
                  'swiss': {'totalRounds': 5},
                },
              },
            ],
          },
        }),
      });

      final stage = await repo.getSwissStage('t-1', divisionId: 'd1');

      expect(stage?.stageId, 'sw');
      expect(stage?.totalRounds, 5);
      expect(adapter.requests.single.query, {'divisionId': 'd1'});
    });

    test('getSwissStage is null without a swiss stage or stages list',
        () async {
      final (none, _) = _setup({
        'GET /tournaments/t-1/bracket': const FakeReply(200, {
          'data': {
            'stages': [
              {'id': 'ko', 'type': 'KNOCKOUT'},
            ],
          },
        }),
      });
      final (bare, _) = _setup({
        'GET /tournaments/t-1/bracket': const FakeReply(200, <dynamic>[]),
      });

      expect(await none.getSwissStage('t-1'), isNull);
      expect(await bare.getSwissStage('t-1'), isNull);
    });

    test('getDivisionStages keeps only object stages', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1/bracket': const FakeReply(200, {
          'data': {
            'stages': [
              {'id': 's1'},
              'junk',
            ],
          },
        }),
      });

      expect(await repo.getDivisionStages('t-1', divisionId: 'd1'), [
        {'id': 's1'},
      ]);
    });

    test('swissUndoRound returns the server round, or the requested one',
        () async {
      final (repo, adapter) = _setup({
        'POST /tournaments/t-1/swiss/rounds/3/undo': const FakeReply(200, {
          'data': {'roundNumber': 2},
        }),
        'POST /tournaments/t-1/swiss/rounds/4/undo': const FakeReply(200, {
          'data': {},
        }),
      });

      expect(await repo.swissUndoRound('t-1', 3, divisionId: 'd1'), 2);
      expect(
        await repo.swissUndoRound('t-1', 4, divisionId: 'd1', stageId: 's9'),
        4,
      );
      expect(adapter.requests[0].body, {'divisionId': 'd1'});
      expect(adapter.requests[1].body, {'divisionId': 'd1', 'stageId': 's9'});
    });

    test('swiss failures carry the HTTP status and server error code',
        () async {
      final (repo, _) = _setup({
        'POST /tournaments/t-1/swiss/rounds/1/undo': const FakeReply(409, {
          'code': 'SWISS_ROUND_LOCKED',
          'message': 'Vòng đã khoá',
        }),
      });

      await expectLater(
        repo.swissUndoRound('t-1', 1, divisionId: 'd1'),
        throwsA(
          isA<SwissApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.code, 'code', 'SWISS_ROUND_LOCKED')
              .having((e) => e.message, 'message', 'Vòng đã khoá'),
        ),
      );
    });
  });

  group('watchBracketMatches', () {
    test('emits an initial snapshot and stops cleanly on cancel', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/t-1/bracket': FakeReply(
          200,
          _bracket([_match('m1')]),
        ),
      });

      final first = await repo
          .watchBracketMatches('t-1', divisionId: 'd1')
          .first;

      expect(first.map((m) => m.id), ['m1']);
      expect(adapter.requests.first.query, {'divisionId': 'd1'});
    });
  });
}
