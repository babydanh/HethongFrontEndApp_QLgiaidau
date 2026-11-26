import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/services/manage_role_access.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_api_adapter.dart';

const _tournamentId = 't-1';
const _divisionId = 'd-1';

/// Body keys the Backend accepts from a referee on PATCH /matches/:id/schedule.
const _refereeScheduleKeys = {
  'courtId',
  'courtName',
  'courtAddress',
  'scheduledAt',
  'matchConfig',
};

typedef _Write = ({String matchId, String? refereeId, int? durationMinutes});

class _VenuesRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MatchRepository implements IMatchRepository {
  final writes = <_Write>[];

  @override
  Stream<List<MatchModel>> watchManagedByTournament(
    String tournamentId, {
    String? divisionId,
  }) => Stream.value(const []);

  @override
  Future<MatchScheduleSnapshot> updateSchedule(
    String tournamentId,
    String matchId, {
    String? courtName,
    String? courtAddress,
    String? courtId,
    String? refereeId,
    DateTime? scheduledAt,
    int? durationMinutes,
    Set<MatchScheduleField> clear = const {},
  }) async {
    writes.add((
      matchId: matchId,
      refereeId: refereeId,
      durationMinutes: durationMinutes,
    ));
    return (scheduledAt: scheduledAt, courtId: courtId, courtName: courtName);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedMatchSocketService implements MatchSocketService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Referee schedule fixture',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'tournamentConfig': {'operatingStart': '07:00', 'operatingEnd': '08:00'},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

MatchModel _waitingMatch() => MatchModel.fromJson({
  'id': 'm-wait',
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội A',
  'team2Name': 'Đội B',
}, 'm-wait');

MatchModel _scheduledMatch() {
  final now = DateTime.now();
  return MatchModel.fromJson({
    'id': 'm-set',
    'tournamentId': _tournamentId,
    'divisionId': _divisionId,
    'round': 1,
    'matchNumber': 2,
    'status': 'SCHEDULED',
    'team1Name': 'Đội C',
    'team2Name': 'Đội D',
    'courtId': 'court-1',
    'courtName': 'Sân 1',
    'refereeId': 'ref-1',
    'scheduledTime': DateTime(
      now.year,
      now.month,
      now.day,
      7,
    ).toUtc().toIso8601String(),
    'durationMinutes': 15,
  }, 'm-set');
}

Future<_MatchRepository> _pump(WidgetTester tester, ManageRole role) async {
  tester.view.physicalSize = const Size(720, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MatchRepository();
  final tournament = _tournament();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream<Tournament?>.value(tournament)),
        tournamentDivisionsProvider(_tournamentId).overrideWith(
          (ref) async => [
            {'id': _divisionId, 'name': 'Open', 'matchType': 'DOUBLES'},
          ],
        ),
        managedMatchesWithDivisionProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith(
          (ref) => Stream.value([_waitingMatch(), _scheduledMatch()]),
        ),
        tournamentManagementRepositoryProvider.overrideWithValue(
          _VenuesRepository(),
        ),
        matchRepositoryProvider.overrideWithValue(repository),
        organizerOpsReadModelProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith(
          (ref) async => const OrganizerOpsReadModel(
            participants: [],
            referees: [
              OrganizerOpsReferee(
                id: 'ref-1',
                userId: 'u-ref-1',
                fullName: 'Trọng tài A',
              ),
            ],
            auditEntries: [],
          ),
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
          initialMatchesView: OrganizerOpsMatchesView.grid,
          manageRole: role,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

TournamentScheduleCourtGrid _grid(WidgetTester tester) =>
    tester.widget(find.byType(TournamentScheduleCourtGrid));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-REF-MODE-APP-18 referee keeps drag, swap and duration but not planning',
    (tester) async {
      await _pump(tester, ManageRole.referee);
      final grid = _grid(tester);

      expect(grid.onScheduleDrop, isNotNull);
      expect(grid.onScheduleSwap, isNotNull);
      expect(grid.onScheduleWaitingWrite, isNotNull);
      expect(grid.onBulkDuration, isNotNull);
      expect(grid.onAutoSchedule, isNull);
      expect(grid.onAiSchedule, isNull);
      expect(grid.onOpenScheduleSettings, isNull);
      expect(grid.onApplyDraft, isNull);
      expect(grid.onCancelDraft, isNull);
    },
  );

  testWidgets(
    'TC-REF-MODE-APP-19 a referee tray write carries the slot duration only',
    (tester) async {
      final repository = await _pump(tester, ManageRole.referee);
      final at = DateTime.now();

      final ok = await _grid(tester).onScheduleWaitingWrite!(
        _waitingMatch(),
        (id: 'court-1', name: 'Sân 1'),
        at,
        30,
      );

      expect(ok, isTrue);
      final write = repository.writes.single;
      expect(write.matchId, 'm-wait');
      expect(write.durationMinutes, 30);
      expect(write.refereeId, isNull);
    },
  );

  testWidgets(
    'TC-REF-MODE-APP-20 referee quick sheet has no referee picker, sends no refereeId',
    (tester) async {
      final repository = await _pump(tester, ManageRole.referee);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(OrganizerOpsScreen)),
      )!;

      await tester.tap(find.byKey(const ValueKey('schedule-match-m-set')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.scheduleQuickDuration), findsOneWidget);
      expect(find.text(l10n.matchMainReferee), findsNothing);

      final save = find.text(l10n.matchSaveChanges);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final write = repository.writes.single;
      expect(write.matchId, 'm-set');
      expect(write.refereeId, isNull);
      expect(write.durationMinutes, isNotNull);
    },
  );

  testWidgets('manager quick sheet still offers the referee picker', (
    tester,
  ) async {
    await _pump(tester, ManageRole.manager);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OrganizerOpsScreen)),
    )!;

    await tester.tap(find.byKey(const ValueKey('schedule-match-m-set')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.matchMainReferee), findsWidgets);
  });

  test(
    'TC-REF-MODE-APP-20b a write without refereeId sends only allowed keys',
    () async {
      dotenv.loadFromString(
        envString:
            'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
      );
      SharedPreferences.setMockInitialValues({});
      final adapter = FakeApiAdapter({
        'PATCH /matches/m-1/schedule': const FakeReply(200, {
          'data': {'courtId': 'court-1', 'courtName': 'Sân 1'},
        }),
      });
      final repository = ApiMatchRepository(
        fakeDioClient(adapter),
        _UnusedMatchSocketService(),
      );

      await repository.updateSchedule(
        _tournamentId,
        'm-1',
        courtId: 'court-1',
        courtName: 'Sân 1',
        scheduledAt: DateTime.utc(2026, 1, 1, 7),
        durationMinutes: 30,
      );

      final body = adapter.requests.single.body!;
      expect(body.containsKey('refereeId'), isFalse);
      expect(_refereeScheduleKeys.containsAll(body.keys), isTrue);
      expect(body['matchConfig'], {'durationMinutes': 30});
    },
  );
}
