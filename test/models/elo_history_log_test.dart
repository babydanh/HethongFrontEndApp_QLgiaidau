import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EloHistoryLog', () {
    test('computes the real ELO delta, independent of changedPoints', () {
      final log = EloHistoryLog.fromJson({
        'id': 'l1',
        'userId': 'u1',
        'previousElo': 1500,
        'newElo': 1484,
        'changedPoints': 16,
      });

      expect(log.eloDiff, -16);
      expect(log.isGain, isFalse);
      expect(log.changedPoints, 16);
    });

    test('a gain and a zero change are classified correctly', () {
      EloHistoryLog log(int prev, int next) =>
          EloHistoryLog.fromJson({'previousElo': prev, 'newElo': next});

      expect(log(1000, 1012).isGain, isTrue);
      expect(log(1000, 1000).isGain, isFalse);
    });

    test('reads snake_case keys and numeric strings, defaulting to zero', () {
      final log = EloHistoryLog.fromJson({
        'previous_elo': '1200',
        'new_elo': 1210.7,
        'changed_points': 'x',
        'created_at': '2026-06-01T00:00:00Z',
      });

      expect(log.previousElo, 1200);
      expect(log.newElo, 1210);
      expect(log.changedPoints, 0);
      expect(log.createdAt, '2026-06-01T00:00:00Z');
      expect(log.id, '');
      expect(log.match, isNull);
    });

    test('the nested match is parsed with the opponent and an upper-cased '
        'result', () {
      final log = EloHistoryLog.fromJson({
        'id': 'l1',
        'match': {
          'id': 'm1',
          'result': 'win',
          'tournamentName': 'Cúp A',
          'opponent': {'id': 'o1', 'fullName': 'Đối thủ'},
          'p1SetsWon': '2',
          'p2_sets_won': 1,
          'scoreDetails': {
            'sets': [1, 2],
          },
        },
      });

      final match = log.match!;
      expect(match.result, 'WIN');
      expect(match.opponentId, 'o1');
      expect(match.opponentName, 'Đối thủ');
      expect(match.p1SetsWon, 2);
      expect(match.p2SetsWon, 1);
      expect(match.scoreDetails, {
        'sets': [1, 2],
      });
    });

    test('opponent name prefers "name" over "fullName"', () {
      final match = EloHistoryMatch.fromJson({
        'opponent': {'name': 'Tên', 'fullName': 'Họ tên'},
      });

      expect(match.opponentName, 'Tên');
    });

    test('toJson round-trips and omits absent optional parts', () {
      final log = EloHistoryLog.fromJson({
        'id': 'l1',
        'userId': 'u1',
        'categoryId': 'c1',
        'reason': 'MATCH',
        'previousElo': 1000,
        'newElo': 1010,
        'changedPoints': 10,
        'createdAt': '2026-06-01',
        'match': {
          'id': 'm1',
          'opponent': {'id': 'o1'},
          'p1SetsWon': 2,
        },
      });

      final json = log.toJson();
      final again = EloHistoryLog.fromJson(json);

      expect(json.containsKey('matchId'), isFalse);
      expect((json['match'] as Map)['opponent'], {'id': 'o1'});
      expect((json['match'] as Map).containsKey('result'), isFalse);
      expect(again.categoryId, 'c1');
      expect(again.match?.p1SetsWon, 2);
      expect(again.match?.opponentId, 'o1');
      expect(again.eloDiff, 10);
    });
  });
}
