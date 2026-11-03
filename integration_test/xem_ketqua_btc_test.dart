import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/xem.dart';

const _tid = 'tour-1';

/// Organizer results tab: match table, "in progress" block and the one-match
/// schedule box, on fake data only (no Backend, no network).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initXem);

  Widget board() => xemApp(
    overrides: [
      // The organiser board reads the management feed, not the public one.
      managedMatchesWithDivisionProvider((
        tournamentId: _tid,
        divisionId: null,
      )).overrideWith((ref) => Stream.value(_matches())),
      matchesProvider(_tid).overrideWith((ref) => Stream.value(_matches())),
      matchRepositoryProvider.overrideWithValue(_MatchRepository()),
      tournamentManagementRepositoryProvider.overrideWithValue(
        _ManagementRepository(),
      ),
      tournamentProvider(_tid).overrideWith((ref) => Stream.value(null)),
    ],
    home: const Scaffold(
      body: SingleChildScrollView(
        child: ResultsMatchBoard(
          tournamentId: _tid,
          isLite: false,
          divisionId: 'd1',
          canManage: true,
        ),
      ),
    ),
  );

  testWidgets('xem: tab ket qua BTC va hop xep lich', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(board());
    await shooter.snap('ket-qua-bang-tran-dang-dien-ra');

    await tester.tap(find.byKey(const ValueKey('results-schedule-todo1')));
    await settle(tester);
    await shooter.snap('ket-qua-hop-xep-lich');
  });

  testWidgets('xem: popup nhap diem co ngay gio', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(board());

    await tester.tap(find.byKey(const ValueKey('results-add-score-todo2')));
    await settle(tester);
    expect(find.byKey(const ValueKey('results-score-sheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('results-score-played-at')),
      findsOneWidget,
    );
    await shooter.snap('ket-qua-popup-nhap-diem');
  });
}

MatchModel _match(
  String id, {
  required int round,
  required int number,
  String status = 'SCHEDULED',
  DateTime? scheduledTime,
  DateTime? completedAt,
  String winnerId = '',
}) => MatchModel(
  id: id,
  tournamentId: _tid,
  round: round,
  matchNumber: number,
  bracketPosition: BracketPosition(round: round, position: number),
  team1Id: 'a$number',
  team2Id: 'b$number',
  status: status,
  divisionId: 'd1',
  scheduledTime: scheduledTime,
  completedAt: completedAt,
  winnerId: winnerId,
  team1Players: [ParticipantPlayer(slot: 1, fullName: 'Nguyen Van $id')],
  team2Players: [ParticipantPlayer(slot: 1, fullName: 'Tran Thi $id')],
  updatedAt: DateTime(2026, 1, 1),
);

List<MatchModel> _matches() => [
  _match(
    'done1',
    round: 1,
    number: 1,
    status: 'COMPLETED',
    winnerId: 'a1',
    completedAt: DateTime(2026, 1, 1, 9),
  ),
  _match('live1', round: 1, number: 2, status: 'ONGOING'),
  _match('todo1', round: 1, number: 3, scheduledTime: DateTime(2026, 1, 2, 10)),
  _match('todo2', round: 1, number: 4),
  _match('next1', round: 2, number: 1),
];

class _MatchRepository extends Fake implements IMatchRepository {}

class _ManagementRepository extends Fake
    implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [
    {
      'courts': [
        {'id': 'c1', 'name': 'San 1'},
        {'id': 'c2', 'name': 'San 2'},
      ],
    },
  ];
}
