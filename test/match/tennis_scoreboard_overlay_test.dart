import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/scoreboard_set_columns.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/tennis_live_scoreboard_overlay.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/tennis_scoreboard_columns.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  String sportKey = 'tennis',
  Map<String, dynamic>? scoreDetails,
  String status = 'ONGOING',
}) => MatchModel(
  id: 'match-1',
  tournamentId: 'tournament-1',
  round: 1,
  matchNumber: 1,
  sportKey: sportKey,
  status: status,
  scoreDetails: scoreDetails,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 26),
);

Map<String, dynamic> _points(Object team1, Object team2) => {
  'liveState': {
    'tennisPointState': {'mode': 'game', 'team1Point': team1, 'team2Point': team2},
  },
};

void main() {
  group('TC-TENNIS-OVL-APP-06 tennis set columns', () {
    test('set 1 shows from the start, even before any game', () {
      final columns = tennisScoreboardSetColumns(const []);
      expect(columns.map((c) => c.setNumber), [1]);
      expect(columns.single.state, SetColumnState.current);
    });

    test('the set being played is a column, games in it', () {
      final columns = tennisScoreboardSetColumns(const [
        SetScoreData(score1: 0, score2: 1),
      ]);
      expect(columns.single.team2, 1);
      expect(columns.single.state, SetColumnState.current);
    });

    test('set 2 is hidden until it starts, then shown with set 1', () {
      const afterSet1 = [
        SetScoreData(score1: 6, score2: 3, isFinished: true),
        SetScoreData(score1: 0, score2: 0),
      ];
      expect(
        tennisScoreboardSetColumns(afterSet1).map((c) => c.setNumber),
        [1],
      );
      // A point played in set 2 starts it.
      final started = tennisScoreboardSetColumns(afterSet1, pointsInPlay: true);
      expect(started.map((c) => c.setNumber), [1, 2]);
      expect(started.first.winner, 1);
      expect(started.last.state, SetColumnState.current);
    });

    test('set 3 shows once a game of it is played', () {
      final columns = tennisScoreboardSetColumns(const [
        SetScoreData(score1: 6, score2: 4, isFinished: true),
        SetScoreData(score1: 3, score2: 6, isFinished: true),
        SetScoreData(score1: 1, score2: 0),
      ]);
      expect(columns.map((c) => c.setNumber), [1, 2, 3]);
      expect(columns.map((c) => c.winner), [1, 2, null]);
    });

    test('a finished match has no current set', () {
      final columns = tennisScoreboardSetColumns(const [
        SetScoreData(score1: 6, score2: 4, isFinished: true),
        SetScoreData(score1: 6, score2: 2),
      ], matchFinished: true);
      expect(columns.every((c) => c.state == SetColumnState.finished), isTrue);
      expect(columns.last.winner, 1);
    });
  });

  group('TC-TENNIS-OVL-APP-07 tennis point of the game', () {
    test('App int indexes read as 0/15/30/40', () {
      expect(tennisScoreboardPoints(_match(scoreDetails: _points(2, 0))), (
        team1: '30',
        team2: '0',
      ));
      expect(tennisScoreboardPoints(_match(scoreDetails: _points(1, 3))), (
        team1: '15',
        team2: '40',
      ));
    });

    test('deuce is 40-40 and advantage is AD', () {
      expect(tennisScoreboardPoints(_match(scoreDetails: _points(3, 3))), (
        team1: '40',
        team2: '40',
      ));
      expect(tennisScoreboardPoints(_match(scoreDetails: _points(4, 3))), (
        team1: 'AD',
        team2: '40',
      ));
    });

    test('Web strings read too', () {
      expect(tennisScoreboardPoints(_match(scoreDetails: _points('40', 'A'))), (
        team1: '40',
        team2: 'AD',
      ));
    });

    test('no point state yet is 0-0; a finished match has none', () {
      expect(tennisScoreboardPoints(_match()), (team1: '0', team2: '0'));
      expect(
        tennisScoreboardPoints(
          _match(scoreDetails: _points(2, 0), status: 'COMPLETED'),
        ),
        isNull,
      );
    });

    test('only tennis gets the tennis board', () {
      expect(isTennisScoreboardMatch(_match()), isTrue);
      expect(isTennisScoreboardMatch(_match(sportKey: 'pickleball')), isFalse);
      expect(isTennisScoreboardMatch(_match(sportKey: 'badminton')), isFalse);
    });
  });

  testWidgets(
    'TC-TENNIS-OVL-APP-08 the board draws games per set and the point',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TennisLiveScoreboardOverlay(
                team1: Text('AAA'),
                team2: Text('BBB'),
                sets: [
                  SetColumn(
                    setNumber: 1,
                    team1: 6,
                    team2: 3,
                    state: SetColumnState.finished,
                    winner: 1,
                  ),
                  SetColumn(
                    setNumber: 2,
                    team1: 2,
                    team2: 1,
                    state: SetColumnState.current,
                    winner: null,
                  ),
                ],
                point1: 'AD',
                point2: '40',
              ),
            ),
          ),
        ),
      );

      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
    },
  );
}
