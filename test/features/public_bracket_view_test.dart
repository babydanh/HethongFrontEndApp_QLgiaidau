import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
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

    final diagram = tester.widget<SingleElimDiagram>(
      find.byType(SingleElimDiagram),
    );
    expect(diagram.scrollOnly, isTrue);
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

    final diagram = tester.widget<DoubleElimDiagram>(
      find.byType(DoubleElimDiagram),
    );
    expect(diagram.scrollOnly, isTrue);
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
    await tester.pumpAndSettle();

    expect(find.byType(CrossTableView), findsOneWidget);
    expect(find.byType(SingleElimDiagram), findsNothing);
    expect(find.byType(DoubleElimDiagram), findsNothing);
  });

  testWidgets('group stage + knockout shows only the knockout diagram', (
    tester,
  ) async {
    final matches = [
      _match('g1', groupName: 'A', stageType: 'GROUP'),
      _match(
        'k1',
        round: 1,
        position: 0,
        nextMatchId: 'k3',
        stageType: 'KNOCKOUT',
      ),
      _match(
        'k2',
        round: 1,
        position: 1,
        nextMatchId: 'k3',
        stageType: 'KNOCKOUT',
      ),
      _match('k3', round: 2, position: 0, stageType: 'KNOCKOUT'),
    ];
    await tester.pumpWidget(
      _host(
        PublicBracketView(
          tournamentId: 't-1',
          matches: matches,
          bracketType: 'group_stage_knockout',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleElimDiagram), findsOneWidget);
    expect(find.byType(CrossTableView), findsNothing);
    // Chỉ thẻ knockout nằm trong sơ đồ; trận vòng bảng không lọt vào.
    final diagram = tester.widget<SingleElimDiagram>(
      find.byType(SingleElimDiagram),
    );
    expect(diagram.matches.map((m) => m.id), unorderedEquals(['k1', 'k2', 'k3']));
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
}
