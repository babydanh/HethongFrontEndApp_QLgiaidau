import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'inline-division-fixture';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _fixtureTournament() => Tournament(
  id: _tournamentId,
  name: 'Inline division layout fixture',
  sport: 'badminton',
  format: 'DOUBLES',
  bracketType: 'single_elimination',
  status: 'in_progress',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'fixture-owner',
  maxTeams: 16,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  divisions: const [
    TournamentDivision(
      id: 'division-alpha',
      name: 'Division Alpha',
      matchType: 'DOUBLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
      participantCount: 2,
    ),
    TournamentDivision(
      id: 'division-beta',
      name: 'Division Beta',
      matchType: 'DOUBLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
      participantCount: 2,
    ),
  ],
);

List<Team> _fixtureTeams() => [
  Team(
    id: 'team-alpha',
    name: 'Alpha Team',
    group: 'Division Alpha',
    divisionId: 'division-alpha',
    createdAt: DateTime(2026, 1, 1),
  ),
  Team(
    id: 'team-beta',
    name: 'Beta Team',
    group: 'Division Beta',
    divisionId: 'division-beta',
    createdAt: DateTime(2026, 1, 1),
  ),
];

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('teams expand directly below the selected compact division row', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentIntroWithInviteProvider.overrideWith(
            (ref, params) async => _fixtureTournament(),
          ),
          tournamentDivisionsProvider.overrideWith(
            (ref, tournamentId) async => const <Map<String, dynamic>>[],
          ),
          introTeamsProvider.overrideWith(
            (ref, tournamentId) async => _fixtureTeams(),
          ),
          followedTournamentsProvider.overrideWith((ref) async => const []),
          matchesProvider.overrideWith(
            (ref, tournamentId) => Stream.value(const []),
          ),
          bracketMatchesProvider.overrideWith(
            (ref, tournamentId) => Stream.value(const []),
          ),
          authProvider.overrideWith(_GuestAuthNotifier.new),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(id: '', fullName: 'Guest'),
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
    await tester.pumpAndSettle();

    final teamsTab = find.widgetWithText(Tab, 'Danh sách đội');
    await tester.ensureVisible(teamsTab);
    await tester.tap(teamsTab);
    await tester.pumpAndSettle();

    expect(find.textContaining('NỘI DUNG THI ĐẤU'), findsNothing);
    expect(find.text('Loại trực tiếp'), findsNothing);
    expect(find.text('Alpha Team'), findsOneWidget);
    expect(find.text('Division Beta'), findsOneWidget);

    final alphaRowBottom = tester.getBottomLeft(find.text('Division Alpha')).dy;
    final alphaTeamTop = tester.getTopLeft(find.text('Alpha Team')).dy;
    final betaRowTop = tester.getTopLeft(find.text('Division Beta')).dy;
    expect(alphaTeamTop, greaterThan(alphaRowBottom));
    expect(alphaTeamTop, lessThan(betaRowTop));

    await tester.ensureVisible(find.text('Division Beta'));
    await tester.tap(find.text('Division Beta'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha Team'), findsNothing);
    expect(find.text('Beta Team'), findsOneWidget);
    final betaRowBottom = tester.getBottomLeft(find.text('Division Beta')).dy;
    expect(
      tester.getTopLeft(find.text('Beta Team')).dy,
      greaterThan(betaRowBottom),
    );

    // Tapping the open division again collapses it; only one opens at a time.
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Division Beta'));
    await tester.pumpAndSettle();
    expect(find.text('Beta Team'), findsNothing);
    expect(find.text('Alpha Team'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
