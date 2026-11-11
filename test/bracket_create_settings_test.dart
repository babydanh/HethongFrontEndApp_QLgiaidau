import 'package:app_quanly_giaidau/features/bracket/utils/bracket_create_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TC-BRKSET-01 initial values', () {
    test('uses the saved division config first', () {
      final s = initialBracketCreateSettings(
        bracketType: 'GROUP_STAGE_KNOCKOUT',
        participantCount: 16,
        roundConfig: {
          'groupsConfig': {
            'numGroups': 2,
            'teamsPerGroup': 8,
            'roundsToPlay': 2,
          },
          'advancementConfig': {'teamsAdvancing': 3},
          'playoffConfig': {
            'type': 'DOUBLE_ELIMINATION',
            'seedingType': 'RANDOM',
          },
        },
      );
      expect(s.numGroups, 2);
      expect(s.teamsPerGroup, 8);
      expect(s.teamsAdvancing, 3);
      expect(s.roundsToPlay, 2);
      expect(s.playoffType, 'DOUBLE_ELIMINATION');
      expect(s.seedingType, 'RANDOM');
    });

    test('falls back to the suggestion when nothing is saved', () {
      final s = initialBracketCreateSettings(
        bracketType: 'GROUP_STAGE_KNOCKOUT',
        participantCount: 16,
        roundConfig: null,
      );
      expect((s.numGroups, s.teamsPerGroup, s.teamsAdvancing), (4, 4, 2));
      expect(s.playoffType, 'SINGLE_ELIMINATION');
      expect(s.seedingType, 'SEEDED');
    });

    test('round robin is always one group', () {
      final s = initialBracketCreateSettings(
        bracketType: 'ROUND_ROBIN',
        participantCount: 10,
        roundConfig: {
          'groupsConfig': {'numGroups': 3, 'roundsToPlay': 9},
        },
      );
      expect(s.numGroups, 1);
      expect(s.roundsToPlay, 4);
    });
  });

  group('TC-BRKSET-02 roundConfig payload', () {
    const base = BracketCreateSettings(
      numGroups: 2,
      teamsPerGroup: 4,
      teamsAdvancing: 2,
      roundsToPlay: 1,
      playoffType: 'SINGLE_ELIMINATION',
      seedingType: 'SEEDED',
    );

    test('group stage keeps unrelated keys and writes the new values', () {
      final out = buildBracketCreateRoundConfig(
        bracketType: 'GROUP_STAGE_KNOCKOUT',
        existing: {
          'scoring': {'winPoints': 3},
          'advancementConfig': {
            'allowWildcardThird': true,
            'wildcardTeamsAdvancing': 2,
          },
        },
        settings: base,
      );
      expect(out['scoring'], {'winPoints': 3});
      expect(out['groupsConfig'], {
        'numGroups': 2,
        'teamsPerGroup': 4,
        'roundsToPlay': 1,
      });
      expect(out['advancementConfig'], {
        'allowWildcardThird': true,
        'wildcardTeamsAdvancing': 2,
        'teamsAdvancing': 2,
      });
      expect(out['playoffConfig'], {
        'type': 'SINGLE_ELIMINATION',
        'seedingType': 'SEEDED',
      });
    });

    test('drops stale saved groups when the group count changes', () {
      final out = buildBracketCreateRoundConfig(
        bracketType: 'GROUP_STAGE_KNOCKOUT',
        existing: {
          'groupsConfig': {
            'numGroups': 4,
            'groups': [
              {
                'name': 'A',
                'participantIds': ['x'],
              },
              {'name': 'B', 'participantIds': []},
              {'name': 'C', 'participantIds': []},
              {'name': 'D', 'participantIds': []},
            ],
          },
        },
        settings: base,
      );
      expect((out['groupsConfig'] as Map).containsKey('groups'), isFalse);
    });

    test('keeps saved groups when the group count is unchanged', () {
      final out = buildBracketCreateRoundConfig(
        bracketType: 'GROUP_STAGE_KNOCKOUT',
        existing: {
          'groupsConfig': {
            'numGroups': 2,
            'groups': [
              {
                'name': 'A',
                'participantIds': ['x'],
              },
              {
                'name': 'B',
                'participantIds': ['y'],
              },
            ],
          },
        },
        settings: base,
      );
      expect((out['groupsConfig'] as Map)['groups'], hasLength(2));
    });

    test('advancing is clamped below teams per group', () {
      final out = buildBracketCreateRoundConfig(
        bracketType: 'GROUP_STAGE_KNOCKOUT',
        existing: null,
        settings: const BracketCreateSettings(
          numGroups: 2,
          teamsPerGroup: 3,
          teamsAdvancing: 9,
          roundsToPlay: 1,
          playoffType: 'SINGLE_ELIMINATION',
          seedingType: 'RANDOM',
        ),
      );
      expect((out['advancementConfig'] as Map)['teamsAdvancing'], 2);
    });

    test('round robin writes one group and only the legs', () {
      final out = buildBracketCreateRoundConfig(
        bracketType: 'ROUND_ROBIN',
        existing: {
          'scoring': {'winPoints': 3},
        },
        settings: base,
      );
      expect(out['scoring'], {'winPoints': 3});
      expect(out['groupsConfig'], {'numGroups': 1, 'roundsToPlay': 1});
      expect(out.containsKey('playoffConfig'), isFalse);
    });
  });
}
