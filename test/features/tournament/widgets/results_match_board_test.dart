import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _tid = 'tour-1';

class _NoVenues extends Fake implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];
}

MatchModel _match(
  String id, {
  required int round,
  required int number,
  String status = 'SCHEDULED',
  String team1Id = 'a',
  String team2Id = 'b',
  bool isBye = false,
  String? divisionId = 'd1',
  DateTime? scheduledTime,
  DateTime? completedAt,
  String winnerId = '',
  Map<String, dynamic>? scoreDetails,
  String? matchCode,
  String? team1Name,
  List<ParticipantPlayer>? team1Players,
  String bracket = 'winners',
  String? stageType,
}) {
  return MatchModel(
    id: id,
    tournamentId: _tid,
    round: round,
    matchNumber: number,
    bracketPosition: BracketPosition(
      bracket: bracket,
      round: round,
      position: number,
    ),
    stageType: stageType,
    team1Id: team1Id,
    team2Id: team2Id,
    status: status,
    isBye: isBye,
    divisionId: divisionId,
    scheduledTime: scheduledTime,
    completedAt: completedAt,
    winnerId: winnerId,
    scoreDetails: scoreDetails,
    matchCode: matchCode,
    team1Name: team1Name ?? 'TBD',
    team1Players:
        team1Players ??
        [ParticipantPlayer(slot: 1, fullName: 'Nguyen Van $id')],
    team2Players: [ParticipantPlayer(slot: 1, fullName: 'Tran Thi $id')],
    updatedAt: DateTime(2026, 1, 1),
  );
}

