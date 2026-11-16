import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_room.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_chat_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/shared/widgets/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _id = 'tournament-chat';

class _GuestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

class _SignedInAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

/// The four server replies the plan names: OPEN, CLOSED, KICKED, PURGED.
const _open = TournamentChatRoom(
  available: true,
  roomId: 'room-1',
  status: 'OPEN',
  canWrite: true,
  role: 'MEMBER',
);
const _closed = TournamentChatRoom(
  available: true,
  roomId: 'room-1',
  status: 'CLOSED',
  canWrite: false,
  role: 'MEMBER',
);
const _kicked = TournamentChatRoom(available: false, reason: 'KICKED');
const _purged = TournamentChatRoom(available: false, reason: 'PURGED');
const _needsRegistration = TournamentChatRoom(
  available: false,
  reason: 'NOT_REGISTERED',
  registrationOpen: true,
);
const _registrationClosed = TournamentChatRoom(
  available: false,
  reason: 'NOT_REGISTERED',
  registrationOpen: false,
);
const _pending = TournamentChatRoom(
  available: true,
  roomId: 'room-1',
  status: 'OPEN',
  canWrite: false,
  role: 'MEMBER',
  registration: 'PENDING',
  name: 'Chat Cup',
  logoUrl: 'https://cdn.example.test/logo.png',
);

