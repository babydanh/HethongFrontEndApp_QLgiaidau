import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/podium_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

final _categories = [
  CategoryModel(
    id: 'cat-pickleball',
    name: 'Pickleball',
    slug: 'pickleball',
    description: '',
    isActive: true,
  ),
];

const _pairNoTeam = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'Nguyen Alpha',
  matchType: 'DOUBLES',
  rank: 1,
  players: [
    ParticipantPlayer(slot: 1, userId: 'u1', fullName: 'Nguyen Alpha'),
    ParticipantPlayer(slot: 2, userId: 'u2', fullName: 'Tran Beta'),
  ],
);

const _pairWithTeam = PlayerRanking(
  id: 'r2',
  userId: 'u3',
  fullName: 'Le Gamma',
  matchType: 'DOUBLES',
  rank: 2,
  teamName: 'Doi Sao Bang',
  players: [
    ParticipantPlayer(slot: 1, userId: 'u3', fullName: 'Le Gamma'),
    ParticipantPlayer(slot: 2, userId: 'u4', fullName: 'Pham Delta'),
  ],
);

Future<void> _pumpLeaderboard(WidgetTester tester, String searchQuery) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_GuestAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: 'user-1', fullName: 'Alex'),
        ),
        categoriesProvider.overrideWith((ref) async => _categories),
        footballTeamRankingsProvider.overrideWith((ref, categoryId) async => []),
        rankingsProvider.overrideWith(
          (ref, query) async => [_pairNoTeam, _pairWithTeam],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: LeaderboardScreen(standalone: true, searchQuery: searchQuery),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('search by the second player keeps the pair in the list', (
    tester,
  ) async {
    await _pumpLeaderboard(tester, 'tran beta');

    expect(find.text('Nguyen Alpha / Tran Beta'), findsWidgets);
    expect(find.text('Doi Sao Bang'), findsNothing);
  });

  testWidgets('search by team name keeps the team and drops the other', (
    tester,
  ) async {
    await _pumpLeaderboard(tester, 'sao bang');

    expect(find.text('Doi Sao Bang'), findsWidgets);
    expect(find.text('Nguyen Alpha / Tran Beta'), findsNothing);
  });

  testWidgets('search by the player of a named team keeps that team', (
    tester,
  ) async {
    await _pumpLeaderboard(tester, 'pham delta');

    expect(find.text('Doi Sao Bang'), findsWidgets);
  });

  testWidgets('search matching nothing shows the empty state', (tester) async {
    await _pumpLeaderboard(tester, 'khong ai ten nhu vay');

    expect(find.text('Nguyen Alpha / Tran Beta'), findsNothing);
    expect(find.text('Doi Sao Bang'), findsNothing);
    expect(find.byIcon(Icons.person_search_rounded), findsOneWidget);
  });

  testWidgets('podium shows both players of a pair without a team name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: PodiumView(rankings: [_pairNoTeam], formatLabel: 'Đôi'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nguyen Alpha / Tran Beta'), findsOneWidget);
  });
}
