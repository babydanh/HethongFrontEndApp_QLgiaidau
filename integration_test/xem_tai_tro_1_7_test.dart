import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sponsors_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/xem.dart';

/// Public sponsor block with 1..7 sponsors, on fake data only (no Backend,
/// no network). Empty logo URLs render the initial-letter avatar.
///
/// A: one MAIN sponsor plus (n - 1) COMPANION sponsors.
/// B: n COMPANION sponsors.
/// C: one sponsor in each of the eight tiers.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initXem);

  for (var n = 1; n <= 7; n++) {
    testWidgets('xem: tai tro A $n (1 chinh + ${n - 1} dong hanh)', (
      tester,
    ) async {
      final sponsors = [
        _sponsor('main', 'Nhà tài trợ chính', 'MAIN'),
        for (var i = 1; i < n; i++)
          _sponsor('c$i', 'Đồng hành $i', 'COMPANION', order: i),
      ];
      await _shoot(tester, binding, sponsors, 'tai-tro-A-$n');
    });
  }

  for (var n = 1; n <= 7; n++) {
    testWidgets('xem: tai tro B $n (dong hanh)', (tester) async {
      final sponsors = [
        for (var i = 1; i <= n; i++)
          _sponsor('c$i', 'Đồng hành $i', 'COMPANION', order: i),
      ];
      await _shoot(tester, binding, sponsors, 'tai-tro-B-$n');
    });
  }

  testWidgets('xem: tai tro C du 8 hang', (tester) async {
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
    final sponsors = [
      for (var i = 0; i < tiers.length; i++)
        _sponsor('t$i', 'Hạng ${tiers[i]}', tiers[i], order: i),
    ];
    final shooter = await _shoot(tester, binding, sponsors, 'tai-tro-C-1');
    await scrollBy(tester, 600);
    await shooter.snap('tai-tro-C-2');
    await scrollBy(tester, 600);
    await shooter.snap('tai-tro-C-3');
  });
}

Future<XemShooter> _shoot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  List<TournamentSponsor> sponsors,
  String name,
) async {
  final shooter = XemShooter(tester, binding);
  await shooter.pump(
    xemApp(
      home: Scaffold(body: SponsorsTab(sponsors: sponsors)),
    ),
  );
  // Every sponsor is on screen (name text or tooltip) and nothing overflows.
  expect(tester.takeException(), isNull);
  await shooter.snap(name);
  return shooter;
}

TournamentSponsor _sponsor(
  String id,
  String name,
  String tier, {
  int order = 0,
}) => TournamentSponsor(
  id: id,
  displayName: name,
  tier: tier,
  logoUrl: '', // empty logo keeps the screen offline (initial-letter avatar)
  displayOrder: order,
  status: 'PUBLISHED',
  isPublic: true,
);
