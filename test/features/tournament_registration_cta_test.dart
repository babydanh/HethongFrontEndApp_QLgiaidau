import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _tournamentId = 'cta-tournament';
const _invite = 'invite-cta';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

class _OrganizerAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.organizer,
  );
}

class _AdminAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.admin);
}

Tournament _tournament({
  String status = 'REGISTRATION_OPEN',
  String visibility = 'PUBLIC',
  bool registrationLocked = false,
  bool registrationExpired = false,
  bool registrationNotStarted = false,
  String creatorId = 'owner-1',
  String creatorFullName = 'Tournament owner',
  String format = 'SINGLES',
  bool isSuperLite = false,
}) {
  final now = DateTime.now();
  return Tournament(
    id: _tournamentId,
    name: 'CTA tournament',
    sport: 'badminton',
    format: format,
    bracketType: 'single_elimination',
    status: status,
    visibility: visibility,
    adminToken: '',
    refereeToken: '',
    viewerToken: '',
    creatorId: creatorId,
    creatorFullName: creatorFullName,
    isSuperLite: isSuperLite,
    maxTeams: 8,
    createdAt: now,
    updatedAt: now,
    registrationStartDate: registrationNotStarted
        ? now.add(const Duration(days: 1))
        : now.subtract(const Duration(days: 1)),
    registrationEndDate: registrationExpired
        ? now.subtract(const Duration(days: 1))
        : now.add(const Duration(days: 1)),
    isRegistrationLocked: registrationLocked,
    divisions: const [
      TournamentDivision(
        id: 'division-1',
        name: 'Adults',
        matchType: 'SINGLES',
        maxParticipants: 8,
      ),
    ],
  );
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'open registration shows floating CTA and preserves route context',
    (tester) async {
      _setPhoneViewport(tester);
      final router = _createRouter(invite: _invite);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _scope(tournament: _tournament(), invite: _invite, child: _app(router)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final context = tester.element(find.byType(TournamentIntroScreen));
      final registerLabel = AppLocalizations.of(context)!.register;
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text(registerLabel), findsOneWidget);
      final registerButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(
        registerButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        Colors.transparent,
      );
      expect(find.byType(FloatingBottomNav), findsOneWidget);

      await tester.tap(find.text(registerLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('register-route:$_tournamentId|$_invite|division-1'),
        findsOneWidget,
      );
    },
  );

  testWidgets('non-open registration keeps the bottom navigation', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(status: 'COMPLETED'),
        invite: null,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    final registerLabel = AppLocalizations.of(context)!.register;
    expect(find.byType(TextButton), findsNothing);
    expect(find.text(registerLabel), findsNothing);
    expect(find.byType(FloatingBottomNav), findsOneWidget);
  });

  testWidgets('locked registration hides CTA instead of disabling it', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(registrationLocked: true),
        invite: null,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text(AppLocalizations.of(context)!.register), findsNothing);
    expect(
      find.text(AppLocalizations.of(context)!.registerRegClosed),
      findsNothing,
    );
    expect(find.byType(FloatingBottomNav), findsOneWidget);
  });

  testWidgets('expired registration hides CTA entirely', (tester) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(registrationExpired: true),
        invite: null,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text(AppLocalizations.of(context)!.register), findsNothing);
    expect(
      find.text(AppLocalizations.of(context)!.registerRegClosed),
      findsNothing,
    );
    expect(find.byType(FloatingBottomNav), findsOneWidget);
  });

  testWidgets('future registration hides CTA instead of disabling it', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(registrationNotStarted: true),
        invite: null,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text(AppLocalizations.of(context)!.register), findsNothing);
    expect(
      find.text(AppLocalizations.of(context)!.lite_registrationNotOpen),
      findsNothing,
    );
    expect(find.byType(FloatingBottomNav), findsOneWidget);
  });

  testWidgets('private access denial still exposes actionable CTA', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(visibility: 'PRIVATE'),
        invite: null,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    final registerLabel = AppLocalizations.of(context)!.register;
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(TextButton), findsOneWidget);
    expect(find.text(registerLabel), findsOneWidget);
    expect(find.byType(FloatingBottomNav), findsOneWidget);
  });
  testWidgets('viewer does not see a management action in the header', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(tournament: _tournament(), invite: null, child: _app(router)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    expect(
      find.byTooltip(AppLocalizations.of(context)!.managementTitle),
      findsNothing,
    );
  });

  testWidgets('authorized organizer opens the Lite management route', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(isSuperLite: true),
        invite: null,
        authNotifier: _OrganizerAuthNotifier.new,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    final manageAction = find.byTooltip(
      AppLocalizations.of(context)!.managementTitle,
    );
    expect(manageAction, findsOneWidget);

    await tester.tap(manageAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('lite-manage:$_tournamentId'), findsOneWidget);
  });

  testWidgets('authorized organizer opens the standard management route', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(),
        invite: null,
        authNotifier: _OrganizerAuthNotifier.new,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    await tester.tap(
      find.byTooltip(AppLocalizations.of(context)!.managementTitle),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('organizer-manage:$_tournamentId'), findsOneWidget);
  });

  testWidgets('overview omits requested chips and organizer banner', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(
          format: 'DOUBLES',
          status: 'REGISTRATION_CLOSED',
        ),
        invite: null,
        authNotifier: _OrganizerAuthNotifier.new,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.lite_doubles), findsNothing);
    expect(find.text(l10n.statusLabelRegistrationClosed), findsNothing);
    expect(find.text('Bạn là Ban tổ chức'), findsNothing);
    expect(find.text('CTA tournament'), findsOneWidget);
  });
  testWidgets('tournament creator sees the management action', (tester) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(),
        invite: null,
        profileId: 'owner-1',
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    expect(
      find.byTooltip(AppLocalizations.of(context)!.managementTitle),
      findsOneWidget,
    );
  });

  testWidgets('admin sees the management action', (tester) async {
    _setPhoneViewport(tester);
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        tournament: _tournament(),
        invite: null,
        authNotifier: _AdminAuthNotifier.new,
        child: _app(router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(TournamentIntroScreen));
    expect(
      find.byTooltip(AppLocalizations.of(context)!.managementTitle),
      findsOneWidget,
    );
  });
}

