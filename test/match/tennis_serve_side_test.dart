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

void _tennisPoints(ProviderContainer c, bool team1, int count) {
  for (var i = 0; i < count; i++) {
    _panel(c).tennisAwardPoint(team1);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-TENNIS-SERVE-01 server changes every game', () {
    test('teams 1, 2, 1, 2 serve games 1 to 4 whoever wins them', () {
      final c = _container(_tennis());
      final servers = <int?>[];
      for (var game = 0; game < 4; game++) {
        servers.add(_state(c).racketServerTeam);
        _tennisPoints(c, game.isEven, 4);
      }
      expect(servers, [1, 2, 1, 2]);
    });

    test('the referee picked team 2: it serves games 1, 3, 5', () {
      final c = _container(_tennis());
      _panel(c).racketPickFirstServer(2, 0);
      final servers = <int?>[];
      for (var game = 0; game < 3; game++) {
        servers.add(_state(c).racketServerTeam);
        _tennisPoints(c, true, 4);
      }
      expect(servers, [2, 1, 2]);
    });

    test('the serve keeps alternating into the next set', () {
      final c = _container(_tennis());
      _tennisPoints(c, true, 24); // 6-0, set closed after six games
      expect(_state(c).finishedSets.single.isFinished, isTrue);
      expect(_state(c).racketServerTeam, 1);
      _tennisPoints(c, true, 4);
      expect(_state(c).racketServerTeam, 2);
    });
  });

  group('TC-TENNIS-SERVE-02 serve cell follows the points of the game', () {
    test('right at 0-0, left after 1 point, right after 2, left after 3', () {
      final c = _container(_tennis());
      final cells = <bool>[];
      for (var point = 0; point < 4; point++) {
        cells.add(_state(c).racketServerRight);
        _tennisPoints(c, point.isEven, 1);
      }
      expect(cells, [true, false, true, false]);
    });

    test('a new game starts from the right cell again', () {
      final c = _container(_tennis());
      _tennisPoints(c, true, 3);
      expect(_state(c).racketServerRight, isFalse);
      _tennisPoints(c, true, 1);
      expect(_state(c).racketServerRight, isTrue);
    });

    test('the server and receiver stand diagonally', () {
      final c = _container(_tennis());
      _tennisPoints(c, true, 1);
      final cells = _state(c).racketCells(doubles: false);
      final server = cells.singleWhere((e) => e.role == CourtCellRole.server);
      final receiver = cells.singleWhere(
        (e) => e.role == CourtCellRole.receiver,
      );
      expect((server.team, server.rightCourt), (1, false));
      expect((receiver.team, receiver.rightCourt), (2, false));
    });
  });

  group('TC-TENNIS-ENDS-01 change of ends after odd games', () {
    test('flips after games 1, 3, 5 and not after 2, 4, 6', () {
      final c = _container(_tennis());
      final flipped = <bool>[];
      for (var game = 0; game < 6; game++) {
        _tennisPoints(c, true, 4);
        flipped.add(_state(c).racketPick.endsFlipped);
      }
      // After the set closes at 6 games (even) nothing flips.
      expect(flipped, [true, true, false, false, true, true]);
    });

    test('the first game of the next set flips again', () {
      final c = _container(_tennis());
      _tennisPoints(c, true, 24);
      expect(_state(c).racketPick.endsFlipped, isTrue);
      _tennisPoints(c, true, 4);
      expect(_state(c).racketPick.endsFlipped, isFalse);
    });

    test('undo of the game point that changed ends puts the ends back', () {
      final c = _container(_tennis());
      _tennisPoints(c, true, 3);
      _tennisPoints(c, true, 1);
      expect(_state(c).racketPick.endsFlipped, isTrue);
      expect(_panel(c).racketUndoStep(), isTrue);
      expect(_state(c).racketPick.endsFlipped, isFalse);
      expect(_state(c).racketServerTeam, 1);
      expect(_state(c).racketServerRight, isFalse);
      expect(_state(c).tennis!.team1GamePoints, 3);
    });
  });

  group('TC-TENNIS-TB-01 tie-break serve and ends', () {
    ProviderContainer tiebreak() => _container(
      _tennis(),
      sets: const [SetScoreData(score1: 6, score2: 6)],
      tennis: const TennisGameState(isTiebreak: true),
    );

    test('server by points: 1, 2, 2, 1, 1, 2, 2, 1', () {
      final c = tiebreak();
      final servers = <int?>[];
      for (var point = 0; point < 8; point++) {
        servers.add(_state(c).racketServerTeam);
        _tennisPoints(c, point.isEven, 1);
      }
      expect(servers, [1, 2, 2, 1, 1, 2, 2, 1]);
    });

    test('serve cell alternates every point of the tie-break', () {
      final c = tiebreak();
      final cells = <bool>[];
      for (var point = 0; point < 4; point++) {
        cells.add(_state(c).racketServerRight);
        _tennisPoints(c, point.isEven, 1);
      }
      expect(cells, [true, false, true, false]);
    });

    test('ends change after the 6th point only, then after the set', () {
      final c = tiebreak();
      final flips = <bool>[];
      for (var point = 0; point < 6; point++) {
        _tennisPoints(c, point.isEven, 1);
        flips.add(_state(c).racketPick.endsFlipped);
      }
      expect(flips, [false, false, false, false, false, true]);
      // 3-3, team 1 takes four straight: 7-3 closes the set at 7-6 (odd).
      _tennisPoints(c, true, 4);
      expect(_state(c).finishedSets.single.isFinished, isTrue);
      expect(_state(c).racketPick.endsFlipped, isFalse);
    });

    test('the tie-break server leads the next set after the game server', () {
      final c = tiebreak();
      _tennisPoints(c, true, 7); // 7-0, 13 games played, team 1 opened it
      expect(_state(c).racketServerTeam, 2);
    });

    test('undo of the 6th point changes the ends back', () {
      final c = tiebreak();
      for (var point = 0; point < 6; point++) {
        _tennisPoints(c, point.isEven, 1);
      }
      expect(_state(c).racketPick.endsFlipped, isTrue);
      _panel(c).racketUndoStep();
      expect(_state(c).racketPick.endsFlipped, isFalse);
      // 5 points played: turn 3, so team 2 serves the 6th point again.
      expect(_state(c).racketServerTeam, 2);
    });
  });
}
