import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_athletes_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_dispatcher.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Tournament _tournament(
  String status, {
  String name = 'City Pickleball Cup',
  String sport = 'pickleball',
  bool superLite = false,
  bool quick = false,
  String? communityId,
  String? bannerUrl,
  String? logoUrl,
  String description = '',
  DateTime? startDate,
  DateTime? registrationEndDate,
  List<Map<String, dynamic>> divisions = const [],
}) => Tournament.fromJson({
  'name': name,
  'sport': sport,
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'description': description,
  if (quick) 'isLite': true,
  'communityId': communityId,
  'bannerUrl': bannerUrl,
  'logoUrl': logoUrl,
  if (superLite)
    'tournamentConfig': {'mode': 'LITE', 'hideAdvancedSettings': true},
  if (startDate != null) 'startDate': startDate.toIso8601String(),
  if (registrationEndDate != null)
    'registrationEndDate': registrationEndDate.toIso8601String(),
  if (divisions.isNotEmpty) 'divisions': divisions,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Widget _app(
  Tournament tournament, {
  Locale locale = const Locale('vi'),
  UserProfile? profile,
  TournamentManagementRepository? managementRepository,
  ITournamentRepository? tournamentRepository,
  List<MatchModel>? matches,
}) => ProviderScope(
  overrides: [
    userProfileProvider.overrideWith(
      (ref) async =>
          profile ??
          const UserProfile(
            id: 'manager-1',
            role: 'ORGANIZER',
            roles: ['ORGANIZER', 'ADMIN'],
          ),
    ),
    if (managementRepository != null)
      tournamentManagementRepositoryProvider.overrideWithValue(
        managementRepository,
      ),
    if (tournamentRepository != null)
      tournamentRepositoryProvider.overrideWithValue(tournamentRepository),
    if (matches != null)
      matchesProvider(
        'tournament-1',
      ).overrideWith((ref) => Stream.value(matches)),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: TournamentManagementHubScreen(
      tournament: tournament,
      actionRouteBase: '/admin/tournament/tournament-1',
      opsWorkspaceRoute: '/organizer/tournaments/tournament-1/ops',
      liteWorkspaceRoute: '/lite-manage/tournament-1?workspace=1',
    ),
  ),
);

class _AuthenticatedAdmin extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.admin);
}

class _EmptyRegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => [];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async => [];

  @override
  Future<List<Region>> searchRegions(String query, {int limit = 10}) async =>
      [];
}

