import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_brand_fallback.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_state_views.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'content-load';
const _key = (id: _tournamentId, invite: null);

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _tournament({String? bannerUrl}) => Tournament(
  id: _tournamentId,
  name: 'Content load',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: 'single_elimination',
  status: 'registration',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'owner',
  maxTeams: 16,
  bannerUrl: bannerUrl,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  divisions: const [
    TournamentDivision(
      id: 'd1',
      name: 'Đôi Nam',
      matchType: 'DOUBLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
    ),
  ],
);

/// [tournament] receives the 1-based number of the request being made.
List<Override> _overrides(
  Future<Tournament?> Function(int call) tournament,
  void Function() onFetch,
) {
  var calls = 0;
  return [
    tournamentIntroWithInviteProvider.overrideWith((ref, params) {
      onFetch();
      return tournament(++calls);
    }),
    tournamentDivisionsProvider.overrideWith((ref, id) async => const []),
    introTeamsProvider.overrideWith((ref, id) async => const <Team>[]),
    followedTournamentsProvider.overrideWith((ref) async => const []),
    matchesProvider.overrideWith(
      (ref, id) => Stream.value(const <MatchModel>[]),
    ),
    authProvider.overrideWith(_GuestAuthNotifier.new),
    userProfileProvider.overrideWith(
      (ref) async => UserProfile(id: '', fullName: 'Guest'),
    ),
  ];
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const TournamentIntroScreen(tournamentId: _tournamentId),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'TC-CONTENT-LOAD-01 a slow refresh keeps the shown content, no skeleton',
    (tester) async {
      var fetches = 0;
      final slow = Completer<Tournament?>();
      final container = ProviderContainer(
        overrides: _overrides(
          (call) => call == 1 ? Future.value(_tournament()) : slow.future,
          () => fetches++,
        ),
      );
      addTearDown(container.dispose);

      await _pump(tester, container);
      await tester.pumpAndSettle();
      expect(find.byType(OverviewTab), findsOneWidget);

      // Pull-to-refresh invalidates the provider; the next request is slow.
      container.invalidate(tournamentIntroWithInviteProvider(_key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fetches, 2);
      expect(find.byType(ShimmerBody), findsNothing);
      expect(find.byType(OverviewTab), findsOneWidget);
    },
  );

  testWidgets(
    'TC-CONTENT-LOAD-02 an already loaded tournament shows on the first frame '
    'and is refreshed in the background',
    (tester) async {
      var fetches = 0;
      final slow = Completer<Tournament?>();
      final container = ProviderContainer(
        overrides: _overrides(
          (call) => call == 1 ? Future.value(_tournament()) : slow.future,
          () => fetches++,
        ),
      );
      addTearDown(container.dispose);
      // First visit: data is fetched and kept by the provider.
      await container.read(tournamentIntroWithInviteProvider(_key).future);
      expect(fetches, 1);

      await _pump(tester, container);
      await tester.pump();

      expect(find.byType(OverviewTab), findsOneWidget);
      expect(find.byType(ShimmerBody), findsNothing);
      // Silent refresh starts while the old data stays on screen.
      await tester.pump(const Duration(milliseconds: 100));
      expect(fetches, 2);
      expect(find.byType(OverviewTab), findsOneWidget);
    },
  );

  testWidgets(
    'TC-CONTENT-LOAD-03 a failed background refresh keeps the shown content',
    (tester) async {
      final container = ProviderContainer(
        overrides: _overrides(
          (call) => call == 1
              ? Future.value(_tournament())
              : Future<Tournament?>.error(TimeoutException('slow network')),
          () {},
        ),
      );
      addTearDown(container.dispose);

      await _pump(tester, container);
      await tester.pumpAndSettle();
      container.invalidate(tournamentIntroWithInviteProvider(_key));
      await tester.pumpAndSettle();

      expect(find.byType(OverviewTab), findsOneWidget);
    },
  );

  testWidgets(
    'TC-CONTENT-LOAD-04 access revoked on refresh still hides the content',
    (tester) async {
      final container = ProviderContainer(
        overrides: _overrides(
          (call) => call == 1
              ? Future.value(_tournament())
              : Future<Tournament?>.error(
                  const TournamentAccessDeniedException(message: 'denied'),
                ),
          () {},
        ),
      );
      addTearDown(container.dispose);

      await _pump(tester, container);
      await tester.pumpAndSettle();
      container.invalidate(tournamentIntroWithInviteProvider(_key));
      await tester.pumpAndSettle();

      expect(find.byType(OverviewTab), findsNothing);
      expect(find.text('denied'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-CONTENT-LOAD-05 first open without data shows a skeleton, then content',
    (tester) async {
      final pending = Completer<Tournament?>();
      final container = ProviderContainer(
        overrides: _overrides((call) => pending.future, () {}),
      );
      addTearDown(container.dispose);

      await _pump(tester, container);
      await tester.pump();
      expect(find.byType(ShimmerBody), findsOneWidget);
      expect(find.byType(OverviewTab), findsNothing);

      pending.complete(_tournament());
      await tester.pumpAndSettle();
      expect(find.byType(ShimmerBody), findsNothing);
      expect(find.byType(OverviewTab), findsOneWidget);
    },
  );

  testWidgets(
    'TC-CONTENT-LOAD-06 banner shows a placeholder until the image arrives',
    (tester) async {
      final container = ProviderContainer(
        overrides: _overrides(
          (call) => Future.value(
            _tournament(bannerUrl: 'https://img.invalid/banner.png'),
          ),
          () {},
        ),
      );
      addTearDown(container.dispose);

      await _pump(tester, container);
      // The frame that builds the content: the image has not decoded yet.
      await tester.pump();

      expect(find.byType(SportoBrandFallback), findsWidgets);
    },
  );
}
