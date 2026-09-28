import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/tournament_avatar.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/home/widgets/global_search_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _categoryId = '1e7d7ef1-8d31-4a62-9cb2-3a57a80ad7a2';

final _category = CategoryModel(
  id: _categoryId,
  name: 'Badminton',
  slug: 'badminton',
  description: '',
  isActive: true,
);

class _SearchTournamentRepository extends Fake
    implements ITournamentRepository {
  _SearchTournamentRepository({this.tournaments = const [], this.fail = false});

  final List<Tournament> tournaments;
  bool fail;
  final requestedCategoryIds = <String?>[];

  @override
  Future<({List<Tournament> tournaments, String? nextCursor, bool hasMore})>
  getPublicTournamentsPaged({
    String? cursor,
    int limit = 6,
    String? categoryId,
    String? status,
    String? search,
    String? bracketType,
    bool? isRanked,
    String? region,
    DateTime? startDate,
    DateTime? endDate,
    bool rethrowOnError = false,
  }) async {
    requestedCategoryIds.add(categoryId);
    if (fail) throw StateError('synthetic request failure');
    return (tournaments: tournaments, nextCursor: null, hasMore: false);
  }
}

class _SearchMatchRepository extends Fake implements IMatchRepository {
  _SearchMatchRepository({this.matches = const []});

  final List<MatchModel> matches;
  final requestedCategoryIds = <String?>[];

  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getPublicMatchesPaged({
    String? cursor,
    int limit = 10,
    String? search,
    String? categoryId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    requestedCategoryIds.add(categoryId);
    return (
      matches: matches,
      nextCursor: null,
      hasMore: false,
      total: matches.length,
    );
  }
}

Tournament _tournament(
  String name, {
  String status = 'draft',
  String sport = 'badminton',
  String? logoUrl,
  String? bannerUrl,
  String? communityLogoUrl,
  DateTime? startDate,
  String? venueName,
  String? city,
}) => Tournament(
  id: 'tournament-1',
  name: name,
  sport: sport,
  format: 'singles',
  bracketType: 'single_elimination',
  status: status,
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'creator-1',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  logoUrl: logoUrl,
  bannerUrl: bannerUrl,
  communityLogoUrl: communityLogoUrl,
  startDate: startDate,
  venueName: venueName,
  city: city,
);

MatchModel _match({
  String team1Name = 'Player Alpha',
  String team2Name = 'Player Beta',
  String status = 'scheduled',
  int score1 = 0,
  int score2 = 0,
  DateTime? completedAt,
  List<SetScore> sets = const [],
  String? tournamentName = 'Synthetic Open',
  String? team1LogoUrl,
  String? team2LogoUrl,
}) => MatchModel(
  id: 'match-1',
  tournamentId: 'tournament-1',
  round: 1,
  matchNumber: 1,
  team1Id: 'player-1',
  team2Id: 'player-2',
  team1Name: team1Name,
  team2Name: team2Name,
  team1LogoUrl: team1LogoUrl,
  team2LogoUrl: team2LogoUrl,
  score1: score1,
  score2: score2,
  sets: sets,
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026),
  completedAt: completedAt,
  tournamentName: tournamentName,
  sportKey: 'badminton',
);

