import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_data.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _m(
  String id,
  String a,
  String b, {
  int round = 1,
  String status = 'SCHEDULED',
  List<List<int>> sets = const [],
  int? leg,
}) => MatchModel.fromJson({
  'tournamentId': 't-1',
  'round': round,
  'matchNumber': 1,
  'status': status,
  'team1Id': a,
  'team2Id': b,
  'team1Name': a,
  'team2Name': b,
  'groupName': 'A',
  'leg': ?leg,
  'sets': [
    for (final s in sets) {'score1': s[0], 'score2': s[1]},
  ],
}, id);

void main() {
  group('TC-GSV-01 matrix cells', () {
    test('one line per set, mirrored for the other side', () {
      final cells = buildMatrixCells([
        _m(
          'm1',
          't1',
          't2',
          status: 'COMPLETED',
          sets: [
            [11, 8],
            [9, 11],
            [11, 5],
          ],
        ),
      ]);
      expect(cells['t1_t2']!.lines, ['11-8', '9-11', '11-5']);
      expect(cells['t2_t1']!.lines, ['8-11', '11-9', '5-11']);
    });

    test('unplayed match has an empty cell that still points at the match', () {
      final cells = buildMatrixCells([_m('m1', 't1', 't2')]);
      expect(cells['t1_t2']!.lines, isEmpty);
      expect(cells['t1_t2']!.match.id, 'm1');
    });
  });

  group('TC-GSV-02 legs and rounds', () {
    test('round restarts inside each leg (4 teams → 3 rounds per leg)', () {
      expect(legForMatch(_m('a', 't1', 't2', round: 3), 4), 1);
      expect(legForMatch(_m('b', 't1', 't2', round: 4), 4), 2);
      expect(roundInLeg(_m('b', 't1', 't2', round: 5), 4), 2);
    });

    test('persisted leg wins over the round calculation', () {
      expect(legForMatch(_m('a', 't1', 't2', round: 1, leg: 2), 4), 2);
    });
  });

  group('TC-GSV-03 names and rest team', () {
    test('bare group code gets the Bảng prefix once', () {
      expect(groupDisplayName('A', 'Bảng'), 'Bảng A');
      expect(groupDisplayName('Bảng B', 'Bảng'), 'Bảng B');
    });

    test('odd group: the team missing from the round rests', () {
      final standings = [
        for (final id in ['t1', 't2', 't3']) Standing(id: id, teamName: id),
      ];
      expect(restingTeam(standings, [_m('a', 't1', 't2')])!.id, 't3');
      expect(restingTeam(standings.take(2).toList(), []), isNull);
    });
  });
}
