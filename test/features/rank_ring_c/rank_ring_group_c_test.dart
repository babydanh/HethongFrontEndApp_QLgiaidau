import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/user_ranking_detail_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/podium_view.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/user_stats_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _tierSRing = Color(0xFFFBBF24);

const _tierS = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'An Nguyen',
  eloPoints: 1850,
  tierName: 'Tier S',
  matchesPlayed: 5,
  rank: 1,
);

class _AuthedAuth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer);
}

Color _ringOf(WidgetTester tester, Finder avatar) {
  final outer = find
      .descendant(of: avatar, matching: find.byType(Container))
      .first;
  final box = tester.widget<Container>(outer).decoration! as BoxDecoration;
  return box.color!;
}

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: home,
      ),
    );

void main() {
  testWidgets('TC-RANK-RING-APP-C01 podium avatar uses tier ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SingleChildScrollView(child: PodiumView(rankings: [_tierS])),
        ),
      ),
    );
    expect(_ringOf(tester, find.byType(RankAvatar).first), _tierSRing);
  });

  testWidgets('TC-RANK-RING-APP-C02 user stats card avatar uses tier ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const Scaffold(body: UserStatsCard(ranking: _tierS))),
    );
    expect(_ringOf(tester, find.byType(RankAvatar)), _tierSRing);
  });

  testWidgets('TC-RANK-RING-APP-C03 ELO history header uses tier ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const EloHistoryScreen(
          userId: 'u1',
          userName: 'An Nguyen',
          currentElo: 1850,
          tierName: 'Tier S',
        ),
        overrides: [eloHistoryProvider.overrideWith((ref, q) async => [])],
      ),
    );
    await tester.pumpAndSettle();
    expect(_ringOf(tester, find.byType(RankAvatar)), _tierSRing);
  });

  testWidgets('TC-RANK-RING-APP-C04 menu avatar uses my best ranking', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(body: AppMenuSheet(onNavigate: (_) {})),
        overrides: [
          authProvider.overrideWith(_AuthedAuth.new),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(id: 'u1', fullName: 'An Nguyen'),
          ),
          myBestRankingProvider.overrideWithValue(_tierS),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(_ringOf(tester, find.byType(RankAvatar)), _tierSRing);
  });

  testWidgets('TC-RANK-RING-APP-C05 live match member avatar uses tier ring', (
    tester,
  ) async {
    final match = MatchModel(
      id: 'm',
      round: 1,
      matchNumber: 1,
      status: 'COMPLETED',
      team1Name: 'An Nguyen',
      team2Name: 'Binh Tran',
      bracketPosition: const BracketPosition(round: 1, position: 1),
      team1MemberInfos: const [
        MatchMemberInfo(
          userId: 'u1',
          fullName: 'An Nguyen',
          eloPoints: 1850,
          tierName: 'Tier S',
        ),
      ],
      team2MemberInfos: const [
        MatchMemberInfo(userId: 'u2', fullName: 'Binh Tran'),
      ],
      updatedAt: DateTime(2026, 11, 1),
    );
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SizedBox(
            width: 360,
            child: SingleChildScrollView(child: LiveMatchCardV2(match: match)),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_ringOf(tester, find.byType(RankAvatar).first), _tierSRing);
  });

  testWidgets('TC-RANK-RING-APP-C06 ranking detail avatar uses tier ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const UserRankingDetailScreen(),
        overrides: [
          userRankingsProvider.overrideWith((ref) async => [_tierS]),
          myBestRankingProvider.overrideWithValue(_tierS),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(_ringOf(tester, find.byType(RankAvatar)), _tierSRing);
  });
}
