import 'dart:async';

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

const _tid = 'tour-1';

class _NoVenues extends Fake implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];
}

MatchModel _match(String id, {required int round, required int number}) {
  return MatchModel(
    id: id,
    tournamentId: _tid,
    round: round,
    matchNumber: number,
    bracketPosition: BracketPosition(round: round, position: number),
    team1Id: 'a',
    team2Id: 'b',
    status: 'SCHEDULED',
    divisionId: 'd1',
    team1Players: [ParticipantPlayer(slot: 1, fullName: 'Nguyen Van $id')],
    team2Players: [ParticipantPlayer(slot: 1, fullName: 'Tran Thi $id')],
    updatedAt: DateTime(2026, 1, 1),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Stream<List<MatchModel>> matches, {
  String? divisionId = 'd1',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchesProvider(_tid).overrideWith((ref) => matches),
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
              canManage: false,
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
  testWidgets('TC-OPEN-SPEED-13 search filters after a short pause', (
    tester,
  ) async {
    await _pump(
      tester,
      Stream.value([
        _match('abc', round: 1, number: 1),
        _match('xyz', round: 1, number: 2),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('results-search')),
      'nguyen van xyz',
    );
    await tester.pump();
    // Still the full list: typing does not rebuild the board on every key.
    expect(_row('abc'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(_row('xyz'), findsOneWidget);
    expect(_row('abc'), findsNothing);
  });

  testWidgets('TC-OPEN-SPEED-14 a new match list refreshes the cached board', (
    tester,
  ) async {
    final matches = StreamController<List<MatchModel>>();
    addTearDown(matches.close);
    await _pump(tester, matches.stream);
    matches.add([_match('first', round: 1, number: 1)]);
    await tester.pump();
    await tester.pump();
    expect(_row('first'), findsOneWidget);

    matches.add([
      _match('first', round: 1, number: 1),
      _match('second', round: 2, number: 1),
    ]);
    await tester.pump();
    await tester.pump();

    expect(_row('first'), findsOneWidget);
    expect(_row('second'), findsOneWidget);
  });

  testWidgets('TC-OPEN-SPEED-15 switching division rebuilds the cached board', (
    tester,
  ) async {
    final list = [
      _match('a', round: 1, number: 1),
      MatchModel(
        id: 'b',
        tournamentId: _tid,
        round: 1,
        matchNumber: 2,
        bracketPosition: const BracketPosition(round: 1, position: 2),
        team1Id: 'a',
        team2Id: 'b',
        status: 'SCHEDULED',
        divisionId: 'd2',
        team1Players: [ParticipantPlayer(slot: 1, fullName: 'Le B')],
        team2Players: [ParticipantPlayer(slot: 1, fullName: 'Pham B')],
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];
    await _pump(tester, Stream.value(list));
    expect(_row('a'), findsOneWidget);
    expect(_row('b'), findsNothing);

    await _pump(tester, Stream.value(list), divisionId: 'd2');

    expect(_row('b'), findsOneWidget);
    expect(_row('a'), findsNothing);
  });
}
