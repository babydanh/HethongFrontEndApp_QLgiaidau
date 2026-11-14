import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_racket.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_tennis.dart';
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

/// One set each (6-4, 4-6): the deciding set is a 10 point match tie-break.
const _oneSetEach = [
  SetScoreData(score1: 6, score2: 4, isFinished: true),
  SetScoreData(score1: 4, score2: 6, isFinished: true),
];

ProviderContainer _matchTiebreak({bool noAd = false}) => _container(
  _tennis({'finalSetMode': 'MATCH_TB10', if (noAd) 'noAd': true}),
  sets: _oneSetEach,
);

/// Plays the given points, true = team 1 wins the point.
void _play(ProviderContainer c, List<bool> points) {
  for (final team1 in points) {
    _panel(c).tennisAwardPoint(team1);
  }
}

/// Points that lead to [t1]-[t2], alternating while both sides still need some.
List<bool> _scoreTo(int t1, int t2) {
  final points = <bool>[];
  var a = 0, b = 0;
  while (a < t1 || b < t2) {
    final team1 = a < t1 && (a <= b || b >= t2);
    points.add(team1);
    team1 ? a++ : b++;
  }
  return points;
}

({int t1, int t2}) _points(ProviderContainer c) => (
  t1: _state(c).tennis?.team1GamePoints ?? 0,
  t2: _state(c).tennis?.team2GamePoints ?? 0,
);

