import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/group_stage_config.dart';
import 'package:flutter_test/flutter_test.dart';

Team _team(
  String id, {
  String divisionId = 'division-a',
  String status = 'COMPLETE',
}) => Team(
  id: id,
  name: 'Team $id',
  divisionId: divisionId,
  approvalStatus: status,
  createdAt: DateTime.utc(2026),
);

TournamentDivision _division(Map<String, dynamic>? roundConfig) =>
    TournamentDivision.fromJson({
      'id': 'division-a',
      'name': 'Open',
      'tournamentConfig': {'roundConfig': ?roundConfig},
    });

void main() {
  test(
    'resolves saved groups and excludes unapproved or other-division teams',
    () {
      final config = resolveGroupStageConfig(
        division: _division({
          'groupsConfig': {
            'numGroups': 2,
            'teamsPerGroup': 2,
            'groups': [
              {
                'name': 'A',
                'participantIds': ['team-1', 'stale-id'],
              },
              {
                'name': 'B',
                'participantIds': ['team-2', 'team-1'],
              },
            ],
          },
          'advancementConfig': {'teamsAdvancing': 1},
          'tieBreakRule': 'HEAD_TO_HEAD',
        }),
        tournamentConfig: const {
          'numberOfGroups': 3,
          'teamsAdvancingPerGroup': 2,
        },
        teams: [
          _team('team-1'),
          _team('team-2'),
          _team('team-3'),
          _team('pending', status: 'PENDING_APPROVAL'),
          _team('other-division', divisionId: 'division-b'),
        ],
      );

      expect(config.groups.map((group) => group.name), ['A', 'B']);
      expect(config.groups.map((group) => group.participantIds.toList()), [
        ['team-1'],
        ['team-2'],
      ]);
      expect(config.unassignedParticipantIds, ['team-3']);
      expect(config.teamsAdvancing, 1);
      expect(config.teamsPerGroup, 2);
    },
  );

  test('uses tournament fallbacks and derives teams per group', () {
    final config = resolveGroupStageConfig(
      division: _division(null),
      tournamentConfig: const {
        'numberOfGroups': '2',
        'teamsAdvancingPerGroup': '1',
      },
      teams: [
        _team('team-1'),
        _team('team-2'),
        _team('team-3'),
        _team('team-4'),
      ],
    );

    expect(config.groups, hasLength(2));
    expect(config.groups.map((group) => group.name), ['A', 'B']);
    expect(config.unassignedParticipantIds, [
      'team-1',
      'team-2',
      'team-3',
      'team-4',
    ]);
    expect(config.teamsAdvancing, 1);
    expect(config.teamsPerGroup, 2);
  });
  test('continues group names alphabetically after Z', () {
    final config = resolveGroupStageConfig(
      division: _division(null),
      tournamentConfig: const {'numberOfGroups': 28},
      teams: List.generate(56, (index) => _team('team-${index + 1}')),
    );

    expect(config.groups, hasLength(28));
    expect(config.groups[25].name, 'Z');
    expect(config.groups[26].name, 'AA');
    expect(config.groups[27].name, 'AB');
  });

  test(
    'keeps an existing group-count choice and moves removed groups to unassigned',
    () {
      final config = resolveGroupStageConfig(
        division: _division({
          'groupsConfig': {
            'numGroups': 4,
            'groups': [
              {
                'name': 'A',
                'participantIds': ['team-1'],
              },
              {
                'name': 'B',
                'participantIds': ['team-2'],
              },
              {
                'name': 'C',
                'participantIds': ['team-3'],
              },
              {
                'name': 'D',
                'participantIds': ['team-4'],
              },
            ],
          },
        }),
        tournamentConfig: const {},
        teams: List.generate(7, (index) => _team('team-${index + 1}')),
      );

      expect(groupCountOptions(participantCount: 7, currentGroupCount: 4), [
        1,
        2,
        3,
        4,
      ]);
      final resized = config.resizeGroupCount(2);

      expect(resized.groups.map((group) => group.name), ['A', 'B']);
      expect(resized.unassignedParticipantIds, [
        'team-5',
        'team-6',
        'team-7',
        'team-3',
        'team-4',
      ]);
      expect(resized.teamsPerGroup, 4);
    },
  );

  test(
    'moves a participant before the selected team and back to unassigned',
    () {
      final config = resolveGroupStageConfig(
        division: _division({
          'groupsConfig': {
            'numGroups': 2,
            'groups': [
              {
                'name': 'A',
                'participantIds': ['team-1'],
              },
              {
                'name': 'B',
                'participantIds': ['team-2', 'team-3'],
              },
            ],
          },
        }),
        tournamentConfig: const {},
        teams: [_team('team-1'), _team('team-2'), _team('team-3')],
      );

      final moved = config.moveParticipant(
        'team-1',
        groupIndex: 1,
        beforeParticipantId: 'team-3',
      );
      expect(moved.groups.map((group) => group.participantIds.toList()), [
        <String>[],
        ['team-2', 'team-1', 'team-3'],
      ]);

      final unassigned = moved.moveParticipant('team-1');
      expect(unassigned.groups.last.participantIds, ['team-2', 'team-3']);
      expect(unassigned.unassignedParticipantIds, ['team-1']);
    },
  );

  test('builds a PATCH payload without dropping existing round settings', () {
    final config =
        resolveGroupStageConfig(
              division: _division({
                'groupsConfig': {'numGroups': 1},
              }),
              tournamentConfig: const {},
              teams: [_team('team-1'), _team('team-2')],
            )
            .moveParticipant('team-1', groupIndex: 0)
            .moveParticipant('team-2', groupIndex: 0);

    expect(
      buildDivisionConfigPatchPayload(
        currentRoundConfig: const {
          'tieBreakRule': 'HEAD_TO_HEAD',
          'groupsConfig': {'seeding': 'RANDOM'},
        },
        config: config,
      ),
      {
        'isConfigOverride': true,
        'roundConfig': {
          'tieBreakRule': 'HEAD_TO_HEAD',
          'groupsConfig': {
            'seeding': 'RANDOM',
            'numGroups': 1,
            'teamsPerGroup': 2,
            'groups': [
              {
                'name': 'A',
                'participantIds': ['team-1', 'team-2'],
              },
            ],
          },
        },
      },
    );
  });

  test('parses top-level and legacy division round configuration', () {
    const topLevelRoundConfig = {
      'groupsConfig': {'numGroups': 2},
    };
    const legacyDivisionConfig = {
      'groupsConfig': {'numGroups': 3},
      'advancementConfig': {'teamsAdvancing': 1},
    };
    final topLevelDivision = TournamentDivision.fromJson({
      'id': 'division-a',
      'name': 'Open',
      'roundConfig': topLevelRoundConfig,
    });
    final legacyDivision = TournamentDivision.fromJson({
      'id': 'division-a',
      'name': 'Open',
      'tournamentConfig': legacyDivisionConfig,
    });

    expect(topLevelDivision.roundConfig, topLevelRoundConfig);
    expect(legacyDivision.roundConfig, legacyDivisionConfig);
  });

  test('keeps division roundConfig available after parsing and copying', () {
    final roundConfig = {
      'groupsConfig': {'numGroups': 2},
      'advancementConfig': {'teamsAdvancing': 1},
    };
    final division = _division(roundConfig);

    expect(division.roundConfig, roundConfig);
    expect(division.copyWith().roundConfig, roundConfig);
    expect(division.toJson().containsKey('roundConfig'), isFalse);
    expect(division.copyWith(roundConfig: {'groupsConfig': {}}).roundConfig, {
      'groupsConfig': <String, dynamic>{},
    });
  });

  test('invalid saved group data falls back without losing eligible teams', () {
    final config = resolveGroupStageConfig(
      division: _division({
        'groupsConfig': {'numGroups': 'invalid', 'groups': 'invalid'},
        'advancementConfig': 'invalid',
      }),
      tournamentConfig: const {
        'numberOfGroups': 2,
        'teamsAdvancingPerGroup': 1,
      },
      teams: [_team('team-1'), _team('team-2'), _team('team-3')],
    );

    expect(config.groups.map((group) => group.name), ['A', 'B']);
    expect(
      config.groups.every((group) => group.participantIds.isEmpty),
      isTrue,
    );
    expect(config.unassignedParticipantIds, ['team-1', 'team-2', 'team-3']);
    expect(config.teamsAdvancing, 1);
  });
}
