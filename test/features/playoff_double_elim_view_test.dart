import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_score_entry_chooser.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_double_elim_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _m(
  String id,
  String bracket,
  int round,
  int position, {
  String status = 'SCHEDULED',
  String team1 = '',
  String team2 = '',
  String next = '',
  String? code,
  List<String>? members,
}) => MatchModel.fromJson({
  'tournamentId': 't-1',
  'round': round,
  'matchNumber': position + 1,
  'status': status,
  'team1Id': 'p1-$id',
  'team2Id': 'p2-$id',
  'team1Name': team1.isEmpty ? 'Đội $id-A' : team1,
  'team2Name': team2.isEmpty ? 'Đội $id-B' : team2,
  'stageType': 'DOUBLE_ELIMINATION',
  'nextMatchId': next,
  'matchCode': code,
  'team1Members': members,
  'bracketPosition': {'bracket': bracket, 'round': round, 'position': position},
}, id);

// Winners: 4 rounds (1 match each is enough), losers: 2 rounds, plus a grand
// final.
final _matches = [
  for (var r = 1; r <= 4; r++) _m('w$r', 'winners', r, 0),
  for (var r = 1; r <= 2; r++) _m('l$r', 'losers', r, 0),
  _m('gf', 'grand_final', 1, 0),
];

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  List<MatchModel>? matches,
  bool canScoreMatch = false,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlayoffDoubleElimView(
              matches: matches ?? _matches,
              tournamentId: 't-1',
              canScoreMatch: canScoreMatch,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(PlayoffDoubleElimView)),
  )!;
}

void main() {
  test('TC-PLF-01 grand final is appended to the winners branch', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
    final branches = buildPlayoffBranches(_matches, l10n);
    expect(branches.winners.length, 5);
    expect(branches.winners.last.label, l10n.doubleElimGrandFinal);
    expect(branches.winners.last.matches.single.id, 'gf');
    expect(branches.losers.length, 2);
  });

  testWidgets('TC-PLF-02 shows a window of 3 rounds and slides with Vòng sau', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Nhánh thắng (5)'), findsOneWidget);
    expect(find.text('Nhánh thua (2)'), findsOneWidget);
    expect(find.textContaining('1/5'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsOneWidget);
    expect(find.text('Đội w3-A'), findsOneWidget);
    expect(find.text('Đội w4-A'), findsNothing);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Vòng sau'));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('4/5'), findsOneWidget);
    expect(find.text('Đội w3-A'), findsOneWidget);
    expect(find.text('Đội w4-A'), findsOneWidget);
    expect(find.text('Đội gf-A'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsNothing);
  });

  testWidgets('TC-PLF-03 losers tab shows its own rounds', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Nhánh thua (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Đội l1-A'), findsOneWidget);
    expect(find.text('Đội l2-A'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsNothing);
  });

  testWidgets('TC-PLF-04 tapping a match opens the detail sheet', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Đội w1-A'));
    await tester.pumpAndSettle();

    expect(find.text('Xem trận'), findsOneWidget);
  });

  testWidgets('TC-PLF-09 a viewer who can score opens the score popup', (
    tester,
  ) async {
    await _pump(tester, canScoreMatch: true);

    await tester.tap(find.text('Đội w1-A'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchScoreEntryChooser), findsOneWidget);
    expect(find.text('Xem trận'), findsNothing);
  });

  testWidgets('TC-PLF-06 opens on the first round that is still unfinished', (
    tester,
  ) async {
    final matches = [
      _m('w1', 'winners', 1, 0, status: 'COMPLETED'),
      _m('w2', 'winners', 2, 0, status: 'COMPLETED'),
      _m('w3', 'winners', 3, 0),
      _m('w4', 'winners', 4, 0),
    ];
    await _pump(tester, matches: matches);

    // Active round 3 of 4 -> window starts at round 2.
    expect(find.textContaining('3/4'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsNothing);
    expect(find.text('Đội w2-A'), findsOneWidget);
    expect(find.text('Đội w4-A'), findsOneWidget);
  });

  testWidgets('TC-PLF-07 an empty side says which match it waits for', (
    tester,
  ) async {
    final x = MatchModel.fromJson({
      'tournamentId': 't-1',
      'round': 2,
      'matchNumber': 1,
      'status': 'SCHEDULED',
      'team1Name': '',
      'team2Name': '',
      'stageType': 'DOUBLE_ELIMINATION',
      'bracketPosition': {'bracket': 'winners', 'round': 2, 'position': 0},
    }, 'x');
    await _pump(
      tester,
      matches: [_m('a', 'winners', 1, 0, next: 'x', code: 'W1'), x],
    );

    expect(find.text('Thắng W1'), findsOneWidget);
    expect(find.text('Chưa xác định'), findsOneWidget);
  });

  testWidgets('TC-PLF-08 doubles cards fit without overflow', (tester) async {
    await _pump(
      tester,
      matches: [
        _m(
          'd',
          'winners',
          1,
          0,
          members: const ['Nguyễn Văn An', 'Trần Quốc Bảo'],
        ),
      ],
    );

    expect(tester.takeException(), isNull);
  });
}
