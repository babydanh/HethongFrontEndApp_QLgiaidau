import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const tierSRing = 0xFFFBBF24;
const unrankedRing = 0xFFCBD5E1;

/// `u1` is Tier S (elo 1850), `u2` has no ranking.
const tierSRanking = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'An',
  eloPoints: 1850,
  tierName: 'Tier S',
  matchesPlayed: 5,
  categoryId: 'c',
  categoryName: 'Cat',
);

Future<void> pumpRanked(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        userRankingsSummaryProvider(
          'u1',
        ).overrideWith((ref) async => const [tierSRanking]),
        userRankingsSummaryProvider('u2').overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Fill colour of the outermost Container under [avatar] (RankAvatar's ring).
int ringOf(WidgetTester tester, Finder avatar) {
  final outer = find
      .descendant(of: avatar, matching: find.byType(Container))
      .first;
  final deco = tester.widget<Container>(outer).decoration! as BoxDecoration;
  return deco.color!.toARGB32();
}
