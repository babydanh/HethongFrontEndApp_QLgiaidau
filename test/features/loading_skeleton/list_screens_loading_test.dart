import 'dart:async';

import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/features/admin/screens/admin_clubs_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/change_requests_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/disputes_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/pending_clubs_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/transactions_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/verification_screen.dart';
import 'package:app_quanly_giaidau/features/football_team/screens/football_teams_screen.dart';
import 'package:app_quanly_giaidau/features/payment/screens/payments_screen.dart';
import 'package:app_quanly_giaidau/features/referee/screens/referee_invites_screen.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_detail_screen.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_screen.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'loading_harness.dart';

void _expectSkeletonNotSpinner(WidgetTester tester) {
  expect(find.byType(SkeletonScope), findsWidgets);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  final screens = <String, ({Widget screen, List<Override> overrides})>{
    'AdminClubsScreen': (
      screen: const AdminClubsScreen(),
      overrides: [pendingDioOverride],
    ),
    'AdminChangeRequestsScreen': (
      screen: const AdminChangeRequestsScreen(),
      overrides: [pendingDioOverride],
    ),
    'AdminDisputesScreen': (
      screen: const AdminDisputesScreen(),
      overrides: [pendingDioOverride],
    ),
    'AdminTransactionsScreen': (
      screen: const AdminTransactionsScreen(),
      overrides: [pendingDioOverride],
    ),
    'AdminVerificationScreen': (
      screen: const AdminVerificationScreen(),
      overrides: [pendingDioOverride],
    ),
    'PendingClubsScreen': (
      screen: const PendingClubsScreen(),
      overrides: [
        pendingCommunitiesProvider.overrideWith(
          (ref) => Completer<List<Community>>().future,
        ),
      ],
    ),
    'SeriesScreen': (
      screen: const SeriesScreen(),
      overrides: [pendingDioOverride],
    ),
    'SeriesDetailScreen': (
      screen: const SeriesDetailScreen(slug: 'demo'),
      overrides: [pendingDioOverride],
    ),
    'PaymentsScreen': (
      screen: const PaymentsScreen(),
      overrides: [
        myPaymentsProvider.overrideWith(
          (ref) => Completer<List<PaymentModel>>().future,
        ),
      ],
    ),
    'RefereeInvitesScreen': (
      screen: const RefereeInvitesScreen(),
      overrides: [
        myRefereeInvitesProvider.overrideWithValue(
          const AsyncLoading<List<TournamentRefereeInvite>>(),
        ),
      ],
    ),
    'TeamListScreen': (
      screen: const TeamListScreen(tournamentId: 'loading-fixture'),
      overrides: [
        teamsProvider.overrideWith(
          (ref, id) => StreamController<List<Team>>().stream,
        ),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
      ],
    ),
    'FootballTeamsScreen': (
      screen: const FootballTeamsScreen(),
      overrides: [pendingDioOverride],
    ),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} shows skeleton, not a spinner, while loading', (
      tester,
    ) async {
      await pumpLoading(
        tester,
        entry.value.screen,
        overrides: entry.value.overrides,
      );
      _expectSkeletonNotSpinner(tester);
    });
  }
}
