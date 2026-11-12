import 'package:app_quanly_giaidau/features/tournament/utils/planned_rounds.dart';
import 'package:flutter_test/flutter_test.dart';

List<PlannedRound> _ko(int? teams, {String type = 'SINGLE_ELIMINATION'}) =>
    computePlannedRounds(bracketType: type, maxParticipants: teams);

void main() {
  test('TC-ROUND-DRAFT-01: 2 đội → 1 vòng (Chung kết)', () {
    final rounds = _ko(2);
    expect(rounds.length, 1);
    expect(rounds.single.kind, PlannedRoundKind.knockout);
    expect(rounds.single.roundKey, '1');
  });

  test('TC-ROUND-DRAFT-02: 3-4 đội → 2 vòng, 5-8 đội → 3 vòng', () {
    expect([_ko(3).length, _ko(4).length], [2, 2]);
    expect([_ko(5).length, _ko(8).length], [3, 3]);
  });

  test('TC-ROUND-DRAFT-03: 12 đội → 4 vòng, khóa 1..4', () {
    final rounds = _ko(12);
    expect(rounds.map((r) => r.roundKey), ['1', '2', '3', '4']);
    expect(rounds.every((r) => r.totalKnockoutRounds == 4), isTrue);
  });

  test('TC-ROUND-DRAFT-04: 64 và 100 đội đều chặn ở 6 vòng', () {
    expect([_ko(64).length, _ko(100).length, _ko(100000).length], [6, 6, 6]);
  });

  test('TC-ROUND-DRAFT-05: null, 0, 1 đội hoặc âm → rỗng', () {
    for (final teams in [null, 0, 1, -3]) {
      expect(_ko(teams), isEmpty);
    }
  });

  test('TC-ROUND-DRAFT-06: SWISS → rỗng', () {
    expect(_ko(16, type: 'SWISS'), isEmpty);
  });

  test('TC-ROUND-DRAFT-07: ROUND_ROBIN chỉ có phần vòng bảng', () {
    final rounds = _ko(8, type: 'ROUND_ROBIN');
    expect(rounds.map((r) => r.roundKey), [null, 'leg_1']);
    expect(rounds.first.kind, PlannedRoundKind.groupShared);
  });

  test('TC-ROUND-DRAFT-08: GROUP_STAGE_KNOCKOUT = vòng 0 + lượt + knockout '
      'theo nhóm × đội đi tiếp', () {
    final rounds = computePlannedRounds(
      bracketType: 'GROUP_STAGE_KNOCKOUT',
      maxParticipants: 100,
      groupCount: 2,
      teamsAdvancing: 2,
      roundConfig: {
        'groupsConfig': {'roundsToPlay': 2},
      },
    );
    expect(rounds.map((r) => r.roundKey), [null, 'leg_1', 'leg_2', '1', '2']);
  });

  test('TC-ROUND-DRAFT-09: lượt đã lưu leg_3 vẫn được tính; vòng knockout '
      'không còn thì ẩn nhưng không đụng khóa đã lưu', () {
    final saved = {
      'rounds': {
        'leg_3': {'x': 1},
        '5': {'y': 1},
      },
    };
    final rounds = computePlannedRounds(
      bracketType: 'GROUP_STAGE_KNOCKOUT',
      maxParticipants: 8,
      groupCount: 2,
      teamsAdvancing: 2,
      roundConfig: saved,
    );
    expect(rounds.map((r) => r.roundKey), [
      null,
      'leg_1',
      'leg_2',
      'leg_3',
      '1',
      '2',
    ]);
    expect((saved['rounds'] as Map).containsKey('5'), isTrue);
  });
}
