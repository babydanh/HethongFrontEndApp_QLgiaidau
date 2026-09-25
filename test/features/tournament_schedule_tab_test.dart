import 'package:app_quanly_giaidau/core/config/app_theme.dart';
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
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, 'schedule-fixture');

Future<void> _pumpTournamentDetail(
  WidgetTester tester, {
  required Locale locale,
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
          (ref, tournamentId) => Stream.value(const []),
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

    expect(find.text('Chưa có trận đấu nào phù hợp'), findsOneWidget);
    expect(find.text('Tìm trận đấu, tên đội hoặc VĐV...'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Tổng quan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có trận đấu nào phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule tab label is localized in English', (tester) async {
    await _pumpTournamentDetail(tester, locale: const Locale('en'));

    expect(find.widgetWithText(Tab, 'Schedule'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
