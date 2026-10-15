import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
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

Tournament _fixtureTournament({
  int? minutesPerSet,
  bool withSponsor = false,
}) => Tournament.fromJson({
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
    'minutesPerSet': ?minutesPerSet,
  },
  if (withSponsor)
    'sponsors': [
      {
        'id': 'sponsor-1',
        'displayName': 'Fixture Sponsor',
        'logoUrl': 'https://example.com/sponsor.png',
        'isPublic': true,
      },
    ],
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
  durationMinutes: durationMinutes,
);

Future<void> _pumpTournamentDetail(
  WidgetTester tester, {
  required Locale locale,
  List<MatchModel> matches = const [],
  Stream<List<MatchModel>>? matchStream,
  int? minutesPerSet,
  bool withSponsor = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentIntroWithInviteProvider.overrideWith(
          (ref, params) async => _fixtureTournament(
            minutesPerSet: minutesPerSet,
            withSponsor: withSponsor,
          ),
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

Future<void> _pumpGrid(
  WidgetTester tester, {
  required List<MatchModel> matches,
  required int minutesPerSet,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScheduleGrid(
            courts: [for (final match in matches) match.court],
            matches: matches,
            startHour: 8,
            endHour: 18,
            minutesPerSet: minutesPerSet,
            onTapMatch: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Chiều cao thẻ trận trong lưới; thẻ cao tỉ lệ với thời lượng hiển thị.
double _cardHeight(WidgetTester tester, MatchModel match) => tester
    .getSize(
      find
          .descendant(
            of: find.byKey(ValueKey('schedule-match-${match.id}')),
            matching: find.byType(GestureDetector),
          )
          .first,
    )
    .height;

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

  testWidgets('sponsor tab is last, right after the schedule tab', (
    tester,
  ) async {
    await _pumpTournamentDetail(
      tester,
      locale: const Locale('vi'),
      withSponsor: true,
    );

    final tabBar = tester.widget<TabBar>(find.byType(TabBar).first);
    final labels = [for (final tab in tabBar.tabs) (tab as Tab).text];
    expect(labels.last, 'Tài trợ');
    expect(labels[labels.length - 2], 'Lịch thi đấu');

    await _tapTab(tester, find.widgetWithText(Tab, 'Lịch thi đấu'));
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

  testWidgets('schedule frame holds only the grid, no unplaced section', (
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
          court: 'Court 1',
          scheduledTime: DateTime(2026, 8, 12, 9),
        ),
        _scheduleMatch(2),
      ],
    );
    await _tapTab(tester, find.widgetWithText(Tab, 'Schedule'));

    final frame = find.byKey(const ValueKey('schedule-frame'));
    expect(frame, findsOneWidget);
    expect(
      find.descendant(of: frame, matching: find.byType(ScheduleGrid)),
      findsOneWidget,
    );
    expect(find.textContaining('Player 2'), findsNothing);
  });

  testWidgets('schedule is empty when every match is still unplaced', (
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
        _scheduleMatch(1, courtId: 'court-1', court: 'Court 1'),
        _scheduleMatch(2, scheduledTime: DateTime(2026, 8, 12, 10)),
      ],
    );
    await _tapTab(tester, find.widgetWithText(Tab, 'Schedule'));

    expect(find.byKey(const ValueKey('schedule-frame')), findsNothing);
    expect(find.text('No matches yet'), findsOneWidget);
    expect(find.text('No matches match the selected filter'), findsNothing);
    expect(find.textContaining('Player 1'), findsNothing);
    expect(find.textContaining('Player 2'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default schedule date is the first date with matches', (
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
          court: 'Court 1',
          team1Name: 'Thirteenth Player',
          scheduledTime: DateTime(2026, 8, 13, 9),
        ),
      ],
    );
    await _tapTab(tester, find.widgetWithText(Tab, 'Schedule'));

    expect(find.textContaining('Thirteenth Player'), findsOneWidget);
  });

  testWidgets('matches without time or court are not shown', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpTournamentDetail(
      tester,
      locale: const Locale('vi'),
      matches: [
        _scheduleMatch(
          1,
          courtId: 'court-1',
          court: 'Court 1',
          scheduledTime: DateTime(2026, 8, 12, 9),
        ),
        _scheduleMatch(2, team1Name: 'Unset Time A', team2Name: 'Unset Time B'),
        _scheduleMatch(
          3,
          team1Name: 'Unset Court A',
          team2Name: 'Unset Court B',
          scheduledTime: DateTime(2026, 8, 12, 10),
        ),
      ],
    );
    await _tapTab(tester, find.widgetWithText(Tab, 'Lịch thi đấu'));

    expect(find.textContaining('Player 1'), findsOneWidget);
    expect(find.textContaining('Unset Time A'), findsNothing);
    expect(find.textContaining('Unset Court A'), findsNothing);
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

  testWidgets('schedule keeps search without status filter chips', (
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
    await _tapTab(tester, find.widgetWithText(Tab, 'Schedule'));
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
    expect(find.text('All (19)'), findsNothing);
    expect(find.text('Live (1)'), findsNothing);
    expect(find.text('Completed (1)'), findsNothing);
    expect(find.text('Player 5'), findsOneWidget);
    expect(find.text('Player 9'), findsOneWidget);

    final frame = tester.getRect(find.byKey(const ValueKey('schedule-frame')));
    expect(frame.left, 0);
    expect(frame.right, 390);

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'SearchOnly Player');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Player 5'), findsNothing);
    expect(find.text('Player 9'), findsNothing);
    expect(find.text('Opponent 1'), findsOneWidget);
    await tester.enterText(searchField, '');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Player 5'), findsOneWidget);
    expect(find.text('Player 9'), findsOneWidget);

    final backButton = find.byIcon(Icons.arrow_back_ios_rounded).first;
    final backTopBeforeScroll = tester.getRect(backButton).top;
    for (var attempt = 0; attempt < 4; attempt++) {
      await tester.dragFrom(const Offset(200, 450), const Offset(0, -800));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(tester.getRect(backButton).top, backTopBeforeScroll);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal court scroll leaves the time column fixed', (
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
        for (var court = 1; court <= 4; court++)
          _scheduleMatch(
            court,
            courtId: 'court-$court',
            courtName: 'Court $court',
            scheduledTime: DateTime(2026, 8, 12, 8),
          ),
      ],
    );
    await _tapTab(tester, find.widgetWithText(Tab, 'Schedule'));

    final frame = find.byKey(const ValueKey('schedule-frame'));
    await tester.ensureVisible(frame);
    await tester.pumpAndSettle();
    final timeLabel = find.text('08:00').first;
    final quarterHourLabel = find.text('08:15').first;
    expect(
      tester.getRect(quarterHourLabel).top - tester.getRect(timeLabel).top,
      120,
    );
    expect(tester.widget<Text>(timeLabel).style?.fontSize, 12);
    final timeLeftBefore = tester.getRect(timeLabel).left;
    final gridRect = tester.getRect(
      find.descendant(of: frame, matching: find.byType(ScheduleGrid)),
    );
    expect(tester.getRect(timeLabel).right, gridRect.left + 55);
    final frameBeforeScroll = tester.getRect(frame);
    await tester.dragFrom(
      Offset(frameBeforeScroll.left + 200, frameBeforeScroll.top + 80),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();

    final frameRect = tester.getRect(frame);
    final courtFour = tester.getRect(find.text('Court 4'));
    expect(courtFour.left, greaterThanOrEqualTo(frameRect.left + 56));
    expect(courtFour.right, lessThanOrEqualTo(frameRect.right));
    expect(tester.getRect(timeLabel).left, timeLeftBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default ScheduleGrid preserves its existing scale', (
    tester,
  ) async {
    final match = _scheduleMatch(
      1,
      court: 'Court 1',
      scheduledTime: DateTime(2026, 8, 12, 9),
    );
    await _pumpGrid(tester, matches: [match], minutesPerSet: 15);

    final hourLabel = find.text('09:00').first;
    final quarterLabel = find.text('09:15').first;
    expect(
      tester.getRect(quarterLabel).top - tester.getRect(hourLabel).top,
      144,
    );
    expect(tester.widget<Text>(hourLabel).style?.fontSize, 10.5);
    expect(
      tester.widget<Text>(quarterLabel).style?.fontWeight,
      FontWeight.w500,
    );
  });

  group('schedule card duration fallback', () {
    final slot = DateTime(2026, 8, 12, 9);

    testWidgets('BO3 fallback multiplies minutesPerSet by 3 sets', (
      tester,
    ) async {
      final fallback = _scheduleMatch(
        1,
        court: 'Court 1',
        scheduledTime: slot,
      ).copyWith(sportRules: const {'bestOf': 3});
      final saved = _scheduleMatch(
        2,
        court: 'Court 2',
        scheduledTime: slot,
        durationMinutes: 60,
      );
      await _pumpGrid(tester, matches: [fallback, saved], minutesPerSet: 20);

      expect(
        _cardHeight(tester, fallback),
        closeTo(_cardHeight(tester, saved), 0.01),
      );
    });

    testWidgets('BO5 fallback multiplies minutesPerSet by 5 sets', (
      tester,
    ) async {
      final fallback = _scheduleMatch(
        1,
        court: 'Court 1',
        scheduledTime: slot,
      ).copyWith(sportRules: const {'bestOf': 5});
      final saved = _scheduleMatch(
        2,
        court: 'Court 2',
        scheduledTime: slot,
        durationMinutes: 100,
      );
      await _pumpGrid(tester, matches: [fallback, saved], minutesPerSet: 20);

      expect(
        _cardHeight(tester, fallback),
        closeTo(_cardHeight(tester, saved), 0.01),
      );
    });

    testWidgets('match without sport rules falls back to one set', (
      tester,
    ) async {
      final fallback = _scheduleMatch(1, court: 'Court 1', scheduledTime: slot);
      final saved = _scheduleMatch(
        2,
        court: 'Court 2',
        scheduledTime: slot,
        durationMinutes: 20,
      );
      await _pumpGrid(tester, matches: [fallback, saved], minutesPerSet: 20);

      expect(
        _cardHeight(tester, fallback),
        closeTo(_cardHeight(tester, saved), 0.01),
      );
    });

    testWidgets('LITE scoring counts one set regardless of bestOf', (
      tester,
    ) async {
      final fallback = _scheduleMatch(
        1,
        court: 'Court 1',
        scheduledTime: slot,
      ).copyWith(sportRules: const {'scoringMode': 'FREE', 'bestOf': 3});
      final saved = _scheduleMatch(
        2,
        court: 'Court 2',
        scheduledTime: slot,
        durationMinutes: 20,
      );
      await _pumpGrid(tester, matches: [fallback, saved], minutesPerSet: 20);

      expect(
        _cardHeight(tester, fallback),
        closeTo(_cardHeight(tester, saved), 0.01),
      );
    });

    testWidgets('saved durationMinutes wins over minutesPerSet fallback', (
      tester,
    ) async {
      final saved = _scheduleMatch(
        1,
        court: 'Court 1',
        scheduledTime: slot,
        durationMinutes: 45,
      ).copyWith(sportRules: const {'bestOf': 3});
      final reference = _scheduleMatch(
        2,
        court: 'Court 2',
        scheduledTime: slot,
        durationMinutes: 45,
      );
      await _pumpGrid(tester, matches: [saved, reference], minutesPerSet: 20);

      expect(
        _cardHeight(tester, saved),
        closeTo(_cardHeight(tester, reference), 0.01),
      );
    });

    testWidgets('schedule tab reads minutesPerSet from tournament config', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final fallback = _scheduleMatch(
        1,
        courtId: 'court-1',
        court: 'Court 1',
        scheduledTime: slot,
      ).copyWith(sportRules: const {'bestOf': 3});
      final saved = _scheduleMatch(
        2,
        courtId: 'court-2',
        court: 'Court 2',
        scheduledTime: slot,
        durationMinutes: 60,
      );
      await _pumpTournamentDetail(
        tester,
        locale: const Locale('en'),
        minutesPerSet: 20,
        matches: [fallback, saved],
      );
      await _tapTab(tester, find.widgetWithText(Tab, 'Schedule'));

      expect(
        _cardHeight(tester, fallback),
        closeTo(_cardHeight(tester, saved), 0.01),
      );
    });

    testWidgets('schedule tab defaults to 15 minutes per set when unset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final fallback = _scheduleMatch(
        1,
        courtId: 'court-1',
        court: 'Court 1',
        scheduledTime: slot,
      ).copyWith(sportRules: const {'bestOf': 3});
      final saved = _scheduleMatch(
        2,
        courtId: 'court-2',
        court: 'Court 2',
        scheduledTime: slot,
        durationMinutes: 45,
      );
      await _pumpTournamentDetail(
        tester,
        locale: const Locale('en'),
        matches: [fallback, saved],
      );
      await _tapTab(tester, find.widgetWithText(Tab, 'Schedule'));

      expect(
        _cardHeight(tester, fallback),
        closeTo(_cardHeight(tester, saved), 0.01),
      );
    });
  });
}
