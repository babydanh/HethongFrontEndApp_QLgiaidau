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

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _fixtureTournament() => Tournament.fromJson({
  'name': 'Schedule tab smoke fixture',
  'sport': 'pickleball',
  'format': 'DOUBLES',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'visibility': 'PUBLIC',
  'creatorId': 'fixture-owner',
  'maxTeams': 8,
  'venue': {'name': 'Sporto Arena', 'locationAddress': 'District 1'},
  'tournamentConfig': {
    'scheduleDate': '2026-08-12',
    'operatingStart': '08:00',
    'operatingEnd': '18:00',
    'stepMinutes': 15,
  },
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, 'schedule-fixture');

MatchModel _scheduleMatch(
  int matchNumber, {
  String? courtId,
  String? courtName,
  String court = '',
  String? team1Name,
  String? team2Name,
  String status = 'scheduled',
  DateTime? scheduledTime,
}) => MatchModel(
  id: 'schedule-match-$matchNumber',
  round: 1,
  matchNumber: matchNumber,
  team1Name: team1Name ?? 'Player $matchNumber',
  team2Name: team2Name ?? 'Opponent $matchNumber',
  status: status,
  bracketPosition: BracketPosition(round: 1, position: matchNumber),
  court: court,
  courtId: courtId,
  courtName: courtName,
  scheduledTime: scheduledTime,
  updatedAt: DateTime.utc(2026, 1, 1),
);

Future<void> _pumpTournamentDetail(
  WidgetTester tester, {
  required Locale locale,
  List<MatchModel> matches = const [],
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
        followedTournamentsProvider.overrideWith((ref) async => const []),
        introTeamsProvider.overrideWith((ref, tournamentId) async => const []),
        matchesProvider.overrideWith(
          (ref, tournamentId) => Stream.value(matches),
        ),
        bracketMatchesProvider.overrideWith(
          (ref, tournamentId) => Stream.value(const []),
        ),
        authProvider.overrideWith(_UnauthenticatedNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: '', fullName: 'Guest'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const TournamentIntroScreen(tournamentId: 'schedule-fixture'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('schedule tab opens matches and the overview action targets it', (
    tester,
  ) async {
    await _pumpTournamentDetail(tester, locale: const Locale('vi'));

    final scheduleTab = find.widgetWithText(Tab, 'Lịch thi đấu');
    expect(scheduleTab, findsOneWidget);
    await tester.ensureVisible(scheduleTab);
    await tester.tap(scheduleTab);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có trận đấu'), findsOneWidget);
    expect(find.text('Tìm theo tên VĐV / CLB...'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Tổng quan'));
    await tester.pumpAndSettle();
    final overviewScheduleAction = find.byIcon(Icons.calendar_month_rounded);
    await tester.ensureVisible(overviewScheduleAction);
    await tester.tap(overviewScheduleAction);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có trận đấu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule tab label is localized in English', (tester) async {
    await _pumpTournamentDetail(tester, locale: const Locale('en'));

    expect(find.widgetWithText(Tab, 'Schedule'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule date and hours are localized in Vietnamese', (
    tester,
  ) async {
    await _pumpTournamentDetail(
      tester,
      locale: const Locale('vi'),
      matches: [
        _scheduleMatch(
          1,
          courtId: 'court-1',
          courtName: 'Sân 1',
          scheduledTime: DateTime(2026, 8, 12, 8),
        ),
      ],
    );

    final scheduleTab = find.widgetWithText(Tab, 'Lịch thi đấu');
    await tester.ensureVisible(scheduleTab);
    await tester.tap(scheduleTab);
    await tester.pumpAndSettle();

    expect(find.text('Giờ hoạt động: 08:00–18:00'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule filters and keeps navigation fixed while scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final matches = <MatchModel>[
      for (var court = 1; court <= 4; court++)
        for (var slot = 0; slot < 4; slot++)
          _scheduleMatch(
            (court - 1) * 4 + slot + 1,
            courtId: 'court-$court',
            courtName: 'Court $court',
            team1Name: court == 1 && slot == 0 ? 'SearchOnly Player' : null,
            status: court == 2 && slot == 0
                ? 'live'
                : court == 3 && slot == 0
                ? 'completed'
                : 'scheduled',
            scheduledTime: DateTime(2026, 8, 12, 8 + slot),
          ),
      _scheduleMatch(
        17,
        courtId: 'court-unknown',
        court: 'Sporto Arena',
        scheduledTime: DateTime(2026, 8, 12, 13),
      ),
      _scheduleMatch(
        18,
        court: 'Sporto Arena',
        scheduledTime: DateTime(2026, 8, 12, 14),
      ),
      _scheduleMatch(19),
    ];

    await _pumpTournamentDetail(
      tester,
      locale: const Locale('en'),
      matches: matches,
    );
    final scheduleTab = find.widgetWithText(Tab, 'Schedule');
    await tester.ensureVisible(scheduleTab);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(scheduleTab);
    for (
      var attempt = 0;
      attempt < 10 && find.byType(TextField).evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Court 1'), findsOneWidget);
    expect(find.textContaining('Court hours'), findsOneWidget);
    final liveFilter = find.text('Live (1)');
    await tester.ensureVisible(liveFilter);
    await tester.tap(liveFilter);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Player 5'), findsOneWidget);

    final allFilter = find.text('All (19)');
    await tester.ensureVisible(allFilter);
    await tester.tap(allFilter);
    await tester.pump(const Duration(milliseconds: 200));
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'SearchOnly Player');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Player 5'), findsNothing);
    expect(find.text('Opponent 1'), findsOneWidget);
    await tester.enterText(searchField, '');
    await tester.pump(const Duration(milliseconds: 200));

    final backButton = find.byIcon(Icons.arrow_back_ios_rounded).first;
    final backTopBeforeScroll = tester.getRect(backButton).top;
    for (final heading in [
      'Court 2',
      'Court 3',
      'Court 4',
      'Court not assigned',
      'Court name unavailable',
      'Not scheduled',
    ]) {
      for (
        var attempt = 0;
        attempt < 8 && find.text(heading).evaluate().isEmpty;
        attempt++
      ) {
        await tester.dragFrom(const Offset(200, 450), const Offset(0, -800));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text(heading), findsOneWidget);
    }

    expect(tester.getRect(backButton).top, backTopBeforeScroll);

    expect(tester.takeException(), isNull);
  });
}
