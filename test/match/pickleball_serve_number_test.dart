import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

const _config = SportConfig(
  kind: SportRuleKind.pickleball,
  scoringModel: SportScoringModel.pickleballSideOut,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 11,
  mustWinByTwo: true,
  maxPoints: 0,
  tiebreakAt: 0,
);

/// The real score panel logic, started from a state the test chooses.
class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

ProviderContainer _container({
  PickleballServeState? serve,
  int score1 = 0,
  int score2 = 0,
}) {
  final container = ProviderContainer(
    overrides: [
      scorePanelNotifierProvider.overrideWith2(
        (arg) => _Panel(
          arg,
          ScorePanelState(
            config: _config,
            pickleball: serve,
            rally: RallySetState(currentP1: score1, currentP2: score2),
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(scorePanelNotifierProvider(_params), (_, _) {});
  return container;
}

ScorePanelNotifier _panel(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params).notifier);

PickleballServeState _serve(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params)).pickleball!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-SERVE-01 server number in side-out doubles', () {
    test('a point keeps the same server: server 2 stays server 2', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 2,
        ),
        score1: 3,
        score2: 1,
      );

      expect(_panel(c).pickleballAwardPoint(true), isTrue);

      expect(_serve(c).serverNumber, 2);
      expect(_serve(c).isTeam1Serving, isTrue);
    });

    test('a point by server 1 keeps server 1', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 1,
        ),
      );

      _panel(c).pickleballAwardPoint(true);

      expect(_serve(c).serverNumber, 1);
    });

    test('server 1 loses: server 2; server 2 loses: side-out to server 1', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 1,
        ),
      );

      _panel(c).pickleballSwitchServer();
      expect(_serve(c).isTeam1Serving, isTrue);
      expect(_serve(c).serverNumber, 2);

      _panel(c).pickleballSwitchServer();
      expect(_serve(c).isTeam1Serving, isFalse);
      expect(_serve(c).serverNumber, 1);
    });

    test('the first serve of a game has one fault only: it starts at 2', () {
      expect(const PickleballServeState().serverNumber, 2);
      expect(const PickleballServeState().isTeam1Serving, isTrue);
    });

    test('a side-out hands the other team server 1', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 2,
        ),
      );

      _panel(c).pickleballSideOut();

      expect(_serve(c).isTeam1Serving, isFalse);
      expect(_serve(c).serverNumber, 1);
    });

    test('a new game starts at server 2 again', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 1,
        ),
        score1: 10,
        score2: 3,
      );

      _panel(c).pickleballAwardPoint(true);

      final state = c.read(scorePanelNotifierProvider(_params));
      expect(state.finishedSets, hasLength(1));
      expect(state.rally?.currentP1, 0);
      expect(state.pickleball!.serverNumber, 2);
    });
  });
}