Future<void> _pump(
  WidgetTester tester,
  List<MatchModel> matches, {
  bool canManage = false,
  String? divisionId = 'd1',
  ResultsBoardFilter initialFilter = ResultsBoardFilter.all,
  bool finalOnly = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchesProvider(_tid).overrideWith((ref) => Stream.value(matches)),
        managedMatchesWithDivisionProvider((
          tournamentId: _tid,
          divisionId: null,
        )).overrideWith((ref) => Stream.value(matches)),
        tournamentManagementRepositoryProvider.overrideWithValue(_NoVenues()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: SingleChildScrollView(
                  child: ResultsMatchBoard(
                    tournamentId: _tid,
                    isLite: false,
                    divisionId: divisionId,
                    canManage: canManage,
                    initialFilter: initialFilter,
                    finalOnly: finalOnly,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/live/:id',
              builder: (_, _) => const Scaffold(body: Text('live-room')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Finder _row(String id) => find.byKey(ValueKey('results-row-$id'));

/// Every box-head button, in board order.
Finder get _toggles => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('results-box-toggle-'),
);

/// Opens the box at [index] (board order) and waits for the unfold.
Future<void> _toggleBox(WidgetTester tester, int index) async {
  await tester.tap(_toggles.at(index));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every round gets its own box, in play order', (tester) async {
    await _pump(tester, [
      _match('r1a', round: 1, number: 1),
      _match('r2a', round: 2, number: 1),
      _match('bye', round: 1, number: 3, isBye: true),
    ]);

    expect(_toggles, findsNWidgets(2));
    // Only the first round that waits for a score starts open.
    expect(_row('r1a'), findsOneWidget);
    expect(_row('r2a'), findsNothing);
    await _toggleBox(tester, 1);
    expect(_row('r2a'), findsOneWidget);
    expect(_row('bye'), findsNothing);
    expect(find.byKey(const ValueKey('results-box-live')), findsNothing);
  });

  group('TC-FINAL-02 finalOnly lists the knockout final only', () {
    final knockout = [
      _match('r1a', round: 1, number: 1, stageType: 'SINGLE_ELIMINATION'),
      _match('r1b', round: 1, number: 2, stageType: 'SINGLE_ELIMINATION'),
      _match('fin', round: 2, number: 1, stageType: 'SINGLE_ELIMINATION'),
    ];

    testWidgets('a finished knockout division shows the last round only', (
      tester,
    ) async {
      await _pump(tester, knockout, finalOnly: true);

      expect(_toggles, findsNWidgets(1));
      expect(_row('fin'), findsOneWidget);
      expect(_row('r1a'), findsNothing);
    });

    testWidgets('without finalOnly every round stays', (tester) async {
      await _pump(tester, knockout);

      expect(_toggles, findsNWidgets(2));
    });

    testWidgets('no knockout final keeps the full board', (tester) async {
      await _pump(tester, [
        _match('a', round: 1, number: 1, stageType: 'ROUND_ROBIN'),
        _match('b', round: 2, number: 1, stageType: 'ROUND_ROBIN'),
      ], finalOnly: true);

      // Round robin rounds share one "Vòng bảng" box; both matches stay.
      expect(_row('a'), findsOneWidget);
      expect(_row('b'), findsOneWidget);
    });
  });

  testWidgets('a live match sits in the red live box once, not in its round', (
    tester,
  ) async {
    await _pump(tester, [
      _match('live1', round: 1, number: 1, status: 'ONGOING'),
      _match('todo1', round: 1, number: 2),
    ]);

    expect(find.byKey(const ValueKey('results-box-live')), findsOneWidget);
    expect(_row('live1'), findsOneWidget);
    expect(_row('todo1'), findsOneWidget);
  });

  testWidgets('a live match that already has a winner is not shown as live', (
    tester,
  ) async {
    await _pump(tester, [
      _match('ghost', round: 1, number: 1, status: 'ONGOING', winnerId: 'a'),
    ]);
    expect(find.byKey(const ValueKey('results-box-live')), findsNothing);
  });

  testWidgets('chip Đã xong keeps finished rows and hides the live box', (
    tester,
  ) async {
    await _pump(tester, [
      _match('live1', round: 1, number: 1, status: 'ONGOING'),
      _match(
        'done',
        round: 1,
        number: 2,
        status: 'COMPLETED',
        completedAt: DateTime(2026, 1, 1, 9),
      ),
      _match('todo', round: 1, number: 3),
    ]);

    await tester.tap(find.byKey(const ValueKey('results-filter-finished')));
    await tester.pumpAndSettle();

    expect(_row('done'), findsOneWidget);
    expect(_row('todo'), findsNothing);
    expect(_row('live1'), findsNothing);
    expect(find.byKey(const ValueKey('results-box-live')), findsNothing);
  });

  testWidgets('chip Sắp tới keeps only matches that have not started', (
    tester,
  ) async {
    await _pump(tester, [
      _match('live1', round: 1, number: 1, status: 'ONGOING'),
      _match(
        'done',
        round: 1,
        number: 2,
        status: 'COMPLETED',
        completedAt: DateTime(2026, 1, 1, 9),
      ),
      _match('todo', round: 1, number: 3),
    ]);

    await tester.tap(find.byKey(const ValueKey('results-filter-upcoming')));
    await tester.pumpAndSettle();

    expect(_row('todo'), findsOneWidget);
    expect(_row('done'), findsNothing);
    expect(_row('live1'), findsNothing);
  });

  testWidgets('search narrows the board by player name', (tester) async {
    await _pump(tester, [
      _match('abc', round: 1, number: 1),
      _match('xyz', round: 1, number: 2),
    ]);

    await tester.enterText(
      find.byKey(const ValueKey('results-search')),
      'nguyen van xyz',
    );
    await tester.pumpAndSettle();

    expect(_row('xyz'), findsOneWidget);
    expect(_row('abc'), findsNothing);
  });

  testWidgets('organiser sees #code, viewer sees the running number', (
    tester,
  ) async {
    final matches = [_match('m1', round: 1, number: 1, matchCode: 'V1602')];

    await _pump(tester, matches, canManage: true);
    expect(find.text('#V1602'), findsOneWidget);

    await _pump(tester, matches);
    expect(find.text('#V1602'), findsNothing);
    expect(
      find.descendant(of: _row('m1'), matching: find.text('1')),
      findsOneWidget,
    );
  });

  testWidgets('a named team shows its logo, players show one line each', (
    tester,
  ) async {
    await _pump(tester, [
      _match(
        'team',
        round: 1,
        number: 1,
        team1Name: 'Sam Set',
        team1Players: const [
          ParticipantPlayer(slot: 1, fullName: 'Pham Thi Lan'),
          ParticipantPlayer(slot: 2, fullName: 'Vu Thi Nga'),
        ],
      ),
    ]);

    expect(find.text('Sam Set'), findsOneWidget);
    expect(find.byKey(const ValueKey('side-lines-team-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('side-lines-player-0')), findsOneWidget);
  });

  testWidgets('a finished row shows both set scores next to each side', (
    tester,
  ) async {
    await _pump(tester, [
      MatchModel(
        id: 'fin',
        tournamentId: _tid,
        round: 1,
        matchNumber: 1,
        bracketPosition: const BracketPosition(round: 1, position: 1),
        team1Id: 'a',
        team2Id: 'b',
        status: 'COMPLETED',
        divisionId: 'd1',
        winnerId: 'a',
        completedAt: DateTime(2026, 1, 1, 9),
        sets: const [
          SetScore(score1: 11, score2: 5),
          SetScore(score1: 11, score2: 7),
        ],
        team1Players: const [ParticipantPlayer(slot: 1, fullName: 'An Binh')],
        team2Players: const [
          ParticipantPlayer(slot: 1, fullName: 'Cuong Dung'),
        ],
        updatedAt: DateTime(2026, 1, 1),
      ),
    ]);

    expect(find.text('11  11'), findsOneWidget);
    expect(find.text('5  7'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('tapping a live row opens the live room', (tester) async {
    await _pump(tester, [
      _match('live1', round: 1, number: 1, status: 'ONGOING'),
    ]);

    await tester.tap(_row('live1'));
    await tester.pumpAndSettle();

    expect(find.text('live-room'), findsOneWidget);
  });

  testWidgets('organiser opens the score popup by tapping a pending row', (
    tester,
  ) async {
    await _pump(tester, [
      _match('todo1', round: 1, number: 1),
    ], canManage: true);

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    await tester.tap(find.byKey(const ValueKey('results-score-todo1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('results-score-sheet')), findsOneWidget);
  });

  testWidgets('a viewer has no pencil and tapping a pending row does nothing', (
    tester,
  ) async {
    await _pump(tester, [_match('todo1', round: 1, number: 1)]);

    expect(find.byKey(const ValueKey('results-score-todo1')), findsNothing);
    await tester.tap(_row('todo1'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('results-score-sheet')), findsNothing);
  });

  testWidgets('a row without both teams has no pencil even for organisers', (
    tester,
  ) async {
    await _pump(tester, [
      _match('wait', round: 1, number: 1, team2Id: ''),
    ], canManage: true);

    expect(find.byKey(const ValueKey('results-score-wait')), findsNothing);
  });

  testWidgets('only matches of the selected division are listed', (
    tester,
  ) async {
    await _pump(tester, [
      _match('mine', round: 1, number: 1),
      _match('other', round: 1, number: 2, divisionId: 'd2'),
    ]);

    expect(_row('mine'), findsOneWidget);
    expect(_row('other'), findsNothing);
  });

  testWidgets('a division without matches shows the empty message', (
    tester,
  ) async {
    await _pump(tester, [_match('bye', round: 1, number: 1, isBye: true)]);

    expect(find.text('Chưa có trận nào ở hạng mục này'), findsOneWidget);
    expect(find.byKey(const ValueKey('results-search')), findsNothing);
  });

  testWidgets('a match whose division id lives in scoreDetails is listed', (
    tester,
  ) async {
    await _pump(tester, [
      _match(
        'nested',
        round: 1,
        number: 1,
        divisionId: null,
        scoreDetails: const {'division_id': 'd1'},
      ),
    ]);

    expect(_row('nested'), findsOneWidget);
  });

  testWidgets('organiser can schedule pending rows only, without an icon', (
    tester,
  ) async {
    await _pump(tester, [
      _match('todo', round: 1, number: 1),
      _match(
        'done',
        round: 1,
        number: 2,
        status: 'COMPLETED',
        completedAt: DateTime(2026, 1, 1, 9),
      ),
    ], canManage: true);

    expect(find.byKey(const ValueKey('results-schedule-todo')), findsOneWidget);
    expect(find.byKey(const ValueKey('results-schedule-done')), findsNothing);
    expect(find.byIcon(Icons.event_outlined), findsNothing);
  });

  testWidgets('a viewer never gets the schedule action', (tester) async {
    await _pump(tester, [_match('todo', round: 1, number: 1)]);
    expect(find.byKey(const ValueKey('results-schedule-todo')), findsNothing);
    expect(find.byIcon(Icons.event_outlined), findsNothing);
  });

  testWidgets('tapping the time line opens the schedule dialog only', (
    tester,
  ) async {
    await _pump(tester, [_match('todo', round: 1, number: 1)], canManage: true);

    await tester.tap(find.byKey(const ValueKey('results-schedule-todo')));
    await tester.pumpAndSettle();

    expect(find.text('Xếp lịch trận'), findsOneWidget);
    expect(find.byKey(const ValueKey('results-score-sheet')), findsNothing);
  });

  group('Lavish mockup parity', () {
    final live = _match('live1', round: 1, number: 1, status: 'ONGOING');
    final todo = _match('todo', round: 1, number: 2);
    final done = MatchModel(
      id: 'fin',
      tournamentId: _tid,
      round: 1,
      matchNumber: 3,
      bracketPosition: const BracketPosition(round: 1, position: 3),
      team1Id: 'a',
      team2Id: 'b',
      status: 'COMPLETED',
      divisionId: 'd1',
      winnerId: 'a',
      completedAt: DateTime(2026, 1, 1, 9),
      sets: const [SetScore(score1: 11, score2: 8)],
      team1Players: const [ParticipantPlayer(slot: 1, fullName: 'An Binh')],
      team2Players: const [ParticipantPlayer(slot: 1, fullName: 'Cuong Dung')],
      updatedAt: DateTime(2026, 1, 1),
    );

    Color? pointsColor(WidgetTester tester, String id, int side) => tester
        .widget<Text>(find.byKey(ValueKey('results-points-$id-$side')))
        .style
        ?.color;

    testWidgets('TC-BOARD-01 chips carry the count of each state', (
      tester,
    ) async {
      await _pump(tester, [live, todo, done]);

      String count(String name) => tester
          .widget<Text>(find.byKey(ValueKey('results-filter-count-$name')))
          .data!;
      expect(count('live'), '1');
      expect(count('upcoming'), '1');
      expect(count('finished'), '1');
      expect(
        find.byKey(const ValueKey('results-filter-count-all')),
        findsNothing,
      );
    });

    testWidgets('TC-BOARD-02 "Tới vòng" stays next to the search box', (
      tester,
    ) async {
      await _pump(tester, [todo]);

      expect(find.byKey(const ValueKey('results-jump')), findsOneWidget);
      expect(find.text('Tới vòng'), findsOneWidget);
    });

    testWidgets('TC-BOARD-03 each box head has a pill and a match count', (
      tester,
    ) async {
      await _pump(tester, [live, todo, done]);

      final liveBox = find.byKey(const ValueKey('results-box-live'));
      expect(
        find.descendant(of: liveBox, matching: find.text('Đang đấu')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: liveBox, matching: find.text('1 trận')),
        findsOneWidget,
      );
      expect(find.text('2 trận'), findsOneWidget);
    });

    testWidgets('TC-BOARD-04 a live row has the red dot and a vs line', (
      tester,
    ) async {
      await _pump(tester, [live, todo]);

      expect(
        find.byKey(const ValueKey('results-live-dot-live1')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('results-live-dot-todo')), findsNothing);
      expect(
        find.descendant(of: _row('live1'), matching: find.text('vs')),
        findsOneWidget,
      );
    });

    testWidgets('TC-BOARD-05 live points are red, lost and empty ones faded', (
      tester,
    ) async {
      await _pump(tester, [live, todo, done]);

      expect(pointsColor(tester, 'live1', 1), const Color(0xFFE11D48));
      expect(pointsColor(tester, 'fin', 1), const Color(0xFF0F172A));
      expect(pointsColor(tester, 'fin', 2), const Color(0xFFCBD5E1));
      expect(pointsColor(tester, 'todo', 1), const Color(0xFFCBD5E1));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('results-points-todo-1')))
            .data,
        '–',
      );
    });

    testWidgets('TC-BOARD-06 meta line: live = court + round badge', (
      tester,
    ) async {
      await _pump(tester, [
        live.copyWith(court: 'Sân 2'),
        todo.copyWith(
          court: 'Sân 1',
          scheduledTime: DateTime(2026, 1, 1, 8, 30),
        ),
      ]);

      expect(
        find.byKey(const ValueKey('results-meta-court-live1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('results-meta-badge-live1')),
        findsOneWidget,
      );
      final courtBadge = tester.widget<Text>(
        find.byKey(const ValueKey('results-meta-badge-todo')),
      );
      expect(courtBadge.data, 'Sân 1');
      expect(
        find.byKey(const ValueKey('results-meta-time-todo')),
        findsOneWidget,
      );
    });

    testWidgets('TC-BOARD-07 an empty side names the match it waits for', (
      tester,
    ) async {
      final next = MatchModel(
        id: 'next',
        tournamentId: _tid,
        round: 2,
        matchNumber: 1,
        bracketPosition: const BracketPosition(round: 2, position: 1),
        divisionId: 'd1',
        team1Name: '',
        team2Name: '',
        updatedAt: DateTime(2026, 1, 1),
      );
      await _pump(tester, [
        _match(
          'f1',
          round: 1,
          number: 1,
          matchCode: 'V1601',
        ).copyWith(nextMatchId: 'next'),
        _match(
          'f2',
          round: 1,
          number: 2,
          matchCode: 'V1602',
        ).copyWith(nextMatchId: 'next'),
        next,
      ]);

      await _toggleBox(tester, 1);
      expect(find.text('Chờ đội thắng V1601'), findsOneWidget);
      expect(find.text('Chờ đội thắng V1602'), findsOneWidget);
    });

    testWidgets('TC-BOARD-08 organiser sees "+" where the score goes', (
      tester,
    ) async {
      await _pump(tester, [todo], canManage: true);
      expect(
        find.byKey(const ValueKey('results-add-score-todo')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('results-points-todo-1')), findsNothing);

      await _pump(tester, [todo]);
      expect(
        find.byKey(const ValueKey('results-add-score-todo')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('results-points-todo-1')),
        findsOneWidget,
      );
    });

    testWidgets('TC-BOARD-09 the code is not repeated in round labels', (
      tester,
    ) async {
      await _pump(tester, [
        _match(
          'live1',
          round: 1,
          number: 1,
          status: 'ONGOING',
          matchCode: 'V1602',
        ),
        _match('todo', round: 1, number: 2, matchCode: 'V1603'),
      ], canManage: true);

      final badge = tester.widget<Text>(
        find.byKey(const ValueKey('results-meta-badge-live1')),
      );
      expect(badge.data, isNot(contains('#')));
      expect(badge.data, isNot(contains('V1602')));
      expect(find.textContaining(' - #'), findsNothing);
      expect(find.text('#V1602'), findsOneWidget);
    });

    testWidgets('TC-BOARD-10 the court badge drops the venue name', (
      tester,
    ) async {
      await _pump(tester, [
        todo.copyWith(
          court: 'Sân 1 - Nhà thi đấu A',
          scheduledTime: DateTime(2026, 1, 1, 8, 30),
        ),
      ]);

      final badge = tester.widget<Text>(
        find.byKey(const ValueKey('results-meta-badge-todo')),
      );
      expect(badge.data, 'Sân 1');
    });
  });

  group('management chips (Web ResultsBoard parity)', () {
    final disputedA = _match('dis-a', round: 1, number: 1, status: 'DISPUTED');
    final disputedB = _match('dis-b', round: 1, number: 2, status: 'DISPUTED');
    final done = _match(
      'done',
      round: 1,
      number: 3,
      status: 'COMPLETED',
      completedAt: DateTime.utc(2026, 11, 3),
    );
    final cancelled = _match('cx', round: 1, number: 4, status: 'CANCELLED');
    final todo = _match('todo', round: 1, number: 5);

    String count(WidgetTester tester, String name) => tester
        .widget<Text>(find.byKey(ValueKey('results-filter-count-$name')))
        .data!;

    testWidgets('TC-RESULTS-01 managers get five chips, viewers keep four', (
      tester,
    ) async {
      await _pump(tester, [todo], canManage: true);
      for (final name in [
        'all',
        'live',
        'upcoming',
        'finished',
        'unfinished',
      ]) {
        expect(find.byKey(ValueKey('results-filter-$name')), findsOneWidget);
      }
      for (final name in ['late', 'disputed']) {
        expect(find.byKey(ValueKey('results-filter-$name')), findsNothing);
      }

      await _pump(tester, [todo]);
      for (final name in ['unfinished', 'late', 'disputed']) {
        expect(find.byKey(ValueKey('results-filter-$name')), findsNothing);
      }
    });

    testWidgets('TC-RESULTS-02 disputes sit in no count chip', (
      tester,
    ) async {
      await _pump(tester, [
        disputedA,
        disputedB,
        done,
        cancelled,
        todo,
      ], canManage: true);

      // Like the Web progress card: completed + cancelled, disputes excluded.
      expect(count(tester, 'finished'), '2');
      expect(count(tester, 'unfinished'), '1');
    });

    testWidgets('TC-RESULTS-04 initialFilter opens with that chip selected', (
      tester,
    ) async {
      await _pump(
        tester,
        [disputedA, todo],
        canManage: true,
        initialFilter: ResultsBoardFilter.unfinished,
      );

      expect(_row('todo'), findsOneWidget);
      expect(_row('dis-a'), findsNothing);
    });
  });

  group('branch boxes and fold (TC-RBR)', () {
    const double8 = 'DOUBLE_ELIMINATION';

    Finder head(String key) => find.byKey(ValueKey('results-box-head-$key'));
    Color headColor(WidgetTester tester, String key) =>
        tester.widget<Material>(head(key)).color!;

    MatchModel losers(String id, int round) => _match(
      id,
      round: round,
      number: 1,
      bracket: 'losers',
      stageType: double8,
    );

    testWidgets('TC-RBR-10 winners, losers and grand final differ in colour', (
      tester,
    ) async {
      await _pump(tester, [
        _match('w1', round: 1, number: 1, stageType: double8),
        losers('l1', 2),
        _match(
          'gf',
          round: 9,
          number: 1,
          bracket: 'grand_final',
          stageType: double8,
        ),
      ]);
      final heads = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('results-box-head-'),
      );
      expect(heads, findsNWidgets(3));
      final colours = {
        for (final e in tester.widgetList<Material>(heads)) e.color,
      };
      expect(colours, hasLength(3));
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    });

    testWidgets('TC-RBR-11 only the first round that waits for a score opens', (
      tester,
    ) async {
      await _pump(tester, [
        _match('r1a', round: 1, number: 1, status: 'COMPLETED'),
        _match('r1b', round: 1, number: 2, status: 'COMPLETED'),
        _match('r2', round: 2, number: 1),
      ]);
      expect(_row('r1a'), findsNothing);
      expect(_row('r1b'), findsNothing);
      expect(_row('r2'), findsOneWidget);
    });

    testWidgets('TC-RBR-12 tapping a head folds and opens its box', (
      tester,
    ) async {
      await _pump(tester, [
        _match('r1a', round: 1, number: 1),
        _match('r1b', round: 1, number: 2),
        _match('r2', round: 2, number: 1),
      ]);
      expect(_row('r2'), findsNothing);
      await _toggleBox(tester, 1);
      expect(_row('r2'), findsOneWidget);
      await _toggleBox(tester, 1);
      expect(_row('r2'), findsNothing);
    });

    testWidgets('TC-RBR-13 a search opens every box that still has a match', (
      tester,
    ) async {
      await _pump(tester, [
        _match('r1', round: 1, number: 1),
        _match('r1b', round: 1, number: 2),
        _match('r2', round: 2, number: 1),
      ]);
      await tester.enterText(
        find.byKey(const ValueKey('results-search')),
        'van',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(_row('r1'), findsOneWidget);
      expect(_row('r2'), findsOneWidget);
    });

    testWidgets('TC-RBR-14 an open box shows the column header row', (
      tester,
    ) async {
      await _pump(tester, [_match('r1', round: 1, number: 1)]);
      expect(find.text('Cặp đấu'), findsOneWidget);
      expect(find.text('Kết quả'), findsOneWidget);
    });

    testWidgets('TC-RBR-15 the red live box folds too', (tester) async {
      await _pump(tester, [
        _match('live1', round: 1, number: 1, status: 'ONGOING'),
      ]);
      expect(_row('live1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('results-box-toggle-live')));
      await tester.pumpAndSettle();
      expect(_row('live1'), findsNothing);
    });

    testWidgets('TC-RBR-16 each losers round is its own box', (tester) async {
      await _pump(tester, [losers('l1', 2), losers('l2', 4)]);
      expect(head('losers|2'), findsOneWidget);
      expect(head('losers|4'), findsOneWidget);
      expect(headColor(tester, 'losers|2'), headColor(tester, 'losers|4'));
    });

    testWidgets('TC-RBR-17 no late or disputed chip, even for managers', (
      tester,
    ) async {
      await _pump(tester, [_match('r1', round: 1, number: 1)], canManage: true);
      expect(find.byKey(const ValueKey('results-filter-late')), findsNothing);
      expect(
        find.byKey(const ValueKey('results-filter-disputed')),
        findsNothing,
      );
    });
  });

  group('"Tới vòng" (TC-RBR-2x)', () {
    final threeRounds = [
      _match('r1a', round: 1, number: 1),
      _match('r1b', round: 1, number: 2),
      _match('r1c', round: 1, number: 3),
      _match('r1d', round: 1, number: 4),
      _match('r2a', round: 2, number: 1),
      _match('r2b', round: 2, number: 2),
      _match('r3', round: 3, number: 1),
    ];

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('results-jump')));
      await tester.pumpAndSettle();
    }

    testWidgets('TC-RBR-20 the menu lists every round with its pending count', (
      tester,
    ) async {
      await _pump(tester, threeRounds);
      await openMenu(tester);
      expect(find.byType(PopupMenuItem<String>), findsNWidgets(3));
      expect(find.textContaining('· 4 chờ'), findsOneWidget);
      expect(find.textContaining('· 2 chờ'), findsOneWidget);
      expect(find.textContaining('· 1 chờ'), findsOneWidget);
    });

    testWidgets('TC-RBR-21 picking a round opens it and folds the others', (
      tester,
    ) async {
      await _pump(tester, threeRounds);
      expect(_row('r1a'), findsOneWidget);
      expect(_row('r3'), findsNothing);

      await openMenu(tester);
      await tester.tap(find.byType(PopupMenuItem<String>).last);
      await tester.pumpAndSettle();

      expect(_row('r3'), findsOneWidget);
      expect(_row('r1a'), findsNothing);
      expect(_row('r2a'), findsNothing);
    });

    testWidgets('TC-RBR-22 the picked round is scrolled into view', (
      tester,
    ) async {
      await _pump(tester, threeRounds);
      await openMenu(tester);
      await tester.tap(find.byType(PopupMenuItem<String>).last);
      await tester.pumpAndSettle();
      final top = tester.getTopLeft(_row('r3')).dy;
      expect(top, greaterThanOrEqualTo(0));
      expect(top, lessThan(tester.view.physicalSize.height));
    });
  });
}
