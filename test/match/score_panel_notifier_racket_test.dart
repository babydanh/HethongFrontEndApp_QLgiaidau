import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_racket.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

class _Writes extends Fake implements IMatchRepository {
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
  }) async {}
}

class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

SportConfig _badminton() => resolveSportConfig(null, SportRuleKind.badminton);

SportConfig _tennis([Map<String, dynamic> format = const {}]) =>
    resolveSportConfig({
      'kind': 'TENNIS',
      'setsToWin': 2,
      'format': format,
    }, SportRuleKind.tennis);

ProviderContainer _container(
  SportConfig config, {
  List<SetScoreData> sets = const [],
  TennisGameState? tennis,
  RallySetState? rally,
}) {
  final isTennis = config.kind == SportRuleKind.tennis;
  final container = ProviderContainer(
    overrides: [
      matchRepositoryProvider.overrideWithValue(_Writes()),
      scorePanelNotifierProvider.overrideWith2(
        (arg) => _Panel(
          arg,
          ScorePanelState(
            config: config,
            finishedSets: sets,
            tennis: tennis,
            rally: rally ?? (isTennis ? null : const RallySetState()),
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  container.listen(scorePanelNotifierProvider(_params), (_, _) {});
  return container;
}

ScorePanelNotifier _panel(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params).notifier);

ScorePanelState _state(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params));

void _rally(ProviderContainer c, bool team1, int count) {
  for (var i = 0; i < count; i++) {
    _panel(c).rallyAddPoint(team1);
  }
}

void _tennisPoints(ProviderContainer c, bool team1, int count) {
  for (var i = 0; i < count; i++) {
    _panel(c).tennisAwardPoint(team1);
  }
}

const _lateSet = RallySetState(
  currentP1: 20,
  currentP2: 5,
  lastWinner: 1,
  swaps1: 4,
  swaps2: 1,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-RACKET-N-01 first server', () {
    test('can be picked at 0-0 and moves the serve', () {
      final c = _container(_badminton());
      expect(_panel(c).racketPickFirstServer(2, 1), isTrue);
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerPlayerIndex(doubles: true), 1);
    });

    test('cannot be picked once a point was scored', () {
      final c = _container(_badminton());
      _rally(c, true, 1);
      final before = _state(c).racketPick;
      expect(_panel(c).racketPickFirstServer(2, 1), isFalse);
      expect(identical(_state(c).racketPick, before), isTrue);
    });
  });

  group('TC-RACKET-N-02 badminton keeps who won the last rally', () {
    test('serving team scores: same server, the pair swaps cells', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, true, 1);
      expect(_state(c).rally!.lastWinner, 1);
      expect(_state(c).racketServerTeam, 1);
      expect(_state(c).racketServerRight, isFalse);
      // Player 0 started right, the pair swapped, so player 0 serves from the
      // left cell now (odd score).
      expect(_state(c).racketServerPlayerIndex(doubles: true), 0);
    });

    test('receiving team wins the rally: it takes the serve, no swap', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, false, 1);
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerRight, isFalse);
    });
  });

  group('TC-RACKET-N-03 undo restores score and server', () {
    test('three points then three undos', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      final before = _state(c);
      _rally(c, true, 1);
      _rally(c, false, 1);
      _rally(c, false, 1);
      expect(_state(c).canRacketUndo, isTrue);
      for (var i = 0; i < 3; i++) {
        expect(_panel(c).racketUndoStep(), isTrue);
      }
      expect(_state(c).rally!.currentP1, 0);
      expect(_state(c).rally!.currentP2, 0);
      expect(_state(c).racketServerTeam, before.racketServerTeam);
      expect(
        _state(c).racketServerPlayerIndex(doubles: true),
        before.racketServerPlayerIndex(doubles: true),
      );
    });

    test('nothing to undo on a fresh match', () {
      final c = _container(_badminton());
      expect(_state(c).canRacketUndo, isFalse);
      expect(_panel(c).racketUndoStep(), isFalse);
    });
  });

  group('TC-RACKET-N-04 minus makes the history unknown', () {
    test('serve hidden until a correction or the next point', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, true, 2);
      _panel(c).rallyRemovePoint(true);
      expect(_state(c).racketServerTeam, isNull);
      expect(_panel(c).racketCorrectServer(2, 1), isTrue);
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerPlayerIndex(doubles: true), 1);
    });

    test('undo after minus restores the exact server', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, true, 2);
      final team = _state(c).racketServerTeam;
      final player = _state(c).racketServerPlayerIndex(doubles: true);
      _panel(c).rallyRemovePoint(true);
      _panel(c).racketUndoStep();
      expect(_state(c).racketServerTeam, team);
      expect(_state(c).racketServerPlayerIndex(doubles: true), player);
    });
  });

  group('TC-RACKET-N-05 undo stops at a closed set', () {
    test('the point that closes the set cannot be undone', () {
      final c = _container(_badminton(), rally: _lateSet);
      _rally(c, true, 1);
      expect(_state(c).finishedSets.length, 1);
      expect(_state(c).canRacketUndo, isFalse);
      expect(_panel(c).racketUndoStep(), isFalse);
    });
  });

  group('TC-RACKET-N-06 undo depth', () {
    test('at most 50 steps are kept', () {
      final c = _container(_badminton());
      for (var i = 0; i < 20; i++) {
        _rally(c, true, 1);
        _rally(c, false, 1);
      }
      expect(_state(c).racketUndo.length, 40);
      for (var i = 0; i < 20; i++) {
        _panel(c).rallyRemovePoint(i.isEven);
      }
      expect(_state(c).racketUndo.length, 50);
    });
  });

  group('TC-RACKET-N-07 tennis doubles server alternates', () {
    test('the partner serves the next service game of the team', () {
      final c = _container(_tennis());
      _panel(c).racketPickFirstServer(1, 0);
      expect(_state(c).racketServerPlayerIndex(doubles: true), 0);
      _tennisPoints(c, true, 4); // game 1 to team 1
      expect(_state(c).racketServerTeam, 2);
      _tennisPoints(c, false, 4); // game 2 to team 2
      expect(_state(c).racketServerTeam, 1);
      expect(_state(c).racketServerPlayerIndex(doubles: true), 1);
    });

    test('the other team picked as first server serves first', () {
      final c = _container(_tennis());
      _panel(c).racketPickFirstServer(2, 1);
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerPlayerIndex(doubles: true), 1);
    });
  });

  group('TC-RACKET-N-08 tennis tie-break', () {
    test('serve changes after 1 point then every 2 points', () {
      final c = _container(
        _tennis(),
        sets: const [SetScoreData(score1: 6, score2: 6)],
        tennis: const TennisGameState(isTiebreak: true),
      );
      expect(_state(c).racketServerTeam, 1);
      _tennisPoints(c, true, 1);
      expect(_state(c).racketServerTeam, 2);
      _tennisPoints(c, false, 2);
      expect(_state(c).racketServerTeam, 1);
    });
  });

  group('TC-RACKET-N-09 court edits go through undo', () {
    test('swap places changes who stands right, undo puts it back', () {
      final c = _container(_badminton());
      final before = _state(c).racketPick.rightStarterTeam2;
      expect(_panel(c).racketApplyDrop(const SwapPlaces(2)), isTrue);
      expect(_state(c).racketPick.rightStarterTeam2, 1 - before);
      _panel(c).racketUndoStep();
      expect(_state(c).racketPick.rightStarterTeam2, before);
    });

    test('switch ends flips the halves, undo flips back', () {
      final c = _container(_badminton());
      expect(_panel(c).racketApplyDrop(const SwitchEnds()), isTrue);
      expect(_state(c).racketPick.endsFlipped, isTrue);
      _panel(c).racketUndoStep();
      expect(_state(c).racketPick.endsFlipped, isFalse);
    });

    test('set server drop corrects the serving team and is undoable', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, true, 2);
      expect(
        _panel(c).racketApplyDrop(
          const SetServer(team: 2, playerIndex: 1, changesServingTeam: true),
        ),
        isTrue,
      );
      expect(_state(c).racketServerTeam, 2);
      _panel(c).racketUndoStep();
      expect(_state(c).racketServerTeam, 1);
    });
  });

  group('TC-RACKET-N-10 ends change by the rules', () {
    test(
      'tennis: after game 1 the halves change, after game 2 they do not',
      () {
        final c = _container(_tennis());
        _tennisPoints(c, true, 4);
        expect(_state(c).racketPick.endsFlipped, isTrue);
        _tennisPoints(c, false, 4);
        expect(_state(c).racketPick.endsFlipped, isTrue);
        _tennisPoints(c, true, 4);
        expect(_state(c).racketPick.endsFlipped, isFalse);
      },
    );

    test('badminton: the halves change after a game', () {
      final c = _container(_badminton(), rally: _lateSet);
      _rally(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
    });
  });

  group('TC-RACKET-N-11 server correction limits', () {
    test('a later game at 0-0 cannot change the serving team', () {
      final c = _container(
        _badminton(),
        sets: const [SetScoreData(score1: 21, score2: 10, isFinished: true)],
      );
      expect(_state(c).racketServerTeam, 1);
      expect(_panel(c).racketCorrectServer(2, 0), isFalse);
      expect(_state(c).racketServerTeam, 1);
    });

    test('tennis: correcting to the other team hands the serve over', () {
      final c = _container(_tennis());
      _tennisPoints(c, true, 1);
      expect(_state(c).racketServerTeam, 1);
      expect(_panel(c).racketCorrectServer(2, 0), isTrue);
      expect(_state(c).racketServerTeam, 2);
    });
  });

  group('TC-RACKET-N-12 minus gives back an automatic change of ends', () {
    test('badminton deciding game: 11, minus, plus flips only once', () {
      final c = _container(
        _badminton(),
        sets: const [
          SetScoreData(score1: 21, score2: 10, isFinished: true),
          SetScoreData(score1: 10, score2: 21, isFinished: true),
        ],
        rally: const RallySetState(
          currentP1: 10,
          currentP2: 9,
          lastWinner: 1,
          swaps1: 0,
          swaps2: 0,
        ),
      );
      expect(_state(c).racketPick.endsFlipped, isFalse);
      _rally(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
      _panel(c).rallyRemovePoint(true);
      expect(_state(c).racketPick.endsFlipped, isFalse);
      _rally(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
    });

    test('tennis tie-break: the 6th point, minus, plus flips only once', () {
      final c = _container(
        _tennis(),
        sets: const [SetScoreData(score1: 6, score2: 6)],
        tennis: const TennisGameState(isTiebreak: true, team1GamePoints: 5),
      );
      _tennisPoints(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
      _panel(c).tennisRemovePoint(true);
      expect(_state(c).racketPick.endsFlipped, isFalse);
      _tennisPoints(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
    });
  });

  group('TC-RACKET-N-13 minus at zero changes nothing', () {
    test('no Undo step is added', () {
      final b = _container(_badminton());
      _panel(b).rallyRemovePoint(true);
      expect(_state(b).canRacketUndo, isFalse);
      final t = _container(_tennis());
      _panel(t).tennisRemovePoint(false);
      expect(_state(t).canRacketUndo, isFalse);
    });
  });

  group('TC-RACKET-N-14 correcting the server leaves the other pair alone', () {
    test('the other team keeps the swaps it really made', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, false, 1); // team 2 takes the serve
      _rally(c, false, 1); // team 2 wins serving: its pair swaps once
      expect(_state(c).rally!.swaps2, 1);
      expect(_panel(c).racketCorrectServer(1, 1), isTrue);
      expect(_state(c).rally!.swaps2, 1);
    });
  });
}
