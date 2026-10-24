import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
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

const _tournamentId = 'schedule-inline-fixture';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _fixtureTournament() => Tournament(
  id: _tournamentId,
  name: 'Schedule inline fixture',
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
  scheduleSettings: const {
    'scheduleDate': '2026-08-12',
    'operatingStart': '08:00',
    'operatingEnd': '18:00',
  },
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

MatchModel _match({
  required String id,
  required String divisionId,
  required String team1,
  required String team2,
  required int minutes,
  required DateTime start,
  Map<String, dynamic>? scoreDetails,
  String status = 'scheduled',
  String winnerId = '',
  String court = 'Court 1',
}) => MatchModel(
  id: id,
  round: 1,
  matchNumber: 1,
  team1Name: team1,
  team2Name: team2,
  divisionId: divisionId,
  status: status,
  bracketPosition: BracketPosition(round: 1, position: 1),
  court: court,
  courtId: court.toLowerCase().replaceAll(' ', '-'),
  courtName: court,
  scheduledTime: start,
  durationMinutes: minutes,
  scoreDetails: scoreDetails,
  winnerId: winnerId,
  updatedAt: DateTime.utc(2026, 1, 1),
);

void _setPhoneViewport(WidgetTester tester) {
  // Viewport điện thoại 390×844; không đổi chiều cao để che lỗi layout.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpIntro(
  WidgetTester tester, {
  required List<MatchModel> matches,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentIntroWithInviteProvider.overrideWith(
          (ref, params) async => _fixtureTournament(),
        ),
        tournamentDivisionsProvider.overrideWith(
          (ref, tournamentId) async => const <Map<String, dynamic>>[],
        ),
        introTeamsProvider.overrideWith((ref, tournamentId) async => const []),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        matchesProvider.overrideWith(
          (ref, tournamentId) => Stream.value(matches),
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
}

Future<void> _openScheduleTab(WidgetTester tester) async {
  final scheduleTab = find.widgetWithText(Tab, 'Lịch thi đấu');
  await tester.ensureVisible(scheduleTab);
  await tester.tap(scheduleTab);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'one grid shows matches of every division at once without a division selector',
    (tester) async {
      _setPhoneViewport(tester);
      await _pumpIntro(
        tester,
        matches: [
          _match(
            id: 'alpha-30',
            divisionId: 'division-alpha',
            team1: 'Alpha Player',
            team2: 'Alpha Rival',
            minutes: 30,
            start: DateTime(2026, 8, 12, 9),
          ),
          _match(
            id: 'beta-30',
            divisionId: 'division-beta',
            team1: 'Beta Player',
            team2: 'Beta Rival',
            minutes: 30,
            start: DateTime(2026, 8, 12, 10),
          ),
        ],
      );
      await _openScheduleTab(tester);

      expect(
        find.byKey(const ValueKey('schedule-match-alpha-30')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('schedule-match-beta-30')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('schedule-match-alpha-30')),
          matching: find.text('Division Alpha'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('schedule-match-beta-30')),
          matching: find.text('Division Beta'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'division labels reserve visual space for following same-court matches',
    (tester) async {
      _setPhoneViewport(tester);
      await _pumpIntro(
        tester,
        matches: [
          _match(
            id: 'compact-a',
            divisionId: 'division-alpha',
            team1: 'Compact A',
            team2: 'Compact B',
            minutes: 5,
            start: DateTime(2026, 8, 12, 9),
          ),
          _match(
            id: 'compact-next',
            divisionId: 'division-alpha',
            team1: 'Compact C',
            team2: 'Compact D',
            minutes: 5,
            start: DateTime(2026, 8, 12, 9, 5),
          ),
          _match(
            id: 'full-a',
            divisionId: 'division-alpha',
            team1: 'Full A',
            team2: 'Full B',
            minutes: 8,
            start: DateTime(2026, 8, 12, 10),
          ),
          _match(
            id: 'full-next',
            divisionId: 'division-alpha',
            team1: 'Full C',
            team2: 'Full D',
            minutes: 8,
            start: DateTime(2026, 8, 12, 10, 8),
          ),
        ],
      );
      await _openScheduleTab(tester);

      for (final ids in [
        ('compact-a', 'compact-next'),
        ('full-a', 'full-next'),
      ]) {
        final first = tester.getRect(
          find.byKey(ValueKey('schedule-match-${ids.$1}')),
        );
        final next = tester.getRect(
          find.byKey(ValueKey('schedule-match-${ids.$2}')),
        );
        expect(first.overlaps(next), isFalse);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a 5-minute match is one compact row while a 60-minute match stacks its teams',
    (tester) async {
      _setPhoneViewport(tester);
      await _pumpIntro(
        tester,
        matches: [
          _match(
            id: 'short',
            divisionId: 'division-alpha',
            team1: 'Alpha Player',
            team2: 'Alpha Rival',
            minutes: 5,
            start: DateTime(2026, 8, 12, 9),
          ),
          _match(
            id: 'long',
            divisionId: 'division-alpha',
            team1: 'Long One',
            team2: 'Long Two',
            minutes: 60,
            start: DateTime(2026, 8, 12, 11),
          ),
        ],
      );
      await _openScheduleTab(tester);

      expect(
        tester.getTopLeft(find.text('Alpha Player')).dy,
        tester.getTopLeft(find.text('Alpha Rival')).dy,
      );
      expect(
        tester.getTopLeft(find.text('Long Two')).dy,
        greaterThan(tester.getTopLeft(find.text('Long One')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a 15-minute match sits at its own time row without stacking into a second lane',
    (tester) async {
      _setPhoneViewport(tester);
      await _pumpIntro(
        tester,
        matches: [
          _match(
            id: 'quarter-a',
            divisionId: 'division-alpha',
            team1: 'Quarter A One',
            team2: 'Quarter A Two',
            minutes: 15,
            start: DateTime(2026, 8, 12, 9),
          ),
          _match(
            id: 'quarter-b',
            divisionId: 'division-alpha',
            team1: 'Quarter B One',
            team2: 'Quarter B Two',
            minutes: 15,
            start: DateTime(2026, 8, 12, 9, 15),
          ),
        ],
      );
      await _openScheduleTab(tester);

      final first = find.byKey(const ValueKey('schedule-match-quarter-a'));
      final second = find.byKey(const ValueKey('schedule-match-quarter-b'));
      expect(
        tester.getTopLeft(second).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(first).dy),
      );
      expect(tester.getTopLeft(second).dx, tester.getTopLeft(first).dx);
      expect(tester.getSize(first).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a match under 8 minutes stays one row; 8 minutes stacks its teams',
    (tester) async {
      _setPhoneViewport(tester);
      await _pumpIntro(
        tester,
        matches: [
          _match(
            id: 'seven',
            divisionId: 'division-alpha',
            team1: 'Seven One',
            team2: 'Seven Two',
            minutes: 7,
            start: DateTime(2026, 8, 12, 9),
          ),
          _match(
            id: 'eight',
            divisionId: 'division-alpha',
            team1: 'Eight One',
            team2: 'Eight Two',
            minutes: 8,
            start: DateTime(2026, 8, 12, 10),
          ),
        ],
      );
      await _openScheduleTab(tester);

      final sevenCard = find.byKey(const ValueKey('schedule-match-seven'));
      final eightCard = find.byKey(const ValueKey('schedule-match-eight'));
      // Thẻ 7 phút là thẻ một dòng nên có "vs" giữa hai đội; thẻ 8 phút là thẻ
      // đầy đủ (header/footer) và không có "vs".
      expect(
        find.descendant(of: sevenCard, matching: find.text('vs')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: eightCard, matching: find.text('Eight One')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: eightCard, matching: find.text('vs')),
        findsNothing,
      );
      expect(
        tester.getTopLeft(find.text('Seven One')).dy,
        tester.getTopLeft(find.text('Seven Two')).dy,
      );
      expect(
        tester.getTopLeft(find.text('Eight Two')).dy,
        greaterThan(tester.getTopLeft(find.text('Eight One')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'score columns follow the sets recorded in scoreDetails, not the best-of',
    (tester) async {
      _setPhoneViewport(tester);
      await _pumpIntro(
        tester,
        matches: [
          _match(
            id: 'scored',
            divisionId: 'division-alpha',
            team1: 'Score One',
            team2: 'Score Two',
            minutes: 30,
            start: DateTime(2026, 8, 12, 9),
            scoreDetails: {
              'sets': [
                {'team1Score': 12, 'team2Score': 4},
                {'team1Score': 8, 'team2Score': 15},
              ],
            },
          ),
        ],
      );
      await _openScheduleTab(tester);

      final card = find.byKey(const ValueKey('schedule-match-scored'));
      for (final score in ['12', '4', '8', '15']) {
        expect(
          find.descendant(of: card, matching: find.text(score)),
          findsOneWidget,
        );
      }
      expect(find.descendant(of: card, matching: find.text('-')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a match with no recorded set has no score columns', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await _pumpIntro(
      tester,
      matches: [
        _match(
          id: 'unplayed',
          divisionId: 'division-alpha',
          team1: 'Unplayed One',
          team2: 'Unplayed Two',
          minutes: 30,
          start: DateTime(2026, 8, 12, 9),
        ),
      ],
    );
    await _openScheduleTab(tester);

    final card = find.byKey(const ValueKey('schedule-match-unplayed'));
    for (final name in ['Unplayed One', 'Unplayed Two']) {
      expect(
        find.descendant(of: card, matching: find.text(name)),
        findsOneWidget,
      );
    }
    expect(find.descendant(of: card, matching: find.text('-')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed status does not tint the losing team name', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await _pumpIntro(
      tester,
      matches: [
        _match(
          id: 'scheduled-color',
          divisionId: 'division-alpha',
          team1: 'Scheduled One',
          team2: 'Scheduled Two',
          minutes: 30,
          start: DateTime(2026, 8, 12, 9),
        ),
        _match(
          id: 'completed-color',
          divisionId: 'division-alpha',
          team1: 'Completed Winner',
          team2: 'Completed Loser',
          minutes: 30,
          start: DateTime(2026, 8, 12, 10),
          status: 'completed',
          winnerId: 'completed-color-team1',
        ),
      ],
    );
    await _openScheduleTab(tester);

    final scheduledColor = tester
        .widget<Text>(find.text('Scheduled Two'))
        .style!
        .color;
    final completedLoserColor = tester
        .widget<Text>(find.text('Completed Loser'))
        .style!
        .color;
    expect(completedLoserColor, scheduledColor);
  });

  testWidgets(
    'two courts fit the phone width: the last court and its cards stay on screen',
    (tester) async {
      _setPhoneViewport(tester);
      await _pumpIntro(
        tester,
        matches: [
          _match(
            id: 'first-court',
            divisionId: 'division-alpha',
            team1: 'First One',
            team2: 'First Two',
            minutes: 30,
            start: DateTime(2026, 8, 12, 9),
          ),
          _match(
            id: 'second-court',
            divisionId: 'division-alpha',
            team1: 'Second One',
            team2: 'Second Two',
            minutes: 30,
            start: DateTime(2026, 8, 12, 9),
            court: 'Court 2',
          ),
        ],
      );
      await _openScheduleTab(tester);

      final frame = tester.getRect(
        find.byKey(const ValueKey('schedule-frame')),
      );
      final courtTwoHeader = find
          .ancestor(
            of: find.byTooltip('Court 2'),
            matching: find.byType(Container),
          )
          .first;
      final headerRect = tester.getRect(courtTwoHeader);
      final secondCard = tester.getRect(
        find.byKey(const ValueKey('schedule-match-second-court')),
      );
      expect(secondCard.left, greaterThanOrEqualTo(headerRect.left));
      expect(secondCard.right, lessThanOrEqualTo(headerRect.right));
      expect(secondCard.right, lessThanOrEqualTo(frame.right));
      expect(tester.takeException(), isNull);
    },
  );
}
