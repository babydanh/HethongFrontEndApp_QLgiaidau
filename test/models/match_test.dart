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

    test('should handle TBD team names', () {
      final json = {'team1Name': null, 'team2Name': null};
      final match = MatchModel.fromJson(json, 'm1');
      expect(match.team1Name, 'TBD');
      expect(match.team2Name, 'TBD');
    });
  });

    final _defaultBracket = BracketPosition(round: 1, position: 0);
    final _now = DateTime.now();

  // Test MatchModel isLive/isCompleted
  group('TC-FLUTTER-MATCH-005: MatchModel status getters', () {
    test('isLive returns true for live statuses', () {
      expect(MatchModel(id: '1', round: 1, matchNumber: 1, status: 'live', bracketPosition: _defaultBracket, updatedAt: _now).isLive, true);
      expect(MatchModel(id: '1', round: 1, matchNumber: 1, status: 'ongoing', bracketPosition: _defaultBracket, updatedAt: _now).isLive, true);
      expect(MatchModel(id: '1', round: 1, matchNumber: 1, status: 'in_progress', bracketPosition: _defaultBracket, updatedAt: _now).isLive, true);
    });

    test('isLive returns false for non-live statuses', () {
      expect(MatchModel(id: '1', round: 1, matchNumber: 1, status: 'scheduled', bracketPosition: _defaultBracket, updatedAt: _now).isLive, false);
      expect(MatchModel(id: '1', round: 1, matchNumber: 1, status: 'completed', bracketPosition: _defaultBracket, updatedAt: _now).isLive, false);
      expect(MatchModel(id: '1', round: 1, matchNumber: 1, status: 'cancelled', bracketPosition: _defaultBracket, updatedAt: _now).isLive, false);
    });

    test('isCompleted returns true for completed', () {
      expect(MatchModel(id: '1', round: 1, matchNumber: 1, status: 'completed', bracketPosition: _defaultBracket, updatedAt: _now).isCompleted, true);
      expect(MatchModel(id: '1', round: 1, matchNumber: 1, status: 'scheduled', bracketPosition: _defaultBracket, updatedAt: _now).isCompleted, false);
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
      final bp = BracketPosition.fromJson({'bracket': 'winners', 'round': 2, 'position': 1});
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
