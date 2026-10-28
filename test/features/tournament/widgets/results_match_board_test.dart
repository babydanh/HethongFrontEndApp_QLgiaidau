import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_score_entry_chooser.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_match_summary_card.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    team1Players: [ParticipantPlayer(slot: 1, fullName: 'Nguyen Van $id')],
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
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
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
    ),
  );
  await tester.pump();
  await tester.pump();
}

Finder _row(String id) => find.byKey(ValueKey('results-row-$id'));

void main() {
  testWidgets('default round is the first one with a pending match', (
    tester,
  ) async {
    await _pump(tester, [
      _match(
        'r1done',
        round: 1,
        number: 1,
        status: 'COMPLETED',
        completedAt: DateTime(2026, 1, 1, 9),
      ),
      _match('r1todo', round: 1, number: 2),
      _match('r2todo', round: 2, number: 1),
      _match('bye', round: 1, number: 3, isBye: true),
    ]);

    expect(_row('r1done'), findsOneWidget);
    expect(_row('r1todo'), findsOneWidget);
    expect(_row('r2todo'), findsNothing);
    expect(_row('bye'), findsNothing);
  });

  testWidgets('switching round shows that round', (tester) async {
    await _pump(tester, [
      _match('r1todo', round: 1, number: 1),
      _match('r1other', round: 1, number: 2),
      _match('r2todo', round: 2, number: 1),
    ]);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const ValueKey('results-round-select')),
            matching: find.byType(LavishChipButton),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(_row('r2todo'), findsOneWidget);
    expect(_row('r1todo'), findsNothing);
  });

  testWidgets('live block shows live matches of any round, once', (
    tester,
  ) async {
    await _pump(tester, [
      _match('live1', round: 1, number: 1, status: 'ONGOING'),
      _match('todo2', round: 2, number: 1),
      _match('todo1', round: 1, number: 2),
    ]);

    expect(find.byType(LiveMatchSummaryCard), findsOneWidget);
    // The live match is not repeated inside "Sắp tới".
    expect(_row('live1'), findsNothing);
    expect(_row('todo1'), findsOneWidget);
  });

  testWidgets('no live match hides the live block entirely', (tester) async {
    await _pump(tester, [_match('todo1', round: 1, number: 1)]);
    expect(find.byType(LiveMatchSummaryCard), findsNothing);
  });

  testWidgets('a live match that already has a winner is not shown as live', (
    tester,
  ) async {
    await _pump(tester, [
      _match('ghost', round: 1, number: 1, status: 'ONGOING', winnerId: 'a'),
    ]);
    expect(find.byType(LiveMatchSummaryCard), findsNothing);
  });

  testWidgets('organiser opens the chooser from a pending row', (tester) async {
    await _pump(tester, [
      _match('todo1', round: 1, number: 1),
    ], canManage: true);

    await tester.tap(_row('todo1'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchScoreEntryChooser), findsOneWidget);
  });

  testWidgets('a viewer cannot open the chooser', (tester) async {
    await _pump(tester, [_match('todo1', round: 1, number: 1)]);

    await tester.tap(_row('todo1'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchScoreEntryChooser), findsNothing);
  });

  testWidgets('a row without both teams is not tappable even for organisers', (
    tester,
  ) async {
    await _pump(tester, [
      _match('wait', round: 1, number: 1, team2Id: ''),
    ], canManage: true);

    await tester.tap(_row('wait'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchScoreEntryChooser), findsNothing);
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
    expect(find.byKey(const ValueKey('results-round-select')), findsNothing);
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
}
