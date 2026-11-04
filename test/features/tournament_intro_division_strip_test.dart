import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_accordion.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_strip.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'results-tournament';
const _divisionA = 'division-1';
const _divisionB = 'division-2';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _completedTournament() {
  final now = DateTime.now();
  return Tournament(
    id: _tournamentId,
    name: 'Giải đã kết thúc',
    sport: 'badminton',
    format: 'SINGLES',
    bracketType: 'single_elimination',
    status: 'completed',
    visibility: 'PUBLIC',
    adminToken: '',
    refereeToken: '',
    viewerToken: '',
    creatorId: 'owner-1',
    maxTeams: 8,
    createdAt: now,
    updatedAt: now,
    divisions: const [
      TournamentDivision(
        id: _divisionA,
        name: 'Adults',
        matchType: 'SINGLES',
        maxParticipants: 8,
      ),
      TournamentDivision(
        id: _divisionB,
        name: 'Youth',
        matchType: 'SINGLES',
        maxParticipants: 8,
      ),
    ],
  );
}

Future<List<String?>> _pumpResultsTab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final requestedDivisions = <String?>[];
  final tournament = _completedTournament();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_GuestAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'viewer-1',
            fullName: 'Viewer',
            email: 'viewer@example.test',
          ),
        ),
        tournamentIntroWithInviteProvider((
          id: _tournamentId,
          invite: null,
        )).overrideWith((ref) async => tournament),
        tournamentDivisionsProvider(
          _tournamentId,
        ).overrideWith((ref) async => const <Map<String, dynamic>>[]),
        introTeamsProvider(_tournamentId).overrideWith((ref) async => const []),
        teamsProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream.value(const [])),
        matchesProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream.value(const [])),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        tournamentResultProvider.overrideWith((ref, params) {
          requestedDivisions.add(params.divisionId);
          return Stream.value(const <String, dynamic>{'awards': []});
        }),
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
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // "Kết quả" is the last tab: slide the tab bar to its end before tapping.
  await tester.drag(find.byType(TabBar), const Offset(-600, 0));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.widgetWithText(Tab, 'Kết quả'));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return requestedDivisions;
}

void main() {
  testWidgets(
    'TC-DIVSHARE-09: results tab picks a division with the shared strip, not the old accordion',
    (tester) async {
      await _pumpResultsTab(tester);

      expect(find.byType(DivisionStrip), findsOneWidget);
      expect(find.byType(DivisionAccordion), findsNothing);
      expect(
        find.byKey(const ValueKey('results-division-$_divisionA')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('results-division-$_divisionB')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TC-DIVSHARE-10: tapping a chip loads the results of that division',
    (tester) async {
      final requested = await _pumpResultsTab(tester);
      expect(requested.last, _divisionA);

      await tester.tap(
        find.byKey(const ValueKey('results-division-$_divisionB')),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(requested.last, _divisionB);
    },
  );
}
