import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/rank_tier_badge.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_progress_card.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_tier_badge.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_legend_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _localized(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

PlayerRanking _rank({String source = 'ELO', bool available = true}) =>
    PlayerRanking(
      id: 'rank-1',
      userId: 'user-1',
      fullName: 'Alex',
      categoryId: 'pickleball',
      categoryName: 'Pickleball',
      eloPoints: 1450,
      matchesPlayed: 1,
      tierName: source == 'DUPR' ? 'High Tier C' : '',
      tierSource: source,
      tierAvailable: available,
    );

List<EloTier> _duprTiers() => [
  for (final (index, name) in [
    (0, 'Low Tier D'),
    (1, 'High Tier D'),
    (2, 'Low Tier C'),
    (3, 'High Tier C'),
    (4, 'Low Tier B'),
    (5, 'High Tier B'),
    (6, 'Low Tier A'),
    (7, 'High Tier A'),
  ])
    EloTier(
      id: 'tier-$index',
      categoryId: 'pickleball',
      name: name,
      minElo: 0,
      maxElo: 0,
      minValue: 2.0 + index * 0.5,
      maxValue: index == 7 ? null : 2.5 + index * 0.5,
      tierSource: 'DUPR',
    ),
];

void main() {
  testWidgets('DUPR chưa có bậc thì không hiện badge', (tester) async {
    await tester.pumpWidget(
      _localized(
        const Column(
          children: [
            RankTierBadge(
              tierName: 'Beginner',
              elo: 1450,
              tierSource: 'DUPR',
              tierAvailable: false,
            ),
            EloTierBadge(
              elo: 1450,
              tierName: 'Beginner',
              tierSource: 'DUPR',
              tierAvailable: false,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(RankTierBadge), findsOneWidget);
    expect(find.byType(EloTierBadge), findsOneWidget);
    expect(find.text('LTA'), findsNothing);
    expect(find.text('Beginner'), findsNothing);
  });

  testWidgets('nguồn ELO vẫn suy badge như cũ', (tester) async {
    await tester.pumpWidget(
      _localized(const RankTierBadge(tierName: '', elo: 1450)),
    );

    expect(find.text('LTB'), findsOneWidget);
  });

  testWidgets('ẩn dòng tiến độ ELO với DUPR và giữ cho ELO', (tester) async {
    await tester.pumpWidget(_localized(EloProgressCard(userName: 'Alex', rankings: [_rank(source: 'DUPR')])));
    expect(find.textContaining('ELO to'), findsNothing);

    await tester.pumpWidget(_localized(EloProgressCard(userName: 'Alex', rankings: [_rank()])));
    expect(find.text('50 ELO to High Tier B'), findsOneWidget);
  });

  testWidgets('chú giải DUPR hiển thị khoảng và nguồn', (tester) async {
    await tester.pumpWidget(_localized(TierLegendView(tiers: _duprTiers())));
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Tiers powered by DUPR'), findsOneWidget);
    expect(find.text('High Tier C'), findsOneWidget);
    expect(find.text('3.50 – 3.99'), findsOneWidget);
    expect(find.text('Tier S'), findsNothing);
  });

  testWidgets('chú giải rỗng không gây lỗi', (tester) async {
    await tester.pumpWidget(_localized(const TierLegendView(tiers: [])));
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatar không dùng viền rank ELO khi DUPR chưa có bậc', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        const RankAvatar(
          name: 'Alex',
          elo: 1450,
          tierName: 'High Tier B',
          tierSource: 'DUPR',
          tierAvailable: false,
          matchesPlayed: 8,
        ),
      ),
    );

    final avatar = tester.widget<Container>(find.byType(Container).first);
    expect((avatar.decoration! as BoxDecoration).color, TierPalette.unrankedRing);
  });
}
