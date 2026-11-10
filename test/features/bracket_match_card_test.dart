import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_card_parts.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_match_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TC-BMC-01..05: the match card of the full-screen diagram uses the same
// design as the card of the paged board in the tab.
MatchModel _match({
  String status = 'SCHEDULED',
  String team1 = 'p1',
  String team2 = 'p2',
  String winnerId = '',
  bool isBye = false,
  String? court,
  List<List<int>> sets = const [],
}) => MatchModel.fromJson({
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': status,
  'isBye': isBye,
  'team1Id': team1,
  'team2Id': team2,
  'team1Name': team1.isEmpty ? '' : 'Đội A',
  'team2Name': team2.isEmpty ? '' : 'Đội B',
  'winnerId': winnerId,
  'matchCode': 'TK01',
  'courtName': court,
  'stageType': 'SINGLE_ELIMINATION',
  'scoreDetails': {
    'sets': [
      for (final s in sets) {'team1Score': s[0], 'team2Score': s[1]},
    ],
  },
  'bracketPosition': {'bracket': 'winners', 'round': 1, 'position': 0},
}, 'm1');

Future<void> _pump(WidgetTester tester, MatchModel match) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 176,
            height: 92,
            child: BracketMatchCard(
              match: match,
              tournamentId: 't-1',
              isReferee: false,
              isReadOnly: true,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('TC-BMC-01 header shows code · court and no footer button', (
    tester,
  ) async {
    await _pump(tester, _match(court: 'Sân 2'));

    expect(find.byType(BracketCardHeader), findsOneWidget);
    expect(find.textContaining('TK01'), findsOneWidget);
    expect(find.textContaining('Sân 2'), findsOneWidget);
    expect(find.text('Chấm điểm'), findsNothing);
  });

  testWidgets('TC-BMC-02 winner side is tinted and shows the set score', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        status: 'COMPLETED',
        winnerId: 'p1',
        sets: const [
          [11, 7],
        ],
      ),
    );

    final rows = find.byType(BracketSideRow);
    expect(rows, findsNWidgets(2));
    Color? tint(int i) {
      final box = tester.widget<Container>(
        find.descendant(of: rows.at(i), matching: find.byType(Container)).first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    expect(tint(0), AppTheme.primary.withValues(alpha: 0.08));
    expect(tint(1), isNull);
    final winnerScore = tester.widget<Text>(find.text('11'));
    expect(winnerScore.style?.color, AppTheme.primary);
    expect(winnerScore.style?.fontWeight, FontWeight.w900);
  });

  testWidgets('TC-BMC-03 empty BYE side reads "Miễn đấu", never "BYE"', (
    tester,
  ) async {
    await _pump(tester, _match(status: 'COMPLETED', team2: '', isBye: true));

    expect(find.text('Miễn đấu'), findsOneWidget);
    expect(find.text('BYE'), findsNothing);
    // The tag stands out: amber pill, bold text (TC-BMC-05).
    final label = tester.widget<Text>(find.text('Miễn đấu'));
    expect(label.style?.fontWeight, FontWeight.w800);
    final pill = tester.widget<Container>(
      find
          .ancestor(of: find.text('Miễn đấu'), matching: find.byType(Container))
          .first,
    );
    final decoration = pill.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFF59E0B).withValues(alpha: 0.16));
  });

  testWidgets(
    'TC-BMC-04 live match shows the live tag (Đang đấu) in the header',
    (tester) async {
      await _pump(tester, _match(status: 'LIVE'));

      expect(
        find.descendant(
          of: find.byType(BracketCardHeader),
          matching: find.text('Đang đấu'),
        ),
        findsOneWidget,
      );
    },
  );
}
