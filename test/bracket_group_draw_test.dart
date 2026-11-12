import 'dart:math';

import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_group_draw.dart';
import 'package:flutter_test/flutter_test.dart';

Team _team(String id, {int? elo}) => Team(
  id: id,
  name: 'Team $id',
  divisionId: 'division-a',
  approvalStatus: 'COMPLETE',
  eloPoints: elo,
  createdAt: DateTime.utc(2026),
);

void main() {
  group('drawBracketGroups by ELO', () {
    test('spreads the strongest teams over the groups in snake order', () {
      final teams = [for (var i = 1; i <= 8; i++) _team('t$i', elo: i * 100)];

      final groups = drawBracketGroups(teams: teams, numGroups: 2, byElo: true);

      // Sorted strongest first: t8 t7 t6 t5 t4 t3 t2 t1, dealt A B B A A B B A.
      expect(groups, [
        ['t8', 't5', 't4', 't1'],
        ['t7', 't6', 't3', 't2'],
      ]);
    });

    test('puts teams without an ELO last and breaks ties by name', () {
      final teams = [
        _team('none'),
        _team('b', elo: 1000),
        _team('a', elo: 1000),
        _team('low', elo: 10),
      ];

      final groups = drawBracketGroups(teams: teams, numGroups: 2, byElo: true);

      // Order a, b, low, none dealt A B B A.
      expect(groups, [
        ['a', 'none'],
        ['b', 'low'],
      ]);
    });
  });

  group('drawBracketGroups at random', () {
    test('assigns every team exactly once and keeps groups balanced', () {
      final teams = [for (var i = 1; i <= 10; i++) _team('t$i')];

      final groups = drawBracketGroups(
        teams: teams,
        numGroups: 3,
        byElo: false,
        random: Random(7),
      );

      final all = groups.expand((ids) => ids).toList();
      expect(all.toSet(), {for (final team in teams) team.id});
      expect(all, hasLength(10));
      final sizes = groups.map((ids) => ids.length).toList()..sort();
      expect(sizes, [3, 3, 4]);
    });

    test('is reproducible for a given random source', () {
      final teams = [for (var i = 1; i <= 8; i++) _team('t$i')];

      List<List<String>> draw() => drawBracketGroups(
        teams: teams,
        numGroups: 2,
        byElo: false,
        random: Random(3),
      );

      expect(draw(), draw());
    });
  });

  test('a single group (round robin) holds every team', () {
    final teams = [for (var i = 1; i <= 4; i++) _team('t$i', elo: i)];

    final groups = drawBracketGroups(teams: teams, numGroups: 1, byElo: true);

    expect(groups, [
      ['t4', 't3', 't2', 't1'],
    ]);
  });

  test('no teams gives empty groups instead of failing', () {
    final groups = drawBracketGroups(
      teams: const [],
      numGroups: 2,
      byElo: false,
    );

    expect(groups, [<String>[], <String>[]]);
  });

  group('withDrawnGroups', () {
    test('writes the groups and keeps every other key', () {
      final result = withDrawnGroups(
        {
          'playoffConfig': {'type': 'SINGLE_ELIMINATION'},
          'groupsConfig': {'numGroups': 2, 'roundsToPlay': 1},
        },
        [
          ['t1', 't2'],
          ['t3', 't4'],
        ],
      );

      expect(result['playoffConfig'], {'type': 'SINGLE_ELIMINATION'});
      final groupsConfig = result['groupsConfig'] as Map;
      expect(groupsConfig['numGroups'], 2);
      expect(groupsConfig['roundsToPlay'], 1);
      expect(groupsConfig['groups'], [
        {
          'name': 'A',
          'participantIds': ['t1', 't2'],
        },
        {
          'name': 'B',
          'participantIds': ['t3', 't4'],
        },
      ]);
    });

    test('keeps a group name the organizer already chose', () {
      final result = withDrawnGroups(
        {
          'groupsConfig': {
            'groups': [
              {
                'name': 'Gold',
                'participantIds': ['old'],
              },
              {'participantIds': <String>[]},
            ],
          },
        },
        [
          ['t1'],
          ['t2'],
        ],
      );

      final groups = (result['groupsConfig'] as Map)['groups'] as List;
      expect((groups[0] as Map)['name'], 'Gold');
      expect((groups[0] as Map)['participantIds'], ['t1']);
      expect((groups[1] as Map)['name'], 'B');
    });

    test('does not mutate the roundConfig it was given', () {
      final original = <String, dynamic>{
        'groupsConfig': {'numGroups': 2},
      };

      withDrawnGroups(original, [
        ['t1'],
        ['t2'],
      ]);

      expect((original['groupsConfig'] as Map).containsKey('groups'), isFalse);
    });
  });
}
