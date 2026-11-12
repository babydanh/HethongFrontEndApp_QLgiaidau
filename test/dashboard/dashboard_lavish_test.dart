import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/dashboard/screens/dashboard_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer);
}

class _Workspace extends MyTournamentWorkspaceNotifier {
  _Workspace(this.onRefresh, {this.fail = false});
  final void Function() onRefresh;
  final bool fail;

  @override
  Future<TournamentWorkspace> build() async {
    if (fail) throw Exception('boom');
    return TournamentWorkspace.empty;
  }

  @override
  Future<void> refresh() async {
    onRefresh();
    state = const AsyncData(TournamentWorkspace.empty);
  }
}

const _profile = UserProfile(
  id: 'u1',
  fullName: 'Nguyen An',
  email: 'an@example.com',
);

const _rank = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'Nguyen An',
  eloPoints: 1360,
  tierName: 'Gold',
  rank: 2,
  matchesPlayed: 8,
  matchesWon: 6,
  categoryId: 'badminton',
  categoryName: 'Badminton',
  peakElo: 1410,
);

Future<void> _pump(
  WidgetTester tester, {
  Object? profileError,
  Object? rankingsError,
  List<PlayerRanking> rankings = const [_rank],
  bool workspaceFails = false,
  void Function()? onProfile,
  void Function()? onRankings,
  void Function()? onTeams,
  void Function()? onWorkspace,
  ThemeData? theme,
  Size size = const Size(800, 1600),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final overrides = <Override>[
    authProvider.overrideWith(_Auth.new),
    userProfileProvider.overrideWith((ref) async {
      onProfile?.call();
      if (profileError != null) throw profileError;
      return _profile;
    }),
    userRankingsProvider.overrideWith((ref) async {
      onRankings?.call();
      if (rankingsError != null) throw rankingsError;
      return rankings;
    }),
    myFootballTeamsProvider.overrideWith((ref) async {
      onTeams?.call();
      return const <FootballTeamSummary>[];
    }),
    categoriesProvider.overrideWith((ref) async => const []),
    followedTournamentsProvider.overrideWith((ref) async => const []),
    myTournamentWorkspaceProvider.overrideWith(
      () => _Workspace(onWorkspace ?? () {}, fail: workspaceFails),
    ),
  ];
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const DashboardScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 400));
}

const _streakRank = PlayerRanking(
  id: 'r2',
  userId: 'u1',
  fullName: 'Nguyen An',
  eloPoints: 1360,
  rank: 2,
  matchesPlayed: 8,
  matchesWon: 6,
  categoryId: 'badminton',
  categoryName: 'Cầu lông đơn nam nâng cao',
  currentStreakType: 'WIN',
  currentStreakCount: 12,
);

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  testWidgets('overview renders ELO number and the 4 stats from data', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Nguyen An'), findsOneWidget);
    expect(find.text('1360 ELO'), findsOneWidget);
    expect(find.byType(LavishStatGrid), findsOneWidget);
    for (final v in ['8', '6', '75%', '1410']) {
      expect(find.text(v), findsWidgets, reason: v);
    }
    expect(tester.takeException(), isNull);
    await _end(tester);
  });

  testWidgets('dark theme renders without overflow', (tester) async {
    await _pump(tester, theme: AppTheme.darkTheme);
    expect(find.text('1360 ELO'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _end(tester);
  });

  testWidgets('rankings empty shows LavishEmptyState', (tester) async {
    await _pump(tester, rankings: const []);
    expect(find.byType(LavishEmptyState), findsOneWidget);
    expect(find.byType(LavishErrorState), findsNothing);
    await _end(tester);
  });

  testWidgets('rankings error shows LavishErrorState with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      rankingsError: Exception('x'),
      onRankings: () => calls++,
    );
    expect(find.byType(LavishErrorState), findsOneWidget);
    expect(find.byType(LavishEmptyState), findsNothing);
    final before = calls;
    await tester.tap(find.text('Thử lại'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, greaterThan(before));
    await _end(tester);
  });

  testWidgets('profile error shows LavishErrorState', (tester) async {
    await _pump(tester, profileError: Exception('x'));
    expect(find.byType(LavishErrorState), findsWidgets);
    await _end(tester);
  });

  for (final tab in ['Hoạt động', 'Quản lý']) {
    testWidgets('$tab tab: workspace error shows LavishErrorState', (
      tester,
    ) async {
      await _pump(tester, workspaceFails: true);
      await tester.tap(find.text(tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LavishErrorState), findsWidgets);
      await _end(tester);
    });
  }

  testWidgets('Quản lý tab: no tournaments shows LavishEmptyState', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Quản lý'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LavishEmptyState), findsOneWidget);
    await _end(tester);
  });

  testWidgets('pull to refresh reloads profile, rankings, teams, workspace', (
    tester,
  ) async {
    var profile = 0, rankings = 0, teams = 0, workspace = 0;
    await _pump(
      tester,
      onProfile: () => profile++,
      onRankings: () => rankings++,
      onTeams: () => teams++,
      onWorkspace: () => workspace++,
    );
    final p0 = profile, r0 = rankings, t0 = teams, w0 = workspace;

    unawaited(
      tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator).first)
          .show(),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(profile, greaterThan(p0));
    expect(rankings, greaterThan(r0));
    expect(teams, greaterThan(t0));
    expect(workspace, greaterThan(w0));
    await _end(tester);
  });

  testWidgets('ranking row trailing does not overflow at 320dp and 2x text', (
    tester,
  ) async {
    await _pump(
      tester,
      rankings: const [_streakRank],
      size: const Size(320, 700),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await _end(tester);
  });

  testWidgets(
    'TC-RANK-RING-APP-50 profile row ring uses the best rank, not /users/profile',
    (tester) async {
      // Arrange: /users/profile never carries eloPoints/tierName.
      await _pump(
        tester,
        rankings: const [
          PlayerRanking(
            id: 'r9',
            userId: 'u1',
            fullName: 'Nguyen An',
            eloPoints: 1850,
            tierName: 'Tier S',
            matchesPlayed: 9,
          ),
        ],
      );
      // Act
      final ring = find
          .descendant(
            of: find.byType(RankAvatar).first,
            matching: find.byType(Container),
          )
          .first;
      final deco = tester.widget<Container>(ring).decoration! as BoxDecoration;
      // Assert
      expect(deco.color, const Color(0xFFFBBF24));
      await _end(tester);
    },
  );
}