GoRouter _createRouter({String? invite}) => GoRouter(
  initialLocation: invite == null
      ? '/intro/$_tournamentId'
      : '/intro/$_tournamentId?invite=$invite',
  routes: [
    GoRoute(
      path: '/intro/:id',
      builder: (context, state) => TournamentIntroScreen(
        tournamentId: state.pathParameters['id']!,
        inviteCode: state.uri.queryParameters['invite'],
      ),
    ),
    GoRoute(
      path: '/register/:id',
      builder: (context, state) => Scaffold(
        body: Text(
          'register-route:${state.pathParameters['id']}|'
          '${state.uri.queryParameters['invite'] ?? ''}|'
          '${state.uri.queryParameters['divisionId'] ?? ''}',
        ),
      ),
    ),
    GoRoute(
      path: '/lite-manage/:id',
      builder: (context, state) =>
          Scaffold(body: Text('lite-manage:${state.pathParameters['id']}')),
    ),
    GoRoute(
      path: '/organizer/tournaments/:id/manage',
      builder: (context, state) => Scaffold(
        body: Text('organizer-manage:${state.pathParameters['id']}'),
      ),
    ),
    GoRoute(path: '/home', builder: (context, state) => const SizedBox()),
  ],
);

Widget _app(GoRouter router) => MaterialApp.router(
  theme: AppTheme.lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  routerConfig: router,
);

ProviderScope _scope({
  required Tournament tournament,
  required String? invite,
  required Widget child,
  AuthNotifier Function()? authNotifier,
  String profileId = 'viewer-1',
}) => ProviderScope(
  overrides: [
    authProvider.overrideWith(authNotifier ?? _GuestAuthNotifier.new),
    userProfileProvider.overrideWith(
      (ref) async => UserProfile(
        id: profileId,
        fullName: 'Viewer',
        email: 'viewer@example.test',
      ),
    ),
    tournamentIntroWithInviteProvider((
      id: _tournamentId,
      invite: invite,
    )).overrideWith((ref) async => tournament),
    tournamentDivisionsProvider(
      _tournamentId,
    ).overrideWith((ref) async => const <Map<String, dynamic>>[]),
    introTeamsProvider(_tournamentId).overrideWith((ref) async => const []),
    teamsProvider(_tournamentId).overrideWith((ref) => Stream.value(const [])),
    matchesProvider(
      _tournamentId,
    ).overrideWith((ref) => Stream.value(const [])),
    followedTournamentsProvider.overrideWith((ref) async => const []),
  ],
  child: child,
);
