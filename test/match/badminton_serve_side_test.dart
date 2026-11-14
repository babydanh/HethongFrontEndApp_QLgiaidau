import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/racket_court_layout.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_racket.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
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

const _gameWon = SetScoreData(score1: 21, score2: 10, isFinished: true);
const _gameLost = SetScoreData(score1: 10, score2: 21, isFinished: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-BADMINTON-SERVE-01 server and cell by score parity', () {
    test('first server opens from the right cell at 0-0', () {
      final c = _container(_badminton());
      expect(_state(c).racketServerTeam, 1);
      expect(_state(c).racketServerRight, isTrue);
    });

    test('scoring keeps the serve and moves it to the other cell', () {
      final c = _container(_badminton());
      final seen = <(int?, bool)>[];
      for (var i = 0; i < 4; i++) {
        _rally(c, true, 1);
        seen.add((_state(c).racketServerTeam, _state(c).racketServerRight));
      }
      // 1-0 left, 2-0 right, 3-0 left, 4-0 right; team 1 keeps serving.
      expect(seen, [(1, false), (1, true), (1, false), (1, true)]);
    });

    test('winning a rally on receive takes the serve; cell by own score', () {
      final c = _container(_badminton());
      _rally(c, true, 2); // 2-0 team 1 serves
      _rally(c, false, 1); // 2-1 team 2 serves, own score 1 = left
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerRight, isFalse);
      _rally(c, false, 1); // 2-2 team 2 keeps it, own score 2 = right
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerRight, isTrue);
      _rally(c, true, 1); // 3-2 team 1 serves again, own score 3 = left
      expect(_state(c).racketServerTeam, 1);
      expect(_state(c).racketServerRight, isFalse);
    });

    test('picked first server team 2 opens the game', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(2, 1);
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerRight, isTrue);
    });
  });

  group('TC-BADMINTON-SERVE-02 doubles: pair swaps cells after a win', () {
    test('same player serves, cells alternate right, left, right', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      final players = <int?>[];
      final rights = <bool>[];
      for (var i = 0; i < 3; i++) {
        players.add(_state(c).racketServerPlayerIndex(doubles: true));
        rights.add(_state(c).racketServerRight);
        _rally(c, true, 1);
      }
      expect(players, [0, 0, 0]);
      expect(rights, [true, false, true]);
    });

    test('the partner of the server stands in the other cell of the pair', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, true, 1);
      final cells = _state(c).racketCells(doubles: true);
      final team1 = cells.where((e) => e.team == 1);
      final server = team1.singleWhere((e) => e.role == CourtCellRole.server);
      final partner = team1.singleWhere((e) => e.role != CourtCellRole.server);
      expect(server.rightCourt, isFalse);
      expect(server.playerIndex, 0);
      expect(partner.playerIndex, 1);
    });

    test('team 2 takes the serve: its pair has not swapped yet', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, true, 2);
      _rally(c, false, 1);
      // Team 2 wins on receive: score 1, left cell, no swap made yet.
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerRight, isFalse);
      final right = _state(c).racketPick.rightStarterOf(2);
      expect(_state(c).racketServerPlayerIndex(doubles: true), 1 - right);
    });
  });

  group('TC-BADMINTON-ENDS-01 change of ends', () {
    test('flips after game 1 and the winner of game 1 serves game 2', () {
      final c = _container(
        _badminton(),
        rally: const RallySetState(
          currentP1: 5,
          currentP2: 20,
          lastWinner: 2,
          swaps1: 0,
          swaps2: 3,
        ),
      );
      expect(_state(c).racketPick.endsFlipped, isFalse);
      _rally(c, false, 1);
      expect(_state(c).finishedSets, hasLength(1));
      expect(_state(c).racketPick.endsFlipped, isTrue);
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerRight, isTrue);
    });

    test('a leader reaching 11 in game 1 does not change ends', () {
      final c = _container(_badminton());
      _rally(c, true, 11);
      expect(_state(c).racketPick.endsFlipped, isFalse);
    });

    test('deciding game: ends change when the first side reaches 11', () {
      final c = _container(_badminton(), sets: const [_gameWon, _gameLost]);
      expect(_state(c).racketServerTeam, 2); // winner of game 2
      _rally(c, true, 10);
      expect(_state(c).racketPick.endsFlipped, isFalse);
      _rally(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
    });

    test('deciding game: the other side reaching 11 later changes nothing', () {
      final c = _container(_badminton(), sets: const [_gameWon, _gameLost]);
      _rally(c, true, 11);
      _rally(c, false, 11);
      expect(_state(c).racketPick.endsFlipped, isTrue);
    });

    test('deciding game: 10-10 then 11-10 changes ends exactly once', () {
      final c = _container(_badminton(), sets: const [_gameWon, _gameLost]);
      for (var i = 0; i < 10; i++) {
        _rally(c, true, 1);
        _rally(c, false, 1);
      }
      expect(_state(c).racketPick.endsFlipped, isFalse);
      _rally(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
      _rally(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
    });

    test('undo of the 11th point puts the ends back', () {
      final c = _container(_badminton(), sets: const [_gameWon, _gameLost]);
      _rally(c, true, 11);
      expect(_state(c).racketPick.endsFlipped, isTrue);
      _panel(c).racketUndoStep();
      expect(_state(c).racketPick.endsFlipped, isFalse);
      expect(_state(c).rally!.currentP1, 10);
    });
  });

  group('TC-BADMINTON-UNDO-01 undo restores the server', () {
    test('after the serve passed to team 2 the first server is back', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, true, 1);
      final beforeTeam = _state(c).racketServerTeam;
      final beforeRight = _state(c).racketServerRight;
      final beforePlayer = _state(c).racketServerPlayerIndex(doubles: true);
      _rally(c, false, 1);
      expect(_state(c).racketServerTeam, 2);
      _panel(c).racketUndoStep();
      expect(_state(c).racketServerTeam, beforeTeam);
      expect(_state(c).racketServerRight, beforeRight);
      expect(_state(c).racketServerPlayerIndex(doubles: true), beforePlayer);
    });

    test('undo of a point scored on serve takes the pair swap back', () {
      final c = _container(_badminton());
      _panel(c).racketPickFirstServer(1, 0);
      _rally(c, true, 1);
      expect(_state(c).racketServerRight, isFalse);
      _panel(c).racketUndoStep();
      expect(_state(c).racketServerRight, isTrue);
      expect(_state(c).racketServerPlayerIndex(doubles: true), 0);
    });
  });
}
