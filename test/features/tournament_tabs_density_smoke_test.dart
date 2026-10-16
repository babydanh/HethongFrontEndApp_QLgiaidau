import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _tournamentId = 'tab-density-fixture';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _fixtureTournament() => Tournament.fromJson({
  'name': 'Compact tabs fixture',
  'sport': 'badminton',
  'format': 'DOUBLES',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'visibility': 'PUBLIC',
  'creatorId': 'fixture-owner',
  'maxTeams': 8,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);

Tournament _divisionTransitionTournament() => Tournament.fromJson({
  'name': 'Division transition fixture',
  'sport': 'badminton',
  'format': 'SINGLES',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'visibility': 'PUBLIC',
  'creatorId': 'fixture-owner',
  'maxTeams': 16,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'divisions': [
    for (var index = 0; index < 2; index++)
      {
        'id': 'division-$index',
        'name': 'Division $index',
        'matchType': index.isEven ? 'SINGLES' : 'DOUBLES',
        'bracketType': 'single_elimination',
        'maxParticipants': 16,
        'participantCount': 2,
      },
  ],
}, _tournamentId);

List<MatchModel> _divisionTransitionMatches() {
  final match = _fixtureMatches().first;
  return [
    match.copyWith(id: 'division-zero-match', divisionId: 'division-0'),
    match.copyWith(id: 'division-one-match', divisionId: 'division-1'),
  ];
}

Future<void> _pumpDivisionTransitionScreen(
  WidgetTester tester, {
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/tournaments/$_tournamentId',
    routes: [
      GoRoute(
        path: '/tournaments/:id',
        builder: (context, state) {
          final screen = TournamentIntroScreen(
            tournamentId: state.pathParameters['id']!,
          );
          return disableAnimations
              ? MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: screen,
                )
              : screen;
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentIntroWithInviteProvider.overrideWith(
          (ref, params) async => _divisionTransitionTournament(),
        ),
        tournamentDivisionsProvider.overrideWith(
          (ref, tournamentId) async => const <Map<String, dynamic>>[],
        ),
        introTeamsProvider.overrideWith((ref, tournamentId) async => const []),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        matchesProvider.overrideWith(
          (ref, tournamentId) => Stream.value(_divisionTransitionMatches()),
        ),
        bracketMatchesProvider.overrideWith(
          (ref, tournamentId) => Stream.value(const <MatchModel>[]),
        ),
        tournamentResultProvider.overrideWith(
          (ref, params) => Stream.value({'awards': const []}),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: '', fullName: 'Guest'),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  final tabBar = find.byType(TabBar).first;
  for (var attempt = 0; attempt < 8; attempt++) {
    final viewport = tester.getRect(tabBar);
    final tabRect = tester.getRect(tab);
    if (tabRect.left >= viewport.left && tabRect.right <= viewport.right) {
      break;
    }
    await tester.drag(
      tabBar,
      Offset(tabRect.left < viewport.left ? 300 : -300, 0),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(tab);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  expect(tester.takeException(), isNull, reason: 'tab: $label');
}

List<Team> _fixtureTeams() => [
  Team(
    id: 'team-alpha-beta',
    name: 'Player Alpha / Player Beta',
    members: const ['Player Alpha', 'Player Beta'],
    group: 'Division Alpha',
    divisionId: 'division-alpha',
    createdAt: DateTime(2026, 1, 1),
  ),
];

List<MatchModel> _fixtureMatches() => [
  MatchModel(
    id: 'live-match',
    tournamentId: _tournamentId,
    round: 1,
    matchNumber: 1,
    team1Id: 'team-gamma',
    team2Id: 'team-delta',
    team1Name: 'Player Gamma',
    team2Name: 'Player Delta',
    status: 'in_progress',
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
  MatchModel(
    id: 'completed-match',
    tournamentId: _tournamentId,
    round: 1,
    matchNumber: 2,
    team1Id: 'team-epsilon',
    team2Id: 'team-zeta',
    team1Name: 'Player Epsilon',
    team2Name: 'Player Zeta',
    score1: 2,
    score2: 1,
    winnerId: 'team-epsilon',
    loserId: 'team-zeta',
    status: 'completed',
    bracketPosition: const BracketPosition(round: 1, position: 2),
    completedAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  ),
];

void _registerDivisionTransitionTests() {
  testWidgets('changing a live division animates its expansion', (
    tester,
  ) async {
    await _pumpDivisionTransitionScreen(tester);
    await _openTab(tester, 'Đang diễn ra');
    expect(find.byType(LiveTab), findsOneWidget);

    final targetDivision = find.text('Division 1');
    expect(targetDivision.hitTestable(), findsOneWidget);
    final divisionRow = find
        .ancestor(
          of: targetDivision,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.margin == const EdgeInsets.only(bottom: 4),
          ),
        )
        .first;
    final expansion = find.descendant(
      of: divisionRow,
      matching: find.byType(AnimatedCrossFade),
    );
    final collapsedHeight = tester.getSize(expansion).height;

    await tester.tap(targetDivision);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final intermediateHeight = tester.getSize(expansion).height;
    await tester.pump(const Duration(milliseconds: 160));
    final expandedHeight = tester.getSize(expansion).height;

    expect(intermediateHeight, greaterThan(collapsedHeight));
    expect(expandedHeight, greaterThan(intermediateHeight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('division expansion respects reduced motion', (tester) async {
    await _pumpDivisionTransitionScreen(tester, disableAnimations: true);
    await _openTab(tester, 'Đang diễn ra');
    expect(find.byType(LiveTab), findsOneWidget);

    final targetDivision = find.text('Division 1');
    final divisionRow = find
        .ancestor(
          of: targetDivision,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.margin == const EdgeInsets.only(bottom: 4),
          ),
        )
        .first;
    final expansion = find.descendant(
      of: divisionRow,
      matching: find.byType(AnimatedCrossFade),
    );

    await tester.tap(targetDivision);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final immediateHeight = tester.getSize(expansion).height;
    await tester.pump(const Duration(milliseconds: 300));
    final finalHeight = tester.getSize(expansion).height;

    expect(immediateHeight, closeTo(finalHeight, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical scrolling reverses after division selection', (
    tester,
  ) async {
    await _pumpDivisionTransitionScreen(tester);
    await _openTab(tester, 'Đang diễn ra');
    expect(find.byType(LiveTab), findsOneWidget);

    final targetDivision = find.text('Division 1');
    expect(targetDivision.hitTestable(), findsOneWidget);
    await tester.tap(targetDivision);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final outerScrollable = find
        .descendant(
          of: find.byType(NestedScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = tester.state<ScrollableState>(outerScrollable).position;
    expect(position.axisDirection, AxisDirection.down);
    final beforeScroll = position.pixels;

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -180));
    await tester.pump(const Duration(milliseconds: 250));
    final scrolledDown = position.pixels;
    expect(scrolledDown, greaterThan(beforeScroll));

    await tester.drag(find.byType(NestedScrollView), const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 250));
    final scrolledUp = position.pixels;
    expect(scrolledUp, lessThan(scrolledDown));
    expect(tester.takeException(), isNull);
  });
}

void main() {
  testWidgets('compact tournament tabs render their existing fixture data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/tournaments/$_tournamentId',
      routes: [
        GoRoute(
          path: '/tournaments/:id',
          builder: (context, state) =>
              TournamentIntroScreen(tournamentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/live/:matchId',
          builder: (context, state) => Scaffold(
            body: Text(
              'Opened match: ${state.pathParameters['matchId']} '
              'in ${state.uri.queryParameters['tournamentId']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentIntroWithInviteProvider.overrideWith(
            (ref, params) async => _fixtureTournament(),
          ),
          tournamentDivisionsProvider.overrideWith(
            (ref, tournamentId) async => const <Map<String, dynamic>>[],
          ),
          introTeamsProvider.overrideWith(
            (ref, tournamentId) async => _fixtureTeams(),
          ),
          followedTournamentsProvider.overrideWith((ref) async => const []),
          matchesProvider.overrideWith(
            (ref, tournamentId) => Stream.value(_fixtureMatches()),
          ),
          bracketMatchesProvider.overrideWith(
            (ref, tournamentId) => Stream.value(const <MatchModel>[]),
          ),
          tournamentResultProvider.overrideWith(
            (ref, params) => Stream.value({
              'awards': [
                {
                  'rank': 1,
                  'participant': {'teamName': 'Champion Alpha'},
                },
                {
                  'rank': 2,
                  'participant': {'teamName': 'Runner-up Beta'},
                },
                {
                  'rank': 3,
                  'participant': {'teamName': 'Bronze Gamma'},
                },
              ],
            }),
          ),
          authProvider.overrideWith(_GuestAuthNotifier.new),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(id: '', fullName: 'Guest'),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await _openTab(tester, 'Đang diễn ra');
    expect(find.text('Player Gamma'), findsOneWidget);
    expect(find.text('Player Delta'), findsOneWidget);

    await _openTab(tester, 'Kết quả');
    expect(find.text('Champion Alpha'), findsWidgets);

    await _openTab(tester, 'Danh sách đội');
    expect(find.text('Player Alpha / Player Beta'), findsOneWidget);

    await _openTab(tester, 'Lịch thi đấu');
    final unplacedCell = find.byKey(
      const ValueKey('schedule-unplaced-section'),
    );
    expect(
      find.descendant(
        of: unplacedCell,
        matching: find.textContaining('Player Epsilon'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: unplacedCell,
        matching: find.textContaining('Player Zeta'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
  _registerDivisionTransitionTests();
}
