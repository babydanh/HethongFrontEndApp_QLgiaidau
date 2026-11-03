import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_double_elim_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _m(String id, String bracket, int round, int position) =>
    MatchModel.fromJson({
      'tournamentId': 't-1',
      'round': round,
      'matchNumber': position + 1,
      'status': 'SCHEDULED',
      'team1Name': 'Đội $id-A',
      'team2Name': 'Đội $id-B',
      'stageType': 'DOUBLE_ELIMINATION',
      'bracketPosition': {
        'bracket': bracket,
        'round': round,
        'position': position,
      },
    }, id);

// Winners: 4 rounds (8,4,2,1 matches would be big; 1 match each is enough),
// losers: 2 rounds, plus a grand final.
final _matches = [
  for (var r = 1; r <= 4; r++) _m('w$r', 'winners', r, 0),
  for (var r = 1; r <= 2; r++) _m('l$r', 'losers', r, 0),
  _m('gf', 'grand_final', 1, 0),
];

Future<AppLocalizations> _pump(WidgetTester tester) async {
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
              matches: _matches,
              tournamentId: 't-1',
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

  testWidgets('TC-PLF-02 winners branch pages 3 rounds at a time', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Nhánh thắng'), findsOneWidget);
    expect(find.text('Nhánh thua'), findsOneWidget);
    expect(find.text('Trang 1 / 2'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsOneWidget);
    expect(find.text('Đội w3-A'), findsOneWidget);
    expect(find.text('Đội w4-A'), findsNothing);

    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(find.text('Trang 2 / 2'), findsOneWidget);
    expect(find.text('Đội w4-A'), findsOneWidget);
    expect(find.text('Đội gf-A'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsNothing);
  });

  testWidgets('TC-PLF-03 losers tab shows its own rounds on one page', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Nhánh thua'));
    await tester.pumpAndSettle();

    expect(find.text('Đội l1-A'), findsOneWidget);
    expect(find.text('Đội l2-A'), findsOneWidget);
    expect(find.text('Đội w1-A'), findsNothing);
    expect(find.textContaining('Trang'), findsNothing);
  });

  testWidgets('TC-PLF-04 tapping a match opens the detail sheet', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Đội w1-A'));
    await tester.pumpAndSettle();

    expect(find.text('Xem trận'), findsOneWidget);
  });
}
