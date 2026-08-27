import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';

void main() {
  group('FootballLiveState terminal semantics', () {
    test('does not complete before a decisive phase', () {
      const state = FootballLiveState(
        team1Goals: 1,
        team2Goals: 0,
        phase: 'FIRST_HALF',
      );

      expect(state.isDecisivePhase, isFalse);
      expect(state.isMatchComplete, isFalse);
      expect(state.winnerTeam, 0);
    });

    test('completes a non-draw result at full time with the higher scorer', () {
      const team1 = FootballLiveState(
        team1Goals: 1,
        team2Goals: 0,
        phase: 'FULL_TIME',
      );
      const team2 = FootballLiveState(
        team1Goals: 0,
        team2Goals: 2,
        phase: 'COMPLETED',
      );

      expect(team1.isMatchComplete, isTrue);
      expect(team1.winnerTeam, 1);
      expect(team2.isMatchComplete, isTrue);
      expect(team2.winnerTeam, 2);
    });

    test('requires penalty shootout for a regulation draw', () {
      const noShootout = FootballLiveState(
        phase: 'FULL_TIME',
        team1Goals: 0,
        team2Goals: 0,
      );
      const tiedShootout = FootballLiveState(
        phase: 'PENALTY_SHOOTOUT',
        team1Goals: 0,
        team2Goals: 0,
        shootoutTeam1Goals: 3,
        shootoutTeam2Goals: 3,
      );
      const validShootout = FootballLiveState(
        phase: 'PENALTY_SHOOTOUT',
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

    test('does not treat regulation goals as valid during shootout phase', () {
      const state = FootballLiveState(
        phase: 'PENALTY_SHOOTOUT',
        team1Goals: 1,
        team2Goals: 0,
      );

      expect(state.isMatchComplete, isFalse);
      expect(state.winnerTeam, 0);
    });

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
