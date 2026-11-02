import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _sheet({
  VoidCallback? onClose,
  VoidCallback? onReport,
  VoidCallback? onTournament,
  bool dark = true,
  bool live = true,
  String? eloA = '1500',
  String? eloB,
  List<LiveInfoRowData>? rows,
  List<LiveSetChipData> sets = const [
    LiveSetChipData(label: 'Set 1 · 21-18'),
    LiveSetChipData(label: 'Set 2 · 3-5', current: true),
  ],
}) {
  return MaterialApp(
    theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
    home: Scaffold(
      body: LiveMatchDetailsSheet(
        sheetTitle: 'Match details',
        sideA: LiveEloSideData(name: 'Alpha', elo: eloA),
        sideB: LiveEloSideData(name: 'Beta', elo: eloB, athletes: 'B1 / B2'),
        score1: 7,
        score2: 5,
        live: live,
        sets: sets,
        rows:
            rows ??
            [
              LiveInfoRowData(
                icon: Icons.emoji_events_outlined,
                label: 'Tournament',
                text: 'Cup ABC · Round 1',
                onTap: onTournament,
              ),
              const LiveInfoRowData(
                icon: Icons.location_on_outlined,
                label: 'Place',
                text: 'Court 1',
              ),
            ],
        reportLabel: 'Report',
        closeTooltip: 'Close',
        onClose: onClose ?? () {},
        onReport: onReport ?? () {},
      ),
    ),
  );
}

void main() {
  testWidgets('TC-LIVEDET-01 head shows both sides, score, sets and rows', (
    tester,
  ) async {
    await tester.pumpWidget(_sheet());

    expect(find.text('Match details'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('B1 / B2'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('1500 ELO'), findsOneWidget);
    expect(find.text('Set 1 · 21-18'), findsOneWidget);
    expect(find.text('Set 2 · 3-5'), findsOneWidget);
    expect(find.text('Tournament'), findsOneWidget);
    expect(find.text('Court 1'), findsOneWidget);
  });

  testWidgets('TC-LIVEDET-02 close, report and tournament row fire', (
    tester,
  ) async {
    var closed = 0, reported = 0, opened = 0;
    await tester.pumpWidget(
      _sheet(
        onClose: () => closed++,
        onReport: () => reported++,
        onTournament: () => opened++,
      ),
    );

    await tester.tap(find.byTooltip('Close'));
    await tester.tap(find.text('Cup ABC · Round 1'));
    await tester.tap(find.text('Report'));

    expect([closed, opened, reported], [1, 1, 1]);
  });

  testWidgets('TC-LIVEDET-03 no ELO card and no "not available" filler', (
    tester,
  ) async {
    await tester.pumpWidget(_sheet(eloA: null, eloB: null));

    expect(find.textContaining('ELO'), findsNothing);
    expect(find.textContaining('Not available'), findsNothing);
    expect(find.textContaining('Chưa có'), findsNothing);
  });

  testWidgets('TC-LIVEDET-04 rows without a value are not drawn', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sheet(
        rows: const [
          LiveInfoRowData(
            icon: Icons.person_outline_rounded,
            label: 'Referee',
            text: '  ',
          ),
          LiveInfoRowData(
            icon: Icons.location_on_outlined,
            label: 'Place',
            text: 'Court 1',
          ),
        ],
      ),
    );

    expect(find.text('Referee'), findsNothing);
    expect(find.text('Place'), findsOneWidget);
  });

  testWidgets('TC-LIVEDET-05 hides the set strip when there are no sets', (
    tester,
  ) async {
    await tester.pumpWidget(_sheet(sets: const []));

    expect(find.textContaining('Set '), findsNothing);
  });

  testWidgets('TC-LIVEDET-06 live score is red, finished score is not', (
    tester,
  ) async {
    await tester.pumpWidget(_sheet(live: true));
    final liveColor = tester.widget<Text>(find.text('7')).style?.color;
    await tester.pumpWidget(_sheet(live: false));
    final doneColor = tester.widget<Text>(find.text('7')).style?.color;

    expect(liveColor, isNot(doneColor));
  });

  testWidgets('TC-LIVEDET-07 tap targets are at least 44dp, both themes', (
    tester,
  ) async {
    for (final dark in [true, false]) {
      await tester.pumpWidget(_sheet(dark: dark, onTournament: () {}));
      final close = tester.getSize(find.byTooltip('Close'));
      final report = tester.getSize(
        find.ancestor(of: find.text('Report'), matching: find.byType(InkWell)),
      );
      final tournament = tester.getSize(
        find.ancestor(
          of: find.text('Cup ABC · Round 1'),
          matching: find.byType(InkWell),
        ),
      );
      expect(close.height, greaterThanOrEqualTo(44));
      expect(close.width, greaterThanOrEqualTo(44));
      expect(report.height, greaterThanOrEqualTo(44));
      expect(tournament.height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    }
  });
}
