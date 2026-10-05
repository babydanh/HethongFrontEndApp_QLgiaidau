import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _fixtureTournament() => Tournament.fromJson({
  'name': 'Schedule tab smoke fixture',
  'sport': 'pickleball',
  'format': 'DOUBLES',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'visibility': 'PUBLIC',
  'creatorId': 'fixture-owner',
  'maxTeams': 8,
  'venue': {'name': 'Sporto Arena', 'locationAddress': 'District 1'},
  'tournamentConfig': {
    'scheduleDate': '2026-08-12',
    'operatingStart': '08:00',
    'operatingEnd': '18:00',
    'stepMinutes': 15,
  },
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, 'schedule-fixture');

MatchModel _scheduleMatch(
  int matchNumber, {
  String? courtId,
  String? courtName,
  String court = '',
  String? team1Name,
  String? team2Name,
  String status = 'scheduled',
  DateTime? scheduledTime,
  int? durationMinutes,
}) => MatchModel(
  id: 'schedule-match-$matchNumber',
  round: 1,
  matchNumber: matchNumber,
  team1Name: team1Name ?? 'Player $matchNumber',
  team2Name: team2Name ?? 'Opponent $matchNumber',
  status: status,
  bracketPosition: BracketPosition(round: 1, position: matchNumber),
  court: court,
  courtId: courtId,
  courtName: courtName,
  scheduledTime: scheduledTime,
  updatedAt: DateTime.utc(2026, 1, 1),
  timeLimitMinutes: durationMinutes,
);

Future<void> _pumpTournamentDetail(
  WidgetTester tester, {
  required Locale locale,
  List<MatchModel> matches = const [],
  Stream<List<MatchModel>>? matchStream,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentIntroWithInviteProvider.overrideWith(
          (ref, params) async => _fixtureTournament(),
        ),
        tournamentDivisionsProvider.overrideWith(
          (ref, tournamentId) async => const <Map<String, dynamic>>[],
        ),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        introTeamsProvider.overrideWith((ref, tournamentId) async => const []),
        matchesProvider.overrideWith(
          (ref, tournamentId) => matchStream ?? Stream.value(matches),
        ),
        bracketMatchesProvider.overrideWith(
          (ref, tournamentId) => Stream.value(const []),
        ),
        authProvider.overrideWith(_UnauthenticatedNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: '', fullName: 'Guest'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const TournamentIntroScreen(tournamentId: 'schedule-fixture'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _matchCardSurface(String playerName) => find
    .ancestor(
      of: find.text(playerName),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    )
    .first;

Future<void> _scrollHorizontallyTo(
  WidgetTester tester,
  Finder target,
  Finder viewportFinder,
) async {
  final viewport = tester.getRect(viewportFinder);
  for (var attempt = 0; attempt < 10; attempt++) {
    final targetRect = tester.getRect(target);
    if (targetRect.left >= viewport.left &&
        targetRect.right <= viewport.right) {
      return;
    }
    final deltaX = targetRect.left < viewport.left ? 300.0 : -300.0;
    await tester.drag(viewportFinder, Offset(deltaX, 0));
    await tester.pumpAndSettle();
  }
}

Future<void> _tapTab(WidgetTester tester, Finder target) async {
  await _scrollHorizontallyTo(tester, target, find.byType(TabBar).first);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _tapStatusFilter(WidgetTester tester, Finder target) async {
  final scrollView = find
      .ancestor(of: target, matching: find.byType(SingleChildScrollView))
      .first;
  await _scrollHorizontallyTo(tester, target, scrollView);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _dragListUntilVisible(
  WidgetTester tester,
  Finder scrollable,
  String text,
) async {
  final target = find.text(text);
  for (
    var attempt = 0;
    attempt < 8 && target.hitTestable().evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(scrollable, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  testWidgets('schedule tab is last and opens the schedule page', (
    tester,
  ) async {
    await _pumpTournamentDetail(tester, locale: const Locale('vi'));

    final tabBar = tester.widget<TabBar>(find.byType(TabBar).first);
    expect((tabBar.tabs.last as Tab).text, 'Lịch thi đấu');

    final scheduleTab = find.widgetWithText(Tab, 'Lịch thi đấu');
    await _tapTab(tester, scheduleTab);

    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule stays selected when a live tab is inserted', (
    tester,
  ) async {
    final matchStream = StreamController<List<MatchModel>>.broadcast();
    addTearDown(matchStream.close);

    await _pumpTournamentDetail(
      tester,
      locale: const Locale('en'),
      matchStream: matchStream.stream,
    );
    matchStream.add(const []);
    await tester.pumpAndSettle();

    final scheduleTab = find.widgetWithText(Tab, 'Schedule');
    await _tapTab(tester, scheduleTab);

    matchStream.add([
      _scheduleMatch(
        1,
        status: 'live',
        scheduledTime: DateTime(2026, 8, 12, 8),
      ),
    ]);
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar).first);
    expect((tabBar.tabs.last as Tab).text, 'Schedule');
    expect(tabBar.controller?.index, tabBar.tabs.length - 1);
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlapping court matches use separate readable lanes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpTournamentDetail(
      tester,
      locale: const Locale('en'),
      matches: [
        _scheduleMatch(
          1,
          courtId: 'court-1',
          courtName: 'Court 1',
          scheduledTime: DateTime(2026, 8, 12, 8),
          durationMinutes: 45,
        ),
        _scheduleMatch(
          2,
          courtId: 'court-1',
          courtName: 'Court 1',
          scheduledTime: DateTime(2026, 8, 12, 8, 30),
          durationMinutes: 45,
        ),
        _scheduleMatch(
          3,
          courtId: 'court-1',
          courtName: 'Court 1',
          status: 'completed',
          scheduledTime: DateTime(2026, 8, 12, 10),
        ),
      ],
    );

    final scheduleTab = find.widgetWithText(Tab, 'Schedule');
    await _tapTab(tester, scheduleTab);

    final firstCard = tester.getRect(_matchCardSurface('Player 1'));
    final secondCard = tester.getRect(_matchCardSurface('Player 2'));
    expect(firstCard.overlaps(secondCard), isFalse);
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
    expect(find.text('0 - 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unplaced matches stay available in a collapsed section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpTournamentDetail(
      tester,
      locale: const Locale('en'),
      matches: [
        _scheduleMatch(17, scheduledTime: DateTime(2026, 8, 12, 12)),
        _scheduleMatch(
          18,
          courtId: 'court-unknown',
          court: 'Sporto Arena',
          scheduledTime: DateTime(2026, 8, 12, 13),
        ),
        _scheduleMatch(19),
      ],
    );
    final scheduleTab = find.widgetWithText(Tab, 'Schedule');
    await _tapTab(tester, scheduleTab);

    final section = find.text('Matches missing court/time (3)');
    expect(section, findsOneWidget);
    expect(find.text('Court not assigned'), findsNothing);

    final unplacedPanel = find.byKey(
      const ValueKey('schedule-unplaced-matches'),
    );
    final unplacedHeader = find.byKey(
      const ValueKey('schedule-unplaced-header'),
    );
    expect(unplacedHeader.hitTestable(), findsOneWidget);
    await tester.tap(unplacedHeader);
    await tester.pump();
    final collapsedPanelHeight = tester.getSize(unplacedPanel).height;
    await tester.pump(const Duration(milliseconds: 125));
    final transitioningPanelHeight = tester.getSize(unplacedPanel).height;
    await tester.pump(const Duration(milliseconds: 150));
    final expandedPanelHeight = tester.getSize(unplacedPanel).height;
    expect(transitioningPanelHeight, greaterThan(collapsedPanelHeight));
    expect(expandedPanelHeight, greaterThan(transitioningPanelHeight));
    await tester.pumpAndSettle();
    expect(find.text('Court not assigned'), findsOneWidget);

    final unplacedScrollable = find
        .descendant(of: unplacedPanel, matching: find.byType(Scrollable))
        .first;
    for (final text in [
      'Court not assigned',
      'Player 17',
      'Court name unavailable',
      'Player 18',
      'Not scheduled',
      'Player 19',
    ]) {
      await _dragListUntilVisible(tester, unplacedScrollable, text);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule tab label is localized in English', (tester) async {
    await _pumpTournamentDetail(tester, locale: const Locale('en'));

    expect(find.widgetWithText(Tab, 'Schedule'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule date and hours are localized in Vietnamese', (
    tester,
  ) async {
    await _pumpTournamentDetail(
      tester,
      locale: const Locale('vi'),
      matches: [
        _scheduleMatch(
          1,
          courtId: 'court-1',
          courtName: 'Sân 1',
          scheduledTime: DateTime(2026, 8, 12, 8),
        ),
      ],
    );

    final scheduleTab = find.widgetWithText(Tab, 'Lịch thi đấu');
    await _tapTab(tester, scheduleTab);

    expect(find.text('Giờ hoạt động: 08:00–18:00'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unplaced matches respect status and search filters', (
    tester,
  ) async {
    await _pumpTournamentDetail(
      tester,
      locale: const Locale('en'),
      matches: [
        _scheduleMatch(
          1,
          status: 'scheduled',
          scheduledTime: DateTime(2026, 8, 12, 12),
        ),
        _scheduleMatch(2, status: 'completed'),
        _scheduleMatch(3, status: 'live'),
      ],
    );

    final scheduleTab = find.widgetWithText(Tab, 'Schedule');
    await _tapTab(tester, scheduleTab);

    await _tapStatusFilter(tester, find.text('Scheduled (1)'));
    expect(find.text('Matches missing court/time (1)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schedule-unplaced-header')));
    await tester.pumpAndSettle();
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsNothing);
    expect(find.text('Player 3'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('schedule-unplaced-header')));
    await tester.pumpAndSettle();

    await _tapStatusFilter(tester, find.text('All (3)'));
    await tester.enterText(find.byType(TextField).first, 'Player 3');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Matches missing court/time (1)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schedule-unplaced-header')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    final unplacedPlayer = find.descendant(
      of: find.byKey(const ValueKey('schedule-unplaced-matches')),
      matching: find.text('Player 3'),
    );
    expect(unplacedPlayer, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('schedule-unplaced-matches')),
        matching: find.text('Player 1'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule filters and keeps navigation fixed while scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final matches = <MatchModel>[
      for (var court = 1; court <= 4; court++)
        for (var slot = 0; slot < 4; slot++)
          _scheduleMatch(
            (court - 1) * 4 + slot + 1,
            courtId: 'court-$court',
            courtName: 'Court $court',
            team1Name: court == 1 && slot == 0 ? 'SearchOnly Player' : null,
            status: court == 2 && slot == 0
                ? 'live'
                : court == 3 && slot == 0
                ? 'completed'
                : 'scheduled',
            scheduledTime: DateTime(2026, 8, 12, 8 + slot),
          ),
      _scheduleMatch(
        17,
        courtId: 'court-unknown',
        court: 'Sporto Arena',
        scheduledTime: DateTime(2026, 8, 12, 13),
      ),
      _scheduleMatch(
        18,
        court: 'Sporto Arena',
        scheduledTime: DateTime(2026, 8, 12, 14),
      ),
      _scheduleMatch(19),
    ];

    await _pumpTournamentDetail(
      tester,
      locale: const Locale('en'),
      matches: matches,
    );
    final scheduleTab = find.widgetWithText(Tab, 'Schedule');
    await _tapTab(tester, scheduleTab);
    for (
      var attempt = 0;
      attempt < 10 && find.byType(TextField).evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Court 1'), findsOneWidget);
    expect(find.textContaining('Court hours'), findsOneWidget);
    final liveFilter = find.text('Live (1)');
    await _tapStatusFilter(tester, liveFilter);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Player 5'), findsOneWidget);
    final completedFilter = find.text('Completed (1)');
    await _tapStatusFilter(tester, completedFilter);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Player 9'), findsOneWidget);
    expect(find.text('0 - 0'), findsOneWidget);

    final allFilter = find.text('All (19)');
    await _tapStatusFilter(tester, allFilter);
    await tester.pump(const Duration(milliseconds: 200));
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'SearchOnly Player');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Player 5'), findsNothing);
    expect(find.text('Opponent 1'), findsOneWidget);
    await tester.enterText(searchField, '');
    await tester.pump(const Duration(milliseconds: 200));

    final backButton = find.byIcon(Icons.arrow_back_ios_rounded).first;
    final backTopBeforeScroll = tester.getRect(backButton).top;
    for (final heading in ['Court 2', 'Court 3', 'Court 4']) {
      for (
        var attempt = 0;
        attempt < 8 && find.text(heading).evaluate().isEmpty;
        attempt++
      ) {
        await tester.dragFrom(const Offset(200, 450), const Offset(0, -800));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text(heading), findsOneWidget);
    }

    expect(tester.getRect(backButton).top, backTopBeforeScroll);

    expect(tester.takeException(), isNull);
  });
}
