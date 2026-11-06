import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
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
  SportConfig config = _config,
}) {
  final container = ProviderContainer(
    overrides: [
      matchRepositoryProvider.overrideWithValue(writes ?? _Writes()),
      scorePanelNotifierProvider.overrideWith2(
        (arg) => _Panel(
          arg,
          ScorePanelState(
            config: config,
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
          openingDone: true,
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

      expect(await lastSideOut(writes), {
        'servingTeam': 1,
        'serverNumber': 2,
        'openingDone': false,
      });
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

      expect(await lastSideOut(writes), {
        'servingTeam': 2,
        'serverNumber': 1,
        'openingDone': true,
      });
    });
  });

  group('TC-SERVE-03 Lite and rally follow the serve too', () {
    const lite = SportConfig(
      kind: SportRuleKind.pickleball,
      scoringModel: SportScoringModel.pickleballSideOut,
      isOpenScoring: true,
      bestOf: 3,
      setsToWin: 2,
      pointsPerSet: 11,
      mustWinByTwo: true,
      maxPoints: 0,
      tiebreakAt: 0,
    );

    test('Lite: the receiving team may score and takes the serve', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 2,
        ),
        config: lite,
      );

      expect(_panel(c).pickleballAwardPoint(false), isTrue);

      expect(_serve(c).isTeam1Serving, isFalse);
      expect(_serve(c).serverNumber, 1);
    });

    test('Lite: the serving team scoring keeps its server', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 2,
        ),
        config: lite,
      );

      _panel(c).pickleballAwardPoint(true);

      expect(_serve(c).isTeam1Serving, isTrue);
      expect(_serve(c).serverNumber, 2);
    });

    test('Lite: a set at 17-10 is not closed, the serve keeps tracking', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 1,
        ),
        score1: 16,
        score2: 10,
        config: lite,
      );

      _panel(c).pickleballAwardPoint(true);

      final state = c.read(scorePanelNotifierProvider(_params));
      expect(state.rally!.currentP1, 17);
      expect(state.finishedSets, isEmpty);
    });

    test('strict side-out still refuses the receiving team', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 1,
        ),
      );

      expect(_panel(c).pickleballAwardPoint(false), isFalse);
    });
  });

  group('TC-SERVE-04 opening serve has one fault only', () {
    test('(a) picking the serving team at 0-0: losing the first rally hands '
        'the serve to the other team at server 1', () {
      final c = _container(serve: const PickleballServeState());

      _panel(c).pickleballSetServingTeam(false);
      expect(_serve(c).isTeam1Serving, isFalse);
      expect(_serve(c).serverNumber, 2);
      expect(_serve(c).openingDone, isFalse);

      _panel(c).pickleballSwitchServer();

      expect(_serve(c).isTeam1Serving, isTrue);
      expect(_serve(c).serverNumber, 1);
      expect(_serve(c).openingDone, isTrue);
      expect(c.read(scorePanelNotifierProvider(_params)).rally!.currentP1, 0);
      expect(c.read(scorePanelNotifierProvider(_params)).rally!.currentP2, 0);
    });

    test('(b) after the opening hand-over: server 1 loses -> server 2 of the '
        'same team; server 2 loses -> the other team at server 1', () {
      final c = _container(serve: const PickleballServeState());
      _panel(c).pickleballSetServingTeam(false);
      _panel(c).pickleballSwitchServer(); // opening: team 1 now serves at 1

      _panel(c).pickleballSwitchServer();
      expect(_serve(c).isTeam1Serving, isTrue);
      expect(_serve(c).serverNumber, 2);

      _panel(c).pickleballSwitchServer();
      expect(_serve(c).isTeam1Serving, isFalse);
      expect(_serve(c).serverNumber, 1);
    });

    test('the opening fault still counts after the serving team scores', () {
      final c = _container(serve: const PickleballServeState());

      _panel(c).pickleballAwardPoint(true);
      _panel(c).pickleballAwardPoint(true);
      _panel(c).pickleballSwitchServer();

      expect(_serve(c).isTeam1Serving, isFalse);
      expect(_serve(c).serverNumber, 1);
    });

    test('a side-out ends the opening', () {
      final c = _container(serve: const PickleballServeState());

      _panel(c).pickleballSideOut();

      expect(_serve(c).openingDone, isTrue);
    });

    test('picking the serving team after points were scored is a side-out', () {
      final c = _container(
        serve: const PickleballServeState(),
        score1: 2,
        score2: 1,
      );

      _panel(c).pickleballSetServingTeam(false);

      expect(_serve(c).isTeam1Serving, isFalse);
      expect(_serve(c).serverNumber, 1);
      expect(_serve(c).openingDone, isTrue);
    });

    test('a new game opens again: one fault, even after a hand-over', () {
      final c = _container(
        serve: const PickleballServeState(
          isTeam1Serving: true,
          serverNumber: 1,
          openingDone: true,
        ),
        score1: 10,
        score2: 3,
      );

      _panel(c).pickleballAwardPoint(true);

      expect(_serve(c).serverNumber, 2);
      expect(_serve(c).openingDone, isFalse);
    });

    test('(d) open scoring: the receiving team scores and the opening ends', () {
      const lite = SportConfig(
        kind: SportRuleKind.pickleball,
        scoringModel: SportScoringModel.pickleballSideOut,
        isOpenScoring: true,
        bestOf: 3,
        setsToWin: 2,
        pointsPerSet: 11,
        mustWinByTwo: true,
        maxPoints: 0,
        tiebreakAt: 0,
      );
      final c = _container(serve: const PickleballServeState(), config: lite);

      expect(_panel(c).pickleballAwardPoint(false), isTrue);

      final state = c.read(scorePanelNotifierProvider(_params));
      expect(state.rally!.currentP2, 1);
      expect(state.pickleball!.isTeam1Serving, isFalse);
      expect(state.pickleball!.openingDone, isTrue);
    });
  });

  group('TC-SERVE-05 the opening flag survives reopening the match', () {
    Future<PickleballServeState> reopened({
      required Map<String, Object?> sideOutState,
      List<Map<String, Object?>> sets = const [],
    }) async {
      final match = MatchModel.fromJson({
        'id': 'match-1',
        'tournamentId': 'tournament-1',
        'status': 'LIVE',
        'sport': 'pickleball',
        'scoreDetails': {
          'sets': sets,
          'liveState': {'sideOutState': sideOutState},
        },
      }, 'match-1');
      final container = ProviderContainer(
        overrides: [
          matchRepositoryProvider.overrideWithValue(_Writes()),
          singleMatchProvider.overrideWith((ref, p) => Stream.value(match)),
          tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(scorePanelNotifierProvider(_params), (_, _) {});
      await container.read(singleMatchProvider(_params).future);
      await Future<void>.delayed(Duration.zero);
      return _serve(container);
    }

    test('(e) a saved flag is read back as written', () async {
      final open = await reopened(
        sideOutState: {
          'servingTeam': 2,
          'serverNumber': 2,
          'openingDone': false,
        },
        sets: [
          {'team1Score': 3, 'team2Score': 1},
        ],
      );
      expect(open.openingDone, isFalse);
      expect(open.isTeam1Serving, isFalse);

      final done = await reopened(
        sideOutState: {'servingTeam': 1, 'serverNumber': 1, 'openingDone': true},
      );
      expect(done.openingDone, isTrue);
    });

    test('(e) old data without the flag: 0-0 is still opening, points mean '
        'the opening is over', () async {
      final atStart = await reopened(
        sideOutState: {'servingTeam': 1, 'serverNumber': 1},
      );
      expect(atStart.openingDone, isFalse);

      final midSet = await reopened(
        sideOutState: {'servingTeam': 1, 'serverNumber': 1},
        sets: [
          {'team1Score': 4, 'team2Score': 2},
        ],
      );
      expect(midSet.openingDone, isTrue);
    });
  });
}
