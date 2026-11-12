import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/dashboard/screens/dashboard_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_progress_card.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _unranked = Color(0xFFCBD5E1);
const _tierSRing = Color(0xFFFBBF24);

class _GuestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

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
  testWidgets('TC-RANK-RING-APP-10 EloProgressCard ring uses tier color', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: EloProgressCard(
            userName: 'An',
            rankings: [
              PlayerRanking(
                id: 'r',
                userId: 'u',
                fullName: 'An',
                eloPoints: 1850,
                tierName: 'Tier S',
                matchesPlayed: 5,
                categoryId: 'c',
                categoryName: 'Cat',
              ),
            ],
          ),
        ),
      ),
    );
    expect(_ringOf(tester, find.byType(RankAvatar)), _tierSRing);
  });

  testWidgets('TC-RANK-RING-APP-11 EloProgressCard unranked ring is gray', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: EloProgressCard(userName: 'An', rankings: []),
        ),
      ),
    );
    expect(_ringOf(tester, find.byType(RankAvatar)), _unranked);
  });

  testWidgets('TC-RANK-RING-APP-12 leaderboard rows ring by tier / unranked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const LeaderboardScreen(standalone: true),
        overrides: [
          authProvider.overrideWith(_GuestAuth.new),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(id: 'x', fullName: 'X'),
          ),
          categoriesProvider.overrideWith(
            (ref) async => [
              CategoryModel(
                id: 'cat',
                name: 'Pickleball',
                slug: 'pickleball',
                description: '',
                isActive: true,
              ),
            ],
          ),
          footballTeamRankingsProvider.overrideWith(
            (ref, categoryId) async => [],
          ),
          rankingsProvider.overrideWith(
            (ref, query) async => const [
              PlayerRanking(
                id: 'a',
                userId: 'a',
                fullName: 'Top',
                eloPoints: 1850,
                tierName: 'Tier S',
                matchesPlayed: 9,
                rank: 1,
              ),
              PlayerRanking(
                id: 'b',
                userId: 'b',
                fullName: 'Newbie',
                tierName: '',
                matchesPlayed: 0,
                rank: 2,
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final avatars = find.byType(RankAvatar);
    expect(avatars, findsNWidgets(2));
    expect(_ringOf(tester, avatars.at(0)), _tierSRing);
    expect(_ringOf(tester, avatars.at(1)), _unranked);
  });

  testWidgets('TC-RANK-RING-APP-13 dashboard profile row ring by tier', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        const DashboardScreen(),
        overrides: [
          authProvider.overrideWith(_AuthedAuth.new),
          userProfileProvider.overrideWith(
            // /users/profile never carries eloPoints; the tier comes from rankings.
            (ref) async => const UserProfile(id: 'p', fullName: 'Nguyen An'),
          ),
          userRankingsProvider.overrideWith(
            (ref) async => const [
              PlayerRanking(
                id: 'r',
                userId: 'p',
                fullName: 'Nguyen An',
                eloPoints: 1850,
                tierName: 'Tier S',
                matchesPlayed: 5,
              ),
            ],
          ),
          myFootballTeamsProvider.overrideWith((ref) async => const []),
          categoriesProvider.overrideWith((ref) async => const []),
          followedTournamentsProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(_ringOf(tester, find.byType(RankAvatar).first), _tierSRing);
    expect(tester.takeException(), isNull);
  });
}
