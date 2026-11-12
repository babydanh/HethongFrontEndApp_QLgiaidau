import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_api_adapter.dart';

Map<String, dynamic> _tournament({
  String id = 't-1',
  String name = 'Cúp A',
  List<dynamic>? divisions,
  String format = 'singles',
}) => {
  'id': id,
  'name': name,
  'sport': 'pickleball',
  'format': format,
  'status': 'in_progress',
  'maxTeams': 8,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  ...?divisions == null ? null : {'divisions': divisions},
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

  group('getById', () {
    test('uses the detailed divisions when the detail has none', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1': FakeReply(200, {'data': _tournament()}),
        'GET /tournaments/t-1/divisions': const FakeReply(200, {
          'data': [
            {'id': 'd1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
          ],
        }),
      });

      final t = await repo.getById('t-1');

      expect(t?.divisions.map((d) => d.id), ['d1']);
    });

    test(
      'merges detailed division fields over the embedded ones by id',
      () async {
        final (repo, _) = _setup({
          'GET /tournaments/t-1': FakeReply(200, {
            'data': _tournament(
              divisions: [
                {'id': 'd1', 'name': 'Tên cũ', 'matchType': 'SINGLES'},
                {
                  'id': 'd2',
                  'name': 'Không có chi tiết',
                  'matchType': 'SINGLES',
                },
              ],
            ),
          }),
          'GET /tournaments/t-1/divisions': const FakeReply(200, {
            'data': [
              {'id': 'd1', 'name': 'Tên mới', 'matchType': 'DOUBLES'},
            ],
          }),
        });

        final t = await repo.getById('t-1');

        expect(t?.divisions.map((d) => d.name), [
          'Tên mới',
          'Không có chi tiết',
        ]);
        expect(t?.divisions.first.matchType.toUpperCase(), 'DOUBLES');
      },
    );

    test('forwards a trimmed invite code only when it is not blank', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/t-1': FakeReply(200, {'data': _tournament()}),
      });

      await repo.getById('t-1', inviteCode: '  ABC  ');
      await repo.getById('t-1', inviteCode: '   ');

      final detail = adapter.requests.where(
        (r) => r.path == '/tournaments/t-1',
      );
      expect(detail.map((r) => r.query), [
        {'invite': 'ABC'},
        <String, dynamic>{},
      ]);
    });

    test(
      'still loads when sponsors fail and attaches them when they work',
      () async {
        final (withSponsors, _) = _setup({
          'GET /tournaments/t-1': FakeReply(200, {'data': _tournament()}),
          'GET /tournaments/t-1/sponsors': const FakeReply(200, {
            'data': [
              {'id': 's1', 'displayName': 'Nhà tài trợ', 'logoUrl': 'l.png'},
              {'id': 's2', 'displayName': ''},
            ],
          }),
        });
        final (noSponsors, _) = _setup({
          'GET /tournaments/t-1': FakeReply(200, {'data': _tournament()}),
        });

        final a = await withSponsors.getById('t-1');
        final b = await noSponsors.getById('t-1');

        // A sponsor without a display name is dropped.
        expect(a?.sponsors.map((s) => s.id), ['s1']);
        expect(b?.sponsors, isEmpty);
      },
    );

    test('403 becomes TournamentAccessDeniedException with the server '
        'message', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1': const FakeReply(403, {
          'message': 'Chỉ dành cho thành viên CLB',
        }),
      });

      await expectLater(
        repo.getById('t-1'),
        throwsA(
          isA<TournamentAccessDeniedException>().having(
            (e) => e.message,
            'message',
            'Chỉ dành cho thành viên CLB',
          ),
        ),
      );
    });

    test('403 without a message uses the club-only default text', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1': const FakeReply(403, <String, dynamic>{}),
      });

      await expectLater(
        repo.getById('t-1'),
        throwsA(
          isA<TournamentAccessDeniedException>().having(
            (e) => e.message,
            'message',
            contains('Câu Lạc Bộ'),
          ),
        ),
      );
    });

    test(
      'a later failure returns the cached snapshot, not "not found"',
      () async {
        final adapter = FakeApiAdapter({
          'GET /tournaments/t-1': FakeReply(200, {'data': _tournament()}),
        });
        final repo = ApiTournamentRepository(fakeDioClient(adapter));
        final first = await repo.getById('t-1');

        adapter.routes['GET /tournaments/t-1'] = const FakeReply(500, {});
        final second = await repo.getById('t-1');
        final unknown = await repo.getById('never-loaded');

        expect(first, isNotNull);
        expect(second?.id, 't-1');
        expect(unknown, isNull);
      },
    );

    test('a 200 without data yields null', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1': const FakeReply(200, {'data': null}),
      });

      expect(await repo.getById('t-1'), isNull);
    });
  });

  group('sponsors and invite lookup', () {
    test('getPublicSponsors accepts bare lists and swallows errors', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1/sponsors': const FakeReply(200, [
          {'id': 's1', 'displayName': 'A'},
          'junk',
        ]),
      });

      expect((await repo.getPublicSponsors('t-1')).single.id, 's1');
      expect(await repo.getPublicSponsors('missing'), isEmpty);
    });

    test('getByInviteCode returns the tournament, null on failure', () async {
      final (repo, _) = _setup({
        'GET /tournaments/join/ABC': FakeReply(200, {
          'data': _tournament(id: 't-9'),
        }),
      });

      expect((await repo.getByInviteCode('ABC'))?.id, 't-9');
      expect(await repo.getByInviteCode('BAD'), isNull);
    });
  });

  group('workspace and referee', () {
    test('getMyWorkspace omits an empty cursor and parses meta', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/workspace/me': FakeReply(200, {
          'data': {
            'organizedTournaments': [
              _tournament(),
              {'name': 'không id'},
            ],
            'meta': {'nextCursor': 'n2', 'hasMore': true},
          },
        }),
      });

      final ws = await repo.getMyWorkspace(cursor: '');

      expect(ws.organizedTournaments.map((t) => t.id), ['t-1']);
      expect(ws.nextCursor, 'n2');
      expect(ws.hasMore, isTrue);
      expect(adapter.requests.single.query, {'limit': 20});
    });

    test('getMyWorkspace sends a real cursor and rethrows failures', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/workspace/me': const FakeReply(200, {
          'organizedTournaments': <dynamic>[],
        }),
      });
      final (failing, _) = _setup({});

      await repo.getMyWorkspace(cursor: 'c1', limit: 5);

      expect(adapter.requests.single.query, {'limit': 5, 'cursor': 'c1'});
      await expectLater(failing.getMyWorkspace(), throwsA(isA<DioException>()));
    });

    test('getMyWorkspace forwards the role filter only when given', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/workspace/me': const FakeReply(200, {
          'organizedTournaments': <dynamic>[],
        }),
      });

      await repo.getMyWorkspace(limit: 4, role: 'ORGANIZER');

      expect(adapter.requests.single.query, {'limit': 4, 'role': 'ORGANIZER'});
    });

    test(
      'respondToRefereeInvite and kickParticipant send trimmed payloads',
      () async {
        final (repo, adapter) = _setup({
          'PATCH /tournaments/t-1/referees/r1/respond': const FakeReply(
            200,
            {},
          ),
          'POST /tournaments/t-1/participants/p1/kick': const FakeReply(
            200,
            {},
          ),
        });

        await repo.respondToRefereeInvite(
          tournamentId: 't-1',
          refereeId: 'r1',
          action: 'ACCEPT',
        );
        await repo.kickParticipant(
          tournamentId: 't-1',
          participantId: 'p1',
          reason: '  vắng mặt  ',
        );

        expect(adapter.requests[0].body, {'action': 'ACCEPT'});
        expect(adapter.requests[1].body, {'reason': 'vắng mặt'});
      },
    );
  });

  group('organizer lists', () {
    test(
      'getOrganizerParticipants drops id-less rows and filters division',
      () async {
        final (repo, adapter) = _setup({
          'GET /tournaments/t-1/manage/participants': const FakeReply(200, {
            'data': [
              {'id': 'p1', 'teamName': 'Đội 1'},
              {'teamName': 'không id'},
              7,
            ],
          }),
        });

        final list = await repo.getOrganizerParticipants(
          't-1',
          divisionId: 'd1',
        );
        await repo.getOrganizerParticipants('t-1', divisionId: '');

        expect(list.map((p) => p.id), ['p1']);
        expect(adapter.requests[0].query['divisionId'], 'd1');
        expect(adapter.requests[1].query.containsKey('divisionId'), isFalse);
        // A cache-buster is always sent.
        expect(adapter.requests[0].query.containsKey('_t'), isTrue);
      },
    );

    test(
      'getOrganizerParticipants returns empty when data is not a list',
      () async {
        final (repo, _) = _setup({
          'GET /tournaments/t-1/manage/participants': const FakeReply(200, {
            'data': 'x',
          }),
        });

        expect(await repo.getOrganizerParticipants('t-1'), isEmpty);
      },
    );

    test(
      'getTournamentReferees parses rows and applies the default name',
      () async {
        final (repo, _) = _setup({
          'GET /tournaments/t-1/referees': const FakeReply(200, [
            {'id': 'r1', 'userId': 'u1', 'full_name': 'Trọng Tài A'},
            {'id': 'r2'},
            {'name': 'no id'},
          ]),
        });

        final refs = await repo.getTournamentReferees('t-1');

        expect(refs.map((r) => r.id), ['r1', 'r2']);
        expect(refs[0].fullName, 'Trọng Tài A');
        expect(refs[1].fullName, 'Trọng tài');
      },
    );

    test('getOpsAuditLogs parses actor and falls back for bad dates', () async {
      final (repo, adapter) = _setup({
        'GET /tournaments/t-1/ops-audit-logs': const FakeReply(200, {
          'data': [
            {
              'id': 'a1',
              'table_name': 'matches',
              'recordId': 'm1',
              'created_at': '2026-02-01T00:00:00Z',
              'user': {'email': 'ref@x.vn'},
            },
            {'id': 'a2', 'createdAt': 'not-a-date'},
            {'tableName': 'no id'},
          ],
        }),
      });

      final logs = await repo.getOpsAuditLogs('t-1', divisionId: 'd1');

      expect(logs.map((l) => l.id), ['a1', 'a2']);
      expect(logs[0].tableName, 'matches');
      expect(logs[0].actorName, 'ref@x.vn');
      expect(logs[0].createdAt, DateTime.utc(2026, 2, 1));
      expect(logs[1].action, 'UPDATE');
      expect(logs[1].createdAt.millisecondsSinceEpoch, 0);
      expect(adapter.requests.single.query, {'divisionId': 'd1'});
    });
  });

  group('getDivisions', () {
    test('returns divisions that have an id', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1/divisions': const FakeReply(200, {
          'data': [
            {'id': 'd1', 'name': 'Đơn'},
            {'name': 'không id'},
          ],
        }),
      });

      expect((await repo.getDivisions('t-1')).map((d) => d.id), ['d1']);
    });

    test(
      'falls back to a synthetic default division for a doubles name',
      () async {
        final (repo, _) = _setup({
          'GET /tournaments/t-1': FakeReply(200, {
            'data': _tournament(name: 'Giải đôi nam'),
          }),
          'GET /tournaments/t-1/divisions': const FakeReply(200, {'data': []}),
        });

        final divisions = await repo.getDivisions('t-1');

        expect(divisions, hasLength(1));
        expect(divisions.single.id, 'default_t-1');
        expect(divisions.single.matchType, 'DOUBLES');
        expect(divisions.single.name, 'Giải đôi nam');
      },
    );

    test('singles format gives SINGLES; nothing loadable gives []', () async {
      final (singles, _) = _setup({
        'GET /tournaments/t-1': FakeReply(200, {'data': _tournament()}),
      });
      final (nothing, _) = _setup({});

      expect((await singles.getDivisions('t-1')).single.matchType, 'SINGLES');
      expect(await nothing.getDivisions('t-1'), isEmpty);
    });
  });

  group('registration', () {
    const route = 'POST /tournaments/t-1/register';
    final reply = FakeReply(201, {
      'data': {
        'participant': {'id': 'p1', 'teamStatus': 'WAITLISTED'},
        'entryFee': 150000,
        'paymentEligible': true,
      },
    });

    test(
      'sends only meaningful fields and the invite as a query param',
      () async {
        final (repo, adapter) = _setup({route: reply});

        final result = await repo.registerParticipant(
          tournamentId: 't-1',
          teamName: '  Đội Mới  ',
          divisionId: 'default_t-1',
          inviteCode: ' INV ',
          partnerEmailOrPhone: '   ',
          partnerUserId: ' u2 ',
          memberIds: const [],
          reserveMemberIds: const ['r1'],
          footballTeamId: ' ft ',
          customResponses: const {},
        );

        final sent = adapter.requests.single;
        expect(sent.body, {
          'teamName': 'Đội Mới',
          'partnerUserId': 'u2',
          'footballTeamId': 'ft',
          'reserveMemberIds': ['r1'],
          'rankingConsent': false,
        });
        expect(sent.query, {'invite': 'INV'});
        expect(result.participantId, 'p1');
        expect(result.isWaitlisted, isTrue);
        expect(result.entryFee, 150000);
        expect(result.paymentEligible, isTrue);
      },
    );

    test(
      'keeps a real division id and optional pairing/custom answers',
      () async {
        final (repo, adapter) = _setup({route: reply});

        await repo.registerParticipant(
          tournamentId: 't-1',
          teamName: 'X',
          divisionId: 'd1',
          doublesPairingMode: 'RANDOM',
          rankingConsent: true,
          customResponses: const {'q': 'a'},
          memberIds: const ['m1'],
        );

        expect(adapter.requests.single.body, {
          'teamName': 'X',
          'divisionId': 'd1',
          'doublesPairingMode': 'RANDOM',
          'memberIds': ['m1'],
          'rankingConsent': true,
          'customResponses': {'q': 'a'},
        });
        expect(adapter.requests.single.query, isEmpty);
      },
    );

    test('rejects a non-object response body', () async {
      final (repo, _) = _setup({route: const FakeReply(201, 'oops')});

      await expectLater(
        repo.registerParticipant(tournamentId: 't-1', teamName: 'X'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'joinLite rejects a blank code and drops synthetic division ids',
      () async {
        final (repo, adapter) = _setup({
          'POST /tournaments/lite/join/CODE': const FakeReply(200, {}),
        });

        await expectLater(
          repo.joinLite('   '),
          throwsA(isA<FormatException>()),
        );
        await repo.joinLite(' CODE ', divisionId: 'default_t-1');
        await repo.joinLite('CODE', divisionId: 'd1');

        expect(adapter.requests, hasLength(2));
        expect(adapter.requests[0].body, isNull);
        expect(adapter.requests[1].body, {'divisionId': 'd1'});
      },
    );

    test('withdraw sends only the provided bank/division fields', () async {
      final (repo, adapter) = _setup({
        'POST /tournaments/t-1/withdraw': const FakeReply(200, {
          'refund': 'PENDING',
        }),
      });

      final result = await repo.withdraw(
        tournamentId: 't-1',
        bankName: 'VCB',
        divisionId: 'd1',
      );

      expect(adapter.requests.single.body, {
        'bankName': 'VCB',
        'tournamentDivisionId': 'd1',
      });
      expect(result, {'refund': 'PENDING'});
    });

    test('withdraw returns an empty map for a non-object reply', () async {
      final (repo, _) = _setup({
        'POST /tournaments/t-1/withdraw': const FakeReply(200, <dynamic>[]),
      });

      expect(await repo.withdraw(tournamentId: 't-1'), isEmpty);
    });
  });

  group('public participants', () {
    test(
      'hides withdrawn, rejected and cancelled teams (any casing)',
      () async {
        final (repo, _) = _setup({
          'GET /tournaments/t-1/participants': const FakeReply(200, {
            'data': [
              {'id': 'a', 'teamStatus': 'APPROVED'},
              {'id': 'b', 'teamStatus': 'withdrawn'},
              {'id': 'c', 'teamStatus': 'REJECTED'},
              {'id': 'd', 'teamStatus': 'Cancelled'},
              {'id': 'e'},
            ],
          }),
        });

        final list = await repo.getPublicParticipants('t-1');

        expect(list.map((p) => p.id), ['a', 'e']);
      },
    );

    test('returns empty on failure or a non-list body', () async {
      final (failing, _) = _setup({});
      final (odd, _) = _setup({
        'GET /tournaments/t-1/participants': const FakeReply(200, {'data': 3}),
      });

      expect(await failing.getPublicParticipants('t-1'), isEmpty);
      expect(await odd.getPublicParticipants('t-1'), isEmpty);
    });
  });

  group('football roster', () {
    const base = '/tournaments/t-1/participants/p1/football-roster';

    test('getFootballRosterStatus unwraps data or a bare object', () async {
      final (repo, _) = _setup({
        'GET $base': const FakeReply(200, {
          'data': {
            'entry': {'id': 'e1', 'status': 'PENDING'},
            'roster': [
              {'userId': 'u1'},
              'junk',
            ],
          },
        }),
      });

      final status = await repo.getFootballRosterStatus(
        tournamentId: 't-1',
        participantId: 'p1',
      );

      expect(status.entryId, 'e1');
      expect(status.entryStatus, 'PENDING');
      expect(status.roster, hasLength(1));
    });

    test('invalid roster responses raise FormatException', () async {
      final (repo, _) = _setup({
        'GET $base': const FakeReply(200, 'x'),
        'PATCH $base': const FakeReply(200, 'x'),
      });

      await expectLater(
        repo.getFootballRosterStatus(tournamentId: 't-1', participantId: 'p1'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        repo.updateFootballRoster(
          tournamentId: 't-1',
          participantId: 'p1',
          memberIds: const [],
          reserveMemberIds: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('updateFootballRoster sends both member lists', () async {
      final (repo, adapter) = _setup({
        'PATCH $base': const FakeReply(200, {
          'data': {
            'entry': {'id': 'e1'},
          },
        }),
      });

      final status = await repo.updateFootballRoster(
        tournamentId: 't-1',
        participantId: 'p1',
        memberIds: const ['m1'],
        reserveMemberIds: const ['r1'],
      );

      expect(status.entryId, 'e1');
      expect(adapter.requests.single.body, {
        'memberIds': ['m1'],
        'reserveMemberIds': ['r1'],
      });
    });

    test('respondFootballRoster only accepts CONFIRM or DECLINE', () async {
      final (repo, adapter) = _setup({
        'POST $base/respond': const FakeReply(200, {}),
      });

      await repo.respondFootballRoster(
        tournamentId: 't-1',
        participantId: 'p1',
        action: 'CONFIRM',
      );
      await expectLater(
        repo.respondFootballRoster(
          tournamentId: 't-1',
          participantId: 'p1',
          action: 'confirm',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // The invalid action never reached the network.
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.body, {'action': 'CONFIRM'});
    });
  });
}
