import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_table_row.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/swiss_standings_view.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/standings_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/public_bracket_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

MatchModel _match(
  String id, {
  int round = 1,
  int position = 0,
  String bracket = 'winners',
  String nextMatchId = '',
  String? stageType,
  String? groupName,
}) => MatchModel.fromJson({
  'id': id,
  'tournamentId': 't-1',
  'round': round,
  'matchNumber': position + 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội $id-A',
  'team2Name': 'Đội $id-B',
  'nextMatchId': nextMatchId,
  'bracketPosition': {'bracket': bracket, 'round': round, 'position': position},
  if (stageType != null) 'stageType': stageType,
  if (groupName != null) 'groupName': groupName,
}, id);

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Future<({ScrollableState page, ScrollableState bracket})> _pumpBracketOnPage(
  WidgetTester tester,
  List<MatchModel> matches,
) async {
  tester.view.physicalSize = const Size(400, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _host(
      Column(
        children: [
          const SizedBox(height: 300),
          PublicBracketView(
            tournamentId: 't-1',
            matches: matches,
            bracketType: 'single_elimination',
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    page: tester.state<ScrollableState>(find.byType(Scrollable).first),
    bracket: tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleElimDiagram),
        matching: find.byType(Scrollable),
      ),
    ),
  );
}

void main() {
  final singleMatches = [
    _match('s1', round: 1, position: 0, nextMatchId: 's3'),
    _match('s2', round: 1, position: 1, nextMatchId: 's3'),
    _match('s3', round: 2, position: 0),
  ];

  testWidgets('single elimination renders the diagram only, read-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PublicBracketView(
          tournamentId: 't-1',
          matches: singleMatches,
          bracketType: 'single_elimination',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bảng'), findsNothing);
    expect(find.text('Playoff'), findsNothing);
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('bracket-only: no banner, search, filter or round cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PublicBracketView(
          tournamentId: 't-1',
          matches: singleMatches,
          bracketType: 'single_elimination',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(find.byIcon(Icons.account_tree_rounded), findsNothing);
    expect(find.text('Vòng Knockout'), findsNothing);
    expect(find.text('Sơ đồ Knockout'), findsNothing);
  });

  testWidgets('double elimination uses the winners/losers diagram', (
    tester,
  ) async {
    final matches = [
      _match('w1', round: 1, position: 0, nextMatchId: 'w2'),
      _match('w2', round: 2, position: 0, bracket: 'winners'),
      _match(
        'l1',
        round: 1,
        position: 0,
        bracket: 'losers',
        stageType: 'DOUBLE_ELIMINATION',
      ),
    ];
    await tester.pumpWidget(
      _host(
        PublicBracketView(
          tournamentId: 't-1',
          matches: matches,
          bracketType: 'double_elimination',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bảng'), findsNothing);
    expect(find.text('Playoff'), findsNothing);
    expect(find.byType(SingleElimDiagram), findsNothing);
  });

  testWidgets('round robin keeps its cross table, not a knockout diagram', (
    tester,
  ) async {
    final matches = [
      _match('r1', groupName: 'A', stageType: 'GROUP'),
      _match('r2', position: 1, groupName: 'A', stageType: 'GROUP'),
    ];
    await tester.pumpWidget(
      _host(
        PublicBracketView(
          tournamentId: 't-1',
          matches: matches,
          bracketType: 'round_robin',
        ),
        overrides: [
          standingsWithDivisionProvider((
            tournamentId: 't-1',
            divisionId: null,
          )).overrideWith((ref) => Stream.value(const <Standing>[])),
          matchesWithDivisionProvider((
            tournamentId: 't-1',
            divisionId: null,
          )).overrideWith((ref) => Stream.value(matches)),
        ],
      ),
    );
    expect(find.text('Bảng'), findsNothing);
    expect(find.text('Playoff'), findsNothing);
    expect(find.byType(CrossTableView), findsOneWidget);
    expect(find.byType(SingleElimDiagram), findsNothing);
    expect(find.byType(DoubleElimDiagram), findsNothing);
  });

  testWidgets(
    'TC-FEAT-01 group stage + knockout shows both tabs and division standings',
    (tester) async {
      final matches = [
        _match('g1', groupName: 'A', stageType: 'GROUP'),
        _match('k1', round: 1, position: 0, stageType: 'KNOCKOUT'),
        _match('k2', round: 1, position: 1, stageType: 'KNOCKOUT'),
        _match('k3', round: 2, position: 0, stageType: 'KNOCKOUT'),
      ];
      final standings = [
        const Standing(
          id: 'a1',
          teamName: 'Đội bảng A1',
          group: 'A',
          totalPoints: 9,
        ),
        const Standing(
          id: 'a2',
          teamName: 'Đội bảng A2',
          group: 'A',
          totalPoints: 6,
        ),
        const Standing(
          id: 'a3',
          teamName: 'Đội bảng A3',
          group: 'A',
          totalPoints: 3,
        ),
        const Standing(
          id: 'a4',
          teamName: 'Đội bảng A4',
          group: 'A',
          totalPoints: 0,
        ),
      ];
      final tournament = Tournament(
        id: 't-1',
        name: 'Giải kiểm thử',
        sport: 'pickleball',
        format: 'doubles',
        bracketType: 'round_robin',
        adminToken: '',
        refereeToken: '',
        viewerToken: '',
        creatorId: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        _host(
          PublicBracketView(
            tournamentId: 't-1',
            divisionId: 'division-1',
            matches: matches,
            bracketType: 'group_stage_knockout',
          ),
          overrides: [
            standingsWithDivisionProvider((
              tournamentId: 't-1',
              divisionId: 'division-1',
            )).overrideWith((ref) => Stream.value(standings)),
            tournamentProvider(
              't-1',
            ).overrideWith((ref) => Stream.value(tournament)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bảng'), findsOneWidget);
      expect(find.text('Playoff'), findsOneWidget);
      expect(find.byType(StandingsView), findsOneWidget);
      expect(find.text('Đội bảng A1'), findsOneWidget);
      expect(find.byType(SingleElimDiagram), findsNothing);
      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.rows.take(2).every((row) => row.color != null), isTrue);
      expect(table.rows[2].color, isNull);

      await tester.tap(find.text('Playoff'));
      await tester.pumpAndSettle();

      expect(find.byType(StandingsView), findsNothing);
      final diagram = tester.widget<SingleElimDiagram>(
        find.byType(SingleElimDiagram),
      );
      expect(diagram.matches.map((match) => match.id), ['k1', 'k2', 'k3']);
    },
  );

  testWidgets('TC-FEAT-02 group stage + knockout with no matches keeps tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const PublicBracketView(
          tournamentId: 't-1',
          divisionId: 'division-1',
          matches: [],
          bracketType: 'group_stage_knockout',
        ),
        overrides: [
          standingsWithDivisionProvider((
            tournamentId: 't-1',
            divisionId: 'division-1',
          )).overrideWith((ref) => Stream.value(const <Standing>[])),
          tournamentProvider(
            't-1',
          ).overrideWith((ref) => Stream.value(null)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(PublicBracketView)),
    )!;
    expect(find.text('Bảng'), findsOneWidget);
    expect(find.text('Playoff'), findsOneWidget);
    expect(find.text(l10n.standings_empty), findsOneWidget);

    await tester.tap(find.text('Playoff'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.bracketView_noMatches), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no matches yet shows an empty state, no diagram', (tester) async {
    await tester.pumpWidget(
      _host(
        const PublicBracketView(
          tournamentId: 't-1',
          matches: [],
          bracketType: 'single_elimination',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleElimDiagram), findsNothing);
    expect(find.byType(DoubleElimDiagram), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical drag over the bracket scrolls the page', (
    tester,
  ) async {
    final scroll = await _pumpBracketOnPage(tester, singleMatches);
    await tester.dragFrom(
      tester.getCenter(find.byType(SingleElimDiagram)),
      const Offset(0, -60),
    );
    await tester.pumpAndSettle();

    expect(scroll.page.position.pixels, greaterThan(0));
    expect(scroll.bracket.position.pixels, 0);
  });

  testWidgets('horizontal drag over the bracket pans it, page stays put', (
    tester,
  ) async {
    final scroll = await _pumpBracketOnPage(tester, singleMatches);
    await tester.dragFrom(
      tester.getCenter(find.byType(SingleElimDiagram)),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();

    expect(scroll.bracket.position.pixels, greaterThan(0));
    expect(scroll.page.position.pixels, 0);
  });

  group('swiss', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    final swissMatches = [
      _match('s1', round: 1, position: 0, stageType: 'SWISS'),
      _match('s2', round: 2, position: 0, stageType: 'SWISS'),
      _match('s3', round: 2, position: 1, stageType: 'SWISS'),
      MatchModel.fromJson({
        'id': 'bye',
        'tournamentId': 't-1',
        'round': 2,
        'matchNumber': 3,
        'status': 'COMPLETED',
        'isBye': true,
        'team1Name': 'Đội Nghỉ',
        'team2Name': 'TBD',
        'stageType': 'SWISS',
        'bracketPosition': {'bracket': 'main', 'round': 2, 'position': 2},
      }, 'bye'),
    ];
    const standings = [
      Standing(id: 'p1', teamName: 'Đội Nhất', rank: 1, totalPoints: 6),
      Standing(id: 'p2', teamName: 'Đội Nhì', rank: 2, totalPoints: 3),
    ];
    const stage = SwissStageInfo(
      stageId: 'stage-1',
      config: SwissConfig(
        totalRounds: 4,
        tiebreakOrder: [SwissTiebreak.buchholz],
        firstRoundPairing: 'SEED',
      ),
    );

    // Plain theme: AppTheme loads google_fonts assets, unavailable without .env.
    Widget plainHost(Widget child, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

    List<Override> swissOverrides() => [
      standingsWithDivisionProvider.overrideWith(
        (ref, params) => Stream.value(standings),
      ),
      swissStageProvider.overrideWith((ref, params) => Stream.value(stage)),
    ];

    testWidgets('public view: standings + current round only, no diagram', (
      tester,
    ) async {
      await tester.pumpWidget(
        plainHost(
          PublicBracketView(
            tournamentId: 't-1',
            matches: swissMatches,
            bracketType: 'swiss',
          ),
          swissOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SwissStandingsView), findsOneWidget);
      expect(find.byType(CrossTableView), findsNothing);
      expect(find.byType(SingleElimDiagram), findsNothing);
      expect(find.text('Vòng 2'), findsWidgets);
      // Current round (2) has three rows: two matches and the BYE.
      expect(find.byType(MatchTableRow), findsNWidgets(3));
      expect(find.text('Đội Nghỉ'), findsOneWidget);
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...swissOverrides(),
            tournamentProvider.overrideWith(
              (ref, id) => Stream.value(
                Tournament(
                  id: 't-1',
                  name: 'Swiss fixture',
                  sport: 'pickleball',
                  format: 'SINGLES',
                  bracketType: 'swiss',
                  status: 'in_progress',
                  visibility: 'PUBLIC',
                  adminToken: '',
                  refereeToken: '',
                  viewerToken: '',
                  creatorId: 'owner',
                  maxTeams: 16,
                  createdAt: DateTime(2026, 1, 1),
                  updatedAt: DateTime(2026, 1, 1),
                ),
              ),
            ),
            bracketMatchesWithDivisionProvider.overrideWith(
              (ref, params) => Stream.value(swissMatches),
            ),
            authProvider.overrideWith(_GuestAuthNotifier.new),
          ],
          child: MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const BracketViewScreen(
              tournamentId: 't-1',
              divisionId: 'd-1',
              bracketType: 'swiss',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('screen: two tabs, no cross-table tab, standings first', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text(vi.bracketView_standings), findsOneWidget);
      expect(find.text(vi.bracketView_schedule), findsOneWidget);
      expect(find.text(vi.bracketView_crossTable), findsNothing);
      expect(find.byType(SwissStandingsView), findsOneWidget);
      expect(find.byType(CrossTableView), findsNothing);
    });

    testWidgets('screen: schedule defaults to the current round, BYE shown', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text(vi.bracketView_schedule));
      await tester.pumpAndSettle();

      // Round 2 only: s2, s3 and the BYE row.
      expect(find.byType(MatchTableRow), findsNWidgets(3));
      expect(find.text(vi.swissBye), findsOneWidget);
      // No bracket diagram entry for Swiss.
      expect(find.byIcon(Icons.account_tree_rounded), findsNothing);

      // Picking round 1 swaps the list.
      await tester.tap(find.text('Vòng 1').first);
      await tester.pumpAndSettle();
      expect(find.byType(MatchTableRow), findsNWidgets(1));
    });
  });
  testWidgets('horizontal drag starting on a double-elim match card pans it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final matches = [
      for (var i = 0; i < 4; i++)
        _match('w1$i', round: 1, position: i, nextMatchId: 'w2${i ~/ 2}'),
      for (var i = 0; i < 2; i++)
        _match('w2$i', round: 2, position: i, nextMatchId: 'w30'),
      _match('w30', round: 3, position: 0),
      for (var i = 0; i < 2; i++)
        _match(
          'l1$i',
          round: 1,
          position: i,
          bracket: 'losers',
          stageType: 'DOUBLE_ELIMINATION',
        ),
    ];
    await tester.pumpWidget(
      _host(
        PublicBracketView(
          tournamentId: 't-1',
          matches: matches,
          bracketType: 'double_elimination',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bracket = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(DoubleElimDiagram),
        matching: find.byType(Scrollable),
      ),
    );
    expect(bracket.position.maxScrollExtent, greaterThan(0));

    await tester.dragFrom(
      tester.getCenter(find.text('Đội w10-A')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    expect(bracket.position.pixels, greaterThan(0));
  });
}
