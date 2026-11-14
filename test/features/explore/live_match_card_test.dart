import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_match_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  String team1Name = 'Đội Sao Đỏ',
  String team2Name = 'Đội Sao Xanh',
  int score1 = 0,
  int score2 = 0,
  String court = '',
  String? tournamentName,
  Map<String, dynamic>? scoreDetails,
  String status = 'live',
}) => MatchModel(
  id: 'm1',
  round: 1,
  matchNumber: 1,
  team1Id: 't1',
  team2Id: 't2',
  team1Name: team1Name,
  team2Name: team2Name,
  score1: score1,
  score2: score2,
  court: court,
  tournamentName: tournamentName,
  scoreDetails: scoreDetails,
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 0),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester,
  MatchModel match, {
  VoidCallback? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: Center(
          child: LiveMatchCard(match: match, onTap: onTap ?? () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('hiện nhãn LIVE, tên hai đội và tỉ số hiện tại', (tester) async {
    await _pump(tester, _match(score1: 11, score2: 7));

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Đội Sao Đỏ'), findsOneWidget);
    expect(find.text('Đội Sao Xanh'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('có tên giải thì hiện tên giải trên đầu thẻ', (tester) async {
    await _pump(tester, _match(tournamentName: 'Giải Mùa Hè 2026'));

    expect(find.text('Giải Mùa Hè 2026'), findsOneWidget);
  });

  testWidgets('không có tên giải thì không dựng dòng tên giải', (tester) async {
    await _pump(tester, _match());

    expect(find.textContaining('Giải'), findsNothing);
  });

  testWidgets('chưa xếp sân hiện Chưa xếp sân, có sân thì hiện tên sân', (
    tester,
  ) async {
    await _pump(tester, _match());
    expect(find.text('Chưa xếp sân'), findsOneWidget);

    await _pump(tester, _match(court: 'Sân số 3'));
    expect(find.text('Sân số 3'), findsOneWidget);
    expect(find.text('Chưa xếp sân'), findsNothing);
  });

  testWidgets(
    'đang trong séc chưa kết thúc thì hiện tỉ số séc đó thay vì tổng số séc',
    (tester) async {
      await _pump(
        tester,
        _match(
          score1: 1,
          score2: 0,
          scoreDetails: {
            'sets': [
              {'score1': 21, 'score2': 15, 'isFinished': true},
              {'score1': 9, 'score2': 4, 'isFinished': false},
            ],
          },
        ),
      );

      expect(find.text('9'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('21'), findsNothing);
    },
  );

  testWidgets('vừa xong séc và séc mới chưa có điểm thì tỉ số về 0 - 0', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        score1: 1,
        score2: 0,
        scoreDetails: {
          'sets': [
            {'score1': 21, 'score2': 15, 'isFinished': true},
          ],
        },
      ),
    );

    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('21'), findsNothing);
  });

  testWidgets('tên đội dài bị cắt tối đa hai dòng và không tràn khung', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(team1Name: 'Câu lạc bộ ${'rất dài ' * 20}', score1: 3),
    );

    final text = tester.widget<Text>(find.textContaining('Câu lạc bộ'));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chạm vào thẻ gọi onTap đúng một lần', (tester) async {
    var taps = 0;
    await _pump(tester, _match(), onTap: () => taps++);

    await tester.tap(find.text('LIVE'));

    expect(taps, 1);
  });
}
