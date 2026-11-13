<<<<<<< origin/main
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_post_composer_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _ringColor(
  WidgetTester tester,
  UserProfile profile, {
  List<PlayerRanking> rankings = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileProvider.overrideWith((ref) async => profile),
        userRankingsProvider.overrideWith((ref) async => rankings),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: CommunityPostComposerSheet(communityId: 'c1', authorName: 'An'),
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
  testWidgets('TC-RANK-RING-APP-20 composer author ring follows tier', (
    tester,
  ) async {
    final color = await _ringColor(
      tester,
      // /users/profile never carries eloPoints; the tier comes from rankings.
      const UserProfile(id: 'u'),
      rankings: const [
        PlayerRanking(
          id: 'r',
          userId: 'u',
          fullName: 'An',
          eloPoints: 1800,
          tierName: 'Tier S',
          matchesPlayed: 3,
        ),
      ],
    );
    expect(color, 0xFFFBBF24);
  });

  testWidgets('TC-RANK-RING-APP-21 composer author unranked ring is grey', (
    tester,
  ) async {
    final color = await _ringColor(tester, const UserProfile(id: 'u'));
    expect(color, 0xFFCBD5E1);
  });
}

||||||| 6510e896

=======
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_post_composer_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _ringColor(WidgetTester tester, UserProfile profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [userProfileProvider.overrideWith((ref) async => profile)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: CommunityPostComposerSheet(
            communityId: 'c1',
            authorName: 'An',
          ),
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
  testWidgets('TC-RANK-RING-APP-20 composer author ring follows tier', (
    tester,
  ) async {
    final color = await _ringColor(
      tester,
      const UserProfile(id: 'u', eloPoints: 1800, tierName: 'Tier S'),
    );
    expect(color, 0xFFFBBF24);
  });

  testWidgets('TC-RANK-RING-APP-21 composer author unranked ring is grey', (
    tester,
  ) async {
    final color = await _ringColor(tester, const UserProfile(id: 'u'));
    expect(color, 0xFFCBD5E1);
  });
}

>>>>>>> origin/cloud/danh3-app-vien-rank