import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_score_entry_chooser.dart';
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
}) {
  return MatchModel(
    id: id,
    tournamentId: _tid,
    round: round,
    matchNumber: number,
    bracketPosition: BracketPosition(round: round, position: number),
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
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchesProvider(_tid).overrideWith((ref) => Stream.value(matches)),
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

void main() {
  testWidgets('every round gets its own box, in play order', (tester) async {
    await _pump(tester, [
      _match('r1a', round: 1, number: 1),
      _match('r2a', round: 2, number: 1),
      _match('bye', round: 1, number: 3, isBye: true),
    ]);

    expect(_row('r1a'), findsOneWidget);
    expect(_row('r2a'), findsOneWidget);
    expect(_row('bye'), findsNothing);
    expect(find.byKey(const ValueKey('results-box-live')), findsNothing);
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

  testWidgets('organiser opens the chooser from the pencil of a pending row', (
    tester,
  ) async {
    await _pump(tester, [
      _match('todo1', round: 1, number: 1),
    ], canManage: true);

    await tester.tap(find.byKey(const ValueKey('results-score-todo1')));
    await tester.pumpAndSettle();

    expect(find.byType(MatchScoreEntryChooser), findsOneWidget);
  });

  testWidgets('a viewer has no pencil and tapping a pending row does nothing', (
    tester,
  ) async {
    await _pump(tester, [_match('todo1', round: 1, number: 1)]);

    expect(find.byKey(const ValueKey('results-score-todo1')), findsNothing);
    await tester.tap(_row('todo1'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchScoreEntryChooser), findsNothing);
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

  testWidgets('organiser sees a schedule button on pending rows only', (
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

    expect(
      find.descendant(
        of: _row('todo'),
        matching: find.byIcon(Icons.event_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _row('done'),
        matching: find.byIcon(Icons.event_outlined),
      ),
      findsNothing,
    );
  });

  testWidgets('a viewer never sees the schedule button', (tester) async {
    await _pump(tester, [_match('todo', round: 1, number: 1)]);
    expect(find.byIcon(Icons.event_outlined), findsNothing);
  });

  testWidgets('schedule button opens the schedule dialog, not the chooser', (
    tester,
  ) async {
    await _pump(tester, [_match('todo', round: 1, number: 1)], canManage: true);

    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Xếp lịch trận'), findsOneWidget);
    expect(find.byType(MatchScoreEntryChooser), findsNothing);
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

      expect(find.text('Chờ đội thắng V1601'), findsOneWidget);
      expect(find.text('Chờ đội thắng V1602'), findsOneWidget);
    });
  });
}