const _deuce = [true, false, true, false, true, false]; // 40-40

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-TENNIS-MTB-01 match tie-break replaces the deciding set', () {
    test('is due at one set each and counts points as a tie-break to 10', () {
      final c = _matchTiebreak();
      expect(_state(c).tennisMatchTiebreakDue, isTrue);
      expect(_state(c).tennisInTiebreak, isTrue);
      expect(_state(c).tennisPlan.tiebreakTarget, 10);
    });

    test('is not due before the deciding set (0-0 in sets)', () {
      final c = _container(_tennis({'finalSetMode': 'MATCH_TB10'}));
      expect(_state(c).tennisMatchTiebreakDue, isFalse);
      expect(_state(c).tennisInTiebreak, isFalse);
    });

    test('is not due when the mode is standard even at one set each', () {
      final c = _container(_tennis(), sets: _oneSetEach);
      expect(_state(c).tennisMatchTiebreakDue, isFalse);
    });

    test('first point is scored as a tie-break point (1-0, not 15-0)', () {
      final c = _matchTiebreak();
      _play(c, [true]);
      expect(_state(c).tennis!.isTiebreak, isTrue);
      expect(_points(c), (t1: 1, t2: 0));
    });

    test('does not end at 7-5 like a normal tie-break', () {
      final c = _matchTiebreak();
      _play(c, _scoreTo(7, 5));
      expect(_state(c).isMatchComplete, isFalse);
      expect(_points(c), (t1: 7, t2: 5));
    });

    test('does not end at 10-9 (one point lead)', () {
      final c = _matchTiebreak();
      _play(c, _scoreTo(9, 9));
      _play(c, [true]);
      expect(_state(c).isMatchComplete, isFalse);
      expect(_points(c), (t1: 10, t2: 9));
    });

    test('ends at 10-8 and the winner takes the match', () {
      final c = _matchTiebreak();
      _play(c, _scoreTo(9, 8));
      expect(_state(c).isMatchComplete, isFalse);
      _play(c, [true]);
      expect(_state(c).isMatchComplete, isTrue);
      expect(_state(c).winnerTeam, 1);
    });

    test('ends at 10-0 for team 2', () {
      final c = _matchTiebreak();
      _play(c, List.filled(10, false));
      expect(_state(c).winnerTeam, 2);
    });

    test('goes on past 10 until a 2 point lead: 10-12 ends it', () {
      final c = _matchTiebreak();
      _play(c, _scoreTo(10, 10));
      expect(_state(c).isMatchComplete, isFalse);
      _play(c, [false]); // 10-11
      expect(_state(c).isMatchComplete, isFalse);
      _play(c, [false]); // 10-12
      expect(_state(c).winnerTeam, 2);
    });

    test('is stored as a 7-6 deciding set when team 1 wins it', () {
      final c = _matchTiebreak();
      _play(c, List.filled(10, true));
      final sets = _state(c).finishedSets;
      expect(sets, hasLength(3));
      expect(
        (sets.last.score1, sets.last.score2, sets.last.isFinished),
        (7, 6, true),
      );
    });

    test('is stored as 6-7 when team 2 wins it', () {
      final c = _matchTiebreak();
      _play(c, List.filled(10, false));
      final last = _state(c).finishedSets.last;
      expect((last.score1, last.score2), (6, 7));
    });

    test('No-Ad does not shorten the tie-break: 7-6 is not a win', () {
      final c = _matchTiebreak(noAd: true);
      _play(c, _scoreTo(7, 6));
      expect(_state(c).isMatchComplete, isFalse);
      expect(_points(c), (t1: 7, t2: 6));
    });
  });

  group('TC-TENNIS-MTB-02 match tie-break serve and ends', () {
    test('server by points: 1, 2, 2, 1, 1, 2, 2, 1, 1, 2', () {
      final c = _matchTiebreak();
      final servers = <int?>[];
      for (var point = 0; point < 10; point++) {
        servers.add(_state(c).racketServerTeam);
        _play(c, [point.isEven]);
      }
      expect(servers, [1, 2, 2, 1, 1, 2, 2, 1, 1, 2]);
    });

    test('the serve passes after the first point, then every 2 points', () {
      final c = _matchTiebreak();
      _play(c, [true]);
      expect(_state(c).racketServerTeam, 2);
      _play(c, [true]);
      expect(_state(c).racketServerTeam, 2);
      _play(c, [true]);
      expect(_state(c).racketServerTeam, 1);
    });

    test('the serve cell alternates every point from the right', () {
      final c = _matchTiebreak();
      final cells = <bool>[];
      for (var point = 0; point < 4; point++) {
        cells.add(_state(c).racketServerRight);
        _play(c, [true]);
      }
      expect(cells, [true, false, true, false]);
    });

    test('players change ends after the 6th point and not before', () {
      final c = _matchTiebreak();
      final flips = <bool>[];
      for (var point = 0; point < 6; point++) {
        _play(c, [point.isEven]);
        flips.add(_state(c).racketPick.endsFlipped);
      }
      expect(flips, [false, false, false, false, false, true]);
    });

    test('players change ends again after the 12th point', () {
      final c = _matchTiebreak();
      _play(c, _scoreTo(6, 6));
      expect(_state(c).racketPick.endsFlipped, isFalse);
      expect(_points(c), (t1: 6, t2: 6));
    });

    test('undo of the 6th point puts the ends back', () {
      final c = _matchTiebreak();
      _play(c, _scoreTo(3, 3));
      expect(_state(c).racketPick.endsFlipped, isTrue);
      expect(_panel(c).racketUndoStep(), isTrue);
      expect(_state(c).racketPick.endsFlipped, isFalse);
      expect(_points(c).t1 + _points(c).t2, 5);
    });
  });

  group('TC-TENNIS-NOAD-01 No-Ad decides the game at 40-40', () {
    ProviderContainer noAd() => _container(_tennis({'noAd': true}));

    test('is read from the match rules', () {
      expect(_state(noAd()).config.noAd, isTrue);
      expect(_state(_container(_tennis())).config.noAd, isFalse);
    });

    test('at 40-40 the next point wins the game for team 1', () {
      final c = noAd();
      _play(c, _deuce);
      expect(_points(c), (t1: 3, t2: 3));
      _play(c, [true]);
      final set = _state(c).finishedSets.single;
      expect((set.score1, set.score2), (1, 0));
      expect(_points(c), (t1: 0, t2: 0));
    });

    test('at 40-40 the next point wins the game for team 2', () {
      final c = noAd();
      _play(c, _deuce);
      _play(c, [false]);
      final set = _state(c).finishedSets.single;
      expect((set.score1, set.score2), (0, 1));
    });

    test('with advantage rules the same point only gives advantage', () {
      final c = _container(_tennis());
      _play(c, [..._deuce, true]);
      expect(_points(c), (t1: 4, t2: 3));
      expect(_state(c).finishedSets, isEmpty);
    });

    test('40-0 still needs the 4th point', () {
      final c = noAd();
      _play(c, [true, true, true]);
      expect(_state(c).finishedSets, isEmpty);
      _play(c, [true]);
      expect(_state(c).finishedSets.single.score1, 1);
    });

    test('40-30 then 40-40 does not end the game', () {
      final c = noAd();
      _play(c, [true, true, true, false, false]);
      expect(_points(c), (t1: 3, t2: 2));
      _play(c, [false]);
      expect(_points(c), (t1: 3, t2: 3));
      expect(_state(c).finishedSets, isEmpty);
    });
  });

  group('TC-TENNIS-NOAD-02 No-Ad serve and set flow', () {
    ProviderContainer noAd() => _container(_tennis({'noAd': true}));

    test('the serve alternates per game as usual', () {
      final c = noAd();
      final servers = <int?>[];
      for (var game = 0; game < 4; game++) {
        servers.add(_state(c).racketServerTeam);
        _tennisPoints(c, true, 4);
      }
      expect(servers, [1, 2, 1, 2]);
    });

    test('the deciding point is served by the game server from the right', () {
      final c = noAd();
      _play(c, _deuce);
      expect(_state(c).racketServerTeam, 1);
      expect(_state(c).racketServerRight, isTrue);
    });

    test('in game 2 the deciding point is served by team 2', () {
      final c = noAd();
      _tennisPoints(c, true, 4);
      _play(c, _deuce);
      expect(_state(c).racketServerTeam, 2);
      expect(_state(c).racketServerRight, isTrue);
    });

    test('six No-Ad games close the set 6-0 with 24 points', () {
      final c = noAd();
      _tennisPoints(c, true, 24);
      expect(_state(c).finishedSets.single.isFinished, isTrue);
    });

    test('ends change after the deciding-point game like any odd game', () {
      final c = noAd();
      _play(c, [..._deuce, false]);
      expect(_state(c).racketPick.endsFlipped, isTrue);
    });
  });
}
