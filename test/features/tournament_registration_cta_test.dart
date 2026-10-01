import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
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

Tournament _tournament({
  String status = 'REGISTRATION_OPEN',
  String visibility = 'PUBLIC',
  bool registrationLocked = false,
  bool registrationExpired = false,
  bool registrationNotStarted = false,
  String creatorId = 'owner-1',
}) {
  final now = DateTime.now();
  return Tournament(
    id: _tournamentId,
    name: 'CTA tournament',
    sport: 'badminton',
    format: 'SINGLES',
    bracketType: 'single_elimination',
    status: status,
    visibility: visibility,
    adminToken: '',
    refereeToken: '',
    viewerToken: '',
    creatorId: creatorId,
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
}) => ProviderScope(
  overrides: [
    authProvider.overrideWith(_GuestAuthNotifier.new),
    tournamentIntroWithInviteProvider((
      id: _tournamentId,
      invite: invite,
    )).overrideWith((ref) async => tournament),
    tournamentDivisionsProvider(
      _tournamentId,
    ).overrideWith((ref) async => const <Map<String, dynamic>>[]),
    teamsProvider(_tournamentId).overrideWith((ref) => Stream.value(const [])),
    matchesProvider(
      _tournamentId,
    ).overrideWith((ref) => Stream.value(const [])),
    followedTournamentsProvider.overrideWith((ref) async => const []),
  ],
  child: child,
);
