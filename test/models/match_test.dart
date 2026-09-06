// Tests for MatchModel entity
// Covers: MATCH-001, MATCH-005 related entity tests

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

void main() {
  // Test MatchModel.fromJson
  group('TC-FLUTTER-MATCH-001: MatchModel.fromJson', () {
    test('should parse full match JSON correctly', () {
      final json = {
        'id': 'match-1',
        'round': 1,
        'matchNumber': 1,
        'team1Id': 'team-1',
        'team2Id': 'team-2',
        'team1Name': 'Doi A',
        'team2Name': 'Doi B',
        'score1': 21,
        'score2': 15,
        'status': 'completed',
        'winnerId': 'team-1',
        'court': 'San 1',
        'scheduledTime': '2026-07-15T08:00:00Z',
        'refereeName': 'Trong tai A',
        'maxScore': 21,
        'winByTwo': true,
        'sets': [
          {'score1': 21, 'score2': 15},
          {'score1': 18, 'score2': 21},
          {'score1': 21, 'score2': 10},
        ],
        'bracketPosition': {'bracket': 'winners', 'round': 1, 'position': 0},
        'nextMatchId': 'match-2',
        'loserNextMatchId': 'loser-match-1',
      };

      // We can only test MatchModel.fromJson since MatchModel has fromJson
      final match = MatchModel.fromJson(json, 'match-1');

      expect(match.id, 'match-1');
      expect(match.round, 1);
      expect(match.team1Name, 'Doi A');
      expect(match.team2Name, 'Doi B');
      expect(match.status, 'completed');
      expect(match.court, 'San 1');
      expect(match.bracketPosition?.bracket, 'winners');
      expect(match.loserNextMatchId, 'loser-match-1');
    });

    test('should parse Minimal JSON with defaults', () {
      final json = {'name': 'Test'};
      final match = MatchModel.fromJson(json, 'match-1');

      expect(match.id, 'match-1');
      expect(match.round, 1);
      expect(match.team1Name, 'TBD');
      expect(match.team2Name, 'TBD');
      expect(match.status, 'scheduled');
      expect(match.score1, 0);
      expect(match.score2, 0);
      expect(match.winnerId, '');
    });

    test('uses backend set aggregate when score aliases are absent', () {
      final match = MatchModel.fromJson({
        'status': 'COMPLETED',
        'p1SetsWon': 2,
        'p2SetsWon': 1,
      }, 'match-aggregate');

      expect(match.score1, 2);
      expect(match.score2, 1);
    });

    test('should handle TBD team names', () {
      final json = {'team1Name': null, 'team2Name': null};
      final match = MatchModel.fromJson(json, 'm1');
      expect(match.team1Name, 'TBD');
      expect(match.team2Name, 'TBD');
    });

    test('reads the open set for live cards instead of the set aggregate', () {
      final match = MatchModel.fromJson({
        'status': 'ONGOING',
        'score1': 1,
        'score2': 0,
        'scoreDetails': {
          'sets': [
            {'team1Score': 11, 'team2Score': 7, 'isFinished': true},
            {'team1Score': 4, 'team2Score': 2, 'isFinished': false},
          ],
        },
      }, 'm1');

      expect(match.currentLiveScore.score1, 4);
      expect(match.currentLiveScore.score2, 2);
      expect(match.scoreHistory.map((set) => '${set.score1}-${set.score2}'), [
        '11-7',
        '4-2',
      ]);
      expect(match.sets.length, 2);
    });

    test('keeps Quick FREE scoring marker from top-level match payload', () {
      final match = MatchModel.fromJson({
        'sport': 'BADMINTON',
        'tournamentConfig': {
          'mode': 'STRICT',
          'scoringMode': 'FREE',
          'bestOf': 3,
          'setsToWin': 2,
        },
        'sportRules': {
          'kind': 'BADMINTON',
          'mode': 'STRICT',
          'bestOf': 3,
          'setsToWin': 2,
        },
      }, 'quick-free');

      expect(match.tournamentConfig?['scoringMode'], 'FREE');
      expect(match.sportRules?['scoringMode'], 'FREE');
    });
  });

  final _defaultBracket = BracketPosition(round: 1, position: 0);
  final _now = DateTime.now();

  // Test MatchModel isLive/isCompleted
  group('TC-FLUTTER-MATCH-005: MatchModel status getters', () {
    test('isLive returns true for live statuses', () {
      expect(
        MatchModel(
          id: '1',
          round: 1,
          matchNumber: 1,
          status: 'live',
          bracketPosition: _defaultBracket,
          updatedAt: _now,
        ).isLive,
        true,
      );
      expect(
        MatchModel(
          id: '1',
          round: 1,
          matchNumber: 1,
          status: 'ongoing',
          bracketPosition: _defaultBracket,
          updatedAt: _now,
        ).isLive,
        true,
      );
      expect(
        MatchModel(
          id: '1',
          round: 1,
          matchNumber: 1,
          status: 'in_progress',
          bracketPosition: _defaultBracket,
          updatedAt: _now,
        ).isLive,
        true,
      );
    });

    test('isLive returns false for non-live statuses', () {
      expect(
        MatchModel(
          id: '1',
          round: 1,
          matchNumber: 1,
          status: 'scheduled',
          bracketPosition: _defaultBracket,
          updatedAt: _now,
        ).isLive,
        false,
      );
      expect(
        MatchModel(
          id: '1',
          round: 1,
          matchNumber: 1,
          status: 'completed',
          bracketPosition: _defaultBracket,
          updatedAt: _now,
        ).isLive,
        false,
      );
      expect(
        MatchModel(
          id: '1',
          round: 1,
          matchNumber: 1,
          status: 'cancelled',
          bracketPosition: _defaultBracket,
          updatedAt: _now,
        ).isLive,
        false,
      );
    });

    test('isCompleted returns true for completed', () {
      expect(
        MatchModel(
          id: '1',
          round: 1,
          matchNumber: 1,
          status: 'completed',
          bracketPosition: _defaultBracket,
          updatedAt: _now,
        ).isCompleted,
        true,
      );
      expect(
        MatchModel(
          id: '1',
          round: 1,
          matchNumber: 1,
          status: 'scheduled',
          bracketPosition: _defaultBracket,
          updatedAt: _now,
        ).isCompleted,
        false,
      );
    });
  });

  // Test SetScore
  group('SetScore.fromJson', () {
    test('should parse correctly', () {
      final set = SetScore.fromJson({'score1': 21, 'score2': 15});
      expect(set.score1, 21);
      expect(set.score2, 15);
    });

    test('should use defaults', () {
      final set = SetScore.fromJson({});
      expect(set.score1, 0);
      expect(set.score2, 0);
    });
  });

  // Test BracketPosition
  group('BracketPosition.fromJson', () {
    test('should parse correctly', () {
      final bp = BracketPosition.fromJson({
        'bracket': 'winners',
        'round': 2,
        'position': 1,
      });
      expect(bp.bracket, 'winners');
      expect(bp.round, 2);
      expect(bp.position, 1);
    });

    test('should use defaults', () {
      final bp = BracketPosition.fromJson(<String, dynamic>{});
      expect(bp.bracket, 'winners');
      expect(bp.round, 1);
      expect(bp.position, 0);
    });
  });
}
