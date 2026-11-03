import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_athletes_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'tournament-1';
const _divisionA = 'div-a';
const _divisionB = 'div-b';

class _AdminAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.admin);
}

class _FakeManagementRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];

  @override
  Future<Map<String, dynamic>> getFeesConfig() async => const {};

  @override
  Future<List<Map<String, dynamic>>> getMyPayouts() async => const [];

  @override
  Future<List<String>> getGallery(String id) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTournamentRepository implements ITournamentRepository {
  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _divisions = <Map<String, dynamic>>[
  {'id': _divisionA, 'name': 'Đôi Nam', 'matchType': 'DOUBLES'},
  {'id': _divisionB, 'name': 'Đơn Nữ', 'matchType': 'SINGLES'},
];

Tournament _tournament() => Tournament.fromJson({
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
}, _tournamentId);

Future<AppLocalizations> _pumpHub(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final tournament = _tournament();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_AdminAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'manager-1',
            role: 'ORGANIZER',
            roles: ['ORGANIZER', 'ADMIN'],
          ),
        ),
        tournamentManagementRepositoryProvider.overrideWithValue(
          _FakeManagementRepository(),
        ),
        tournamentRepositoryProvider.overrideWithValue(
          _FakeTournamentRepository(),
        ),
        introTeamsProvider(_tournamentId).overrideWith((ref) async => const []),
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream.value(tournament)),
        tournamentDivisionsProvider(
          _tournamentId,
        ).overrideWith((ref) async => _divisions),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const <MatchModel>[]),
        ),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const []),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: TournamentManagementHubScreen(
          tournament: tournament,
          actionRouteBase: '/admin/tournament/$_tournamentId',
          opsWorkspaceRoute: '/organizer/tournaments/$_tournamentId/ops',
          liteWorkspaceRoute: '/lite-manage/$_tournamentId?workspace=1',
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

String? _bracketSelection(WidgetTester tester) => tester
    .widget<BracketViewScreen>(find.byType(BracketViewScreen))
    .selectedDivisionId;

String? _opsSelection(WidgetTester tester) => tester
    .widget<OrganizerOpsScreen>(find.byType(OrganizerOpsScreen))
    .selectedDivisionId;

String? _athletesSelection(WidgetTester tester) => tester
    .widget<TournamentManagementAthletesTab>(
      find.byType(TournamentManagementAthletesTab),
    )
    .selectedDivisionId;

void main() {
  testWidgets(
    'TC-DIVSHARE-05: a division picked in the athletes tab is the one shown in the bracket and schedule tabs',
    (tester) async {
      final l10n = await _pumpHub(tester);
      await _openTab(tester, l10n.tournamentManagementTabAthletes);

      await tester.tap(
        find.byKey(const ValueKey('athlete-division-$_divisionB')),
      );
      await tester.pumpAndSettle();

      await _openTab(tester, l10n.tournamentManagementTabBracket);
      expect(_bracketSelection(tester), _divisionB);

      await _openTab(tester, l10n.tournamentManagementSchedule);
      expect(_opsSelection(tester), _divisionB);
    },
  );

  testWidgets(
    'TC-DIVSHARE-06: a division picked in the bracket tab is the one shown in the athletes tab',
    (tester) async {
      final l10n = await _pumpHub(tester);
      await _openTab(tester, l10n.tournamentManagementTabBracket);

      await tester.tap(find.byKey(const ValueKey('division-chip-$_divisionB')));
      await tester.pumpAndSettle();

      await _openTab(tester, l10n.tournamentManagementTabAthletes);
      expect(_athletesSelection(tester), _divisionB);
      expect(
        find.byKey(const ValueKey('athlete-division-body-$_divisionB')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TC-DIVSHARE-07: before anything is picked no tab is told which division to show',
    (tester) async {
      final l10n = await _pumpHub(tester);

      await _openTab(tester, l10n.tournamentManagementTabAthletes);
      expect(_athletesSelection(tester), isNull);
      await _openTab(tester, l10n.tournamentManagementTabBracket);
      expect(_bracketSelection(tester), isNull);
    },
  );
}
