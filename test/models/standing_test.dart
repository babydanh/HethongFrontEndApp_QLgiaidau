// Tests for Standing entity
// Covers: RANKING-012, RANKING-009, RANKING-010

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';

void main() {
  group('TC-FLUTTER-RANKING-012: Standing.fromJson', () {
    test('should parse full JSON correctly', () {
      final json = {
        'teamName': 'Doi A',
        'group': 'Bang A',
        'played': 5,
        'won': 4,
        'lost': 1,
        'drawn': 0,
        'pointsFor': 20,
        'pointsAgainst': 10,
        'pointDifference': 10,
        'totalPoints': 12,
      };

      final standing = Standing.fromJson(json, 'standing-1');

      expect(standing.id, 'standing-1');
      expect(standing.teamName, 'Doi A');
      expect(standing.group, 'Bang A');
      expect(standing.played, 5);
      expect(standing.won, 4);
      expect(standing.lost, 1);
      expect(standing.drawn, 0);
      expect(standing.pointsFor, 20);
      expect(standing.pointsAgainst, 10);
      expect(standing.pointDifference, 10);
      expect(standing.totalPoints, 12);
    });

    test('should use defaults for missing fields', () {
      final json = {'teamName': ''};
      final standing = Standing.fromJson(json, '1');
      expect(standing.played, 0);
      expect(standing.won, 0);
      expect(standing.lost, 0);
      expect(standing.drawn, 0);
      expect(standing.pointsFor, 0);
      expect(standing.pointsAgainst, 0);
      expect(standing.pointDifference, 0);
      expect(standing.totalPoints, 0);
      expect(standing.group, '');
    });
  });

  group('Standing.toJson', () {
    test('should serialize correctly', () {
      final standing = Standing(
        id: '1', teamName: 'Doi A',
        played: 3, won: 3, totalPoints: 9,
      );
      final json = standing.toJson();
      expect(json['teamName'], 'Doi A');
      expect(json['played'], 3);
      expect(json['totalPoints'], 9);
    });
  });

  group('Standing.copyWith', () {
    test('should update specified fields', () {
      final s = Standing(id: '1', teamName: 'A');
      final s2 = s.copyWith(teamName: 'B', won: 3);
      expect(s2.teamName, 'B');
      expect(s2.won, 3);
      expect(s2.id, '1');
    });
  });
}
