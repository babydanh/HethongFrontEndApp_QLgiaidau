import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/ranked_user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _unranked = 0xFFCBD5E1;
const _tierS = 0xFFFBBF24;

Future<int> _ring(WidgetTester tester, List<PlayerRanking> rankings) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userRankingsSummaryProvider('u1').overrideWith((ref) async => rankings),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: RankedUserAvatarTap(userId: 'u1', name: 'An'),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  final outer = find
      .descendant(of: find.byType(RankAvatar), matching: find.byType(Container))
      .first;
  final deco = tester.widget<Container>(outer).decoration! as BoxDecoration;
  return deco.color!.toARGB32();
}

void main() {
  testWidgets('TC-RANK-RING-APP-30 ring follows best ranking tier', (
    tester,
  ) async {
    final ring = await _ring(tester, const [
      PlayerRanking(
        id: 'r1',
        userId: 'u1',
        fullName: 'An',
        eloPoints: 1800,
        tierName: 'Tier S',
        matchesPlayed: 5,
        categoryId: 'c',
        categoryName: 'Cat',
      ),
    ]);
    expect(ring, _tierS);
  });

  testWidgets('TC-RANK-RING-APP-31 ring is grey when user has no ranking', (
    tester,
  ) async {
    expect(await _ring(tester, const []), _unranked);
  });
}
