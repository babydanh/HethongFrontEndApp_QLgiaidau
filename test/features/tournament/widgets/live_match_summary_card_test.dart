import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_match_summary_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  String court = 'Sân 3',
  DateTime? scheduledTime,
  String name1 = 'Phạm Anh Khoa',
  String name2 = 'Lê Tuấn Công',
  int finishedSets = 1,
}) {
  return MatchModel(
    id: 'm1',
    round: 1,
    matchNumber: 1,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    team1Id: 't1',
    team2Id: 't2',
    status: 'ONGOING',
    court: court,
    scheduledTime: scheduledTime,
    team1Players: [ParticipantPlayer(slot: 1, fullName: name1)],
    team2Players: [ParticipantPlayer(slot: 1, fullName: name2)],
    scoreDetails: {
      'sets': [
        for (var i = 0; i < finishedSets; i++)
          {'isFinished': true, 'team1Score': 5, 'team2Score': 11},
        {'isFinished': false, 'team1Score': 2, 'team2Score': 1},
      ],
    },
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _harness(Widget child, {double width = 360}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('shows round, code, names, score, set chips and time · court', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchSummaryCard(
          match: _match(scheduledTime: DateTime(2026, 1, 1, 8, 40)),
          roundLabel: 'Lượt 1',
          matchCode: '#V1602',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Lượt 1'), findsOneWidget);
    expect(find.text('#V1602'), findsOneWidget);
    expect(find.text('P. A. Khoa'), findsOneWidget);
    expect(find.text('L. T. Công'), findsOneWidget);
    expect(find.text('2 - 1'), findsOneWidget);
    expect(find.text('5-11'), findsOneWidget);
    expect(find.textContaining('08:40'), findsOneWidget);
    expect(find.textContaining('Sân 3'), findsOneWidget);
  });

  testWidgets('has none of the dropped labels', (tester) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchSummaryCard(
          match: _match(),
          roundLabel: 'Lượt 1',
          onTap: () {},
        ),
      ),
    );

    for (final dropped in [
      'TRỰC TIẾP',
      'Vào phòng',
      'Main Bracket',
      'Đang thi đấu',
    ]) {
      expect(find.textContaining(dropped), findsNothing, reason: dropped);
    }
  });

  testWidgets('missing code, time and court leave no placeholder text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchSummaryCard(
          match: _match(court: ''),
          roundLabel: 'Lượt 1',
          onTap: () {},
        ),
      ),
    );

    expect(find.textContaining('null'), findsNothing);
    expect(find.textContaining('#'), findsNothing);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('long names ellipsize at 320 dp without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchSummaryCard(
          match: _match(
            name1: 'Nguyễn Thị Hoàng Bảo Ngọc Khánh Vy Thiên Kim',
            name2: 'Trần Lê Quốc Anh Minh Hoàng Gia Bảo Long',
          ),
          roundLabel: 'Tứ kết nhánh thắng',
          matchCode: '#V1602',
          onTap: () {},
          onScore: () {},
        ),
        width: 320,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the card calls onTap, not onScore', (tester) async {
    var taps = 0;
    var scores = 0;
    await tester.pumpWidget(
      _harness(
        LiveMatchSummaryCard(
          match: _match(),
          roundLabel: 'Lượt 1',
          onTap: () => taps++,
          onScore: () => scores++,
        ),
      ),
    );

    await tester.tap(find.text('2 - 1'));
    expect(taps, 1);
    expect(scores, 0);
  });

  testWidgets('score button exists only with onScore and calls only it', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _harness(
        LiveMatchSummaryCard(
          match: _match(),
          roundLabel: 'Lượt 1',
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    var scores = 0;
    await tester.pumpWidget(
      _harness(
        LiveMatchSummaryCard(
          match: _match(),
          roundLabel: 'Lượt 1',
          onTap: () => taps++,
          onScore: () => scores++,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.edit_outlined));
    expect(scores, 1);
    expect(taps, 0);
  });

  testWidgets('many sets wrap instead of overflowing at 320 dp', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchSummaryCard(
          match: _match(finishedSets: 5),
          roundLabel: 'Lượt 1',
          onTap: () {},
          onScore: () {},
        ),
        width: 320,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('5-11'), findsNWidgets(5));
  });
}
