import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/profile/screens/profile_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

class _TestWorkspaceNotifier extends MyTournamentWorkspaceNotifier {
  @override
  Future<TournamentWorkspace> build() async => const TournamentWorkspace();
}

class _SeededWorkspaceNotifier extends MyTournamentWorkspaceNotifier {
  _SeededWorkspaceNotifier(this.seed);

  final TournamentWorkspace seed;

  @override
  Future<TournamentWorkspace> build() async => seed;
}

Tournament _tournament({
  required String id,
  required String name,
  required String status,
  DateTime? endDate,
}) {
  final now = DateTime(2026, 9, 28);
  return Tournament(
    id: id,
    name: name,
    sport: 'pickleball',
    format: 'knockout',
    bracketType: 'single',
    adminToken: 'a',
    refereeToken: 'r',
    viewerToken: 'v',
    creatorId: 'creator-1',
    status: status,
    createdAt: now,
    updatedAt: now,
    endDate: endDate,
  );
}

final _ownedTournament = _tournament(
  id: 't-owned',
  name: 'Giải Tôi Tổ Chức',
  status: 'REGISTRATION_OPEN',
);

final _joinedTournament = _tournament(
  id: 't-joined',
  name: 'Giải Tôi Tham Gia',
  status: 'UPCOMING',
);

final _communities = [
  const Community(
    id: 'club-member',
    name: 'CLB Thành Viên',
    myRole: 'MEMBER',
    memberCount: 42,
    status: 'ACTIVE',
  ),
  const Community(
    id: 'club-rejected',
    name: 'CLB Bị Từ Chối',
    ownerId: 'user-1',
    myRole: 'OWNER',
    memberCount: 3,
    status: 'REJECTED',
    rejectedReason: 'Thiếu giấy phép',
  ),
];

final _followed = [
  _tournament(id: 't-live', name: 'Giải Đang Chạy', status: 'IN_PROGRESS'),
  _tournament(id: 't-open', name: 'Giải Đang Mở', status: 'REGISTRATION_OPEN'),
  _tournament(
    id: 't-done',
    name: 'Giải Đã Xong',
    status: 'COMPLETED',
    endDate: DateTime(2026, 9, 20),
  ),
  _tournament(id: 't-soon', name: 'Giải Sắp Tới', status: 'UPCOMING'),
];

GoRouter _router() => GoRouter(
  initialLocation: '/profile',
  routes: [
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(
      path: '/club/create',
      builder: (_, _) => const Scaffold(body: Text('club create destination')),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, _) => const Scaffold(body: Text('dashboard destination')),
    ),
    GoRoute(
      path: '/intro/:id',
      builder: (_, state) =>
          Scaffold(body: Text('intro ${state.pathParameters['id']}')),
    ),
    GoRoute(
      path: '/club/:id',
      builder: (_, state) =>
          Scaffold(body: Text('club detail ${state.pathParameters['id']}')),
    ),
    GoRoute(
      path: '/club/:id/edit',
      builder: (_, state) =>
          Scaffold(body: Text('club edit ${state.pathParameters['id']}')),
    ),
  ],
);

Widget _profileApp(GoRouter router) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        () => _TestAuthNotifier(
          const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer),
        ),
      ),
      userProfileProvider.overrideWith(
        (ref) async => const UserProfile(id: 'user-1', fullName: 'Alex Player'),
      ),
      userRankingsProvider.overrideWith((ref) async => const []),
      myTournamentWorkspaceProvider.overrideWith(_TestWorkspaceNotifier.new),
      myCommunitiesProvider.overrideWith((ref) async => _communities),
      followedTournamentsProvider.overrideWith((ref) async => _followed),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
    ),
  );
}

