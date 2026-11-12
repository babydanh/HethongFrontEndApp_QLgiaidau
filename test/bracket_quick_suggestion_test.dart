import 'package:app_quanly_giaidau/features/bracket/utils/bracket_quick_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TC-BRKSUG-01 group stage suggestion (same rule as Web)', () {
    test('16 teams -> 4 groups of 4, top 2 advance', () {
      final s = bracketQuickSuggestion(
        bracketType: 'GROUP_STAGE_KNOCKOUT',
        participantCount: 16,
      );
      expect((s?.groups, s?.teamsPerGroup, s?.teamsAdvancing), (4, 4, 2));
    });

    test('20 teams -> 4 groups of 5', () {
      final s = bracketQuickSuggestion(
        bracketType: 'group_stage_knockout',
        participantCount: 20,
      );
      expect((s?.groups, s?.teamsPerGroup, s?.teamsAdvancing), (4, 5, 2));
    });

    test('4 teams -> 2 groups of 2, only 1 advances', () {
      final s = bracketQuickSuggestion(
        bracketType: 'GROUP_STAGE_KNOCKOUT',
        participantCount: 4,
      );
      expect((s?.groups, s?.teamsPerGroup, s?.teamsAdvancing), (2, 2, 1));
    });

    test('fewer than 4 teams has no suggestion', () {
      expect(
        bracketQuickSuggestion(
          bracketType: 'GROUP_STAGE_KNOCKOUT',
          participantCount: 3,
        ),
        isNull,
      );
    });
  });

  group('TC-BRKSUG-02 round robin suggestion', () {
    test('up to 8 teams -> 1 leg', () {
      final s = bracketQuickSuggestion(
        bracketType: 'ROUND_ROBIN',
        participantCount: 8,
      );
      expect(s?.roundsToPlay, 1);
      expect(s?.groups, isNull);
    });

    test('9+ teams -> 2 legs', () {
      final s = bracketQuickSuggestion(
        bracketType: 'ROUND_ROBIN',
        participantCount: 9,
      );
      expect(s?.roundsToPlay, 2);
    });

    test('fewer than 2 teams has no suggestion', () {
      expect(
        bracketQuickSuggestion(bracketType: 'ROUND_ROBIN', participantCount: 1),
        isNull,
      );
    });
  });

  test('TC-BRKSUG-03 other formats have no suggestion', () {
    expect(
      bracketQuickSuggestion(
        bracketType: 'SINGLE_ELIMINATION',
        participantCount: 16,
      ),
      isNull,
    );
  });
}
