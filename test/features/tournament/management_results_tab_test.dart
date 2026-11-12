import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tid = 'tournament-1';

Tournament _tournament() => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'divisions': [
    {'id': 'div-1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
  ],
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tid);

MatchModel _match(String id, int number, {String status = 'SCHEDULED'}) =>
    MatchModel(
      id: id,
      tournamentId: _tid,
      round: 1,
      matchNumber: number,
      bracketPosition: BracketPosition(round: 1, position: number),
      team1Id: 'a$number',
      team2Id: 'b$number',
      team1Name: 'Team A$number',
      team2Name: 'Team B$number',
      status: status,
      divisionId: 'div-1',
      updatedAt: DateTime.utc(2026, 1, 1),
    );

Widget _app(List<MatchModel> matches) => ProviderScope(
  overrides: [
    userProfileProvider.overrideWith(
      (ref) async => const UserProfile(
        id: 'manager-1',
        role: 'ORGANIZER',
        roles: ['ORGANIZER', 'ADMIN'],
      ),
    ),
    // The public feed stays empty: organisers must read the management feed.
    matchesProvider(
      _tid,
    ).overrideWith((ref) => Stream.value(const <MatchModel>[])),
    managedMatchesWithDivisionProvider((
      tournamentId: _tid,
      divisionId: null,
    )).overrideWith((ref) => Stream.value(matches)),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: TournamentManagementHubScreen(
      tournament: _tournament(),
      actionRouteBase: '/admin/tournament/$_tid',
      opsWorkspaceRoute: '/organizer/tournaments/$_tid/ops',
    ),
  ),
);

Future<AppLocalizations> _pumpHub(
  WidgetTester tester,
  List<MatchModel> matches,
) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(matches));
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(TournamentManagementHubScreen)),
  )!;
}

Future<void> _openResults(WidgetTester tester, AppLocalizations l10n) async {
  final tab = find.widgetWithText(Tab, l10n.tournamentManagementTabResults);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-RESULTS-05 the hub has eight tabs and Kết quả follows Lịch', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester, const []);

    final tabs = tester
        .widgetList<Tab>(find.byType(Tab))
        .map((tab) => tab.text)
        .toList();
    expect(tabs, hasLength(8));
    // Kết quả follows Lịch thi đấu; Cài đặt stays last.
    expect(tabs[4], l10n.tournamentManagementSchedule);
    expect(tabs[5], l10n.tournamentManagementTabResults);
    expect(tabs[5], 'Kết quả');
    expect(tabs.last, l10n.tournamentManagementTabSettings);
  });

  testWidgets(
    'TC-RESULTS-06 opening the tab shows the management match board',
    (tester) async {
      final l10n = await _pumpHub(tester, [
        _match('m1', 1),
        _match('m2', 2, status: 'COMPLETED'),
      ]);

      await _openResults(tester, l10n);

      final board = tester.widget<ResultsMatchBoard>(
        find.byType(ResultsMatchBoard),
      );
      expect(board.canManage, isTrue);
      expect(board.divisionId, 'div-1');
      expect(find.byKey(const ValueKey('results-row-m1')), findsOneWidget);
      expect(find.byKey(const ValueKey('results-row-m2')), findsOneWidget);
      // Managers get one extra chip; late and disputed have none of their own.
      expect(
        find.byKey(const ValueKey('results-filter-unfinished')),
        findsOneWidget,
      );
      for (final name in ['late', 'disputed']) {
        expect(find.byKey(ValueKey('results-filter-$name')), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TC-RESULTS-07 a tournament without matches says so', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester, const []);

    await _openResults(tester, l10n);

    expect(find.text(l10n.resultsBoard_empty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
