import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/participant_detail_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_athletes_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/xem.dart';

/// Team list, athletes tab, athlete profile sheet and the schedule grid, on
/// fake data only (no Backend, no network).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initXem);

  testWidgets('xem: danh sach doi', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      _fakeApp(
        overrides: [
          teamsProvider.overrideWith((ref, id) => Stream.value(_teams)),
          tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        ],
        home: const TeamListScreen(tournamentId: 'tournament-1'),
      ),
    );
    await shooter.snap('danh-sach-doi');
  });

  testWidgets('xem: tab VDV hang nut va hang VDV', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      _fakeApp(
        overrides: [
          introTeamsProvider(
            'tournament-1',
          ).overrideWith((ref) async => const <Team>[]),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => _divisions),
          tournamentRepositoryProvider.overrideWithValue(
            _ParticipantsRepository(),
          ),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _EmptyManagementRepository(),
          ),
        ],
        home: Scaffold(
          body: TournamentManagementAthletesTab(tournament: _tournament()),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('athlete-division-div-mixed')));
    await settle(tester);
    await shooter.snap('tab-vdv-hang-muc-mo');

    await tester.tap(find.byKey(const ValueKey('athletes-more')));
    await settle(tester);
    await shooter.snap('tab-vdv-menu-khac');
  });

  testWidgets('xem: tab VDV hop chon cach ghep tu dong', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      _fakeApp(
        overrides: [
          introTeamsProvider(
            'tournament-1',
          ).overrideWith((ref) async => const <Team>[]),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => _divisions),
          tournamentRepositoryProvider.overrideWithValue(
            _ParticipantsRepository(),
          ),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _EmptyManagementRepository(),
          ),
        ],
        home: Scaffold(
          body: TournamentManagementAthletesTab(tournament: _tournament()),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('athlete-division-div-mixed')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('athletes-auto-pair')));
    await settle(tester);
    await shooter.snap('tab-vdv-tu-ghep');
  });

  testWidgets('xem: tab VDV dang mo dang ky an vong check-in', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      _fakeApp(
        overrides: [
          introTeamsProvider(
            'tournament-1',
          ).overrideWith((ref) async => const <Team>[]),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => _divisions),
          tournamentRepositoryProvider.overrideWithValue(
            _ParticipantsRepository(),
          ),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _EmptyManagementRepository(),
          ),
        ],
        home: Scaffold(
          body: TournamentManagementAthletesTab(
            tournament: _tournament('registration'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('athlete-division-div-mixed')));
    await settle(tester);
    await shooter.snap('tab-vdv-dang-ky');
  });

  testWidgets('xem: ho so VDV', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      _fakeApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _EmptyManagementRepository(),
          ),
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                key: const ValueKey('open-sheet'),
                onPressed: () => ParticipantDetailSheet.show(
                  context,
                  tournamentId: 'tournament-1',
                  participant: _pendingParticipant,
                  tournamentStatus: 'REGISTRATION',
                  divisionName: 'Doi Nam Nu',
                  pairFormat: true,
                ),
                child: const Text('Mo ho so'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-sheet')));
    await settle(tester);
    await shooter.snap('ho-so-vdv');
  });

  testWidgets('xem: luoi lich', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      _fakeApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _VenuesRepository(),
          ),
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentScheduleCourtGrid(
              tournamentId: 'tournament-1',
              matches: _scheduleMatches(),
              scheduleSettings: const {
                'operatingStart': '07:00',
                'operatingEnd': '10:00',
                'minutesPerSet': 15,
              },
            ),
          ),
        ),
      ),
    );
    await shooter.snap('lich-luoi-san');
  });
}

/// [xemApp] plus a fake ELO lookup: avatars in these screens would otherwise
/// call `GET /rankings/user/:id` on the real DioClient (no Backend here), and
/// the late failure leaks into whichever test is running next.
Widget _fakeApp({required Widget home, List<Override> overrides = const []}) =>
    xemApp(
      home: home,
      overrides: [
        userRankingsSummaryProvider.overrideWith(
          (ref, userId) async => const <PlayerRanking>[],
        ),
        ...overrides,
      ],
    );

// --- Fixtures -----------------------------------------------------------

final _teams = [
  _team('a', 'Alpha Pair', ['Alice Alpha', 'Anna Apex']),
  _team('b', 'Beta Pair', ['Bob Beta', 'Ben Bolt']),
  _team('c', 'Gamma Pair', ['Gus Gamma', 'Gil Gold'], status: 'PENDING'),
];

Team _team(
  String id,
  String name,
  List<String> members, {
  String status = 'COMPLETE',
}) => Team(
  id: id,
  name: name,
  members: members,
  approvalStatus: status,
  createdAt: DateTime(2026, 1, 1),
);

