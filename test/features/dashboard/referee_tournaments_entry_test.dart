import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/dashboard/screens/dashboard_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer);
}

TournamentRefereeInvite _accepted(
  String tournamentId,
  String name,
  String tournamentStatus, {
  String category = 'Đôi nam',
}) => TournamentRefereeInvite(
  refereeId: 'ref-$tournamentId-$category',
  tournamentId: tournamentId,
  tournamentName: name,
  tournamentStatus: tournamentStatus,
  categoryName: category,
  assignedAt: null,
  status: 'ACCEPTED',
);

class _Workspace extends MyTournamentWorkspaceNotifier {
  @override
  Future<TournamentWorkspace> build() async => TournamentWorkspace(
    refereeTournaments: [
      _accepted('t-live', 'Giải Mùa Xuân', 'IN_PROGRESS'),
      // A second category of the same tournament is one entry.
      _accepted('t-live', 'Giải Mùa Xuân', 'IN_PROGRESS', category: 'Đôi nữ'),
      // The Backend hides DRAFT/PENDING tournaments from referees (404).
      _accepted('t-draft', 'Giải Nháp', 'DRAFT'),
    ],
  );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
      GoRoute(
        path: '/organizer/tournaments/:id/manage',
        builder: (_, state) => Text('MANAGE:${state.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_SignedIn.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: 'u-1', fullName: 'Trọng Tài'),
        ),
        userRankingsProvider.overrideWith((ref) async => const []),
        myFootballTeamsProvider.overrideWith((ref) async => const []),
        categoriesProvider.overrideWith((ref) async => const []),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        myTournamentWorkspaceProvider.overrideWith(_Workspace.new),
      ],
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
  await tester.tap(find.text('Hoạt động'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-REF-MODE-APP-21 a referee tournament on the dashboard opens its manage page',
    (tester) async {
      await _pump(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DashboardScreen)),
      )!;

      // Group headers render upper-cased.
      expect(
        find.text(l10n.dashboard_refereeTournaments.toUpperCase()),
        findsOneWidget,
      );
      final row = find.byKey(const ValueKey('referee-tournament-t-live'));
      expect(row, findsOneWidget);
      expect(
        find.byKey(const ValueKey('referee-tournament-t-draft')),
        findsNothing,
      );

      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.text('MANAGE:t-live'), findsOneWidget);
    },
  );
}
