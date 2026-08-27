import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';

void main() {
  group('FootballLiveState simplified terminal semantics', () {
    test('completes a non-draw result without a decisive phase', () {
      const state = FootballLiveState(
        team1Goals: 1,
        team2Goals: 0,
        phase: 'FIRST_HALF',
        minute: 0,
      );

      expect(state.isMatchComplete, isTrue);
      expect(state.winnerTeam, 1);
      expect(state.isDecisivePhase, isTrue);
    });

    test('does not require time or phase for either scoring direction', () {
      const team1 = FootballLiveState(
        team1Goals: 1,
        team2Goals: 0,
        phase: 'HALFTIME',
        minute: 12,
      );
      const team2 = FootballLiveState(
        team1Goals: 0,
        team2Goals: 2,
        phase: 'FIRST_HALF',
        minute: 0,
      );

      expect(team1.winnerTeam, 1);
      expect(team1.isMatchComplete, isTrue);
      expect(team2.winnerTeam, 2);
      expect(team2.isMatchComplete, isTrue);
    });

    test('a draw remains incomplete until unequal shootout values exist', () {
      const noShootout = FootballLiveState(
        phase: 'FIRST_HALF',
        team1Goals: 0,
        team2Goals: 0,
      );
      const tiedShootout = FootballLiveState(
        phase: 'FIRST_HALF',
        team1Goals: 0,
        team2Goals: 0,
        shootoutTeam1Goals: 3,
        shootoutTeam2Goals: 3,
      );
      const validShootout = FootballLiveState(
        phase: 'HALFTIME',
        team1Goals: 0,
        team2Goals: 0,
        shootoutTeam1Goals: 4,
        shootoutTeam2Goals: 3,
      );

      expect(noShootout.isMatchComplete, isFalse);
      expect(tiedShootout.hasValidShootout, isFalse);
      expect(tiedShootout.winnerTeam, 0);
      expect(validShootout.hasValidShootout, isTrue);
      expect(validShootout.isMatchComplete, isTrue);
      expect(validShootout.winnerTeam, 1);
    });

    test(
      'regulation goals determine winner even when phase is shootout metadata',
      () {
        const state = FootballLiveState(
          phase: 'PENALTY_SHOOTOUT',
          team1Goals: 1,
          team2Goals: 0,
        );

        expect(state.isMatchComplete, isTrue);
        expect(state.winnerTeam, 1);
      },
    );

    test('copyWith can clear one shootout field when input is empty', () {
      const state = FootballLiveState(
        shootoutTeam1Goals: 4,
        shootoutTeam2Goals: 3,
      );

      final cleared = state.copyWith(shootoutTeam1Goals: null);

      expect(cleared.shootoutTeam1Goals, isNull);
      expect(cleared.shootoutTeam2Goals, 3);
    });
  });
}
