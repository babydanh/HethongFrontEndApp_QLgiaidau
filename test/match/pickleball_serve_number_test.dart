import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
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

/// Records what the panel writes to the server.
class _Writes extends Fake implements IMatchRepository {
  final extras = <Map<String, dynamic>?>[];

  @override
  Future<void> updateScoreDetails(
    String tournamentId,
    String matchId, {
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    Map<String, dynamic>? scoreDetailsExtras,
    String? winnerId,
    String? overrideReason,
    int? expectedRevision,
    bool useLiteParticipantAccess = false,
    ({String date, String? time})? playedAt,
  }) async {
    extras.add(scoreDetailsExtras);
  }
}

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
  _Writes? writes,
}) {
  final container = ProviderContainer(
    overrides: [
      matchRepositoryProvider.overrideWithValue(writes ?? _Writes()),
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
  // The live sync fires 250ms after a change; let it land while the container
  // is still alive (tear-downs run last-in first-out).
  addTearDown(() => Future<void>.delayed(const Duration(milliseconds: 300)));
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

  group('TC-SERVE-02 who serves survives closing the screen', () {
    // The reader (`liveState.sideOutState`) turns this back into the serve
    // state when the match is opened again.
    Future<Map<String, dynamic>?> lastSideOut(_Writes writes) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final liveState = writes.extras.last?['liveState'] as Map?;
      final raw = liveState?['sideOutState'];
      return raw == null ? null : Map<String, dynamic>.from(raw as Map);
    }

    test('a point is written together with the serving team and number', () async {
      final writes = _Writes();
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 2,
        ),
        score1: 3,
        score2: 1,
        writes: writes,
      );

      _panel(c).pickleballAwardPoint(true);

      expect(await lastSideOut(writes), {'servingTeam': 1, 'serverNumber': 2});
    });

    test('a fault with no point after it is written too', () async {
      final writes = _Writes();
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 2,
        ),
        score1: 3,
        score2: 1,
        writes: writes,
      );

      _panel(c).pickleballSwitchServer();

      expect(await lastSideOut(writes), {'servingTeam': 2, 'serverNumber': 1});
    });
  });
}
