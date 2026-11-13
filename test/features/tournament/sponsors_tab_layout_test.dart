import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sponsors_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TournamentSponsor _sponsor(String id, String tier, {int order = 0}) =>
    TournamentSponsor(
      id: id,
      displayName: 'Partner $id',
      tier: tier,
      logoUrl: 'https://cdn.example.test/$id.png',
      displayOrder: order,
    );

/// Tablet width: regular tiers show five logos per row from here up.
const double _tablet = 700;

Finder _card(String id) => find.byKey(ValueKey('sponsor-card-$id'));

Future<void> _pump(
  WidgetTester tester,
  List<TournamentSponsor> sponsors, {
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SponsorsTab(sponsors: sponsors)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('TC-APP-SPONSOR-TIER-01 MAIN and COMPANION show their labels '
      'in the order TITLE, MAIN, GOLD, COMPANION, IN_KIND', (tester) async {
    await _pump(tester, [
      _sponsor('inkind', 'IN_KIND'),
      _sponsor('comp', 'COMPANION'),
      _sponsor('gold', 'GOLD'),
      _sponsor('main', 'MAIN'),
      _sponsor('title', 'TITLE'),
    ]);

    final labels = [
      'TITLE SPONSOR',
      'MAIN SPONSOR',
      'GOLD SPONSOR',
      'SUPPORTING SPONSOR',
      'IN-KIND PARTNER',
    ];
    final tops = [
      for (final label in labels) tester.getTopLeft(find.text(label)).dy,
    ];
    final sorted = [...tops]..sort();
    expect(tops, sorted);
    expect(tops.toSet().length, labels.length);
  });

  testWidgets('TC-APP-SPONSOR-TIER-02 a single MAIN logo is horizontally '
      'centered and large', (tester) async {
    await _pump(tester, [_sponsor('m1', 'MAIN')]);

    expect(tester.getCenter(_card('m1')).dx, closeTo(200, 0.5));
    // 400 wide minus 16dp gutters is 368, so the cell is capped at 320.
    expect(tester.getSize(_card('m1')).width, closeTo(320, 0.5));
    expect(tester.getSize(_card('m1')).height, greaterThanOrEqualTo(140));
  });

  testWidgets('TC-APP-SPONSOR-TIER-03 two TITLE logos wrap and stay centered', (
    tester,
  ) async {
    await _pump(tester, [_sponsor('t1', 'TITLE'), _sponsor('t2', 'TITLE')]);

    expect(tester.getCenter(_card('t1')).dx, closeTo(200, 0.5));
    expect(tester.getCenter(_card('t2')).dx, closeTo(200, 0.5));
    expect(
      tester.getTopLeft(_card('t2')).dy,
      greaterThan(tester.getTopLeft(_card('t1')).dy),
    );
  });

  testWidgets('TC-APP-SPONSOR-TIER-04 five COMPANION logos share one row with '
      'equal width', (tester) async {
    final sponsors = [
      for (var i = 0; i < 5; i++) _sponsor('c$i', 'COMPANION', order: i),
    ];
    await _pump(tester, sponsors, width: _tablet);

    final dys = [for (final s in sponsors) tester.getCenter(_card(s.id)).dy];
    final widths = [
      for (final s in sponsors) tester.getSize(_card(s.id)).width,
    ];
    expect(dys.toSet().length, 1);
    for (final w in widths) {
      expect(w, closeTo(widths.first, 0.01));
    }
    // The row fills the content width and is centered.
    final left = tester.getTopLeft(_card('c0')).dx;
    final right = tester.getTopRight(_card('c4')).dx;
    expect((left + right) / 2, closeTo(_tablet / 2, 0.5));
  });

  testWidgets(
    'TC-APP-SPONSOR-TIER-05 a sixth regular logo wraps to a new row',
    (tester) async {
      final sponsors = [
        for (var i = 0; i < 6; i++) _sponsor('c$i', 'COMPANION', order: i),
      ];
      await _pump(tester, sponsors, width: _tablet);

      expect(
        tester.getCenter(_card('c5')).dy,
        greaterThan(tester.getCenter(_card('c0')).dy),
      );
      expect(
        tester.getSize(_card('c5')).width,
        closeTo(tester.getSize(_card('c0')).width, 0.01),
      );
    },
  );

  testWidgets('TC-APP-SPONSOR-TIER-06 two regular logos keep the 5-per-row '
      'cell size and sit in the middle', (tester) async {
    final five = [
      for (var i = 0; i < 5; i++) _sponsor('f$i', 'SILVER', order: i),
    ];
    await _pump(tester, five, width: _tablet);
    final fullRowWidth = tester.getSize(_card('f0')).width;

    await _pump(tester, [
      _sponsor('s1', 'SILVER'),
      _sponsor('s2', 'SILVER'),
    ], width: _tablet);

    expect(tester.getSize(_card('s1')).width, closeTo(fullRowWidth, 0.01));
    final left = tester.getTopLeft(_card('s1')).dx;
    final right = tester.getTopRight(_card('s2')).dx;
    expect((left + right) / 2, closeTo(_tablet / 2, 0.5));
    expect(tester.getCenter(_card('s1')).dy, tester.getCenter(_card('s2')).dy);
  });

  testWidgets('TC-APP-SPONSOR-TIER-07 regular logos expose the name as a '
      'tooltip', (tester) async {
    await _pump(tester, [_sponsor('g1', 'GOLD')]);

    expect(find.byTooltip('Partner g1'), findsOneWidget);
  });

  testWidgets('TC-APP-SPONSOR-TIER-08 every tier fits a 320dp phone without '
      'overflow', (tester) async {
    const tiers = [
      'TITLE',
      'MAIN',
      'DIAMOND',
      'GOLD',
      'SILVER',
      'BRONZE',
      'COMPANION',
      'IN_KIND',
    ];
    await _pump(tester, [
      for (final tier in tiers)
        for (var i = 0; i < 6; i++) _sponsor('$tier-$i', tier, order: i),
    ], width: 320);

    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-APP-SPONSOR-TIER-09 phones show three regular logos per row '
      'so they stay readable', (tester) async {
    final sponsors = [
      for (var i = 0; i < 4; i++) _sponsor('p$i', 'COMPANION', order: i),
    ];
    await _pump(tester, sponsors);

    final firstRow = tester.getCenter(_card('p0')).dy;
    expect(tester.getCenter(_card('p2')).dy, firstRow);
    expect(tester.getCenter(_card('p3')).dy, greaterThan(firstRow));
    // A third of the 368dp content width, minus the two gaps.
    expect(tester.getSize(_card('p0')).width, closeTo((368 - 16) / 3, 0.5));
  });
}
