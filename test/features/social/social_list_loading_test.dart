import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/home/widgets/explore_new_tournaments.dart';
import 'package:app_quanly_giaidau/features/social/screens/social_list_view.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_session_card_skeleton.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

class _QuietLocation extends UserLocationNotifier {
  @override
  UserLocationState build() =>
      const UserLocationState(status: UserLocationStatus.denied);
}

Widget _app() => ProviderScope(
  overrides: [
    userLocationProvider.overrideWith(_QuietLocation.new),
    filteredSocialSessionsProvider.overrideWithValue(const AsyncLoading()),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: SocialListView()),
  ),
);

void main() {
  testWidgets('social list shows session skeletons while sessions load', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SocialSessionCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'TC-EXPLORE-MERGE-03 a just-started tournament is listed inside its time slot, no empty state',
    (tester) async {
      final start = DateTime.now().subtract(const Duration(hours: 1));
      final tournament = Tournament(
        id: 'tn1',
        name: 'Giai Merge Test',
        sport: 'PICKLEBALL',
        format: 'single_elimination',
        bracketType: 'single_elimination',
        adminToken: 'a',
        refereeToken: 'r',
        viewerToken: 'v',
        creatorId: 'u1',
        status: 'in_progress',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        startDate: start,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userLocationProvider.overrideWith(_QuietLocation.new),
            filteredSocialSessionsProvider.overrideWithValue(
              const AsyncData(<SocialSessionModel>[]),
            ),
            tournamentsProvider.overrideWith((ref) => Stream.value([tournament])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SocialListView()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(DateFormat('HH:mm').format(start)), findsOneWidget);
      expect(find.text('| 1 gặp gỡ'), findsOneWidget);
      expect(find.text('Giai Merge Test'), findsOneWidget);
      expect(find.textContaining('Không có buổi Social'), findsNothing);
      // The block above the list is gone: it only remains in Nearby mode.
      expect(find.byType(ExploreNewTournaments), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