const _divisions = <Map<String, dynamic>>[
  {'id': 'div-mixed', 'name': 'Doi Nam Nu', 'matchType': 'DOUBLES'},
  {'id': 'div-men', 'name': 'Don nam', 'matchType': 'SINGLES'},
];

Tournament _tournament([String status = 'in_progress']) => Tournament.fromJson({
  'name': 'Giai thu nghiem',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 16,
  'maxPlayersPerTeam': 2,
  'divisions': _divisions,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

const _participants = [
  OrganizerOpsParticipant(
    id: 'p-1',
    teamName: 'Nguyen Van A',
    teamStatus: 'COMPLETE',
    isPaid: true,
    isPresent: true,
    entryFee: 200000,
    members: [OrganizerOpsMember(userId: 'u-a', fullName: 'Nguyen Van A')],
    divisionId: 'div-mixed',
  ),
  OrganizerOpsParticipant(
    id: 'p-2',
    teamName: 'Tran Thi B',
    teamStatus: 'COMPLETE',
    isPaid: false,
    entryFee: 200000,
    members: [OrganizerOpsMember(userId: 'u-b', fullName: 'Tran Thi B')],
    divisionId: 'div-mixed',
  ),
  OrganizerOpsParticipant(
    id: 'p-3',
    teamName: 'Le Van C',
    teamStatus: 'PENDING_APPROVAL',
    isPaid: false,
    entryFee: 200000,
    members: [OrganizerOpsMember(userId: 'u-c', fullName: 'Le Van C')],
    divisionId: 'div-mixed',
  ),
  // Waiting for a partner: yellow "Cho" pill + the badge on the Ghep doi box.
  OrganizerOpsParticipant(
    id: 'p-4',
    teamName: 'Pham Van D',
    teamStatus: 'PENDING_PARTNER',
    isPaid: false,
    entryFee: 200000,
    members: [OrganizerOpsMember(userId: 'u-d', fullName: 'Pham Van D')],
    divisionId: 'div-mixed',
  ),
  // Approved with no entry fee: shows "Mien phi".
  OrganizerOpsParticipant(
    id: 'p-5',
    teamName: 'Hoang Thi E',
    teamStatus: 'COMPLETE',
    isPaid: false,
    members: [OrganizerOpsMember(userId: 'u-e', fullName: 'Hoang Thi E')],
    divisionId: 'div-mixed',
  ),
];

const _pendingParticipant = OrganizerOpsParticipant(
  id: 'p-3',
  teamName: 'Tran Thi B',
  teamStatus: 'COMPLETE',
  isPaid: false,
  entryFee: 200000,
  members: [
    OrganizerOpsMember(
      userId: 'u-b',
      fullName: 'Tran Thi B',
      phoneNumber: '0901123123',
    ),
  ],
);

class _ParticipantsRepository implements ITournamentRepository {
  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => divisionId == null
      ? _participants
      : _participants.where((p) => p.divisionId == divisionId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyManagementRepository implements TournamentManagementRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VenuesRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Nha thi dau',
      'courts': [
        {'id': 'court-1', 'name': 'San 1'},
        {'id': 'court-2', 'name': 'San 2'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DateTime _at(int hour) => DateTime(2026, 10, 24, hour);

MatchModel _match(
  String id,
  String names, {
  String? courtId,
  String? courtName,
  DateTime? at,
  String team1Id = '',
  String team2Id = '',
}) {
  final parts = names.split(' - ');
  return MatchModel(
    id: id,
    round: 1,
    matchNumber: 1,
    team1Id: team1Id,
    team2Id: team2Id,
    team1Name: parts.first,
    team2Name: parts.last,
    status: 'scheduled',
    courtId: courtId,
    courtName: courtName,
    scheduledTime: at,
    bracketPosition: const BracketPosition(round: 1, position: 0),
    updatedAt: DateTime.utc(2026),
  );
}

/// Four placed matches (two share a team at 09:00, so they clash) plus five
/// still waiting for a slot.
List<MatchModel> _scheduleMatches() => [
  _match('m1', 'A - B', courtId: 'court-1', courtName: 'San 1', at: _at(7)),
  _match('m2', 'C - D', courtId: 'court-2', courtName: 'San 2', at: _at(7)),
  _match(
    'm3',
    'G - H',
    courtId: 'court-1',
    courtName: 'San 1',
    at: _at(9),
    team1Id: 'team-g',
    team2Id: 'team-h',
  ),
  _match(
    'm4',
    'I - G',
    courtId: 'court-2',
    courtName: 'San 2',
    at: _at(9),
    team1Id: 'team-i',
    team2Id: 'team-g',
  ),
  for (var i = 0; i < 5; i++) _match('w$i', 'W${i}A - W${i}B'),
];
