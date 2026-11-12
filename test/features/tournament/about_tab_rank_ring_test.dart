import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/ranked_user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/about_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _unranked = 0xFFCBD5E1;
const _tierS = 0xFFFBBF24;

const _ranking = PlayerRanking(
  id: 'r1',
  userId: 'creator-1',
  fullName: 'An',
  eloPoints: 1800,
  tierName: 'Tier S',
  matchesPlayed: 5,
  categoryId: 'c',
  categoryName: 'Cat',
);

Future<void> _pump(
  WidgetTester tester,
  List<PlayerRanking> rankings,
  List<String> requested,
) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final now = DateTime(2026, 1, 1);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
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
          body: AboutTab(
            tournament: Tournament(
              id: 't1',
              name: 'Giai',
              sport: 'pickleball',
              format: 'single_elimination',
              bracketType: 'single_elimination',
              adminToken: 'a',
              refereeToken: 'r',
              viewerToken: 'v',
              creatorId: 'creator-1',
              creatorFullName: 'An',
              contactInfo: const {'hidden': false},
              createdAt: now,
              updatedAt: now,
            ),
            teamCount: 0,
            resolveImageUrl: (url) => url ?? '',
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
  testWidgets('TC-RANK-RING-APP-43 organizer avatar ring follows tier', (
    tester,
  ) async {
    final requested = <String>[];
    await _pump(tester, const [_ranking], requested);
    expect(find.byType(RankedUserAvatarTap), findsWidgets);
    expect(_ringColor(tester), _tierS);
    expect(requested.toSet(), {'creator-1'});
  });

  testWidgets('TC-RANK-RING-APP-44 organizer avatar ring is grey unranked', (
    tester,
  ) async {
    await _pump(tester, const [], <String>[]);
    expect(_ringColor(tester), _unranked);
  });
}
