import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_brand_fallback.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_dispatcher.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
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
}) => Tournament.fromJson({
  'name': name,
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  if (quick) 'isLite': true,
  'communityId': communityId,
  'bannerUrl': bannerUrl,
  'logoUrl': logoUrl,
  if (superLite)
    'tournamentConfig': {'mode': 'LITE', 'hideAdvancedSettings': true},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Widget _app(Tournament tournament, {Locale locale = const Locale('vi')}) =>
    ProviderScope(
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

class _IdleLiteManagementNotifier extends LiteManagementNotifier {
  @override
  Future<void> init(String tournamentId) async {}
}

void main() {
  testWidgets('admin, organizer, and Lite entry routes share one hub', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    final container = ProviderContainer(
      overrides: [
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
    await tester.tap(find.text(l10n.endTournament));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.continueButton));
    await tester.pumpAndSettle();
    expect(finalizedIds, isEmpty);
    expect(find.text(l10n.endTournament), findsOneWidget);

    await tester.tap(find.text(l10n.endTournament));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.confirmEndButton));
    await tester.pumpAndSettle();

    expect(finalizedIds, ['tournament-1']);
    expect(tournamentReads, 2);
    expect(find.text(l10n.endTournament), findsNothing);
    expect(find.text(l10n.tournamentEnded), findsOneWidget);
  });

  testWidgets('opens the existing action workspaces from the shared hub', (
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
          routes: [
            for (final action in ['tokens', 'teams', 'draw', 'bracket'])
              GoRoute(
                path: action,
                builder: (context, state) =>
                    Scaffold(body: Text('Destination: $action')),
              ),
          ],
        ),
        GoRoute(
          path: '/organizer/tournaments/:id/ops',
          builder: (context, state) =>
              const Scaffold(body: Text('Destination: workspace')),
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
    final actions = {
      l10n.manageTokens: 'tokens',
      l10n.manageTeams: 'teams',
      l10n.manageDraw: 'draw',
      l10n.viewBracket: 'bracket',
      l10n.opsTitle: 'workspace',
      l10n.lite_managementTitle: 'lite',
    };
    for (final entry in actions.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text('Destination: ${entry.value}'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('renders tournament summary and all existing manager actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text('City Pickleball Cup'), findsOneWidget);
    expect(find.text(l10n.notUpdated), findsNothing);
    expect(find.text(l10n.locationNotUpdated), findsNothing);
    expect(find.text(l10n.manageTokens), findsOneWidget);
    expect(find.text(l10n.manageTeams), findsOneWidget);
    expect(find.text(l10n.manageDraw), findsOneWidget);
    expect(find.text(l10n.viewBracket), findsOneWidget);
    expect(find.text(l10n.endTournament), findsOneWidget);
    expect(find.text(l10n.exportData), findsOneWidget);
    expect(find.text(l10n.opsTitle), findsOneWidget);
    expect(find.byType(SportoBrandFallback), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('management header displays its supplied tournament artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    const bannerUrl = 'https://images.example/tournament-banner.jpg';
    const logoUrl = 'https://images.example/tournament-logo.jpg';

    await tester.pumpWidget(
      _app(_tournament('in_progress', bannerUrl: bannerUrl, logoUrl: logoUrl)),
    );
    await tester.pumpAndSettle();

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
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url == logoUrl,
      ),
      findsOneWidget,
    );
    expect(find.byType(SportoBrandFallback), findsNWidgets(2));
    expect(tester.takeException(), isNull);
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

    await tester.scrollUntilVisible(
      find.text(l10n.exportData),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n.endTournament), findsNothing);
    expect(find.text(l10n.exportData), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(l10n.opsTitle),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.opsTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
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
    await tester.tap(find.text(l10n.tournamentManagementGeneral).first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentManagementName), findsOneWidget);
    expect(find.text(l10n.tournamentManagementLifecycle), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text(l10n.tournamentManagementChooseDate), findsNWidgets(4));
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
    await tester.tap(find.text(l10n.tournamentManagementGeneral).first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentManagementLifecycle), findsOneWidget);
    expect(find.text(l10n.tournamentManagementVisibility), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
