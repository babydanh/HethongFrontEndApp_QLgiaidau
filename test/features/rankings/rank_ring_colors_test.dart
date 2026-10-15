import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/utils/best_ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nguồn: `RANK_BORDER_COLORS` + `ringClass` từng bậc trong web
/// (`src/components/ui/RankAvatar.tsx`, `src/utils/rank-style.ts`).
const _webRing = <String, int>{
  'Low Tier D': 0xFFCBD5E1,
  'High Tier D': 0xFF64748B,
  'Low Tier C': 0xFF6EE7B7,
  'High Tier C': 0xFF10B981,
  'Low Tier B': 0xFF93C5FD,
  'High Tier B': 0xFF3B82F6,
  'Low Tier A': 0xFFFDA4AF,
  'High Tier A': 0xFFF43F5E,
  'Tier S': 0xFFFBBF24,
};

const _eloOfTier = <String, int>{
  'Low Tier D': 1000,
  'High Tier D': 1100,
  'Low Tier C': 1200,
  'High Tier C': 1300,
  'Low Tier B': 1400,
  'High Tier B': 1500,
  'Low Tier A': 1600,
  'High Tier A': 1700,
  'Tier S': 1800,
};

BoxDecoration _ringDecoration(WidgetTester tester) {
  final outer = find
      .descendant(of: find.byType(RankAvatar), matching: find.byType(Container))
      .first;
  return tester.widget<Container>(outer).decoration! as BoxDecoration;
}

PlayerRanking _rank(String id, int elo, {int played = 5, bool admin = false}) =>
    PlayerRanking(
      id: id,
      userId: 'u',
      fullName: 'U',
      eloPoints: elo,
      matchesPlayed: played,
      adminLeaderboardEligible: admin,
    );

void main() {
  test('every tier ring color equals the web ring color', () {
    _webRing.forEach((tier, color) {
      final palette = TierPalette.fromElo(_eloOfTier[tier]!, tier);
      expect(palette.ring, Color(color), reason: tier);
    });
  });

  testWidgets('RankAvatar paints the ring with the web tier color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: RankAvatar(name: 'An', elo: 1850, tierName: 'Tier S'),
        ),
      ),
    );
    final decoration = _ringDecoration(tester);
    expect(decoration.color, const Color(0xFFFBBF24));
    final glow = decoration.boxShadow!.single;
    expect(glow.color.a, closeTo(0x60 / 0xFF, 0.01));
    expect(glow.spreadRadius, lessThan(0));
  });

  testWidgets(
    'RankAvatar uses the neutral web ring and no glow when unranked',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: RankAvatar(name: 'An')),
        ),
      );
      final decoration = _ringDecoration(tester);
      expect(decoration.color, TierPalette.unrankedRing);
      expect(decoration.color, const Color(0xFFCBD5E1));
      expect(decoration.boxShadow, isNull);
    },
  );

  group('bestRankingOf', () {
    test('returns null for an empty list', () {
      expect(bestRankingOf(const []), isNull);
    });

    test('prefers the highest ELO among eligible ranks', () {
      final low = _rank('low', 1200);
      final high = _rank('high', 1750);
      expect(bestRankingOf([low, high]), same(high));
    });

    test('ignores ranks that are not leaderboard eligible', () {
      final unplayed = _rank('unplayed', 1900, played: 0);
      final played = _rank('played', 1300);
      expect(bestRankingOf([unplayed, played]), same(played));
    });

    test('falls back to the first rank when none is eligible', () {
      final first = _rank('first', 0, played: 0);
      final second = _rank('second', 1500, played: 0);
      expect(bestRankingOf([first, second]), same(first));
    });
  });
}
