import 'dart:async';

import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/features/dashboard/screens/dashboard_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'loading_harness.dart';

class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer);
}

/// The workspace request never answers, so every workspace section is loading.
class _PendingWorkspaceNotifier extends MyTournamentWorkspaceNotifier {
  @override
  Future<TournamentWorkspace> build() =>
      Completer<TournamentWorkspace>().future;
}

void main() {
  Future<void> openTab(WidgetTester tester, String label) async {
    await pumpLoading(
      tester,
      const DashboardScreen(),
      overrides: [
        authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async =>
              const UserProfile(id: 'fixture-player', fullName: 'Nguyen An'),
        ),
        userRankingsProvider.overrideWith((ref) async => const []),
        myFootballTeamsProvider.overrideWith((ref) async => const []),
        categoriesProvider.overrideWith((ref) async => const []),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        myTournamentWorkspaceProvider.overrideWith(
          _PendingWorkspaceNotifier.new,
        ),
      ],
    );
    await tester.tap(find.text(label));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final l10n = lookupAppLocalizations(const Locale('en'));
  for (final label in [l10n.dashboard_tab_activity, l10n.dashboard_tab_manage]) {
    testWidgets('dashboard "$label" tab shows skeleton while workspace loads', (
      tester,
    ) async {
      await openTab(tester, label);

      expect(find.byType(SkeletonScope), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(TabBarView),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
