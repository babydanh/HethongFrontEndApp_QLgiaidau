import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _sheet({
  VoidCallback? onClose,
  VoidCallback? onReport,
  VoidCallback? onTournament,
  bool dark = true,
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
        matchTitle: 'Alpha vs Beta',
        stats: const [
          (value: '12', caption: 'watching'),
          (value: '128', caption: 'cheers'),
          (value: '14:30', caption: '01/11/2026'),
        ],
        setsTitle: 'SET SCORES',
        sets: sets,
        eloTitle: 'SINGLES ELO',
        sideA: const LiveEloSideData(name: 'Alpha', elo: '1500'),
        sideB: const LiveEloSideData(name: 'Beta', elo: 'Not available'),
        rows: [
          LiveInfoRowData(
            icon: Icons.emoji_events_outlined,
            text: 'Cup ABC · Round 1',
            onTap: onTournament,
          ),
          const LiveInfoRowData(
            icon: Icons.location_on_outlined,
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
  testWidgets('TC-LIVEDET-01 shows title, headline numbers, sets and ELO', (
    tester,
  ) async {
    await tester.pumpWidget(_sheet());

    expect(find.text('Match details'), findsOneWidget);
    expect(find.text('Alpha vs Beta'), findsOneWidget);
    for (final t in ['12', '128', '14:30', 'watching', 'cheers']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('Set 1 · 21-18'), findsOneWidget);
    expect(find.text('Set 2 · 3-5'), findsOneWidget);
    expect(find.textContaining('1500', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Not available', findRichText: true),
      findsOneWidget,
    );
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

  testWidgets('TC-LIVEDET-03 hides the set strip when there are no sets', (
    tester,
  ) async {
    await tester.pumpWidget(_sheet(sets: const []));

    expect(find.text('SET SCORES'), findsNothing);
    expect(find.text('SINGLES ELO'), findsOneWidget);
  });

  testWidgets('TC-LIVEDET-04 tap targets are at least 48dp, both themes', (
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
      expect(close.height, greaterThanOrEqualTo(48));
      expect(close.width, greaterThanOrEqualTo(48));
      expect(report.height, greaterThanOrEqualTo(48));
      expect(tournament.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    }
  });
}
