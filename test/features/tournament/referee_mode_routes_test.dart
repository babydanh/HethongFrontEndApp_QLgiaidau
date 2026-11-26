import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/services/manage_role_access.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_manage_access_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = 'tournament-1';
const _noPermission = 'Bạn không có quyền vận hành giải đấu này.';

final _tournament = Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _id);

class _SignedInUser extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer);
}

Future<void> _open(
  WidgetTester tester,
  String location, {
  Tournament? tournament,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(_SignedInUser.new),
      tournamentManageAccessProvider(
        _id,
      ).overrideWith((ref) async => ManageRole.referee),
      tournamentProvider(
        _id,
      ).overrideWith((ref) => Stream.value(tournament ?? _tournament)),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  addTearDown(router.dispose);
  router.go(location);
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
}

/// Unmounts the app while its container is alive, so Riverpod's dispose
/// timers run inside the test.
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  testWidgets(
    'TC-REF-MODE-APP-11 organizer-only deep links turn a referee away',
    (tester) async {
      for (final location in [
        '/organizer/tournaments/$_id/ops',
        '/organizer/tournaments/$_id/ops/bracket',
        '/organizer/tournaments/$_id/manage/draw',
        '/organizer/tournaments/$_id/manage/bracket',
        '/organizer/tournaments/$_id/manage/teams',
        '/organizer/tournaments/$_id/manage/teams/add',
        '/organizer/tournaments/$_id/manage/teams/edit',
        '/organizer/tournaments/$_id/manage/swiss-pairing/d1',
      ]) {
        await _open(tester, location);
        expect(find.text(_noPermission), findsOneWidget, reason: location);
        expect(find.byType(OrganizerOpsScreen), findsNothing, reason: location);
        await _close(tester);
      }
    },
  );

  testWidgets(
    'TC-REF-MODE-APP-12 every hub entry route opens the hub as referee',
    (tester) async {
      for (final location in [
        '/organizer/tournaments/$_id/manage',
        '/lite-manage/$_id',
        '/lite/tournaments/$_id/manage',
      ]) {
        await _open(tester, location);
        final hub = tester.widget<TournamentManagementHubScreen>(
          find.byType(TournamentManagementHubScreen),
        );
        expect(hub.role, ManageRole.referee, reason: location);
        await _close(tester);
      }
    },
  );

  testWidgets(
    'TC-REF-MODE-APP-12b a club Lite tournament stays organizer-only',
    (tester) async {
      final clubLite = _tournament.copyWith(
        isSuperLite: true,
        communityId: 'club-1',
      );
      await _open(
        tester,
        '/organizer/tournaments/$_id/manage',
        tournament: clubLite,
      );
      expect(find.text(_noPermission), findsOneWidget);
      expect(find.byType(LiteManagementScreen), findsNothing);
      await _close(tester);
    },
  );
}
