import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_dispatcher.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Tournament _tournament({required bool superLite}) => Tournament.fromJson({
  'name': 'Reload regression tournament',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  if (!superLite) 'isLite': true,
  'communityId': superLite ? 'club-1' : null,
  if (superLite)
    'tournamentConfig': {'mode': 'LITE', 'hideAdvancedSettings': true},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

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

class _IdleLiteManagementNotifier extends LiteManagementNotifier {
  @override
  Future<void> init(String tournamentId) async {}
}

class _TournamentWatchRepository implements ITournamentRepository {
  _TournamentWatchRepository(this.updates);

  final Stream<Tournament?> updates;

  @override
  Stream<Tournament?> watch(String id) => updates;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('retains workspaces across transient stream errors', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;

    for (final superLite in [false, true]) {
      final updates = StreamController<Tournament?>.broadcast();
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'admin-1',
              role: 'ADMIN',
              roles: ['ADMIN'],
            ),
          ),
          authProvider.overrideWith(_AuthenticatedAdmin.new),
          tournamentRepositoryProvider.overrideWith(
            (ref) => _TournamentWatchRepository(updates.stream),
          ),
          regionRepositoryProvider.overrideWith(
            (ref) => _EmptyRegionRepository(),
          ),
          liteManagementProvider.overrideWith(_IdleLiteManagementNotifier.new),
        ],
      );
      final expectedType = superLite
          ? LiteManagementScreen
          : TournamentManagementHubScreen;

      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('vi'),
              home: const TournamentManagementDispatcher(
                tournamentId: 'tournament-1',
                actionRouteBase: '/admin/tournament/tournament-1',
                opsWorkspaceRoute: '/organizer/tournaments/tournament-1/ops',
                liteWorkspaceRoute: '/lite-manage/tournament-1?workspace=1',
              ),
            ),
          ),
        );
        await tester.pump();
        updates.add(_tournament(superLite: superLite));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(seconds: 9));

        expect(
          container.read(tournamentProvider('tournament-1')).hasError,
          isFalse,
        );
        expect(find.byType(expectedType), findsOneWidget);
        final workspaceElement = tester.element(find.byType(expectedType));
        final l10n = AppLocalizations.of(
          tester.element(find.byType(TournamentManagementDispatcher)),
        )!;

        updates.addError(TimeoutException('polling is delayed'));
        await tester.pump();
        expect(find.byType(expectedType), findsOneWidget);
        expect(
          identical(
            tester.element(find.byType(expectedType)),
            workspaceElement,
          ),
          isTrue,
        );

        updates.addError(
          const TournamentAccessDeniedException(message: 'access revoked'),
        );
        await tester.pump();
        await tester.pump();
        expect(
          container.read(tournamentProvider('tournament-1')).error,
          isA<TournamentAccessDeniedException>(),
        );
        expect(find.byType(expectedType), findsNothing);
        expect(find.text('access revoked'), findsOneWidget);
        expect(find.text(l10n.dashboard_retry), findsNothing);
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();
        expect(find.byType(expectedType), findsNothing);
        expect(find.text('access revoked'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await updates.close();
      }
    }
  });
}
