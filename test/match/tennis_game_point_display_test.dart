import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/core/utils/tennis_game_point_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

MatchModel _match({
  required Map<String, dynamic> scoreDetails,
  String sportKey = 'tennis',
}) {
  return MatchModel(
    id: 'match-1',
    round: 1,
    matchNumber: 1,
    team1Name: 'A',
    team2Name: 'B',
    sportKey: sportKey,
    scoreDetails: scoreDetails,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime.utc(2026, 9, 8),
  );
}

void main() {
  test('normalizes App numeric Tennis points to 0/15/30/40', () {
    final result = readTennisGamePointDisplay(
      _match(
        scoreDetails: {
          'liveState': {
            'tennisPointState': {
              'team1Point': 2,
              'team2Point': 0,
              'mode': 'game',
            },
          },
        },
      ),
      isLive: true,
    );

    expect(result?.team1, '30');
    expect(result?.team2, '0');
  });

  test('formats deuce advantage and tiebreak points', () {
    final advantage = readTennisGamePointDisplay(
      _match(
        scoreDetails: {
          'liveState': {
            'tennisPointState': {
              'team1Point': '40',
              'team2Point': 'A',
              'mode': 'standard',
            },
          },
        },
      ),
      isLive: true,
    );
    final tiebreak = readTennisGamePointDisplay(
      _match(
        scoreDetails: {
          'liveState': {
            'tennisPointState': {
              'team1Point': 7,
              'team2Point': 5,
              'mode': 'tiebreak',
            },
          },
        },
      ),
      isLive: true,
    );

    expect(advantage?.team1, '40');
    expect(advantage?.team2, 'Ad');
    expect(tiebreak?.team1, '7');
    expect(tiebreak?.team2, '5');
  });

  test('hides the current point outside a live Tennis match', () {
    final details = {
      'liveState': {
        'tennisPointState': {'team1Point': 2, 'team2Point': 0},
      },
    };

    expect(
      readTennisGamePointDisplay(_match(scoreDetails: details), isLive: false),
      isNull,
    );
    expect(
      readTennisGamePointDisplay(
        _match(scoreDetails: details, sportKey: 'pickleball'),
        isLive: true,
      ),
      isNull,
    );
  });
}
