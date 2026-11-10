import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CourtContext _ctx({required int serverNumber, int? servingTeam = 1}) =>
    CourtContext(
      score1: 3,
      score2: 2,
      isDoubles: true,
      team1PlayerCount: 2,
      team2PlayerCount: 2,
      servingTeam: servingTeam,
      serverNumber: serverNumber,
      scoringMode: CourtScoringMode.sideOut,
      setIndex: 0,
      targetPoints: 11,
      isDecidingSet: false,
    );

CourtTurnStart _turn(int number, int player) => CourtTurnStart(
  team: 1,
  serverNumber: number,
  teamScoreAtStart: 3,
  serverPlayerIndex: player,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'TC-SERVE-APP-01 setServerTurn moves the ball to the chosen player',
    () {
      test('server 2 -> 1: the partner gets the ball back, no undo entry', () {
        final state = CourtState(turnStart: _turn(2, 1));
        final ctx = _ctx(serverNumber: 1);

        final next = setServerTurn(state, ctx, 0);
        final layout = resolveCourtLayout(next, ctx);

        expect(layout.serverPlayerIndex, 0);
        expect(layout.callServerNumber, 1);
        expect(next.history, isEmpty);
      });

      test('server 1 -> 2: the partner of the shown server takes the ball', () {
        final state = CourtState(turnStart: _turn(1, 0));
        final ctx = _ctx(serverNumber: 2);

        final next = setServerTurn(state, ctx, 1);
        final layout = resolveCourtLayout(next, ctx);

        expect(layout.serverPlayerIndex, 1);
        expect(layout.callServerNumber, 2);
        expect(next.history, isEmpty);
      });

      test('a give-serve override is cleared so the pick wins', () {
        final state = CourtState(
          turnStart: _turn(1, 0),
          serverOverride: const CourtServerOverride(team: 1, playerIndex: 1),
        );
        final ctx = _ctx(serverNumber: 2);

        final next = setServerTurn(state, ctx, 0);

        expect(next.serverOverride, isNull);
        expect(resolveCourtLayout(next, ctx).serverPlayerIndex, 0);
      });

      test('without a serving team nothing changes', () {
        final state = CourtState(turnStart: _turn(1, 0));

        final next = setServerTurn(
          state,
          _ctx(serverNumber: 2, servingTeam: null),
          1,
        );

        expect(next, state);
      });
    },
  );

  group('TC-SERVE-APP-03 setServerAfterTeamChange', () {
    test('the chosen player of the new serving team serves, no undo entry', () {
      final state = CourtState(turnStart: _turn(1, 0));
      final ctx = _ctx(serverNumber: 1, servingTeam: 2);

      final next = setServerAfterTeamChange(state, ctx, 2, 1);
      final layout = resolveCourtLayout(next, ctx);

      expect(layout.servingTeam, 2);
      expect(layout.serverPlayerIndex, 1);
      expect(next.history, isEmpty);
    });
  });

  group('TC-SERVE-APP-02 pickleballSetServerNumber', () {
    const params = (tournamentId: 'tournament-1', matchId: 'match-1');
    const config = SportConfig(
      kind: SportRuleKind.pickleball,
      scoringModel: SportScoringModel.pickleballSideOut,
      bestOf: 3,
      setsToWin: 2,
      pointsPerSet: 11,
      mustWinByTwo: true,
      maxPoints: 0,
      tiebreakAt: 0,
    );

    ProviderContainer container({required int serverNumber}) {
      final c = ProviderContainer(
        overrides: [
          matchRepositoryProvider.overrideWithValue(_NoWrites()),
          scorePanelNotifierProvider.overrideWith2(
            (arg) => _Panel(
              arg,
              ScorePanelState(
                config: config,
                pickleball: PickleballServeState(
                  isTeam1Serving: true,
                  serverNumber: serverNumber,
                  openingDone: true,
                ),
                rally: const RallySetState(currentP1: 3, currentP2: 2),
              ),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      addTearDown(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      c.listen(scorePanelNotifierProvider(params), (_, _) {});
      return c;
    }

    test('changes only the server number, not the team or the score', () {
      final c = container(serverNumber: 1);

      c
          .read(scorePanelNotifierProvider(params).notifier)
          .pickleballSetServerNumber(2);

      final state = c.read(scorePanelNotifierProvider(params));
      expect(state.pickleball?.serverNumber, 2);
      expect(state.pickleball?.isTeam1Serving, isTrue);
      expect(state.pickleball?.openingDone, isTrue);
      expect(state.rally?.currentP1, 3);
      expect(state.rally?.currentP2, 2);
    });

    test('picking the number that already serves changes nothing', () {
      final c = container(serverNumber: 2);
      final before = c.read(scorePanelNotifierProvider(params));

      c
          .read(scorePanelNotifierProvider(params).notifier)
          .pickleballSetServerNumber(2);

      expect(c.read(scorePanelNotifierProvider(params)), same(before));
    });
  });
}

class _NoWrites extends Fake implements IMatchRepository {}

class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}
