import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'tab-density-fixture';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _fixtureTournament() => Tournament.fromJson({
  'name': 'Compact tabs fixture',
  'sport': 'badminton',
  'format': 'DOUBLES',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'visibility': 'PUBLIC',
  'creatorId': 'fixture-owner',
  'maxTeams': 8,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);

List<Team> _fixtureTeams() => [
  Team(
    id: 'team-alpha-beta',
    name: 'Player Alpha / Player Beta',
    members: const ['Player Alpha', 'Player Beta'],
    group: 'Division Alpha',
    divisionId: 'division-alpha',
    createdAt: DateTime(2026, 1, 1),
  ),
];

List<MatchModel> _fixtureMatches() => [
  MatchModel(
    id: 'live-match',
    tournamentId: _tournamentId,
    round: 1,
    matchNumber: 1,
    team1Id: 'team-gamma',
    team2Id: 'team-delta',
    team1Name: 'Player Gamma',
    team2Name: 'Player Delta',
    status: 'in_progress',
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  MatchModel(
    id: 'completed-match',
    tournamentId: _tournamentId,
    round: 1,
    matchNumber: 2,
    team1Id: 'team-epsilon',
    team2Id: 'team-zeta',
    team1Name: 'Player Epsilon',
    team2Name: 'Player Zeta',
    score1: 2,
    score2: 1,
    winnerId: 'team-epsilon',
    loserId: 'team-zeta',
    status: 'completed',
    bracketPosition: const BracketPosition(round: 1, position: 2),
    completedAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
];

void main() {
  testWidgets('compact tournament tabs render their existing fixture data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
            (ref, tournamentId) => Stream.value(_fixtureMatches()),
          ),
          bracketMatchesProvider.overrideWith(
            (ref, tournamentId) => Stream.value(const <MatchModel>[]),
          ),
          tournamentResultProvider.overrideWith(
            (ref, params) => Stream.value({
              'awards': [
                {
                  'rank': 1,
                  'participant': {'teamName': 'Champion Alpha'},
                },
                {
                  'rank': 2,
                  'participant': {'teamName': 'Runner-up Beta'},
                },
                {
                  'rank': 3,
                  'participant': {'teamName': 'Bronze Gamma'},
                },
              ],
            }),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    Future<void> openTab(String label) async {
      final tab = find.widgetWithText(Tab, label);
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'tab: $label');
    }

    await openTab('Đang diễn ra');
    expect(find.text('Player Gamma'), findsOneWidget);
    expect(find.text('Player Delta'), findsOneWidget);

    await openTab('Kết quả');
    expect(find.text('Champion Alpha'), findsOneWidget);

    await openTab('Danh sách đội');
    expect(find.text('Player Alpha / Player Beta'), findsOneWidget);

    await openTab('Lịch thi đấu');
    expect(find.text('Player Epsilon'), findsOneWidget);
    expect(find.text('Player Zeta'), findsOneWidget);
  });
}
