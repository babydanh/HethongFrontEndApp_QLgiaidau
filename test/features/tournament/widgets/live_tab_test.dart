import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_match_summary_card.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _live(String id, {String? divisionId}) {
  return MatchModel(
    id: id,
    round: 1,
    matchNumber: 1,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    team1Id: 't1',
    team2Id: 't2',
    status: 'ONGOING',
    divisionId: divisionId,
    updatedAt: DateTime(2026, 1, 1),
  );
}

const _d1 = TournamentDivision(id: 'd1', name: 'Đôi Nam', matchType: 'DOUBLES');
const _d2 = TournamentDivision(id: 'd2', name: 'Đơn Nữ', matchType: 'SINGLES');

Widget _harness(LiveTab tab) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: tab),
  );
}

void main() {
  testWidgets('single division shows one summary card per live match', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveTab(
          liveMatches: [_live('a'), _live('b')],
          tournamentId: 'tour',
          divisions: const [_d1],
        ),
      ),
    );

    expect(find.byType(LiveMatchSummaryCard), findsNWidgets(2));
  });

  testWidgets('a live match without a division still shows and is counted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveTab(
          liveMatches: [
            _live('a', divisionId: 'd1'),
            _live('b', divisionId: 'd2'),
            _live('c'),
          ],
          tournamentId: 'tour',
          divisions: const [_d1, _d2],
          selectedDivisionId: 'd1',
        ),
      ),
    );

    // Open division d1 (a) + the unassigned match (c); d2 (b) stays collapsed.
    expect(find.byType(LiveMatchSummaryCard), findsNWidgets(2));
  });

  testWidgets('score button only for organisers', (tester) async {
    Widget tab({required bool canManage}) => _harness(
      LiveTab(
        liveMatches: [_live('a')],
        tournamentId: 'tour',
        divisions: const [_d1],
        canManage: canManage,
      ),
    );

    await tester.pumpWidget(tab(canManage: false));
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    await tester.pumpWidget(tab(canManage: true));
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });
}