Future<void> _pumpSearch(
  WidgetTester tester, {
  required int scope,
  required _SearchTournamentRepository tournamentRepository,
  required _SearchMatchRepository matchRepository,
  bool showFiltersInitially = false,
  bool withRouter = false,
  ThemeData? theme,
}) async {
  final searchScreen = GlobalSearchScreen(
    key: ValueKey(tournamentRepository),
    initialTabIndex: scope,
    initialQuery: '',
    showFiltersInitially: showFiltersInitially,
  );
  final app = withRouter
      ? _routerApp(searchScreen, theme ?? AppTheme.darkTheme)
      : MaterialApp(
          theme: theme ?? AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: searchScreen,
        );
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_category]),
        tournamentRepositoryProvider.overrideWithValue(tournamentRepository),
        matchRepositoryProvider.overrideWithValue(matchRepository),
      ],
      child: app,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _routerApp(Widget home, ThemeData theme) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: '/intro/:id',
        builder: (context, state) => Scaffold(
          body: Text('Tournament intro ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  return MaterialApp.router(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  testWidgets(
    'SportO fallback stays bounded when a search banner row is tall',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TournamentAvatar(
                      tournamentName: 'Tall result',
                      size: 144,
                      fillHeight: true,
                      borderRadius: BorderRadius.zero,
                      borderWidth: 0,
                    ),
                    const SizedBox(width: 12),
                    const SizedBox(width: 180, height: 280),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final avatarRect = tester.getRect(find.byType(TournamentAvatar));
      final fallbackRect = tester.getRect(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (widget) =>
                    widget is SvgPicture && widget.semanticsLabel == 'SportO',
              ),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(avatarRect.height, 280);
      expect(fallbackRect.size, const Size.square(144));
      expect(fallbackRect.center.dy, avatarRect.center.dy);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tournament banner overrides logos, uses SportO fallback, and hides chevron',
    (tester) async {
      const tournamentName = 'Synthetic Open Cup';
      final tournaments = _SearchTournamentRepository(
        tournaments: [
          _tournament(
            tournamentName,
            status: 'COMPLETED',
            logoUrl: 'https://invalid.example/logo.png',
            bannerUrl: 'https://invalid.example/banner.png',
            startDate: DateTime.utc(2026, 9, 25),
            venueName: 'Central Arena',
            city: 'Da Nang',
          ),
        ],
      );
      await _pumpSearch(
        tester,
        scope: 1,
        tournamentRepository: tournaments,
        matchRepository: _SearchMatchRepository(),
      );

      final avatar = tester.widget<TournamentAvatar>(
        find.byType(TournamentAvatar),
      );
      expect(avatar.imageUrl, 'https://invalid.example/banner.png');
      expect(avatar.size, 144);
      expect(avatar.fillHeight, isTrue);
      expect(avatar.borderRadius, BorderRadius.zero);
      expect(avatar.borderWidth, 0);
      final avatarRect = tester.getRect(find.byType(TournamentAvatar));
      final cardFinder = find
          .ancestor(
            of: find.byType(TournamentAvatar),
            matching: find.byType(Material),
          )
          .first;
      final cardRect = tester.getRect(cardFinder);
      expect(avatarRect.left, cardRect.left + 1);
      expect(avatarRect.top, cardRect.top + 1);
      expect(avatarRect.bottom, cardRect.bottom - 1);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SvgPicture && widget.semanticsLabel == 'SportO',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byType(TournamentAvatar), findsOneWidget);
      expect(find.text('Badminton'), findsOneWidget);
      expect(find.byTooltip('Badminton'), findsNothing);
      expect(find.text('Sep 25, 2026'), findsOneWidget);
      expect(find.textContaining('Central Arena'), findsOneWidget);
      final l10n = lookupAppLocalizations(const Locale('en'));
      final statusLabel = StatusHelper.getTournamentStatusLabel(
        'COMPLETED',
        l10n: l10n,
      );
      final statusFinder = find.text(statusLabel);
      expect(statusFinder, findsOneWidget);
      final badge = tester.widget<Container>(
        find.ancestor(of: statusFinder, matching: find.byType(Container)).first,
      );
      final expectedColor = Color.lerp(
        StatusHelper.getTournamentStatusColor(
          'COMPLETED',
          tester.element(statusFinder),
        ),
        Colors.black,
        0.35,
      );
      expect((badge.decoration as BoxDecoration).color, expectedColor);
      expect(tester.widget<Text>(statusFinder).style?.color, Colors.white);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('tapping a tournament card still opens its intro', (
    tester,
  ) async {
    final tournaments = _SearchTournamentRepository(
      tournaments: [_tournament('Navigable Tournament')],
    );
    await _pumpSearch(
      tester,
      scope: 1,
      tournamentRepository: tournaments,
      matchRepository: _SearchMatchRepository(),
      withRouter: true,
    );

    await tester.tap(find.text('Navigable Tournament'));
    await tester.pumpAndSettle();

    expect(find.text('Tournament intro tournament-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('status chip remains readable with the light theme', (
    tester,
  ) async {
    final tournaments = _SearchTournamentRepository(
      tournaments: [_tournament('Light Theme Cup', status: 'COMPLETED')],
    );
    await _pumpSearch(
      tester,
      scope: 1,
      tournamentRepository: tournaments,
      matchRepository: _SearchMatchRepository(),
      theme: AppTheme.lightTheme,
    );

    final l10n = lookupAppLocalizations(const Locale('en'));
    final statusLabel = StatusHelper.getTournamentStatusLabel(
      'COMPLETED',
      l10n: l10n,
    );
    final statusFinder = find.text(statusLabel);
    expect(statusFinder, findsOneWidget);
    final badge = tester.widget<Container>(
      find.ancestor(of: statusFinder, matching: find.byType(Container)).first,
    );
    final expectedColor = Color.lerp(
      StatusHelper.getTournamentStatusColor(
        'COMPLETED',
        tester.element(statusFinder),
      ),
      Colors.black,
      0.35,
    );
    expect((badge.decoration as BoxDecoration).color, expectedColor);
    expect(tester.widget<Text>(statusFinder).style?.color, Colors.white);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long tournament text stays within narrow cards', (tester) async {
    const tournamentName =
        'Synthetic International Doubles Tournament Championship';
    const venue =
        'Central Indoor Sports Complex North District Competition Hall';
    final tournaments = _SearchTournamentRepository(
      tournaments: [
        _tournament(
          tournamentName,
          status: 'UPCOMING',
          venueName: venue,
          city: 'Da Nang Metropolitan Area',
        ),
      ],
    );
    await _pumpSearch(
      tester,
      scope: 1,
      tournamentRepository: tournaments,
      matchRepository: _SearchMatchRepository(),
    );

    final titleFinder = find.text(tournamentName);
    final locationFinder = find.textContaining(venue);
    expect(
      tester.renderObject<RenderParagraph>(titleFinder).didExceedMaxLines,
      isTrue,
    );
    expect(
      tester.renderObject<RenderParagraph>(locationFinder).didExceedMaxLines,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown tournament values use safe fallbacks', (tester) async {
    const tournamentName = 'Fallback Tournament';
    const unknownStatus = 'UNRECOGNIZED_STATUS';
    final tournaments = _SearchTournamentRepository(
      tournaments: [
        _tournament(
          tournamentName,
          sport: 'unknown-sport-key',
          status: unknownStatus,
          logoUrl: 'https://invalid.example/logo.png',
          communityLogoUrl: 'https://invalid.example/community.png',
        ),
      ],
    );
    await _pumpSearch(
      tester,
      scope: 1,
      tournamentRepository: tournaments,
      matchRepository: _SearchMatchRepository(),
    );

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(tournamentName), findsOneWidget);
    expect(
      find.text(
        StatusHelper.getTournamentStatusLabel(unknownStatus, l10n: l10n),
      ),
      findsOneWidget,
    );
    expect(find.byType(TournamentAvatar), findsOneWidget);
    final avatar = tester.widget<TournamentAvatar>(
      find.byType(TournamentAvatar),
    );
    expect(avatar.imageUrl, isNull);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SvgPicture && widget.semanticsLabel == 'SportO',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tournament category filter uses its canonical ID and renders rows',
    (tester) async {
      final tournaments = _SearchTournamentRepository(
        tournaments: [_tournament('Synthetic Open Cup')],
      );
      await _pumpSearch(
        tester,
        scope: 1,
        tournamentRepository: tournaments,
        matchRepository: _SearchMatchRepository(),
      );

      expect(find.text('Synthetic Open Cup'), findsOneWidget);
      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      expect(chips.take(3).every((chip) => chip.avatar == null), isTrue);
      expect(
        chips.take(3).every((chip) => chip.shape is StadiumBorder),
        isTrue,
      );
      expect(chips.first.selected, isTrue);

      await tester.tap(find.byIcon(Icons.tune_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Badminton').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      expect(tournaments.requestedCategoryIds.last, _categoryId);
    },
  );

  testWidgets(
    'match response rows are visible and use the selected category ID',
    (tester) async {
      final matches = _SearchMatchRepository(matches: [_match()]);
      await _pumpSearch(
        tester,
        scope: 0,
        tournamentRepository: _SearchTournamentRepository(),
        matchRepository: matches,
      );

      expect(find.text('Player Alpha'), findsOneWidget);
      expect(find.text('Player Beta'), findsOneWidget);

      final avatars = find.byType(TournamentAvatar);
      expect(avatars, findsNWidgets(2));
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      final firstAvatar = tester.widget<TournamentAvatar>(avatars.first);
      expect(firstAvatar.borderRadius, isNull);
      expect(
        find.descendant(of: avatars.first, matching: find.byType(ClipOval)),
        findsOneWidget,
      );
      expect(find.text('Synthetic Open'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(
        tester.getRect(avatars.at(0)).center.dy,
        closeTo(tester.getRect(find.text('Player Alpha')).center.dy, 1.5),
      );
      expect(
        tester.getRect(avatars.at(1)).center.dy,
        closeTo(tester.getRect(find.text('Player Beta')).center.dy, 1.5),
      );

      await tester.tap(find.byIcon(Icons.tune_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Badminton').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      expect(matches.requestedCategoryIds.last, _categoryId);
    },
  );

  testWidgets('completed match scores stay paired with opponents', (
    tester,
  ) async {
    final matches = _SearchMatchRepository(
      matches: [
        _match(
          status: 'completed',
          score1: 2,
          score2: 1,
          completedAt: DateTime.utc(2026, 9, 25),
          sets: const [
            SetScore(score1: 21, score2: 18),
            SetScore(score1: 19, score2: 21),
          ],
        ),
      ],
    );
    await _pumpSearch(
      tester,
      scope: 0,
      tournamentRepository: _SearchTournamentRepository(),
      matchRepository: matches,
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('21–18  19–21'), findsOneWidget);
    expect(
      tester.getRect(find.text('2')).center.dy,
      closeTo(tester.getRect(find.text('Player Alpha')).center.dy, 1.5),
    );
    expect(
      tester.getRect(find.text('1')).center.dy,
      closeTo(tester.getRect(find.text('Player Beta')).center.dy, 1.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long match names stay compact on a narrow screen', (
    tester,
  ) async {
    const tournamentName =
        'Synthetic International Badminton Championship Open';
    const team1Name = 'North District Veteran Doubles Team Alpha';
    const team2Name = 'South District Veteran Doubles Team Bravo';
    final matches = _SearchMatchRepository(
      matches: [
        _match(
          tournamentName: tournamentName,
          team1Name: team1Name,
          team2Name: team2Name,
        ),
      ],
    );
    await _pumpSearch(
      tester,
      scope: 0,
      tournamentRepository: _SearchTournamentRepository(),
      matchRepository: matches,
    );

    expect(
      tester
          .renderObject<RenderParagraph>(find.text(tournamentName))
          .didExceedMaxLines,
      isTrue,
    );
    expect(
      tester
          .renderObject<RenderParagraph>(find.text(team1Name))
          .didExceedMaxLines,
      isTrue,
    );
    expect(
      tester
          .renderObject<RenderParagraph>(find.text(team2Name))
          .didExceedMaxLines,
      isTrue,
    );
    expect(find.byType(TournamentAvatar), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty success and request failure remain distinct', (
    tester,
  ) async {
    final tournaments = _SearchTournamentRepository();
    await _pumpSearch(
      tester,
      scope: 1,
      tournamentRepository: tournaments,
      matchRepository: _SearchMatchRepository(),
    );
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.homeGlobalSearchNoResultsQuestion), findsOneWidget);
    expect(find.text(l10n.homeGlobalSearchLoadFailed), findsNothing);

    final failed = _SearchTournamentRepository(fail: true);
    await _pumpSearch(
      tester,
      scope: 1,
      tournamentRepository: failed,
      matchRepository: _SearchMatchRepository(),
    );
    expect(find.text(l10n.homeGlobalSearchLoadFailed), findsOneWidget);
    expect(find.text(l10n.homeGlobalSearchNoResultsQuestion), findsNothing);

    failed.fail = false;
    await tester.tap(find.text(l10n.homeGlobalSearchRetry));
    await tester.pumpAndSettle();
    expect(find.text(l10n.homeGlobalSearchNoResultsQuestion), findsOneWidget);
    expect(failed.requestedCategoryIds, hasLength(2));
  });
}
