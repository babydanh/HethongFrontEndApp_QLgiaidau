import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tid = 'tour';

class _NoVenues extends Fake implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];
}

MatchModel _match(String id, {String? divisionId, String status = 'ONGOING'}) {
  return MatchModel(
    id: id,
    tournamentId: _tid,
    round: 1,
    matchNumber: 1,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    team1Id: 't1',
    team2Id: 't2',
    status: status,
    divisionId: divisionId,
    team1Players: [ParticipantPlayer(slot: 1, fullName: 'Nguyen Van $id')],
    team2Players: [ParticipantPlayer(slot: 1, fullName: 'Tran Thi $id')],
    updatedAt: DateTime(2026, 1, 1),
  );
}

const _d1 = TournamentDivision(id: 'd1', name: 'Đôi Nam', matchType: 'DOUBLES');
const _d2 = TournamentDivision(id: 'd2', name: 'Đơn Nữ', matchType: 'SINGLES');

Future<void> _pump(
  WidgetTester tester,
  List<MatchModel> matches, {
  List<TournamentDivision> divisions = const [_d1],
  String? selectedDivisionId,
  bool canManage = false,
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
          body: LiveTab(
            tournamentId: _tid,
            divisions: divisions,
            selectedDivisionId: selectedDivisionId,
            canManage: canManage,
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
  testWidgets('single division shows the whole board, live box first', (
    tester,
  ) async {
    await _pump(tester, [_match('a'), _match('b', status: 'SCHEDULED')]);

    expect(find.byKey(const ValueKey('results-box-live')), findsOneWidget);
    expect(_row('a'), findsOneWidget);
    expect(_row('b'), findsOneWidget);
  });

  testWidgets(
    'a tournament in progress without live matches still lists rounds',
    (tester) async {
      await _pump(tester, [_match('b', status: 'SCHEDULED')]);

      expect(find.byKey(const ValueKey('results-box-live')), findsNothing);
      expect(_row('b'), findsOneWidget);
    },
  );

  testWidgets('several divisions open only the selected division board', (
    tester,
  ) async {
    await _pump(
      tester,
      [_match('a', divisionId: 'd1'), _match('b', divisionId: 'd2')],
      divisions: const [_d1, _d2],
      selectedDivisionId: 'd1',
    );

    expect(_row('a'), findsOneWidget);
    expect(_row('b'), findsNothing);
  });

  testWidgets('only organisers can tap a row to enter a score', (tester) async {
    await _pump(tester, [_match('a')]);
    expect(find.byKey(const ValueKey('results-score-a')), findsNothing);

    await _pump(tester, [_match('a')], canManage: true);
    expect(find.byKey(const ValueKey('results-score-a')), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });
}