Tournament _tournament() => Tournament.fromJson({
  'name': 'Chat Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION_OPEN',
  'visibility': 'PUBLIC',
  'maxTeams': 8,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _id);

final _lastRoutes = <String>[];

Future<void> _pump(
  WidgetTester tester, {
  required bool signedIn,
  TournamentChatRoom? room,
}) async {
  _lastRoutes.clear();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const TournamentIntroScreen(tournamentId: _id),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) {
          _lastRoutes.add(state.uri.toString());
          return const Scaffold(body: Text('AT /login'));
        },
      ),
      GoRoute(
        path: '/register/:id',
        builder: (_, state) {
          _lastRoutes.add(state.uri.toString());
          return const Scaffold(body: Text('AT /register'));
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) {
          _lastRoutes.add(state.uri.toString());
          return const Scaffold(body: Text('AT /chat'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(signedIn ? _SignedInAuth.new : _GuestAuth.new),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'viewer-1',
            fullName: 'Viewer',
            email: 'viewer@example.test',
          ),
        ),
        tournamentIntroWithInviteProvider((
          id: _id,
          invite: null,
        )).overrideWith((ref) async => _tournament()),
        tournamentDivisionsProvider(
          _id,
        ).overrideWith((ref) async => const <Map<String, dynamic>>[]),
        introTeamsProvider(_id).overrideWith((ref) async => const []),
        teamsProvider(_id).overrideWith((ref) => Stream.value(const [])),
        matchesProvider(_id).overrideWith((ref) => Stream.value(const [])),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        if (room != null)
          tournamentChatRoomProvider(_id).overrideWith((ref) async => room),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));
  const openKey = ValueKey('tournament-chat-open');
  const closedKey = ValueKey('tournament-chat-closed');
  const kickedKey = ValueKey('tournament-chat-kicked');
  const guestKey = ValueKey('tournament-chat-guest');
  const registerKey = ValueKey('tournament-chat-register');
  const registerClosedKey = ValueKey('tournament-chat-register-closed');
  const pendingKey = ValueKey('tournament-chat-pending');

  testWidgets('TC-ROOM-A01 OPEN reply shows the green open chat icon', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _open);

    expect(find.byKey(openKey), findsOneWidget);
    expect(find.byTooltip(l10n.tournamentChatTooltipOpen), findsOneWidget);
    expect(find.byKey(closedKey), findsNothing);
    expect(find.byKey(kickedKey), findsNothing);
    expect(tester.getSize(find.byKey(openKey)).shortestSide, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-ROOM-A01 tapping the open icon opens the room chat', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _open);

    await tester.tap(find.byKey(openKey));
    await tester.pumpAndSettle();

    expect(find.text('AT /chat'), findsOneWidget);
    expect(_lastRoutes.single, startsWith('/chat/room-1'));
    expect(_lastRoutes.single, contains('type=TOURNAMENT'));
    expect(_lastRoutes.single, isNot(contains('readOnly=1')));
  });

  testWidgets('TC-ROOM-A02 CLOSED reply shows the archive icon, opens read-only', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _closed);

    expect(find.byKey(closedKey), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byTooltip(l10n.tournamentChatTooltipClosed), findsOneWidget);

    await tester.tap(find.byKey(closedKey));
    await tester.pumpAndSettle();

    expect(_lastRoutes.single, contains('readOnly=1'));
  });

  testWidgets('TC-ROOM-A03 KICKED reply shows a dimmed icon that explains, not enters', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _kicked);

    expect(find.byKey(kickedKey), findsOneWidget);
    expect(find.byIcon(Icons.block_rounded), findsOneWidget);

    await tester.tap(find.byKey(kickedKey));
    await tester.pump();

    expect(find.text(l10n.chatRoomKickedNotice), findsOneWidget);
    expect(_lastRoutes, isEmpty);
  });

  testWidgets('TC-ROOM-A04 PURGED reply hides the chat icon', (tester) async {
    await _pump(tester, signedIn: true, room: _purged);

    expect(find.byKey(openKey), findsNothing);
    expect(find.byKey(closedKey), findsNothing);
    expect(find.byKey(kickedKey), findsNothing);
    expect(find.byKey(guestKey), findsNothing);
  });

  testWidgets('TC-ROOM-A05 a guest sees the icon and is sent to login on tap', (
    tester,
  ) async {
    await _pump(tester, signedIn: false);

    expect(find.byKey(guestKey), findsOneWidget);

    await tester.tap(find.byKey(guestKey));
    await tester.pumpAndSettle();

    expect(find.text('AT /login'), findsOneWidget);
  });

  testWidgets('TC-ROOM-A06 the bookmark left the app bar; menu holds follow and report', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _open);

    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.tournamentMenuTooltip));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentMenuFollow), findsOneWidget);
    expect(find.text(l10n.tournamentMenuReport), findsOneWidget);
    final itemHeight = tester.getSize(find.ancestor(
      of: find.text(l10n.tournamentMenuReport),
      matching: find.byType(InkWell),
    ).first).height;
    expect(itemHeight, greaterThanOrEqualTo(44));
  });

  testWidgets('TC-ROOM-A07 the report menu item opens the report sheet', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _open);

    await tester.tap(find.byTooltip(l10n.tournamentMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentMenuReport));
    await tester.pumpAndSettle();

    expect(find.byType(ReportSheet), findsOneWidget);
  });

  testWidgets('TC-CHAT-UI-A-04 NOT_REGISTERED opens the registration screen, not the room', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _needsRegistration);

    expect(find.byKey(registerKey), findsOneWidget);
    expect(find.byTooltip(l10n.tournamentChatTooltipRegister), findsOneWidget);
    expect(find.byKey(openKey), findsNothing);

    await tester.tap(find.byKey(registerKey));
    await tester.pumpAndSettle();

    expect(find.text('AT /register'), findsOneWidget);
    expect(_lastRoutes.single, '/register/$_id');
  });

  testWidgets('TC-CHAT-UI-A-04 NOT_REGISTERED with registration closed explains and stays put', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _registrationClosed);

    expect(find.byKey(registerKey), findsNothing);
    expect(find.byKey(registerClosedKey), findsOneWidget);
    expect(
      find.byTooltip(l10n.tournamentChatTooltipRegistrationClosed),
      findsOneWidget,
    );

    await tester.tap(find.byKey(registerClosedKey));
    await tester.pump();

    expect(
      find.text(l10n.tournamentChatTooltipRegistrationClosed),
      findsWidgets,
    );
    expect(_lastRoutes, isEmpty);
  });

  testWidgets('TC-CHAT-UI-A-04 PENDING enters the room with the input locked and the tournament name', (
    tester,
  ) async {
    await _pump(tester, signedIn: true, room: _pending);

    expect(find.byKey(pendingKey), findsOneWidget);
    expect(find.byKey(openKey), findsNothing);

    await tester.tap(find.byKey(pendingKey));
    await tester.pumpAndSettle();

    expect(_lastRoutes.single, startsWith('/chat/room-1'));
    expect(_lastRoutes.single, contains('pending=1'));
    expect(_lastRoutes.single, isNot(contains('readOnly=1')));
    expect(_lastRoutes.single, contains('name=Chat+Cup'));
    expect(_lastRoutes.single, contains('avatar=https'));
  });
}
