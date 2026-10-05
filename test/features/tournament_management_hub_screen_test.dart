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
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_dispatcher.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Tournament _tournament(
  String status, {
  String name = 'City Pickleball Cup',
  bool superLite = false,
  bool quick = false,
  String? communityId,
  String? bannerUrl,
  String? logoUrl,
  String description = '',
  DateTime? startDate,
}) => Tournament.fromJson({
  'name': name,
  'sport': 'pickleball',
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
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Widget _app(
  Tournament tournament, {
  Locale locale = const Locale('vi'),
  UserProfile? profile,
  TournamentManagementRepository? managementRepository,
  ITournamentRepository? tournamentRepository,
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

class _SuccessfulFinalizer extends TournamentActionNotifier {
  _SuccessfulFinalizer(this.onFinalize);

  final void Function(String tournamentId) onFinalize;

  @override
  Future<bool> finalizeTournament(String tournamentId) async {
    onFinalize(tournamentId);
    return true;
  }
}

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
}

class _EmptyTournamentRepository implements ITournamentRepository {
  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => const [];

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

class _IdleLiteManagementNotifier extends LiteManagementNotifier {
  @override
  Future<void> init(String tournamentId) async {}
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('overview tournament title opens its general editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
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

    final hub = find.byType(TournamentManagementHubScreen);
    final l10n = AppLocalizations.of(tester.element(hub))!;
    final targets = [
      ('tournament-overview-dates-edit', l10n.tournamentManagementGeneral),
      (
        'tournament-overview-description-edit',
        l10n.tournamentManagementGeneral,
      ),
      ('tournament-overview-timeline-edit', l10n.tournamentManagementGeneral),
      ('tournament-overview-banner-edit', l10n.tournamentManagementBranding),
      (
        'tournament-overview-athletes-edit',
        l10n.tournamentManagementRegistration,
      ),
      ('tournament-overview-location-edit', l10n.tournamentManagementVenues),
      ('tournament-overview-entry-fee-edit', l10n.tournamentManagementFinance),
    ];

    for (final (key, sectionTitle) in targets) {
      final target = find.byKey(ValueKey(key));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text(sectionTitle), findsWidgets);
      await tester.tap(find.byTooltip(l10n.tournamentManagementBack));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('hub shows only overview and opens accessible settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(_tournament('in_progress'), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('City Pickleball Cup'), findsOneWidget);

    final settings = find.byTooltip('Tournament settings');
    expect(settings, findsOneWidget);
    expect(
      find.descendant(
        of: settings,
        matching: find.byIcon(Icons.settings_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(find.text('SETUP'), findsOneWidget);
    expect(find.text('OPERATIONS'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bracket and schedule stay available in operations settings', (
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
    await tester.tap(find.byTooltip(l10n.tournamentManagementSettingsTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementOperationsGroup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.viewBracket).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.bracketView_noMatches), findsOneWidget);
    expect(find.text(l10n.bracketView_drawHint), findsOneWidget);
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);

    await tester.tap(find.text(l10n.tournamentManagementSchedule).first);
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.opsRefresh), findsOneWidget);
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
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
    final finalizedIds = <String>[];
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
          tournamentActionProvider.overrideWith(
            () => _SuccessfulFinalizer(finalizedIds.add),
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
    expect(finalizedIds, isEmpty);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsOneWidget);

    await tester.tap(find.text(l10n.endTournament));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.confirmEndButton));
    await tester.pumpAndSettle();

    expect(finalizedIds, ['tournament-1']);
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
    expect(find.text(l10n.tournamentManagementGeneral), findsOneWidget);
    expect(find.text(l10n.tournamentManagementBranding), findsOneWidget);
    expect(find.text(l10n.tournamentManagementVenues), findsOneWidget);
    expect(find.text(l10n.tournamentManagementRegistration), findsOneWidget);
    expect(find.text(l10n.tournamentManagementDivisions), findsOneWidget);

    await tester.tap(find.text(l10n.tournamentManagementOperationsGroup));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementSchedule), findsOneWidget);
    expect(find.text(l10n.manageTeams), findsOneWidget);
    expect(find.text(l10n.manageDraw), findsOneWidget);
    expect(find.text(l10n.viewBracket), findsOneWidget);
    expect(find.text(l10n.tournamentManagementSponsors), findsOneWidget);
    expect(find.text(l10n.tournamentManagementFinance), findsOneWidget);
    expect(find.text(l10n.tournamentManagementLivestream), findsOneWidget);

    await tester.tap(find.text(l10n.tournamentManagementSystemGroup));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementPermissions), findsOneWidget);
    expect(find.text(l10n.manageTokens), findsOneWidget);

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
    await tester.tap(find.text(l10n.tournamentManagementOperationsGroup).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementSchedule), findsOneWidget);
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
  testWidgets('phone navigation opens usable tournament settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.tournamentManagementSetupGroup).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementGeneral).first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentManagementName), findsOneWidget);
    expect(find.text(l10n.tournamentManagementLifecycle), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(l10n.tournamentManagementDescription), findsOneWidget);
    expect(find.text(l10n.tournamentManagementChooseDate), findsNWidgets(4));
    expect(find.text(l10n.tournamentManagementGeneral), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementGeneralDescription),
      findsNothing,
    );
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
    await tester.tap(find.text(l10n.tournamentManagementSetupGroup).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementGeneral).first);
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
        child: _app(_tournament('in_progress')),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.tournamentManagementOperationsGroup).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementLiveOperations), findsOneWidget);
    await tester.tap(find.text(l10n.tournamentManagementSchedule).first);
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.opsRefresh), findsOneWidget);
    expect(find.byTooltip(l10n.tournamentManagementBack), findsNWidgets(2));
    final detailBack = find.descendant(
      of: find
          .ancestor(
            of: find.byTooltip(l10n.tournamentManagementBack),
            matching: find.byType(ListTile),
          )
          .first,
      matching: find.byTooltip(l10n.tournamentManagementBack),
    );
    await tester.tap(detailBack);
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementLiveOperations), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.tournamentManagementLivestream),
      160,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text(l10n.tournamentManagementLivestream), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('tablet navigation updates the management detail section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.tournamentManagementSetupGroup).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementGeneral).first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentManagementLifecycle), findsOneWidget);
    expect(find.text(l10n.tournamentManagementVisibility), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
