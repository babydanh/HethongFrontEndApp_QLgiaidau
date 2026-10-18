import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 't-1';
const _divisionId = 'd-1';
const _secondDivisionId = 'd-2';

class _VenuesRepository implements TournamentManagementRepository {
  const _VenuesRepository({this.withCourts = true});

  final bool withCourts;

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    if (withCourts)
      {
        'id': 'venue-1',
        'name': 'Nhà thi đấu',
        'courts': [
          {'id': 'court-1', 'name': 'Sân 1'},
          {'id': 'court-2', 'name': 'Sân 2'},
        ],
      },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Ops schedule grid fixture',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'tournamentConfig': {'operatingStart': '07:00', 'operatingEnd': '10:00'},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

MatchModel _match() => MatchModel.fromJson({
  'id': 'm-1',
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': 1,
  'status': 'ONGOING',
  'team1Name': 'Đội A',
  'team2Name': 'Đội B',
  'courtName': 'Sân 1',
  'scheduledAt': DateTime(2026, 10, 24, 7, 30).toIso8601String(),
}, 'm-1');

MatchModel _scheduledMatch() => MatchModel.fromJson({
  'id': 'm-2',
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': 2,
  'status': 'SCHEDULED',
  'team1Name': 'Đội A',
  'team2Name': 'Đội B',
  'courtName': 'Sân 1',
  'scheduledAt': DateTime(2026, 10, 24, 8, 0).toIso8601String(),
}, 'm-2');

Future<void> _pump(
  WidgetTester tester, {
  required OrganizerOpsMatchesView matchesView,
  List<MatchModel>? matches,
  List<String> divisionIds = const [_divisionId],
  bool withCourts = true,
}) async {
  tester.view.physicalSize = const Size(720, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final tournament = _tournament();
  final shownMatches = matches ?? [_match()];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream<Tournament?>.value(tournament)),
        tournamentDivisionsProvider(_tournamentId).overrideWith(
          (ref) async => [
            for (final id in divisionIds)
              {
                'id': id,
                'name': id == _divisionId ? 'Open' : 'Youth',
                'matchType': 'DOUBLES',
              },
          ],
        ),
        for (final id in divisionIds) ...[
          managedMatchesWithDivisionProvider((
            tournamentId: _tournamentId,
            divisionId: id,
          )).overrideWith((ref) => Stream.value(shownMatches)),
          organizerOpsReadModelProvider((
            tournamentId: _tournamentId,
            divisionId: id,
          )).overrideWith(
            (ref) async => const OrganizerOpsReadModel(
              participants: [],
              referees: [],
              auditEntries: [],
            ),
          ),
        ],
        tournamentManagementRepositoryProvider.overrideWithValue(
          _VenuesRepository(withCourts: withCourts),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OrganizerOpsScreen(
          tournamentId: _tournamentId,
          initialDivisionId: _divisionId,
          view: OrganizerOpsView.matches,
          initialMatchesView: matchesView,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hub passes grid: court grid is the default matches view', (
    tester,
  ) async {
    await _pump(tester, matchesView: OrganizerOpsMatchesView.grid);

    expect(find.byType(ScheduleGrid), findsOneWidget);
    expect(find.text('Sân 1'), findsOneWidget); // tiêu đề cột
    expect(find.text('Đội A'), findsOneWidget);
  });

  testWidgets('the standalone ops screen still opens the list', (tester) async {
    await _pump(tester, matchesView: OrganizerOpsMatchesView.list);

    expect(find.byType(ScheduleGrid), findsNothing);
  });

  testWidgets('the view toggle switches between grid and list', (tester) async {
    await _pump(tester, matchesView: OrganizerOpsMatchesView.grid);
    expect(find.byType(ScheduleGrid), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ops-matches-view-list')));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleGrid), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ops-matches-view-grid')));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleGrid), findsOneWidget);
  });

  testWidgets('grid keeps the court grid and division picker with no matches', (
    tester,
  ) async {
    await _pump(
      tester,
      matchesView: OrganizerOpsMatchesView.grid,
      matches: const [],
      divisionIds: const [_divisionId, _secondDivisionId],
    );

    expect(find.byType(TournamentScheduleCourtGrid), findsOneWidget);
    expect(
      find.byKey(const ValueKey('schedule-division-dropdown')),
      findsOneWidget,
    );
  });

  testWidgets('list keeps the empty notice when there are no matches', (
    tester,
  ) async {
    await _pump(
      tester,
      matchesView: OrganizerOpsMatchesView.list,
      matches: const [],
    );

    expect(find.byType(TournamentScheduleCourtGrid), findsNothing);
    expect(find.byIcon(Icons.sports_score_outlined), findsOneWidget);
  });

  testWidgets('no courts: division picker sits above the notice and changes division', (
    tester,
  ) async {
    await _pump(
      tester,
      matchesView: OrganizerOpsMatchesView.grid,
      matches: const [],
      divisionIds: const [_divisionId, _secondDivisionId],
      withCourts: false,
    );

    expect(find.byIcon(Icons.stadium_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('schedule-division-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Youth').last);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const ValueKey('schedule-division-dropdown')),
    );
    expect(dropdown.value, _secondDivisionId);
  });

  testWidgets('grid shows unplayed matches and list keeps the all filter', (
    tester,
  ) async {
    await _pump(
      tester,
      matchesView: OrganizerOpsMatchesView.list,
      matches: [_scheduledMatch()],
    );
    expect(find.textContaining('Đội A'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ops-matches-view-grid')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đội A'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('ops-matches-view-list')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đội A'), findsWidgets);
  });
}
