import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/services/manage_role_access.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = 'tournament-1';

final _divisions = <Map<String, dynamic>>[
  {'id': 'div-mixed', 'name': 'Đôi Nam Nữ', 'matchType': 'DOUBLES'},
];

final _tournament = Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'divisions': _divisions,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _id);

const _participants = [
  OrganizerOpsParticipant(
    id: 'p-1',
    teamName: 'Danh – Luân',
    teamStatus: 'COMPLETE',
    isPaid: true,
    members: [
      OrganizerOpsMember(userId: 'u-danh', fullName: 'Danh'),
      OrganizerOpsMember(userId: 'u-luan', fullName: 'Luân'),
    ],
    divisionId: 'div-mixed',
  ),
  OrganizerOpsParticipant(
    id: 'p-2',
    teamName: 'An – Bình',
    teamStatus: 'PENDING_APPROVAL',
    isPaid: false,
    members: [
      OrganizerOpsMember(userId: 'u-an', fullName: 'An'),
      OrganizerOpsMember(userId: 'u-binh', fullName: 'Bình'),
    ],
    divisionId: 'div-mixed',
  ),
];

class _Participants implements ITournamentRepository {
  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => _participants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Management implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async =>
      _divisions;

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppLocalizations> _pumpHub(WidgetTester tester, ManageRole role) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async =>
              const UserProfile(id: 'ref-1', role: 'USER', roles: ['PLAYER']),
        ),
        tournamentRepositoryProvider.overrideWithValue(_Participants()),
        tournamentManagementRepositoryProvider.overrideWithValue(_Management()),
        introTeamsProvider(_id).overrideWith((ref) async => const []),
        tournamentProvider(
          _id,
        ).overrideWith((ref) => Stream.value(_tournament)),
        tournamentDivisionsProvider(
          _id,
        ).overrideWith((ref) async => _divisions),
        matchesProvider(
          _id,
        ).overrideWith((ref) => Stream.value(const <MatchModel>[])),
        bracketMatchesWithDivisionProvider((
          tournamentId: _id,
          divisionId: 'div-mixed',
        )).overrideWith((ref) => Stream.value(const <MatchModel>[])),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: TournamentManagementHubScreen(
          tournament: _tournament,
          role: role,
          actionRouteBase: '/organizer/tournaments/$_id/manage',
          opsWorkspaceRoute: '/organizer/tournaments/$_id/ops',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(TournamentManagementHubScreen)),
  )!;
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-REF-MODE-APP-13 referee sees six tabs, no Camera/Settings', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester, ManageRole.referee);

    expect(find.byType(Tab), findsNWidgets(6));
    for (final label in [
      l10n.tournamentManagementOverview,
      l10n.tournamentManagementTabDivisions,
      l10n.tournamentManagementTabAthletes,
      l10n.tournamentManagementTabBracket,
      l10n.tournamentManagementSchedule,
      l10n.tournamentManagementTabResults,
    ]) {
      expect(find.widgetWithText(Tab, label), findsOneWidget, reason: label);
    }
    expect(find.widgetWithText(Tab, l10n.opsCamera), findsNothing);
    expect(
      find.widgetWithText(Tab, l10n.tournamentManagementTabSettings),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-REF-MODE-APP-14 referee sees the role label and notice', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester, ManageRole.referee);

    expect(find.byKey(const ValueKey('referee-mode-banner')), findsOneWidget);
    expect(find.text(l10n.infoReferee), findsWidgets);
    expect(find.text(l10n.refereeModeNotice), findsOneWidget);
  });

  testWidgets('TC-REF-MODE-APP-15 referee has no page-level write buttons', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester, ManageRole.referee);

    expect(find.byTooltip(l10n.tournamentManagementSystemGroup), findsNothing);
    expect(
      find.text(l10n.tournamentManagementCompleteTournament),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('referee-mode-banner')), findsOneWidget);
  });

  testWidgets('manager keeps the eight tabs and the write buttons', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester, ManageRole.manager);

    expect(find.byType(Tab), findsNWidgets(8));
    expect(find.byKey(const ValueKey('referee-mode-banner')), findsNothing);
    expect(
      find.byTooltip(l10n.tournamentManagementSystemGroup),
      findsOneWidget,
    );
    expect(
      find.text(l10n.tournamentManagementCompleteTournament),
      findsOneWidget,
    );
  });

  testWidgets(
    'TC-REF-MODE-APP-16 divisions and athletes tabs are read-only for referee',
    (tester) async {
      final l10n = await _pumpHub(tester, ManageRole.referee);

      await _openTab(tester, l10n.tournamentManagementTabDivisions);
      expect(find.text('Đôi Nam Nữ'), findsWidgets);
      expect(find.text(l10n.tournamentManagementAddDivision), findsNothing);
      expect(
        find.byKey(const ValueKey('division-edit-div-mixed')),
        findsNothing,
      );

      await _openTab(tester, l10n.tournamentManagementTabAthletes);
      expect(find.text('Danh – Luân'), findsWidgets);
      expect(find.text(l10n.opsAddAthlete), findsNothing);
      expect(find.byKey(const ValueKey('athletes-import-excel')), findsNothing);
      expect(
        find.byKey(const ValueKey('participant-approve-p-2')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('participant-row-menu-p-1')),
        findsNothing,
      );
      final checkIn = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('participant-checkin-p-1')),
      );
      expect(checkIn.onTap, isNull);
    },
  );

  testWidgets(
    'TC-REF-MODE-APP-17 bracket, schedule and results get the referee limits',
    (tester) async {
      final l10n = await _pumpHub(tester, ManageRole.referee);

      await _openTab(tester, l10n.tournamentManagementTabBracket);
      final bracket = tester.widget<BracketViewScreen>(
        find.byType(BracketViewScreen),
      );
      expect(bracket.canEditBracket, isFalse);
      expect(bracket.isReferee, isTrue);

      await _openTab(tester, l10n.tournamentManagementSchedule);
      final ops = tester.widget<OrganizerOpsScreen>(
        find.byType(OrganizerOpsScreen),
      );
      expect(ops.manageRole, ManageRole.referee);

      await _openTab(tester, l10n.tournamentManagementTabResults);
      final board = tester.widget<ResultsMatchBoard>(
        find.byType(ResultsMatchBoard),
      );
      // Scoring and time/court/duration edits stay open to a referee.
      expect(board.canManage, isTrue);
    },
  );
}
