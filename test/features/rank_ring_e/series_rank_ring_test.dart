import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_detail_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _ranking = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'Nguyễn Văn An',
  eloPoints: 1850,
  tierName: 'Tier S',
  matchesPlayed: 5,
  categoryId: 'c',
  categoryName: 'Cat',
);

void main() {
  test('TC-RANK-RING-APP-E10: SeriesRanking reads the athlete userId', () {
    final r = SeriesRanking.fromJson({
      'position': 1,
      'userId': 'u1',
      'fullName': 'Nguyễn Văn An',
    });
    expect(r.userId, 'u1');
  });

  testWidgets(
    'TC-RANK-RING-APP-E11: series standings row rings an athlete with an account',
    (tester) async {
      const detail = SeriesDetail(
        id: 's',
        name: 'Chuỗi',
        slug: 's',
        status: 'ONGOING',
        rankings: [
          SeriesRanking(
            position: 1,
            participantName: 'Nguyễn Văn An',
            userId: 'u1',
          ),
          SeriesRanking(position: 2, participantName: 'Khách Lẻ'),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            seriesDetailProvider('s').overrideWith((ref) async => detail),
            userRankingsSummaryProvider(
              'u1',
            ).overrideWith((ref) async => const [_ranking]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SeriesDetailScreen(slug: 's'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      final avatar = find.byType(RankAvatar);
      expect(avatar, findsOneWidget);
      final outer = find
          .descendant(of: avatar, matching: find.byType(Container))
          .first;
      final ring =
          (tester.widget<Container>(outer).decoration! as BoxDecoration).color;
      expect(ring, const Color(0xFFFBBF24));
    },
  );
}
