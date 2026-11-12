import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_comment_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _communityId = 'club-7';
const _unranked = 0xFFCBD5E1;
const _tierS = 0xFFFBBF24;

const _ranking = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'An',
  eloPoints: 1800,
  tierName: 'Tier S',
  matchesPlayed: 5,
  categoryId: 'c',
  categoryName: 'Cat',
);

Future<void> _pumpSheet(
  WidgetTester tester, {
  required String authorId,
  required List<PlayerRanking> rankings,
  required List<String> requested,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        communityTagPresetsProvider(
          _communityId,
        ).overrideWith((ref) async => []),
        communityMemberDirectoryProvider(
          _communityId,
        ).overrideWith((ref) async => {}),
        userRankingsSummaryProvider.overrideWith((ref, userId) async {
          requested.add(userId);
          return rankings;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: CommunityCommentSheet(
            communityId: _communityId,
            postId: 'p1',
            initialPage: CommunityCommentPage(
              hasMore: false,
              items: [
                CommunityCommentModel(
                  id: 'c1',
                  authorId: authorId,
                  authorName: 'An',
                  body: 'Hello',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

int _ringColor(WidgetTester tester) {
  final outer = find
      .descendant(of: find.byType(RankAvatar), matching: find.byType(Container))
      .first;
  final deco = tester.widget<Container>(outer).decoration! as BoxDecoration;
  return deco.color!.toARGB32();
}

void main() {
  testWidgets('TC-RANK-RING-APP-40 comment author ring follows tier', (
    tester,
  ) async {
    final requested = <String>[];
    await _pumpSheet(
      tester,
      authorId: 'u1',
      rankings: const [_ranking],
      requested: requested,
    );
    expect(_ringColor(tester), _tierS);
    expect(requested, ['u1']);
  });

  testWidgets('TC-RANK-RING-APP-41 comment author ring is grey when unranked', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      authorId: 'u1',
      rankings: const [],
      requested: <String>[],
    );
    expect(_ringColor(tester), _unranked);
  });

  testWidgets('TC-RANK-RING-APP-42 comment without author id calls no API', (
    tester,
  ) async {
    final requested = <String>[];
    await _pumpSheet(
      tester,
      authorId: '',
      rankings: const [_ranking],
      requested: requested,
    );
    expect(requested, isEmpty);
    expect(find.text('Hello'), findsOneWidget);
  });
}