Future<({AppLocalizations l10n, GoRouter router})> _pumpProfile(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(430, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = _router();
  addTearDown(router.dispose);
  await tester.pumpWidget(_profileApp(router));
  await tester.pumpAndSettle();

  return (
    l10n: AppLocalizations.of(tester.element(find.byType(ProfileScreen)))!,
    router: router,
  );
}

Finder _filter(String id) => find.byKey(ValueKey('profile-followed-filter-$id'));

void main() {
  testWidgets('community rows keep role/status and open detail or edit', (
    tester,
  ) async {
    final (:l10n, :router) = await _pumpProfile(tester);

    // Both communities are rendered from myCommunitiesProvider.
    expect(find.text(l10n.infoMyClubs), findsOneWidget);
    expect(find.text('CLB Thành Viên'), findsOneWidget);
    expect(find.text('CLB Bị Từ Chối'), findsOneWidget);

    // Member role surfaces as the role badge; memberCount is shown next to it.
    expect(find.text(l10n.profileMemberRole), findsOneWidget);
    expect(find.text('42 ${l10n.profileMembers}'), findsOneWidget);

    // Rejected owner club surfaces the rejection status, reason and resubmit.
    expect(find.text(l10n.profileClubRejected), findsOneWidget);
    expect(find.text('Thiếu giấy phép'), findsOneWidget);
    expect(find.text(l10n.profileClubResubmit), findsOneWidget);

    // Member club opens the detail route.
    await tester.tap(find.text('CLB Thành Viên'));
    await tester.pumpAndSettle();
    expect(find.text('club detail club-member'), findsOneWidget);

    // Rejected owner club opens the edit route instead.
    router.go('/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text('CLB Bị Từ Chối'));
    await tester.pumpAndSettle();
    expect(find.text('club edit club-rejected'), findsOneWidget);
  });

  testWidgets('empty community list offers the create route', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _TestAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                role: UserRole.viewer,
              ),
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(id: 'user-1', fullName: 'Alex'),
          ),
          userRankingsProvider.overrideWith((ref) async => const []),
          myTournamentWorkspaceProvider.overrideWith(_TestWorkspaceNotifier.new),
          myCommunitiesProvider.overrideWith((ref) async => const []),
          followedTournamentsProvider.overrideWith((ref) async => const []),
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
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(ProfileScreen)))!;
    expect(find.text(l10n.profileNoClubs), findsOneWidget);

    await tester.tap(find.text(l10n.profileCreateClub).first);
    await tester.pumpAndSettle();
    expect(find.text('club create destination'), findsOneWidget);
  });

  testWidgets('followed filters narrow the list and rows open intro', (
    tester,
  ) async {
    final (:l10n, :router) = await _pumpProfile(tester);

    expect(find.text(l10n.infoFollowedTournaments), findsOneWidget);
    for (final id in [
      'all',
      'recent_completed',
      'in_progress',
      'registration',
      'upcoming',
    ]) {
      expect(_filter(id), findsOneWidget, reason: 'missing filter $id');
    }

    // "All" shows every followed tournament.
    expect(find.text('Giải Đang Chạy'), findsOneWidget);
    expect(find.text('Giải Đang Mở'), findsOneWidget);
    expect(find.text('Giải Đã Xong'), findsOneWidget);
    expect(find.text('Giải Sắp Tới'), findsOneWidget);

    // Selecting a status filter drops the non-matching rows.
    await tester.ensureVisible(_filter('in_progress'));
    await tester.pumpAndSettle();
    await tester.tap(_filter('in_progress'));
    await tester.pumpAndSettle();
    expect(find.text('Giải Đang Chạy'), findsOneWidget);
    expect(find.text('Giải Đang Mở'), findsNothing);
    expect(find.text('Giải Sắp Tới'), findsNothing);
    expect(find.text('Giải Đã Xong'), findsNothing);

    // A filter with no match falls back to the "no matching" copy.
    await tester.ensureVisible(_filter('upcoming'));
    await tester.pumpAndSettle();
    await tester.tap(_filter('upcoming'));
    await tester.pumpAndSettle();
    expect(find.text('Giải Sắp Tới'), findsOneWidget);

    // Tapping a followed row opens the tournament intro route.
    await tester.tap(find.text('Giải Sắp Tới'));
    await tester.pumpAndSettle();
    expect(find.text('intro t-soon'), findsOneWidget);
  });

  testWidgets('my tournaments list renders grouped roles and manager route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/organizer/tournaments/:id/manage',
          builder: (_, state) =>
              Scaffold(body: Text('manage ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/intro/:id',
          builder: (_, state) =>
              Scaffold(body: Text('intro ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _TestAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                role: UserRole.viewer,
              ),
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(id: 'user-1', fullName: 'Alex'),
          ),
          userRankingsProvider.overrideWith((ref) async => const []),
          myTournamentWorkspaceProvider.overrideWith(
            () => _SeededWorkspaceNotifier(
              TournamentWorkspace(
                organizedTournaments: [
                  _ownedTournament,
                ],
                participatingTournaments: [
                  _joinedTournament,
                ],
              ),
            ),
          ),
          myCommunitiesProvider.overrideWith((ref) async => const []),
          followedTournamentsProvider.overrideWith((ref) async => const []),
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
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(ProfileScreen)))!;
    expect(find.text(l10n.infoMyTournaments), findsOneWidget);
    expect(find.text('Giải Tôi Tổ Chức'), findsOneWidget);
    expect(find.text('Giải Tôi Tham Gia'), findsOneWidget);
    expect(find.text(l10n.profileOwnerTournamentRole), findsOneWidget);
    expect(find.text(l10n.profilePlayerTournamentRole), findsOneWidget);

    // Owner role opens the organizer management workspace.
    await tester.tap(find.text('Giải Tôi Tổ Chức'));
    await tester.pumpAndSettle();
    expect(find.text('manage t-owned'), findsOneWidget);

    // Player role opens the public intro.
    router.go('/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giải Tôi Tham Gia'));
    await tester.pumpAndSettle();
    expect(find.text('intro t-joined'), findsOneWidget);
  });
}
