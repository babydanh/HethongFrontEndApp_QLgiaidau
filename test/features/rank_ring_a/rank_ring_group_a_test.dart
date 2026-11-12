import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_composer_trigger.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_post_card.dart';
import 'package:app_quanly_giaidau/features/community/widgets/user_rank_avatar.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tierS = 0xFFFBBF24;
const _unranked = 0xFFCBD5E1;
const _communityId = 'club-7';

const _tierSRanking = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'An',
  eloPoints: 1850,
  tierName: 'Tier S',
  matchesPlayed: 5,
  categoryId: 'c',
  categoryName: 'Cat',
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<PlayerRanking> rankings = const [_tierSRanking],
  List<String>? requested,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        userRankingsSummaryProvider.overrideWith((ref, userId) async {
          requested?.add(userId);
          return rankings;
        }),
        userRankingsProvider.overrideWith((ref) async => rankings),
        communityTagPresetsProvider(
          _communityId,
        ).overrideWith((ref) async => []),
        communityMemberDirectoryProvider(
          _communityId,
        ).overrideWith((ref) async => {}),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: child),
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
  testWidgets('TC-RANK-RING-APP-A01 feed post author ring follows tier', (
    tester,
  ) async {
    await _pump(
      tester,
      CommunityPostCard(
        post: CommunityPostModel(
          id: 'post-1',
          authorId: 'u1',
          authorName: 'An',
          text: 'Hello club',
        ),
        communityId: _communityId,
      ),
    );
    expect(_ringColor(tester), _tierS);
  });

  testWidgets('TC-RANK-RING-APP-A02 social participant ring follows tier', (
    tester,
  ) async {
    await _pump(tester, const SocialAvatar(name: 'An', userId: 'u1', size: 40));
    expect(_ringColor(tester), _tierS);
  });

  testWidgets('TC-RANK-RING-APP-A03 guest social avatar gets no ring', (
    tester,
  ) async {
    final requested = <String>[];
    await _pump(
      tester,
      const SocialAvatar(name: 'Khach', size: 40),
      requested: requested,
    );
    expect(find.byType(RankAvatar), findsNothing);
    expect(requested, isEmpty);
  });

  testWidgets('TC-RANK-RING-APP-A04 composer trigger shows my best tier', (
    tester,
  ) async {
    await _pump(
      tester,
      CommunityComposerTrigger(
        authorName: 'An',
        onOpen: () {},
        onOpenWithImage: () {},
      ),
    );
    expect(_ringColor(tester), _tierS);
  });

  testWidgets('TC-RANK-RING-APP-A05 payload elo is used without an API call', (
    tester,
  ) async {
    final requested = <String>[];
    await _pump(
      tester,
      const UserRankAvatar(
        userId: 'u1',
        name: 'An',
        elo: 1850,
        tierName: 'Tier S',
      ),
      rankings: const [],
      requested: requested,
    );
    expect(_ringColor(tester), _tierS);
    expect(requested, isEmpty);
  });

  testWidgets('TC-RANK-RING-APP-A06 unranked user keeps the grey ring', (
    tester,
  ) async {
    await _pump(
      tester,
      const UserRankAvatar(userId: 'u1', name: 'An'),
      rankings: const [],
    );
    expect(_ringColor(tester), _unranked);
  });
}
