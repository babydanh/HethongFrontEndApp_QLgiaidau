import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

(ApiTeamRepository, FakeApiAdapter) _setup(Map<String, FakeReply> routes) {
  final adapter = FakeApiAdapter(routes);
  return (ApiTeamRepository(fakeDioClient(adapter)), adapter);
}

Team _team({
  String name = 'Đội A',
  String contact = '',
  List<String> members = const [],
  List<MatchMemberInfo> infos = const [],
}) => Team(
  id: 'x',
  name: name,
  contactEmail: contact,
  members: members,
  memberInfos: infos,
  createdAt: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('football team accounts', () {
    test('listMyFootballTeams parses membership role and rank', () async {
      final (repo, _) = _setup({
        'GET /football-teams/mine': const FakeReply(200, {
          'data': [
            {
              'team': {
                'id': 't1',
                'name': 'FC Vợt',
                'categoryId': 'cat',
                'status': 'active',
                'members': [
                  {'userId': 'u1', 'role': 'captain', 'status': 'ACTIVE'},
                  {'user_id': 'u2', 'status': 'INVITED'},
                  {'userId': 'u3'},
                ],
              },
              'membership': {'role': 'captain'},
              'rank': {'eloPoints': 1234, 'matchesWon': 5, 'winStreak': 2},
            },
            'not-a-map',
          ],
        }),
      });

      final teams = await repo.listMyFootballTeams();

      expect(teams, hasLength(1));
      final team = teams.single;
      expect(team.role, 'CAPTAIN');
      expect(team.status, 'ACTIVE');
      expect(team.eloPoints, 1234);
      expect(team.peakElo, 1000); // missing rank fields fall back to defaults
      expect(team.matchesWon, 5);
      expect(team.winStreak, 2);
      expect(team.members.map((m) => m.role), ['CAPTAIN', 'PLAYER', 'PLAYER']);
      // Only joined members (ACTIVE or no status) count as active.
      expect(team.activeMembers.map((m) => m.userId), ['u1', 'u3']);
    });

    test('listMyFootballTeams returns empty when data is not a list',
        () async {
      final (repo, _) = _setup({
        'GET /football-teams/mine': const FakeReply(200, {'data': 'x'}),
      });

      expect(await repo.listMyFootballTeams(), isEmpty);
    });

    test('createFootballTeam trims the name and rejects a non-object reply',
        () async {
      final (repo, adapter) = _setup({
        'POST /football-teams': const FakeReply(201, {
          'data': {'id': 't9', 'name': 'Mới'},
        }),
      });

      final created = await repo.createFootballTeam(
        name: '  Mới  ',
        categoryId: 'cat',
      );

      expect(created.id, 't9');
      expect(adapter.requests.single.body, {'name': 'Mới', 'categoryId': 'cat'});

      final (bad, _) = _setup({
        'POST /football-teams': const FakeReply(201, {'data': 'oops'}),
      });
      await expectLater(
        bad.createFootballTeam(name: 'x', categoryId: 'c'),
        throwsA(isA<FormatException>()),
      );
    });

    test('getFootballTeam reads the enveloped or the bare team', () async {
      final (repo, _) = _setup({
        'GET /football-teams/t1': const FakeReply(200, {
          'data': {'id': 't1', 'name': 'Bọc'},
        }),
        'GET /football-teams/t2': const FakeReply(200, {
          'id': 't2',
          'name': 'Trần',
        }),
      });

      expect((await repo.getFootballTeam('t1')).name, 'Bọc');
      expect((await repo.getFootballTeam('t2')).name, 'Trần');
    });

    test('updateFootballTeam only sends the fields that changed', () async {
      final (repo, adapter) = _setup({
        'PATCH /football-teams/t1': const FakeReply(200, {
          'data': {'id': 't1', 'name': 'Tên mới'},
        }),
      });

      await repo.updateFootballTeam('t1', name: '  Tên mới ');
      await repo.updateFootballTeam('t1', status: 'DISBANDED');

      expect(adapter.requests[0].body, {'name': 'Tên mới'});
      expect(adapter.requests[1].body, {'status': 'DISBANDED'});
    });

    test('uploadFootballTeamLogo uploads then patches the logoUrl', () async {
      final (repo, adapter) = _setup({
        'POST /upload/image': const FakeReply(200, {
          'data': {'url': 'https://cdn/logo.png'},
        }),
        'PATCH /football-teams/t1': const FakeReply(200, {
          'data': {'id': 't1', 'name': 'FC', 'logoUrl': 'https://cdn/logo.png'},
        }),
      });

      final team = await repo.uploadFootballTeamLogo('t1', [1, 2], 'l.png');

      expect(team.logoUrl, 'https://cdn/logo.png');
      expect(adapter.requests.last.body, {'logoUrl': 'https://cdn/logo.png'});
    });

    test('uploadFootballTeamLogo stops before patching when no url returned',
        () async {
      final (repo, adapter) = _setup({
        'POST /upload/image': const FakeReply(200, {'data': {}}),
      });

      await expectLater(
        repo.uploadFootballTeamLogo('t1', [1], 'l.png'),
        throwsA(isA<FormatException>()),
      );
      expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
    });

    test('searchFootballTeamMembers keeps only object rows', () async {
      final (repo, adapter) = _setup({
        'GET /football-teams/t1/member-candidates': const FakeReply(200, {
          'data': [
            {'id': 'u1'},
            7,
          ],
        }),
      });

      final rows = await repo.searchFootballTeamMembers('t1', 'an');

      expect(rows, [
        {'id': 'u1'},
      ]);
      expect(adapter.requests.single.query, {'q': 'an', 'limit': 20});
    });

    test('invite, cancel, respond, role, remove and leave hit their routes',
        () async {
      final (repo, adapter) = _setup({
        'POST /football-teams/t1/invites': const FakeReply(200, {}),
        'DELETE /football-teams/t1/invites/u1': const FakeReply(200, {}),
        'POST /football-teams/t1/invites/respond': const FakeReply(200, {}),
        'PATCH /football-teams/t1/members/u1': const FakeReply(200, {}),
        'DELETE /football-teams/t1/members/u1': const FakeReply(200, {}),
        'DELETE /football-teams/t1/members/me': const FakeReply(200, {}),
      });

      await repo.inviteFootballTeamMember('t1', 'u1');
      await repo.cancelFootballTeamInvite('t1', 'u1');
      await repo.respondToFootballTeamInvite('t1', 'ACCEPTED');
      await repo.updateFootballTeamMember('t1', 'u1', 'CAPTAIN');
      await repo.removeFootballTeamMember('t1', 'u1');
      await repo.leaveFootballTeam('t1');

      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /football-teams/t1/invites',
        'DELETE /football-teams/t1/invites/u1',
        'POST /football-teams/t1/invites/respond',
        'PATCH /football-teams/t1/members/u1',
        'DELETE /football-teams/t1/members/u1',
        'DELETE /football-teams/t1/members/me',
      ]);
      expect(adapter.requests[0].body, {'userId': 'u1'});
      expect(adapter.requests[2].body, {'status': 'ACCEPTED'});
      expect(adapter.requests[3].body, {'role': 'CAPTAIN'});
    });
  });

  group('tournament registration payload', () {
    const route = 'POST /tournaments/t-1/register';
    const reply = FakeReply(201, {
      'data': {
        'participant': {'id': 'p1', 'teamName': 'Đội A'},
      },
    });

    test('sends distinct non-empty memberIds and omits playerNames', () async {
      final (repo, adapter) = _setup({route: reply});

      await repo.create(
        't-1',
        _team(
          contact: 'a@b.c',
          infos: const [
            MatchMemberInfo(userId: 'u1', fullName: 'An'),
            MatchMemberInfo(userId: 'u1', fullName: 'An lặp'),
            MatchMemberInfo(userId: '', fullName: 'Rỗng'),
            MatchMemberInfo(fullName: 'Khách'),
          ],
        ),
      );

      expect(adapter.requests.single.body, {
        'teamName': 'Đội A',
        'contactPhone': 'a@b.c',
        'memberIds': ['u1'],
      });
    });

    test('falls back to member names, then to the team name, and a default '
        'phone', () async {
      final (repo, adapter) = _setup({route: reply});

      await repo.create('t-1', _team(members: ['B', 'C']));
      await repo.create('t-1', _team());

      expect(adapter.requests[0].body, {
        'teamName': 'Đội A',
        'contactPhone': '0900000000',
        'playerNames': ['B', 'C'],
      });
      expect(adapter.requests[1].body!['playerNames'], ['Đội A']);
    });

    test('returns the Team parsed from data when there is no participant',
        () async {
      final (repo, _) = _setup({
        route: const FakeReply(200, {
          'data': {'id': 'p2', 'teamName': 'Phẳng'},
        }),
      });

      expect((await repo.create('t-1', _team())).id, 'p2');
    });

    test('a non-200/201 success status becomes an Exception', () async {
      final (repo, _) = _setup({route: const FakeReply(204, {})});

      await expectLater(repo.create('t-1', _team()), throwsA(isA<Exception>()));
    });

    test('importTeams registers every team in order', () async {
      final (repo, adapter) = _setup({route: reply});

      await repo.importTeams('t-1', [_team(name: 'A'), _team(name: 'B')]);

      expect(
        adapter.postsTo('/tournaments/t-1/register').map((r) => r.body!['teamName']),
        ['A', 'B'],
      );
    });
  });

  group('participants', () {
    final routes = {
      'GET /tournaments/t-1/divisions': const FakeReply(200, {
        'data': [
          {'id': 'd1', 'name': 'Đôi nam'},
          {'id': '', 'name': 'bỏ'},
        ],
      }),
      'GET /tournaments/t-1/participants': const FakeReply(200, {
        'data': [
          {
            'id': 'p1',
            'teamName': 'Đội 1',
            'divisionId': 'd1',
            'teamStatus': 'approved',
            'qrCode': 'QR1',
            'contactPhone': '0911',
            'createdAt': '2026-05-01T00:00:00Z',
            'members': [
              {'fullName': 'An', 'userId': 'u1'},
              {'user': {'fullName': 'Bình'}},
              {'fullName': ''},
            ],
          },
          {
            'id': 'p2',
            'status': 'pending',
            'registeredBy': 'u9',
            'registeredByUser': {
              'id': 'u9',
              'fullName': 'Chủ đội',
              'avatarUrl': 'https://img/a.png',
              'eloPoints': 1500,
            },
            'division': {'id': 'dx', 'name': 'Đơn nữ'},
          },
        ],
      }),
    };

    test('maps division names, status casing, roster and single-registrant '
        'fallback', () async {
      final (repo, _) = _setup(routes);

      final teams = await repo.getAllByTournament('t-1');

      expect(teams, hasLength(2));
      final a = teams[0];
      expect(a.group, 'Đôi nam'); // resolved through the divisions list
      expect(a.approvalStatus, 'APPROVED');
      expect(a.qrCode, 'QR1');
      expect(a.contactEmail, '0911');
      expect(a.members, ['An', 'Bình']);
      expect(a.createdAt, DateTime.utc(2026, 5, 1));
      final b = teams[1];
      expect(b.group, 'Đơn nữ'); // inline division object wins
      expect(b.approvalStatus, 'PENDING');
      expect(b.qrCode, 'p2'); // qrCode falls back to the id
      expect(b.userId, 'u9');
      expect(b.photoUrl, 'https://img/a.png');
      expect(b.memberInfos.single.fullName, 'Chủ đội');
      expect(b.memberInfos.single.eloPoints, 1500);
    });

    test('still lists participants when the divisions request fails', () async {
      final (repo, _) = _setup({
        'GET /tournaments/t-1/participants': routes[
            'GET /tournaments/t-1/participants']!,
      });

      final teams = await repo.getAllByTournament('t-1');

      expect(teams, hasLength(2));
      expect(teams.first.group, '');
    });

    test('returns an empty list when the participants request fails', () async {
      final (repo, _) = _setup({});

      expect(await repo.getAllByTournament('t-1'), isEmpty);
    });

    test('getById, findByQrCode and count work off the loaded list', () async {
      final (repo, _) = _setup(routes);

      expect((await repo.getById('t-1', 'p2'))?.id, 'p2');
      expect(await repo.getById('t-1', 'nope'), isNull);
      expect((await repo.findByQrCode('t-1', 'QR1'))?.id, 'p1');
      expect(await repo.findByQrCode('t-1', 'zzz'), isNull);
      expect(await repo.count('t-1'), 2);
    });

    test('update, delete and deleteAll call the participant routes', () async {
      final (repo, adapter) = _setup({
        ...routes,
        'PATCH /tournaments/t-1/participants/p1': const FakeReply(200, {}),
        'DELETE /tournaments/t-1/participants/p1': const FakeReply(200, {}),
        'DELETE /tournaments/t-1/participants/p2': const FakeReply(200, {}),
      });

      await repo.update('t-1', 'p1', {'teamStatus': 'APPROVED'});
      await repo.delete('t-1', 'p1');
      adapter.requests.clear();
      await repo.deleteAll('t-1');

      expect(
        adapter.requests
            .where((r) => r.method == 'DELETE')
            .map((r) => r.path),
        [
          '/tournaments/t-1/participants/p1',
          '/tournaments/t-1/participants/p2',
        ],
      );
    });

    test('update propagates server errors', () async {
      final (repo, _) = _setup({});

      await expectLater(
        repo.update('t-1', 'p1', {}),
        throwsA(isA<DioException>()),
      );
    });

    test('watchByTournament emits the first snapshot immediately', () async {
      final (repo, _) = _setup(routes);

      final first = await repo.watchByTournament('t-1').first;

      expect(first, hasLength(2));
    });
  });
}
