import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/profile/screens/profile_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
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
      path: '/dashboard',
      builder: (_, _) => const Scaffold(body: Text('dashboard destination')),
    ),
    GoRoute(
      path: '/intro/:id',
      builder: (_, state) =>
          Scaffold(body: Text('intro ${state.pathParameters['id']}')),
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

Future<void> _pumpProfile(
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
}

void main() {
  testWidgets('followed tournaments split into active and completed sections; rows open intro', (
    tester,
  ) async {
    await _pumpProfile(tester);

    // The activity tab previews only two active followed tournaments.
    // "Chi tiết →" switches to the tournaments tab, which lists every active
    // followed tournament above the completed ones.
    await tester.tap(find.text('Chi tiết →'));
    await tester.pumpAndSettle();

    expect(find.text('Giải đấu đang diễn ra & sắp tới'), findsOneWidget);
    expect(find.text('Giải đấu đã hoàn thành'), findsOneWidget);
    expect(find.text('Giải Sắp Tới'), findsOneWidget);
    expect(find.text('Giải Đã Xong'), findsOneWidget);

    // Tapping a followed row opens the tournament intro route.
    await tester.ensureVisible(find.text('Giải Sắp Tới'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giải Sắp Tới'));
    await tester.pumpAndSettle();
    expect(find.text('intro t-soon'), findsOneWidget);
  });
}
