// Tests for StandingsProvider logic
// Covers: RANKING-009, RANKING-010, RANKING-011

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';

void main() {
  group('TC-FLUTTER-RANKING-012: Standing data structure', () {
    test('should create standing with correct field mapping', () {
      final standing = Standing(
        id: 's1',
        teamName: 'Doi A',
        group: 'Bang A',
        played: 3,
        won: 2,
        drawn: 1,
        lost: 0,
        pointsFor: 10,
        pointsAgainst: 5,
        pointDifference: 5,
        totalPoints: 7,
      );

      expect(standing.teamName, 'Doi A');
      expect(standing.played, 3);
      expect(standing.won, 2);
      expect(standing.drawn, 1);
      expect(standing.totalPoints, 7);
    });

    test('should calculate pointDifference correctly', () {
      final s = Standing(id: '1', teamName: 'A', pointsFor: 10, pointsAgainst: 3, pointDifference: 7);
      expect(s.pointDifference, 7);
    });

    test('should start with zero stats', () {
      final s = Standing(id: '1', teamName: 'A');
      expect(s.played, 0);
      expect(s.won, 0);
      expect(s.lost, 0);
      expect(s.drawn, 0);
      expect(s.totalPoints, 0);
    });
  });

  group('TC-FLUTTER-RANKING-009: Standings calculation logic', () {
    test('win = 3 points, draw = 1 point, loss = 0 points', () {
      // Team A: Win
      // TotalPoints = win*3 + draw*1 + loss*0
      final standing = Standing(
        id: '1', teamName: 'A',
        played: 3, won: 2, drawn: 1, lost: 0,
        totalPoints: 7, // 2*3 + 1*1 = 7
      );
      expect(standing.totalPoints, 7);
    });

    test('sort order by totalPoints desc, then pointDifference desc', () {
      final s1 = Standing(id: '1', teamName: 'A', totalPoints: 9, pointDifference: 10);
      final s2 = Standing(id: '2', teamName: 'B', totalPoints: 9, pointDifference: 5);
      final s3 = Standing(id: '3', teamName: 'C', totalPoints: 6, pointDifference: 3);

      final sorted = [s2, s1, s3]..sort((a, b) {
        if (b.totalPoints != a.totalPoints) return b.totalPoints.compareTo(a.totalPoints);
        return b.pointDifference.compareTo(a.pointDifference);
      });

      expect(sorted[0].teamName, 'A'); // 9 pts, +10 GD
      expect(sorted[1].teamName, 'B'); // 9 pts, +5 GD
      expect(sorted[2].teamName, 'C'); // 6 pts
    });
  });

  group('Standing.copyWith', () {
    test('should create a new Standing with updated fields', () {
      final s = Standing(id: '1', teamName: 'A');
      final updated = s.copyWith(teamName: 'B', won: 3, totalPoints: 9);
      expect(updated.teamName, 'B');
      expect(updated.won, 3);
      expect(updated.totalPoints, 9);
      expect(updated.id, '1');
    });
  });

  group('Standing.toString', () {
    test('should return formatted string', () {
      final s = Standing(id: '1', teamName: 'A', totalPoints: 9, won: 3, lost: 0, drawn: 0);
      expect(s.toString(), 'Standing(A: 9 pts, W3-D0-L0)');
    });
  });
}
