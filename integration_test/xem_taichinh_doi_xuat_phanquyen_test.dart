import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_finance_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_report_sheet.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/xem.dart';

/// Finance, teams, report export sheet and email-invite permissions, on fake
/// data only (no Backend, no network).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initXem);

  testWidgets('xem: tai chinh', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _FinanceRepository(),
          ),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(id: 'user-1', role: 'ORGANIZER'),
          ),
        ],
        home: Scaffold(
          body: TournamentManagementFinanceSection(
            tournament: _tournament(
              status: 'COMPLETED',
              extra: {'creatorId': 'user-1'},
            ),
          ),
        ),
      ),
    );
    await shooter.snap('tai-chinh');
  });

  testWidgets('xem: doi', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          teamsProvider.overrideWith(
            (ref, id) => Stream.value([
              _team('a', 'Alpha Pair', ['Alice Alpha', 'Anna Apex']),
              _team('b', 'Beta Pair', ['Bob Beta', 'Ben Bolt']),
              _team('c', 'Gamma Pair', [
                'Gus Gamma',
                'Gil Gold',
              ], status: 'PENDING'),
            ]),
          ),
          tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        ],
        home: const TeamListScreen(tournamentId: 'tournament-1'),
      ),
    );
    await shooter.snap('doi-danh-sach');
  });

  testWidgets('xem: xuat bao cao', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey('open-sheet'),
                onPressed: () => TournamentReportSheet.show(
                  context,
                  onExport: (Set<TournamentReportSection> sections) async {},
                ),
                child: const Text('Mo sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-sheet')));
    await settle(tester);
    await shooter.snap('xuat-bao-cao');
  });

  testWidgets('xem: phan quyen moi qua email', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _PeopleRepository(),
          ),
        ],
        home: Scaffold(
          body: TournamentManagementPeopleSection(
            tournament: _tournament(status: 'registration'),
            showRegistration: false,
          ),
        ),
      ),
    );
    await shooter.snap('phan-quyen-moi-email');
  });
}

Tournament _tournament({
  required String status,
  Map<String, dynamic> extra = const {},
}) => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'registrationMode': 'APPROVAL',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  ...extra,
}, 'tournament-1');

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

class _FinanceRepository implements TournamentManagementRepository {
  @override
  Future<Map<String, dynamic>> getFeesConfig() async => {
    'allowEntryFees': true,
  };

  @override
  Future<List<Map<String, dynamic>>> getMyPayouts() async => [
    {
      'tournamentId': 'tournament-1',
      'amountRequested': 50000,
      'status': 'PENDING',
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PeopleRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getStaff(String id) async => [
    {'userId': 'u1', 'fullName': 'Staff One', 'role': 'CO_ORGANIZER'},
    {'userId': 'u2', 'fullName': 'Viewer Two', 'role': 'SPECTATOR'},
  ];

  @override
  Future<List<Map<String, dynamic>>> getReferees(String id) async => [
    {
      'id': 'r1',
      'userId': 'u-r1',
      'status': 'ACCEPTED',
      'fullName': 'Referee One',
      'email': 'r1@example.test',
    },
    {
      'id': 'r2',
      'userId': 'u-r2',
      'status': 'INVITED',
      'fullName': 'Referee Two',
      'email': 'r2@example.test',
    },
    {
      'id': 'r3',
      'userId': 'u-r3',
      'status': 'DECLINED',
      'fullName': 'Referee Three',
      'email': 'r3@example.test',
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
