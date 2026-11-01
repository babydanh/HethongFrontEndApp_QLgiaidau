import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
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
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'open-speed';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _inProgressTournament() => Tournament(
  id: _tournamentId,
  name: 'Open speed',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: 'single_elimination',
  status: 'in_progress',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'owner',
  maxTeams: 16,
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

MatchModel _liveMatch() => MatchModel(
  id: 'live-1',
  tournamentId: _tournamentId,
  round: 1,
  matchNumber: 1,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  team1Id: 't1',
  team2Id: 't2',
  status: 'ONGOING',
  divisionId: 'd1',
  team1Players: [ParticipantPlayer(slot: 1, fullName: 'Nguyen Van A')],
  team2Players: [ParticipantPlayer(slot: 1, fullName: 'Tran Thi B')],
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<Tournament?> Function()? tournament,
  Future<List<Team>> Function()? teams,
  Stream<List<MatchModel>>? matches,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentIntroWithInviteProvider.overrideWith(
          (ref, params) =>
              (tournament ?? () async => _inProgressTournament())(),
        ),
        tournamentDivisionsProvider.overrideWith((ref, id) async => const []),
        introTeamsProvider.overrideWith(
          (ref, id) => (teams ?? () async => const <Team>[])(),
        ),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        matchesProvider.overrideWith(
          (ref, id) => matches ?? Stream.value(const <MatchModel>[]),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(id: '', fullName: 'Guest'),
        ),
      ],
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
  testWidgets('TC-OPEN-SPEED-09 loading shows a skeleton, not a spinner', (
    tester,
  ) async {
    final never = Completer<Tournament?>();
    await _pump(tester, tournament: () => never.future);
    await tester.pump();

    expect(find.byType(ShimmerBody), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('TC-OPEN-SPEED-10 a failed team list keeps the tabs visible', (
    tester,
  ) async {
    await _pump(tester, teams: () async => throw StateError('teams down'));
    await tester.pumpAndSettle();

    expect(find.byType(TabBarView), findsOneWidget);
    expect(find.byType(OverviewTab), findsOneWidget);
    expect(find.textContaining('teams down'), findsNothing);
  });

  testWidgets('TC-OPEN-SPEED-11 a slow team list does not block the tabs', (
    tester,
  ) async {
    final never = Completer<List<Team>>();
    await _pump(tester, teams: () => never.future);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TabBarView), findsOneWidget);
    expect(find.byType(OverviewTab), findsOneWidget);
  });

  testWidgets(
    'TC-OPEN-SPEED-12 live count appears on the tab once matches load',
    (tester) async {
      final matches = StreamController<List<MatchModel>>();
      addTearDown(matches.close);
      await _pump(tester, matches: matches.stream);
      await tester.pumpAndSettle();

      // Tab is already there from the tournament status, without a live badge.
      expect(find.widgetWithText(Tab, 'Đang diễn ra'), findsOneWidget);

      matches.add([_liveMatch()]);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(Tab), matching: find.text('1')),
        findsOneWidget,
      );
    },
  );
}
