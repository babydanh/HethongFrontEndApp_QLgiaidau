import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_score_entry_chooser.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_bracket_board.dart';
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
  VoidCallback? onOpenFull,
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
              onOpenFull: onOpenFull,
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

  testWidgets('TC-PLF-02 shows a window of 2 rounds and slides with Vòng sau', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Nhánh thắng (5)'), findsOneWidget);
    expect(find.text('Nhánh thua (2)'), findsOneWidget);
    expect(find.textContaining('1/5'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsOneWidget);
    expect(find.text('Đội w2-A'), findsOneWidget);
    expect(find.text('Đội w3-A'), findsNothing);

    await tester.tap(find.byTooltip('Vòng sau'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2/5'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsNothing);
    expect(find.text('Đội w2-A'), findsOneWidget);
    expect(find.text('Đội w3-A'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Vòng sau'));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('5/5'), findsOneWidget);
    expect(find.text('Đội w4-A'), findsOneWidget);
    expect(find.text('Đội gf-A'), findsOneWidget);
    expect(find.text('Đội w3-A'), findsNothing);
  });

  testWidgets(
    'TC-PLF-10 paging keeps the old window while the new one slides in',
    (tester) async {
      await _pump(tester);

      await tester.tap(find.byTooltip('Vòng sau'));
      await tester.pump(const Duration(milliseconds: 80));
      // Round 1 is only in the leaving window, round 3 only in the arriving one.
      expect(find.text('Đội w1-A'), findsOneWidget);
      expect(find.text('Đội w3-A'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Đội w1-A'), findsNothing);
      expect(find.text('Đội w3-A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TC-PLF-11 the two visible rounds fill the width', (
    tester,
  ) async {
    await _pump(tester);

    // Screen 400 minus 2 x 12 of padding = 376 available.
    final width = tester.getSize(find.byType(PlayoffBracketBoard)).width;
    expect(width, greaterThan(340));
    expect(width, lessThanOrEqualTo(376));
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

  testWidgets('TC-PLF-09 a viewer who can score opens the score sheet', (
    tester,
  ) async {
    await _pump(tester, canScoreMatch: true);

    await tester.tap(find.text('Đội w1-A'));
    // Managers' cards also listen for double tap, so a single tap fires after
    // the double-tap window (~300ms).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Nhập điểm #1'), findsOneWidget);
    expect(find.text('Vào trang Live'), findsOneWidget);
    expect(find.byType(MatchScoreEntryChooser), findsNothing);
    expect(find.text('Xem trận'), findsNothing);
  });

  testWidgets('TC-PLF-10 a quick double tap opens the score sheet once', (
    tester,
  ) async {
    await _pump(tester, canScoreMatch: true);

    await tester.tap(find.text('Đội w1-A'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Đội w1-A'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập điểm #1'), findsOneWidget);
    expect(find.byType(MatchScoreEntryChooser), findsNothing);
  });

  testWidgets('TC-PLF-11 a finished match shows its detail, not the score sheet', (
    tester,
  ) async {
    await _pump(
      tester,
      canScoreMatch: true,
      matches: [_m('w1', 'winners', 1, 0, status: 'COMPLETED')],
    );

    await tester.tap(find.text('Đội w1-A'));
    // Managers' cards also listen for double tap, so a single tap fires after
    // the double-tap window (~300ms).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Xem trận'), findsOneWidget);
    expect(find.text('Vào trang Live'), findsNothing);
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

    // Active round 3 of 4 -> the window of 2 starts at round 3.
    expect(find.textContaining('3/4'), findsOneWidget);
    expect(find.text('Đội w2-A'), findsNothing);
    expect(find.text('Đội w3-A'), findsOneWidget);
    expect(find.text('Đội w4-A'), findsOneWidget);
  });

  testWidgets('TC-PLF-07 an empty side shows N/A, not a feeder hint', (
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
      matches: [
        _m('a', 'winners', 1, 0, next: 'x', code: 'W1'),
        x,
      ],
    );

    expect(find.text('N/A'), findsNWidgets(2));
    expect(find.text('Thắng W1'), findsNothing);
    expect(find.text('Chưa xác định'), findsNothing);
  });

  testWidgets('TC-PLF-09 the empty side of a BYE match says it is a bye', (
    tester,
  ) async {
    final bye = MatchModel.fromJson({
      'tournamentId': 't-1',
      'round': 1,
      'matchNumber': 1,
      'status': 'SCHEDULED',
      'isBye': true,
      'team1Id': 'p1-bye',
      'team1Name': 'ggg',
      'team2Name': '',
      'stageType': 'DOUBLE_ELIMINATION',
      'bracketPosition': {'bracket': 'winners', 'round': 1, 'position': 0},
    }, 'bye');
    await _pump(tester, matches: [bye]);

    expect(find.text('ggg'), findsOneWidget);
    expect(find.text('Miễn đấu'), findsOneWidget);
    expect(find.text('N/A'), findsNothing);
  });

  testWidgets('TC-PLF-EXPAND-01 no expand button without a handler', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const ValueKey('playoff-open-full')), findsNothing);
  });

  testWidgets('TC-PLF-EXPAND-02 expand button sits in the stepper row', (
    tester,
  ) async {
    var opened = 0;
    await _pump(tester, onOpenFull: () => opened++);

    final button = find.byKey(const ValueKey('playoff-open-full'));
    expect(button, findsOneWidget);
    expect(find.byTooltip('Phóng to'), findsOneWidget);
    // Same row as the arrows: vertically level with the next-round arrow.
    expect(
      tester.getCenter(button).dy,
      tester.getCenter(find.byTooltip('Vòng sau')).dy,
    );

    await tester.tap(button);
    expect(opened, 1);
  });

  testWidgets('TC-PLF-SWIPE-01 swiping the stepper row turns the page', (
    tester,
  ) async {
    await _pump(tester);
    final label = find.textContaining('/5');

    await tester.fling(label, const Offset(-200, 0), 800);
    await tester.pumpAndSettle();
    expect(find.textContaining('2/5'), findsOneWidget);

    await tester.fling(label, const Offset(200, 0), 800);
    await tester.pumpAndSettle();
    expect(find.textContaining('1/5'), findsOneWidget);

    // Already on the first round: swiping back stays put.
    await tester.fling(label, const Offset(200, 0), 800);
    await tester.pumpAndSettle();
    expect(find.textContaining('1/5'), findsOneWidget);
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
