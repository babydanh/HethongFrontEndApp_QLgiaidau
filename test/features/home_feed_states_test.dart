import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/home_skeletons.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/home/screens/home_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home match section shows card skeletons while loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    final gate = Completer<void>();

    await tester.pumpWidget(_homeApp(gate: gate, cardMatches: [_scrollMatch(0)]));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TournamentMatchesCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Loading match data...'), findsNothing);
    expect(tester.takeException(), isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TournamentMatchesCardSkeleton), findsNothing);
    expect(find.text('Home team 0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('home explore shows the whole page as skeleton until tournaments load', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    final tournaments = StreamController<List<Tournament>>();
    addTearDown(tournaments.close);

    await tester.pumpWidget(_homeApp(tournaments: tournaments.stream));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(HomeBannerSkeleton), findsOneWidget);
    expect(find.byType(TournamentMatchesCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The status tabs stay real so the user can switch while it loads.
    expect(find.text('Upcoming'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('home match error stays visible and retry refetches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    final repository = _FakeMatchRepository(const [])..failing = true;

    await tester.pumpWidget(_homeApp(repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load match data. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final before = repository.calls;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repository.calls, greaterThan(before));
    expect(
      find.text('Unable to load match data. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('home match section explains a successful empty result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('No upcoming matches'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('pull to refresh reloads the match feed', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    final repository = _FakeMatchRepository([_scrollMatch(0)]);

    await tester.pumpWidget(_homeApp(repository: repository));
    await tester.pumpAndSettle();
    final before = repository.calls;

    unawaited(
      tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator).first)
          .show(),
    );
    await tester.pumpAndSettle();
    // The feed waits one short beat before scanning, which settling skips.
    await tester.pump(const Duration(seconds: 1));

    expect(repository.calls, greaterThan(before));
    expect(find.text('Home team 0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('home keeps a successful scheduled match visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    final match = MatchModel(
      id: 'synthetic-match',
      tournamentId: _tournament.id,
      round: 1,
      matchNumber: 1,
      team1Id: 'team-alpha-id',
      team2Id: 'team-beta-id',
      team1Name: 'Team Alpha',
      team2Name: 'Team Beta',
      status: 'scheduled',
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime.utc(2026, 9, 27),
    );

    await tester.pumpWidget(
      _homeApp(cardMatches: [match]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team Alpha'), findsOneWidget);
    expect(find.text('Team Beta'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'home bỏ tiêu đề section và link "Xem tất cả", nội dung còn nguyên',
    (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        _homeApp(),
      );
      await tester.pumpAndSettle();

      // Người dùng yêu cầu bỏ cho gọn: "Giải đấu nổi bật" + "Xem tất cả" của nó,
      // và tiêu đề lịch thi đấu sắp diễn ra + "Xem tất cả" của nó.
      expect(find.text('Featured Tournaments'), findsNothing);
      expect(find.text('Upcoming Matches'), findsNothing);
      expect(find.text('View All'), findsNothing);

      // Bỏ tiêu đề không được nuốt mất nội dung của section.
      expect(find.text('Synthetic tournament'), findsWidgets);
      expect(find.text('No upcoming matches'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets('header animation does not rebuild active scroll content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final matches = List.generate(8, _scrollMatch);
    await tester.pumpWidget(
      _homeApp(cardMatches: matches),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upcoming').first);
    await tester.pumpAndSettle();
    expect(find.text('Home team 0'), findsOneWidget);

    final scrollView = find.byType(CustomScrollView).first;
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: scrollView, matching: find.byType(Scrollable)).first,
    );
    final initialScrollView = tester.widget<CustomScrollView>(scrollView);
    final headerBuilderFinder = find
        .ancestor(of: scrollView, matching: find.byType(AnimatedBuilder))
        .first;
    final headerAnimation =
        tester.widget<AnimatedBuilder>(headerBuilderFinder).animation
            as Animation<double>;

    expect(scrollable.position.maxScrollExtent, greaterThan(60));
    await tester.dragFrom(const Offset(180, 700), const Offset(0, -220));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(scrollable.position.pixels, greaterThan(60));
    expect(headerAnimation.value, greaterThan(0));
    final collapsedProgress = headerAnimation.value;
    await tester.dragFrom(const Offset(180, 700), const Offset(0, 220));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(scrollable.position.pixels, lessThanOrEqualTo(40));
    expect(headerAnimation.value, lessThan(collapsedProgress));
    expect(
      identical(tester.widget<CustomScrollView>(scrollView), initialScrollView),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('header sport filter lists sports on the very first tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      _homeApp(),
    );
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Pickleball'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _homeApp({
  List<MatchModel> cardMatches = const [],
  _FakeMatchRepository? repository,
  Completer<void>? gate,
  Stream<List<Tournament>>? tournaments,
}) {
  final repo = repository ?? _FakeMatchRepository(cardMatches);
  repo.gate = gate;
  return ProviderScope(
    overrides: [
      matchRepositoryProvider.overrideWith((ref) => repo),
      authProvider.overrideWith(_PreviewAuthNotifier.new),
      tournamentsProvider.overrideWith(
        (ref) => tournaments ?? Stream.value([_tournament]),
      ),
      categoriesProvider.overrideWith(
        (ref) => Future.value([
          CategoryModel(
            id: 'sport-1',
            name: 'Pickleball',
            slug: 'pickleball',
            description: '',
            isActive: true,
          ),
        ]),
      ),
      communityDetailProvider.overrideWith((ref, id) async => _community),
      liveMatchesProvider.overrideWith(
        (ref, tournamentId) => Stream.value(const <MatchModel>[]),
      ),
      unreadCountProvider.overrideWith((ref) => Future.value(0)),
      regionRepositoryProvider.overrideWith((ref) => _FakeRegionRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(initialTab: 0),
    ),
  );
}

final _tournament = Tournament(
  id: 'synthetic-tournament',
  name: 'Synthetic tournament',
  sport: 'pickleball',
  format: 'single_elimination',
  bracketType: 'SINGLE_ELIMINATION',
  status: 'registration',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'synthetic-user',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  startDate: DateTime.utc(2026, 10, 1),
);
MatchModel _scrollMatch(int index) => MatchModel(
  id: 'scroll-match-$index',
  tournamentId: _tournament.id,
  round: 1,
  matchNumber: index + 1,
  team1Id: 'home-team-id-$index',
  team2Id: 'away-team-id-$index',
  team1Name: 'Home team $index',
  team2Name: 'Away team $index',
  status: 'scheduled',
  bracketPosition: BracketPosition(round: 1, position: index + 1),
  updatedAt: DateTime.utc(2026, 9, 27),
);

final _community = Community(id: 'synthetic-club', name: 'Synthetic club');

class _FakeMatchRepository extends Fake implements IMatchRepository {
  _FakeMatchRepository(this.matches);

  final List<MatchModel> matches;
  Completer<void>? gate;
  var failing = false;
  var calls = 0;

  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getTournamentMatchesPaged({
    required String tournamentId,
    String? status,
    String? cursor,
    int limit = 4,
    String? trigger,
  }) async {
    calls++;
    await gate?.future;
    if (failing) throw StateError('synthetic failure');
    return (
      matches: matches,
      nextCursor: null,
      hasMore: false,
      total: matches.length,
    );
  }
}

class _FakeRegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => const [];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async =>
      const [];

  @override
  Future<List<Region>> searchRegions(String query, {int limit = 10}) async =>
      const [];
}

class _PreviewAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.viewer,
    tokenCode: 'synthetic-token',
  );

  @override
  Future<void> init() async {}
}