class _EmptyTournamentRepository implements ITournamentRepository {
  @override
  Future<Map<String, dynamic>> generateBracket(
    String tournamentId, {
    String? divisionId,
    required String seedingType,
    bool allowReset = false,
  }) => throw UnimplementedError();
  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DivisionParticipantsRepository implements ITournamentRepository {
  @override
  Future<Map<String, dynamic>> generateBracket(
    String tournamentId, {
    String? divisionId,
    required String seedingType,
    bool allowReset = false,
  }) => throw UnimplementedError();
  _DivisionParticipantsRepository(this.participants);

  final List<OrganizerOpsParticipant> participants;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => divisionId == null
      ? participants
      : participants.where((p) => p.divisionId == divisionId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyTournamentManagementRepository
    implements TournamentManagementRepository {
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

class _LifecycleRepository extends _EmptyTournamentManagementRepository
    implements TournamentLifecycleRepository {
  final startedIds = <String>[];
  final completedIds = <String>[];
  final calls = <String>[];
  Object? completeError;

  @override
  Future<Map<String, dynamic>> startTournament(String id) async {
    startedIds.add(id);
    calls.add('start');
    return const {};
  }

  @override
  Future<Map<String, dynamic>> closeRegistration(String id) async {
    calls.add('close-registration');
    return const {};
  }

  @override
  Future<Map<String, dynamic>> reopenRegistration(
    String id, {
    DateTime? registrationEndDate,
  }) async {
    calls.add('reopen-registration');
    return const {};
  }

  @override
  Future<Map<String, dynamic>> completeTournament(String id) async {
    completedIds.add(id);
    if (completeError != null) throw completeError!;
    return const {};
  }
}

class _RecordingManagementRepository
    extends _EmptyTournamentManagementRepository {
  final directNames = <String>[];
  final statusUpdates = <Map<String, String>>[];

  @override
  Future<String> addAthleteDirect(
    String id, {
    required String name,
    String? email,
    String? tournamentDivisionId,
  }) async {
    directNames.add(name);
    return 'participant-direct';
  }

  @override
  Future<void> updateParticipantStatus(
    String id,
    String participantId,
    String status,
  ) async {
    statusUpdates.add({'participantId': participantId, 'status': status});
  }
}

class _IdleLiteManagementNotifier extends LiteManagementNotifier {
  @override
  Future<void> init(String tournamentId) async {}
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  final context = tester.element(find.byType(TournamentManagementHubScreen));
  final l10n = AppLocalizations.of(context)!;
  await _openTab(tester, l10n.tournamentManagementTabSettings);
}

void main() {
  testWidgets('overview tournament title opens the information editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final hub = find.byType(TournamentManagementHubScreen);
    final l10n = AppLocalizations.of(tester.element(hub))!;
    await tester.tap(find.text('City Pickleball Cup'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentManagementName), findsOneWidget);
  });
  testWidgets('overview edit targets open their matching management sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;

    Future<void> pumpHub() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _app(
          _tournament(
            'in_progress',
            description: 'Cup overview description',
            startDate: DateTime(2030, 1, 1),
          ),
          managementRepository: _EmptyTournamentManagementRepository(),
          tournamentRepository: _EmptyTournamentRepository(),
        ),
      );
      await tester.pumpAndSettle();
    }

    final targets = <(String, String Function(AppLocalizations))>[
      ('tournament-overview-banner-edit', (l) => l.manageSettingsInfoSection),
      (
        'tournament-overview-dates-edit',
        (l) => l.tournamentManagementRegistration,
      ),
      (
        'tournament-overview-location-edit',
        (l) => l.manageSettingsVenueSection,
      ),
      (
        'tournament-overview-entry-fee-edit',
        (l) => l.tournamentManagementFinance,
      ),
    ];

    for (final (key, labelOf) in targets) {
      await pumpHub();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      final target = find.byKey(ValueKey(key));
      expect(target, findsOneWidget, reason: key);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text(labelOf(l10n)), findsWidgets, reason: key);
    }

    await pumpHub();
    final athletes = find.byKey(
      const ValueKey('tournament-overview-athletes-edit'),
    );
    await tester.ensureVisible(athletes);
    await tester.tap(athletes);
    await tester.pumpAndSettle();
    expect(find.byType(TournamentManagementAthletesTab), findsOneWidget);
  });

  testWidgets('hub shows five pinned tabs and grouped settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(_tournament('in_progress'), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementHubScreen)),
    )!;
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('City Pickleball Cup'), findsOneWidget);
    for (final label in [
      l10n.tournamentManagementOverview,
      l10n.tournamentManagementTabAthletes,
      l10n.tournamentManagementTabBracket,
      l10n.tournamentManagementSchedule,
      l10n.tournamentManagementTabSettings,
    ]) {
      expect(find.widgetWithText(Tab, label), findsOneWidget);
    }

    await _openSettings(tester);
    expect(find.text(l10n.tournamentManagementSetupGroup), findsOneWidget);
    expect(find.text(l10n.manageSettingsInfoSection), findsOneWidget);
    expect(find.text(l10n.manageSettingsOtherSection), findsOneWidget);
    expect(find.text(l10n.tournamentManagementSystemGroup), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bracket and schedule tabs render embedded workspaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentProvider(
            'tournament-1',
          ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
          bracketMatchesWithDivisionProvider((
            tournamentId: 'tournament-1',
            divisionId: null,
          )).overrideWith((ref) => Stream.value(const <MatchModel>[])),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: _app(_tournament('in_progress'), locale: const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementHubScreen)),
    )!;
    await _openTab(tester, l10n.tournamentManagementTabBracket);
    expect(find.text(l10n.bracketView_noMatches), findsOneWidget);
    expect(find.text(l10n.bracketView_drawHint), findsOneWidget);
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);

    await _openTab(tester, l10n.tournamentManagementSchedule);
    expect(find.byType(OrganizerOpsScreen), findsOneWidget);
    expect(find.byTooltip(l10n.opsRefresh), findsOneWidget);
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin, organizer, and Lite entry routes share one hub', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async =>
              const UserProfile(id: 'admin-1', role: 'ADMIN', roles: ['ADMIN']),
        ),
        authProvider.overrideWith(_AuthenticatedAdmin.new),
        tournamentProvider('tournament-1').overrideWith(
          (ref) => Stream.value(_tournament('in_progress', quick: true)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/admin/tournament/tournament-1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);

    for (final location in [
      '/organizer/tournaments/tournament-1/manage',
      '/lite-manage/tournament-1',
      '/lite/tournaments/tournament-1/manage',
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    }
    for (final location in [
      '/lite-manage/tournament-1?workspace=1',
      '/lite/tournaments/tournament-1/manage?workspace=1',
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.byType(LiteManagementScreen), findsNothing);
      expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    }
  });

  testWidgets('club Super Lite keeps the existing Lite management screen', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_AuthenticatedAdmin.new),
        tournamentProvider('tournament-1').overrideWith(
          (ref) => Stream.value(
            _tournament('in_progress', superLite: true, communityId: 'club-1'),
          ),
        ),
        regionRepositoryProvider.overrideWith(
          (ref) => _EmptyRegionRepository(),
        ),
        liteManagementProvider.overrideWith(_IdleLiteManagementNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/lite-manage/tournament-1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LiteManagementScreen), findsOneWidget);
    expect(find.byType(TournamentManagementHubScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Advanced organizer entry opens the shared hub', (tester) async {
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async =>
              const UserProfile(id: 'admin-1', role: 'ADMIN', roles: ['ADMIN']),
        ),
        authProvider.overrideWith(_AuthenticatedAdmin.new),
        tournamentProvider(
          'tournament-1',
        ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/organizer/tournaments/tournament-1/manage');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
  });
  testWidgets('cancel preserves the tournament; success refreshes its status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    var tournamentReads = 0;
    final lifecycleRepository = _LifecycleRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'admin-1',
              role: 'ADMIN',
              roles: ['ADMIN'],
            ),
          ),
          tournamentProvider('tournament-1').overrideWith((ref) {
            tournamentReads += 1;
            return Stream.value(
              _tournament(tournamentReads == 1 ? 'in_progress' : 'completed'),
            );
          }),
          tournamentManagementRepositoryProvider.overrideWithValue(
            lifecycleRepository,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const TournamentManagementDispatcher(
            tournamentId: 'tournament-1',
            actionRouteBase: '/admin/tournament/tournament-1',
            opsWorkspaceRoute: '/organizer/tournaments/tournament-1/ops',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.endTournament));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();
    expect(lifecycleRepository.completedIds, isEmpty);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsOneWidget);

    await tester.tap(find.text(l10n.endTournament));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.confirmEndButton));
    await tester.pumpAndSettle();

    expect(lifecycleRepository.completedIds, ['tournament-1']);
    expect(tournamentReads, 2);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsNothing);
    expect(find.text(l10n.tournamentEnded), findsOneWidget);
  });

  testWidgets('organizer cannot see the server-forbidden end action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        profile: const UserProfile(
          id: 'organizer-1',
          role: 'ORGANIZER',
          roles: ['ORGANIZER'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsNothing);
  });

  testWidgets('keeps lite management accessible from overflow actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    final tournament = _tournament('in_progress', superLite: true);
    final router = GoRouter(
      initialLocation: '/organizer/tournaments/tournament-1/manage',
      routes: [
        GoRoute(
          path: '/organizer/tournaments/:id/manage',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TournamentManagementHubScreen(
              tournament: tournament,
              actionRouteBase: '/organizer/tournaments/$id/manage',
              opsWorkspaceRoute: '/organizer/tournaments/$id/ops',
              liteWorkspaceRoute: '/lite-manage/$id?workspace=1',
            );
          },
        ),
        GoRoute(
          path: '/lite-manage/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Destination: lite')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.lite_managementTitle));
    await tester.pumpAndSettle();

    expect(find.text('Destination: lite'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('settings retain every management section and action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);

    expect(find.text(l10n.tournamentManagementSetupGroup), findsOneWidget);
    expect(find.text(l10n.manageSettingsInfoSection), findsOneWidget);
    expect(find.text(l10n.manageSettingsVenueSection), findsOneWidget);
    expect(find.text(l10n.tournamentManagementRegistration), findsOneWidget);
    expect(find.text(l10n.manageSettingsCompetitionSection), findsOneWidget);

    // Khác đóng sẵn: các mục bên trong chưa nằm trong cây hiển thị.
    expect(find.text(l10n.manageSettingsOtherSection), findsOneWidget);
    expect(find.text(l10n.manageTeams), findsNothing);
    await tester.tap(find.text(l10n.manageSettingsOtherSection));
    await tester.pumpAndSettle();
    expect(find.text(l10n.manageTeams), findsOneWidget);
    expect(find.text(l10n.manageDraw), findsOneWidget);
    expect(find.text(l10n.tournamentManagementSponsors), findsOneWidget);
    expect(find.text(l10n.tournamentManagementFinance), findsOneWidget);
    expect(find.text(l10n.tournamentManagementLivestream), findsOneWidget);
    expect(find.text(l10n.tournamentManagementPermissions), findsOneWidget);
    expect(find.text(l10n.manageTokens), findsOneWidget);
    expect(find.text(l10n.tournamentManagementSystemGroup), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsOneWidget);
    expect(find.text(l10n.exportData), findsOneWidget);
    expect(find.text(l10n.deleteTournament), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('management overview shows one title and the provided banner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    const bannerUrl = 'https://images.example/tournament-banner.jpg';

    await tester.pumpWidget(
      _app(_tournament('in_progress', bannerUrl: bannerUrl)),
    );

    expect(find.text('City Pickleball Cup'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url == bannerUrl,
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides finalization action for a completed tournament', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('completed')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsNothing);
    expect(find.text(l10n.exportData), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await _openSettings(tester);
    expect(find.text(l10n.manageSettingsInfoSection), findsOneWidget);
  });
  testWidgets('supports long English tournament names on phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament(
          'completed',
          name: 'International Community Pickleball Doubles Championship',
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'phone navigation opens the information editor with brand assets',
    (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _app(
          _tournament('in_progress'),
          managementRepository: _EmptyTournamentManagementRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      await _openSettings(tester);
      await tester.tap(find.text(l10n.manageSettingsInfoSection).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.tournamentManagementName), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n.tournamentManagementDescription), findsOneWidget);
      expect(find.text(l10n.tournamentManagementBrandAssets), findsOneWidget);
      expect(find.text(l10n.tournamentManagementChooseDate), findsNothing);
      expect(find.text(l10n.tournamentManagementPublic), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'venue editor shows venues only, without dates or registration fields',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _app(
          _tournament('in_progress'),
          managementRepository: _EmptyTournamentManagementRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      await _openSettings(tester);
      await tester.tap(find.text(l10n.manageSettingsVenueSection).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.tournamentManagementVenues), findsOneWidget);
      expect(find.text(l10n.tournamentManagementStartDate), findsNothing);
      expect(find.text(l10n.tournamentManagementEndDate), findsNothing);
      expect(find.text(l10n.tournamentManagementChooseDate), findsNothing);
      expect(find.text(l10n.tournamentManagementPublic), findsNothing);
      expect(
        find.text(l10n.tournamentManagementRegistrationStarts),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pinned tab strip never covers the first settings group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await _openSettings(tester);

    final tabStripBottom = tester.getRect(find.byType(TabBar).first).bottom;
    final groupTop = tester
        .getRect(find.text(l10n.tournamentManagementSetupGroup).first)
        .top;
    expect(groupTop, greaterThanOrEqualTo(tabStripBottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stream updates preserve open section editor state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    final tournaments = StreamController<Tournament?>();
    addTearDown(tournaments.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentProvider(
            'tournament-1',
          ).overrideWith((ref) => tournaments.stream),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _EmptyTournamentManagementRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const TournamentManagementDispatcher(
            tournamentId: 'tournament-1',
            actionRouteBase: '/organizer/tournaments/tournament-1/manage',
            opsWorkspaceRoute: '/organizer/tournaments/tournament-1/ops',
          ),
        ),
      ),
    );
    tournaments.add(_tournament('in_progress'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.manageSettingsInfoSection).first);
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    nameField.controller!.text = 'Unsaved tournament name';
    await tester.pump();
    tournaments.add(_tournament('in_progress', name: 'Server snapshot update'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Unsaved tournament name',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khác opens a destination and returns to the settings list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.manageSettingsOtherSection));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementFinance));
    await tester.pumpAndSettle();
    final financeTitleInAppBar = find.descendant(
      of: find.byType(AppBar),
      matching: find.text(l10n.tournamentManagementFinance),
    );
    expect(financeTitleInAppBar, findsOneWidget);

    await tester.tap(find.byTooltip(l10n.tournamentManagementBack));
    await tester.pumpAndSettle();
    expect(find.text(l10n.manageSettingsOtherSection), findsOneWidget);
    expect(financeTitleInAppBar, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('operations retains live operations and the final section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          introTeamsProvider(
            'tournament-1',
          ).overrideWith((ref) async => const []),
          tournamentRepositoryProvider.overrideWithValue(
            _EmptyTournamentRepository(),
          ),
          tournamentProvider(
            'tournament-1',
          ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: _app(
          _tournament('in_progress'),
          managementRepository: _EmptyTournamentManagementRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.manageSettingsOtherSection));
    await tester.pumpAndSettle();
    final liveOperations = find.text(l10n.tournamentManagementLiveOperations);
    await tester.ensureVisible(liveOperations);
    await tester.tap(liveOperations);
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.opsRefresh), findsOneWidget);
    expect(find.byTooltip(l10n.tournamentManagementBack), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.tournamentManagementBack));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.tournamentManagementLivestream, skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet navigation updates the management detail section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.tournamentManagementRegistration).first);
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.tournamentManagementRegistrationMode),
      findsOneWidget,
    );
    expect(find.text(l10n.tournamentManagementPublic), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings end with lifecycle actions that apply to the status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('draft')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);

    expect(find.text(l10n.tournamentManagementLifecycle), findsOneWidget);
    expect(find.text(l10n.tournamentManagementPublish), findsOneWidget);
    expect(find.text(l10n.tournamentManagementRegenerateInvite), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'TC-APP-LIFECYCLE-04: lifecycle actions follow status and repository',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      final startRepository = _LifecycleRepository();
      await tester.pumpWidget(
        _app(_tournament('UPCOMING'), managementRepository: startRepository),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);

      final startContext = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final startL10n = AppLocalizations.of(startContext)!;
      // Sắp diễn ra: nút duy nhất là mở đăng ký.
      expect(
        find.text(startL10n.tournamentManagementOpenRegistrationNow),
        findsOneWidget,
      );
      expect(
        find.text(startL10n.tournamentManagementStartTournament),
        findsNothing,
      );

      await tester.pumpWidget(
        _app(
          _tournament('REGISTRATION_CLOSED'),
          managementRepository: startRepository,
        ),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);
      expect(
        find.text(startL10n.tournamentManagementCompleteTournament),
        findsNothing,
      );
      // Đã đóng hết: khai mạc là nút chính, kèm lối "Mở lại đăng ký".
      expect(
        find.text(startL10n.tournamentManagementReopenRegistration),
        findsOneWidget,
      );
      // Đóng hết rồi nên không hỏi "chốt luôn".
      await tester.tap(
        find.text(startL10n.tournamentManagementStartTournament),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(startL10n.tournamentManagementCloseOpenOnStart),
        findsNothing,
      );
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          startL10n.tournamentManagementConfirm,
        ),
      );
      await tester.pumpAndSettle();
      expect(startRepository.startedIds, ['tournament-1']);
      expect(startRepository.calls, ['start']);

      final completeRepository = _LifecycleRepository();
      await tester.pumpWidget(
        _app(
          _tournament('IN_PROGRESS'),
          managementRepository: completeRepository,
        ),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);
      final completeContext = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final completeL10n = AppLocalizations.of(completeContext)!;
      expect(
        find.text(completeL10n.tournamentManagementCompleteTournament),
        findsOneWidget,
      );
      expect(
        find.text(completeL10n.tournamentManagementStartTournament),
        findsNothing,
      );
      await tester.tap(
        find.text(completeL10n.tournamentManagementCompleteTournament),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          completeL10n.tournamentManagementConfirm,
        ),
      );
      await tester.pumpAndSettle();
      expect(completeRepository.completedIds, ['tournament-1']);

      await tester.pumpWidget(
        _app(
          _tournament('COMPLETED'),
          managementRepository: _LifecycleRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);
      final completedL10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      expect(
        find.text(completedL10n.tournamentManagementStartTournament),
        findsNothing,
      );
      expect(
        find.text(completedL10n.tournamentManagementCompleteTournament),
        findsNothing,
      );
    },
  );
  testWidgets('TC-APP-LIFECYCLE-05: displays the server completion error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    const serverMessage = 'Còn trận đang diễn ra: Nội dung đôi';
    final request = RequestOptions(path: '/tournaments/tournament-1/complete');
    final repository = _LifecycleRepository()
      ..completeError = DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 400,
          data: const {'message': serverMessage},
        ),
      );
    await tester.pumpWidget(
      _app(_tournament('IN_PROGRESS'), managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openSettings(tester);
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.tournamentManagementCompleteTournament));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementConfirm),
    );
    await tester.pumpAndSettle();

    expect(find.text(serverMessage), findsOneWidget);
  });
  testWidgets(
    'TC-APP-LIFECYCLE-06: registration open without bracket closes registration, no lock',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      final repository = _LifecycleRepository();
      await tester.pumpWidget(
        _app(
          _tournament('REGISTRATION_OPEN'),
          managementRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      expect(find.text(l10n.tournamentManagementStartTournament), findsNothing);
      await tester.tap(find.text(l10n.tournamentManagementCloseRegistration));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.tournamentManagementConfirm),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, ['close-registration']);
    },
  );
  testWidgets(
    'TC-APP-LIFECYCLE-07: bracket ready while registration open starts, ticking closes first',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      final repository = _LifecycleRepository();
      final match = MatchModel(
        id: 'match-1',
        round: 1,
        matchNumber: 1,
        team1Name: 'A',
        team2Name: 'B',
        status: 'scheduled',
        bracketPosition: const BracketPosition(round: 1, position: 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        divisionId: 'div-1',
      );
      await tester.pumpWidget(
        _app(
          _tournament(
            'REGISTRATION_OPEN',
            divisions: [
              {'id': 'div-1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
            ],
          ),
          managementRepository: repository,
          matches: [match],
        ),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      // Đã có sơ đồ: nút duy nhất là khai mạc, không còn "Chốt đăng ký".
      expect(
        find.text(l10n.tournamentManagementCloseRegistration),
        findsNothing,
      );
      await tester.tap(find.text(l10n.tournamentManagementStartTournament));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.tournamentManagementCloseOpenOnStart));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.tournamentManagementConfirm),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, ['close-registration', 'start']);
    },
  );
  testWidgets(
    'TC-APP-LIFECYCLE-08: reopening after the deadline passed asks for a new deadline first',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      final repository = _LifecycleRepository();
      await tester.pumpWidget(
        _app(
          _tournament(
            'REGISTRATION_CLOSED',
            registrationEndDate: DateTime.utc(2020, 1, 1),
          ),
          managementRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await tester.tap(find.text(l10n.tournamentManagementReopenRegistration));
      await tester.pumpAndSettle();

      // Server từ chối mở lại khi hạn cũ đã qua: phải chọn hạn mới trước.
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(repository.calls, isEmpty);
    },
  );

  testWidgets(
    'registration editor holds visibility, mode, dates and deadlines',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _app(
          _tournament('in_progress'),
          managementRepository: _EmptyTournamentManagementRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      await _openSettings(tester);
      await tester.tap(find.text(l10n.tournamentManagementRegistration).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.tournamentManagementPublic), findsOneWidget);
      expect(
        find.text(l10n.tournamentManagementRegistrationMode),
        findsOneWidget,
      );
      expect(
        find.text(l10n.tournamentManagementRegistrationStarts),
        findsOneWidget,
      );
      expect(
        find.text(l10n.tournamentManagementRegistrationEnds),
        findsOneWidget,
      );
      expect(find.text(l10n.tournamentManagementStartDate), findsOneWidget);
      expect(find.text(l10n.tournamentManagementEndDate), findsOneWidget);
      expect(
        find.text(l10n.tournamentManagementRegenerateInvite),
        findsNothing,
      );
      expect(find.text(l10n.tournamentManagementName), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('banner collapses while tabs stay pinned', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    final title = find.text(l10n.managementTitle);
    double titleOpacity() => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(of: title, matching: find.byType(AnimatedOpacity))
              .first,
        )
        .opacity;

    expect(titleOpacity(), 0);
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(titleOpacity(), 1);
    expect(find.text('City Pickleball Cup').hitTestable(), findsNothing);
    expect(find.byType(TabBar).hitTestable(), findsOneWidget);
    expect(
      find.widgetWithText(Tab, l10n.tournamentManagementOverview).hitTestable(),
      findsOneWidget,
    );
    // Tab strip cuộn ngang ở 390 px, nên tab Cài đặt nằm ngoài viewport ban đầu.
    // Spec dòng 361 yêu cầu reachable: cuộn tab strip tới nó rồi mới kiểm hit-test.
    final settingsTab = find.widgetWithText(
      Tab,
      l10n.tournamentManagementTabSettings,
    );
    await tester.ensureVisible(settingsTab);
    await tester.pumpAndSettle();
    expect(settingsTab.hitTestable(), findsOneWidget);
  });

  testWidgets('athletes tab row with no registrations shows the empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    final divisions = <Map<String, dynamic>>[
      {'id': 'div-empty', 'name': 'Đôi Nam Nữ', 'matchType': 'DOUBLES'},
    ];
    final tournament = _tournament('in_progress', divisions: divisions);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          introTeamsProvider(
            'tournament-1',
          ).overrideWith((ref) async => const []),
          tournamentProvider(
            'tournament-1',
          ).overrideWith((ref) => Stream.value(tournament)),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => divisions),
        ],
        child: _app(
          tournament,
          managementRepository: _EmptyTournamentManagementRepository(),
          tournamentRepository: _EmptyTournamentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openTab(tester, l10n.tournamentManagementTabAthletes);
    // Row đóng: chưa có phần tham gia nào được dựng.
    expect(find.byType(TournamentManagementPeopleSection), findsNothing);

    final row = find.byKey(const ValueKey('athlete-division-row-div-empty'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(TournamentManagementPeopleSection), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementApplicationsEmpty),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('android back closes an opened section before leaving the hub', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.manageSettingsInfoSection).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementName), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentManagementName), findsNothing);
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    expect(
      find.text(l10n.manageSettingsInfoSection).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bracket tab embeds an editable bracket workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openTab(tester, l10n.tournamentManagementTabBracket);

    final bracket = tester.widget<BracketViewScreen>(
      find.byType(BracketViewScreen).first,
    );
    expect(bracket.isEmbedded, isTrue);
    expect(bracket.canEditBracket, isTrue);
  });

  testWidgets(
    'overview tab content is positioned immediately below pinned tab strip without excessive gap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(_app(_tournament('completed', quick: false)));
      await tester.pumpAndSettle();

      final tabBarRect = tester.getRect(find.byType(TabBar).first);
      final locationFinder = find.byKey(
        const ValueKey('tournament-overview-location-edit'),
      );
      expect(locationFinder, findsOneWidget);
      final locationRect = tester.getRect(locationFinder);

      final gap = locationRect.top - tabBarRect.bottom;
      expect(gap, greaterThanOrEqualTo(0.0));
      expect(gap, lessThanOrEqualTo(24.0));
    },
  );

  testWidgets(
    'athletes tab content is positioned immediately below pinned tab strip without excessive gap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      final divisions = <Map<String, dynamic>>[
        {'id': 'div-mixed', 'name': 'Đôi Nam Nữ', 'matchType': 'DOUBLES'},
        {'id': 'div-men', 'name': 'Đơn nam', 'matchType': 'SINGLES'},
      ];
      final tournament = _tournament('in_progress', divisions: divisions);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => divisions),
          ],
          child: _app(
            tournament,
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: _EmptyTournamentRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      final tabFinder = find.widgetWithText(
        Tab,
        l10n.tournamentManagementTabAthletes,
      );
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();
      // Cuộn lên 180px kéo trên outer header (tương ứng với ảnh người dùng gửi)
      await tester.dragFrom(const Offset(200, 100), const Offset(0, -180));
      await tester.pumpAndSettle();

      final tabBarRect = tester.getRect(find.byType(TabBar).first);
      final firstRow = find.byKey(
        const ValueKey('athlete-division-row-div-mixed'),
      );
      expect(firstRow, findsOneWidget);
      final rowRect = tester.getRect(firstRow);

      final gap = rowRect.top - tabBarRect.bottom;
      expect(gap, greaterThanOrEqualTo(0.0));
      expect(gap, lessThanOrEqualTo(24.0));
    },
  );

  testWidgets(
    'tournament title keeps a steady gap below the banner frame while the header collapses',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        _app(
          _tournament(
            'in_progress',
            bannerUrl: 'https://images.example/tournament-banner.jpg',
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final dy in [0.0, -40.0, -80.0]) {
        if (dy != 0.0) {
          await tester.dragFrom(const Offset(200, 300), Offset(0, dy));
          await tester.pumpAndSettle();
        }
        // Đáy khung cắt là phần người dùng nhìn thấy; ảnh parallax bên trong
        // có thể kéo dài hơn khung nên không dùng làm mốc.
        final frameBottom = tester
            .getRect(find.byType(FlexibleSpaceBar))
            .bottom;
        final titleTop = tester.getRect(find.text('City Pickleball Cup')).top;
        expect(
          titleTop - frameBottom,
          inInclusiveRange(0.0, 24.0),
          reason:
              'sau khi kéo thêm $dy: đáy khung=$frameBottom, đỉnh tên giải=$titleTop',
        );
      }
    },
  );

  testWidgets(
    'bracket tab content is positioned immediately below pinned tab strip without excessive gap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentRepositoryProvider.overrideWithValue(
              _EmptyTournamentRepository(),
            ),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: _app(
            _tournament('in_progress'),
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: _EmptyTournamentRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      final tabFinder = find.widgetWithText(
        Tab,
        l10n.tournamentManagementTabBracket,
      );
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(200, 100), const Offset(0, -180));
      await tester.pumpAndSettle();

      final tabBarRect = tester.getRect(find.byType(TabBar).first);
      final bracketFinder = find.byType(BracketViewScreen);
      expect(bracketFinder, findsOneWidget);
      final bracketRect = tester.getRect(bracketFinder);

      final gap = bracketRect.top - tabBarRect.bottom;
      expect(gap, greaterThanOrEqualTo(0.0));
      expect(gap, lessThanOrEqualTo(24.0));
    },
  );

  testWidgets(
    'schedule tab content is positioned immediately below pinned tab strip without excessive gap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentRepositoryProvider.overrideWithValue(
              _EmptyTournamentRepository(),
            ),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: _app(
            _tournament('in_progress'),
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: _EmptyTournamentRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      await _openTab(tester, l10n.tournamentManagementSchedule);
      // Không drag thêm (đo ở vị trí sau khi chọn tab)
      final tabBarRect = tester.getRect(find.byType(TabBar).first);
      final iconFinder = find.byIcon(Icons.category_outlined);
      expect(iconFinder, findsOneWidget);
      final iconRect = tester.getRect(iconFinder);
      final cardFinder = find
          .ancestor(of: iconFinder, matching: find.byType(Container))
          .first;
      final cardRect = tester.getRect(cardFinder);

      final gap = cardRect.top - tabBarRect.bottom;
      expect(gap, greaterThanOrEqualTo(0.0));
      expect(gap, lessThanOrEqualTo(72.0));
    },
  );

  group('athletes tab as expandable division rows', () {
    final divisions = <Map<String, dynamic>>[
      {'id': 'div-mixed', 'name': 'Đôi Nam Nữ', 'matchType': 'DOUBLES'},
      {'id': 'div-men', 'name': 'Đơn nam', 'matchType': 'SINGLES'},
    ];
    const participants = [
      OrganizerOpsParticipant(
        id: 'p-1',
        teamName: 'Danh – Luân',
        teamStatus: 'COMPLETE',
        isPaid: true,
        members: [
          OrganizerOpsMember(
            userId: 'u-danh',
            fullName: 'Danh',
            role: 'CAPTAIN',
          ),
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
      OrganizerOpsParticipant(
        id: 'p-4',
        teamName: 'Nhật Minh',
        teamStatus: 'PENDING_PARTNER',
        isPaid: false,
        members: [OrganizerOpsMember(userId: 'u-minh', fullName: 'Nhật Minh')],
        divisionId: 'div-mixed',
      ),
      OrganizerOpsParticipant(
        id: 'p-3',
        teamName: 'Cường',
        teamStatus: 'COMPLETE',
        isPaid: true,
        members: [OrganizerOpsMember(userId: 'u-cuong', fullName: 'Cường')],
        divisionId: 'div-men',
      ),
    ];

    Future<void> pumpAthletes(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      final tournament = _tournament('in_progress', divisions: divisions);
      final repository = _DivisionParticipantsRepository(participants);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => divisions),
          ],
          child: _app(
            tournament,
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await _openTab(tester, l10n.tournamentManagementTabAthletes);
    }

    final rowMixed = find.byKey(
      const ValueKey('athlete-division-row-div-mixed'),
    );
    final rowMen = find.byKey(const ValueKey('athlete-division-row-div-men'));
    final bodyMixed = find.byKey(
      const ValueKey('athlete-division-body-div-mixed'),
    );
    final bodyMen = find.byKey(const ValueKey('athlete-division-body-div-men'));

    testWidgets('shows one row per division and no old segment or chips', (
      tester,
    ) async {
      await pumpAthletes(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;

      expect(rowMixed, findsOneWidget);
      expect(rowMen, findsOneWidget);
      expect(find.text('Đôi Nam Nữ'), findsOneWidget);
      expect(find.text('Đơn nam'), findsOneWidget);
      // Không row nào mở lúc đầu, và segment cũ không còn.
      expect(bodyMixed, findsNothing);
      expect(bodyMen, findsNothing);
      expect(find.text(l10n.opsRoster), findsNothing);
      expect(find.text(l10n.tournamentManagementRegistration), findsNothing);
    });

    testWidgets('tapping a row expands it and shows only its own teams', (
      tester,
    ) async {
      await pumpAthletes(tester);

      await tester.ensureVisible(rowMixed);
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();

      expect(bodyMixed, findsOneWidget);
      expect(find.text('Danh – Luân'), findsOneWidget);
      // Đội của nội dung khác không lọt vào row này.
      expect(find.text('Cường'), findsNothing);
    });

    testWidgets('opening another row closes the previous one', (tester) async {
      await pumpAthletes(tester);

      await tester.ensureVisible(rowMixed);
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();
      expect(bodyMixed, findsOneWidget);

      await tester.ensureVisible(rowMen);
      await tester.tap(rowMen);
      await tester.pumpAndSettle();

      expect(bodyMen, findsOneWidget);
      expect(bodyMixed, findsNothing);
    });

    testWidgets('tapping the open row again collapses it', (tester) async {
      await pumpAthletes(tester);

      await tester.ensureVisible(rowMixed);
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();
      expect(bodyMixed, findsOneWidget);

      // Mở row có thể làm trang cuộn; đưa row về vùng bấm được rồi bấm lại.
      await tester.ensureVisible(rowMixed);
      await tester.pumpAndSettle();
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();
      expect(bodyMixed, findsNothing);
    });

    testWidgets('expanded row shows the Excel import and template buttons', (
      tester,
    ) async {
      await pumpAthletes(tester);

      await tester.ensureVisible(rowMixed);
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('athletes-import-excel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('athletes-download-template')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Excel import opens the roster import sheet', (
      tester,
    ) async {
      await pumpAthletes(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;

      await tester.ensureVisible(rowMixed);
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();

      final importButton = find.byKey(const ValueKey('athletes-import-excel'));
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.rosterImportTitle), findsOneWidget);
    });

    testWidgets('pending registration lives inside its own division row', (
      tester,
    ) async {
      await pumpAthletes(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;

      await tester.ensureVisible(rowMixed);
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();

      expect(find.text('An – Bình'), findsOneWidget);
      expect(find.text(l10n.tournamentManagementApprove), findsOneWidget);
      expect(find.text(l10n.tournamentManagementReject), findsOneWidget);
    });

    final teamPairKey = const ValueKey('athlete-team-row-p-1');
    final teamPairDetail = const ValueKey('athlete-team-detail-p-1');

    Future<void> openMixed(WidgetTester tester) async {
      await pumpAthletes(tester);
      await tester.ensureVisible(rowMixed);
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();
    }

    testWidgets('doubles team opens member details with avatar and role', (
      tester,
    ) async {
      await openMixed(tester);
      expect(find.byKey(teamPairDetail), findsNothing);

      final row = find.byKey(teamPairKey);
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      final detail = find.byKey(teamPairDetail);
      expect(detail, findsOneWidget);
      // Mỗi VĐV trong đội có avatar riêng (chữ cái đầu khi chưa có ảnh).
      expect(
        find.descendant(of: detail, matching: find.byType(RankAvatar)),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: detail, matching: find.text('Danh')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.text('Luân')),
        findsOneWidget,
      );

      // Bấm vào tên đội (dòng tiêu đề); tâm cả cột đã rơi vào panel chi tiết.
      await tester.tap(
        find.descendant(of: row, matching: find.text('Danh – Luân')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(teamPairDetail), findsNothing);
    });

    testWidgets('doubles team with one member is still expandable', (
      tester,
    ) async {
      await openMixed(tester);
      final row = find.byKey(const ValueKey('athlete-team-row-p-4'));
      await tester.ensureVisible(row);
      // Nội dung đôi: có mũi tên dù mới có 1 người, như web.
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.expand_more_rounded),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: row, matching: find.text('Nhật Minh')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('athlete-team-detail-p-4')),
        findsOneWidget,
      );
    });

    testWidgets('single-player team has no expand affordance', (tester) async {
      await pumpAthletes(tester);
      await tester.ensureVisible(rowMen);
      await tester.tap(rowMen);
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('athlete-team-row-p-3'));
      expect(row, findsOneWidget);
      // Đội đơn: không có mũi tên mở rộng, bấm vào không sinh panel chi tiết.
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.expand_more_rounded),
        ),
        findsNothing,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('athlete-team-detail-p-3')),
        findsNothing,
      );
    });

    testWidgets('team-sport tournament teams are expandable like web', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      final footballDivisions = <Map<String, dynamic>>[
        {'id': 'div-fb', 'name': 'Sân 7', 'matchType': 'SINGLES'},
      ];
      final tournament = _tournament(
        'in_progress',
        sport: 'football',
        divisions: footballDivisions,
      );
      // Bóng đá: teamSize có giá trị -> môn đồng đội, đội luôn mở được.
      expect(tournament.teamSize, isNotNull);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => footballDivisions),
          ],
          child: _app(
            tournament,
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: _DivisionParticipantsRepository(const [
              OrganizerOpsParticipant(
                id: 'p-fb',
                teamName: 'FC Một',
                teamStatus: 'COMPLETE',
                isPaid: true,
                members: [OrganizerOpsMember(userId: 'u-fb', fullName: 'Hùng')],
                divisionId: 'div-fb',
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await _openTab(tester, l10n.tournamentManagementTabAthletes);
      final row = find.byKey(const ValueKey('athlete-division-row-div-fb'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      final team = find.byKey(const ValueKey('athlete-team-row-p-fb'));
      expect(
        find.descendant(
          of: team,
          matching: find.byIcon(Icons.expand_more_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pending approval actions sit on the team row itself', (
      tester,
    ) async {
      await openMixed(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      final row = find.byKey(const ValueKey('athlete-team-row-p-2'));

      // Chưa mở đội vẫn thấy Duyệt / Từ chối ngay trên dòng.
      expect(
        find.descendant(
          of: row,
          matching: find.text(l10n.tournamentManagementApprove),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.text(l10n.tournamentManagementReject),
        ),
        findsOneWidget,
      );
    });

    testWidgets('waiting-for-partner status uses the short label', (
      tester,
    ) async {
      await openMixed(tester);
      expect(find.text('Chờ ghép'), findsOneWidget);
      expect(find.text('Đang chờ ghép đồng đội'), findsNothing);
    });

    testWidgets('team rows are flat: no card border inside the division row', (
      tester,
    ) async {
      await openMixed(tester);
      final row = find.byKey(const ValueKey('athlete-team-row-p-1'));
      expect(row, findsOneWidget);
      // Không còn box viền bao đội (box trong box).
      final bordered = find.descendant(
        of: row,
        matching: find.byWidgetPredicate((w) {
          if (w is! Container) return false;
          final d = w.decoration;
          return d is BoxDecoration &&
              d.border is Border &&
              d.borderRadius != null;
        }),
      );
      expect(bordered, findsNothing);

      // Nội dung nới ra sát mép: bỏ padding ngang 16 của tab.
      final rowRect = tester.getRect(rowMixed);
      final screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(rowRect.left, lessThanOrEqualTo(0.5));
      expect(rowRect.right, greaterThanOrEqualTo(screen - 0.5));

      // Dòng đội cũng sát mép: không còn lề ngang bao quanh danh sách đội.
      final teamRect = tester.getRect(row);
      expect(teamRect.left, lessThanOrEqualTo(0.5));
      expect(teamRect.right, greaterThanOrEqualTo(screen - 0.5));
      // Bỏ lề không được gây tràn: hàng tên + trạng thái + mũi tên vừa khung.
      expect(tester.takeException(), isNull);
    });

    Future<_RecordingManagementRepository> addAthleteFromRow(
      WidgetTester tester, {
      required num effectiveEntryFee,
    }) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      final feeDivisions = <Map<String, dynamic>>[
        {
          'id': 'div-mixed',
          'name': 'Đôi Nam Nữ',
          'matchType': 'DOUBLES',
          'effectiveEntryFee': effectiveEntryFee,
        },
      ];
      final tournament = _tournament(
        'REGISTRATION_OPEN',
        divisions: feeDivisions,
      );
      final management = _RecordingManagementRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => feeDivisions),
          ],
          child: _app(
            tournament,
            managementRepository: management,
            tournamentRepository: _DivisionParticipantsRepository(const []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await _openTab(tester, l10n.tournamentManagementTabAthletes);

      await tester.ensureVisible(rowMixed);
      await tester.tap(rowMixed);
      await tester.pumpAndSettle();
      final addButton = find.text(l10n.opsAddAthlete);
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      final directTab = find.text(l10n.opsAddAthleteDirect);
      await tester.ensureVisible(directTab);
      await tester.tap(directTab);
      await tester.pumpAndSettle();
      final nameField = find.byKey(const ValueKey('add-athlete-direct-name'));
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Paid athlete');
      await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
      await tester.pumpAndSettle();
      return management;
    }

    testWidgets('add athlete from a row with a fee does not auto-approve', (
      tester,
    ) async {
      final management = await addAthleteFromRow(
        tester,
        effectiveEntryFee: 100,
      );

      expect(management.directNames, ['Paid athlete']);
      // Phí dương: VĐV phải chờ duyệt, không được tự động duyệt.
      expect(management.statusUpdates, isEmpty);
    });

    testWidgets('add athlete from a free row auto-approves', (tester) async {
      final management = await addAthleteFromRow(tester, effectiveEntryFee: 0);

      expect(management.directNames, ['Paid athlete']);
      // Đối chứng: cùng luồng nhưng phí 0 thì sheet tự duyệt. Nếu phí không
      // tới được sheet, hai test này sẽ cho cùng một kết quả.
      expect(management.statusUpdates, isNotEmpty);
    });
  });
}
