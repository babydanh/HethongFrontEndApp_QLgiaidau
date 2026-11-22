import 'package:app_quanly_giaidau/domain/services/tennis_serve_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal tennis scorer that feeds [TennisScoreInput], ported from the
/// reference engine (tennis-rules.js) so the rule tests read the same.
class _Sim {
  _Sim({this.noAd = false, this.matchTiebreak = false});

  final bool noAd;
  final bool matchTiebreak;
  final sets = <List<int>>[];
  final wins = [0, 0];
  var g = [0, 0];
  var p = [0, 0];
  var mode = 'standard';
  TennisCourtState court = const TennisCourtState();

  TennisScoreInput get input => TennisScoreInput(
    setIndex: sets.length,
    gamesBefore: sets.fold(0, (n, s) => n + s[0] + s[1]),
    games1: g[0],
    games2: g[1],
    points1: p[0],
    points2: p[1],
    isTiebreak: mode != 'standard',
    noAd: noAd,
  );

  void point(int team, [int count = 1]) {
    for (var i = 0; i < count; i++) {
      _one(team - 1);
    }
  }

  void game(int team) => point(team, 4);

  void games(List<int> winners) => winners.forEach(game);

  void _one(int t) {
    final o = 1 - t;
    p[t]++;
    if (mode == 'standard') {
      final won = noAd ? p[t] >= 4 : p[t] >= 4 && p[t] - p[o] >= 2;
      if (!won) return;
      g[t]++;
      p = [0, 0];
      final setWon =
          (g[t] >= 6 && g[t] - g[o] >= 2) || (g[t] == 7 && g[o] == 6);
      if (setWon) return _close(t);
      if (g[0] == 6 && g[1] == 6) mode = 'tiebreak';
      return;
    }
    final target = mode == 'matchTiebreak' ? 10 : 7;
    if (p[t] < target || p[t] - p[o] < 2) return;
    if (mode == 'matchTiebreak') {
      g = t == 0 ? [1, 0] : [0, 1];
    } else {
      g[t]++;
    }
    _close(t);
  }

  void _close(int t) {
    sets.add(g);
    wins[t]++;
    g = [0, 0];
    p = [0, 0];
    final deciding = wins[0] == 1 && wins[1] == 1;
    mode = deciding && matchTiebreak ? 'matchTiebreak' : 'standard';
  }

  void apply(TennisCourtState? next) {
    expect(next, isNotNull, reason: 'the choice was refused');
    court = next!;
  }

  String get server {
    final s = tennisServeOf(input, court);
    return '${s.team == 1 ? 'A' : 'B'}${s.playerIndex + 1}';
  }

  String get receiver {
    final r = tennisReceiverOf(input, court);
    return '${r.team == 1 ? 'A' : 'B'}${r.playerIndex + 1}';
  }

  bool get serveRight => tennisServeOf(input, court).serveRight;

  TennisHint? get hint => tennisHint(input, court);
}

/// A1 serves first, B1 receives right (the default).
_Sim _started({bool noAd = false, bool matchTiebreak = false}) {
  final m = _Sim(noAd: noAd, matchTiebreak: matchTiebreak);
  m.apply(tennisPickServer(m.input, m.court, 1, 0));
  return m;
}

/// Game 2: B picked B1 to serve.
_Sim _toGame2({bool matchTiebreak = false}) {
  final m = _started(matchTiebreak: matchTiebreak)..game(1);
  m.apply(tennisPickServer(m.input, m.court, 2, 0));
  return m;
}

List<TennisCellActionKind> _kinds(_Sim m, int team, int player) => [
  for (final a in tennisCellActions(m.input, m.court, team, player)) a.kind,
];

void main() {
  test(
    'TC-TENNIS-SERVE-01 nothing picked: A1 serves, B1 receives, hint to pick',
    () {
      final m = _Sim();
      expect(m.server, 'A1');
      expect(m.receiver, 'B1');
      expect(m.hint, TennisHint.pickServer);
      expect(tennisQuickPick(m.input, m.court, 2), isTrue);
    },
  );

  test('TC-TENNIS-SERVE-02 picking the server shows the receiver at once', () {
    final m = _Sim();
    m.apply(tennisPickServer(m.input, m.court, 1, 1));
    expect(m.server, 'A2');
    expect(m.receiver, 'B1');
    expect(m.hint, TennisHint.swapReceiver);
    m.apply(tennisPickReceiveRight(m.input, m.court, 2, 1));
    expect(m.receiver, 'B2');
  });

  test('TC-TENNIS-SERVE-03 Rule 17: right court first, then alternate', () {
    final m = _started();
    expect([m.serveRight, m.receiver], [true, 'B1']);
    m.point(1);
    expect([m.serveRight, m.receiver], [false, 'B2']);
    m.point(2);
    expect([m.serveRight, m.receiver], [true, 'B1']);
    expect(m.hint, isNull);
  });

  test(
    'TC-TENNIS-SERVE-04 Rule 14: game 2 team B serves player 0 by default',
    () {
      final m = _started()..game(1);
      expect(m.server, 'B1');
      expect(m.hint, TennisHint.pickServer);
      expect(tennisQuickPick(m.input, m.court, 2), isTrue);
      expect(tennisQuickPick(m.input, m.court, 1), isFalse);
    },
  );

  test('TC-TENNIS-SERVE-05 Rule 14: A1, B1, A2, B2, A1', () {
    final m = _toGame2();
    final order = [m.server];
    for (final w in [2, 1, 2, 1]) {
      m.game(w);
      order.add(m.server);
    }
    expect(order, ['B1', 'A2', 'B2', 'A1', 'B1']);
  });

  test('TC-TENNIS-SERVE-06 a team is locked after its first serving turn', () {
    final a = _started()..point(1);
    expect(tennisPickServer(a.input, a.court, 1, 1), isNull);
    final b = _toGame2();
    expect(tennisPickServer(b.input, b.court, 2, 1), isNotNull);
    b.point(2);
    expect(tennisPickServer(b.input, b.court, 2, 1), isNull);
  });

  test('TC-TENNIS-SERVE-07 Rule 27c: correction continues the rotation', () {
    final m = _toGame2()..game(2);
    expect(m.server, 'A2');
    m.apply(tennisCorrectServer(m.input, m.court, 1, 0));
    expect(m.server, 'A1');
    m.games([1, 2]);
    expect(m.server, 'A2');
    expect(tennisCorrectServer(m.input, m.court, 2, 0), isNull);
  });

  test(
    'TC-TENNIS-SERVE-08 Rules 15 + 27e: receiver fix lasts this game only',
    () {
      final m = _started()..point(1);
      expect(tennisPickReceiveRight(m.input, m.court, 2, 1), isNull);
      m.apply(tennisFixReceiver(m.input, m.court, 2, 1));
      expect(m.receiver, 'B1'); // 15-0: left court, B2 now right
      m.point(1, 3);
      m.apply(tennisPickServer(m.input, m.court, 2, 0));
      m.game(2);
      expect(m.receiver, 'B1'); // game 3: back to the set order
    },
  );

  test('TC-TENNIS-SERVE-09 deuce right, advantage left, deuce right', () {
    final m = _started()
      ..point(1, 3)
      ..point(2, 3);
    expect(m.serveRight, isTrue);
    m.point(1);
    expect(m.serveRight, isFalse);
    m.point(2);
    expect(m.serveRight, isTrue);
  });

  test('TC-TENNIS-SERVE-10 No-Ad: the receivers choose who returns', () {
    final m = _started(noAd: true)
      ..point(1, 3)
      ..point(2, 3);
    expect(m.hint, TennisHint.decidingReceiver);
    expect(_kinds(m, 2, 1), contains(TennisCellActionKind.decidingReceiver));
    m.apply(tennisChooseDecidingReceiver(m.input, m.court, 2, 1));
    expect([m.serveRight, m.receiver], [false, 'B2']);
    expect(m.hint, isNull);
    expect(tennisChooseDecidingReceiver(m.input, m.court, 1, 0), isNull);
  });

  test('TC-TENNIS-SERVE-11 Advantage rules: no deciding-point choice', () {
    final m = _started()
      ..point(1, 3)
      ..point(2, 3);
    expect(
      _kinds(m, 2, 1),
      isNot(contains(TennisCellActionKind.decidingReceiver)),
    );
    expect(tennisChooseDecidingReceiver(m.input, m.court, 2, 1), isNull);
  });

  test(
    'TC-TENNIS-SERVE-12 Rule 5b: tie-break order continues the rotation',
    () {
      final m = _toGame2()..games([2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2]);
      expect(m.mode, 'tiebreak');
      final seq = <String>[];
      for (var i = 0; i < 6; i++) {
        seq.add('${m.server}${m.serveRight ? 'R' : 'L'}');
        m.point(i.isOdd ? 1 : 2);
      }
      expect(seq, ['A1R', 'B1L', 'B1R', 'A2L', 'A2R', 'B2L']);
    },
  );

  test('TC-TENNIS-SERVE-13 the tie-break opener receives first in set 2', () {
    final m = _toGame2()..games([2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2]);
    final opener = tennisServeOf(m.input, m.court).team;
    m.point(1, 7);
    expect(m.sets.first, [7, 6]);
    expect(tennisServeOf(m.input, m.court).team, 3 - opener);
  });

  test(
    'TC-TENNIS-SERVE-14 a new set asks again, set 1 choices do not carry',
    () {
      final m = _toGame2();
      m.apply(tennisPickReceiveRight(m.input, m.court, 1, 1));
      m.games([2, 1, 2, 1, 2, 1, 1, 1]); // A wins 6-3
      expect(m.sets.first, [6, 3]);
      expect(m.hint, TennisHint.pickServer);
      expect(m.server, 'B1');
      expect(m.receiver, 'A1');
    },
  );

  test(
    'TC-TENNIS-SERVE-15 match tie-break: the second team stays free until its turn',
    () {
      final m = _toGame2(matchTiebreak: true)..games([1, 1, 1, 1, 1]);
      for (var i = 0; i < 6; i++) {
        m.game(2);
      }
      expect(m.mode, 'matchTiebreak');
      expect(m.hint, TennisHint.pickServer);
      final opener = tennisServeOf(m.input, m.court).team;
      m.apply(tennisPickServer(m.input, m.court, opener, 1));
      m.point(1);
      final second = 3 - opener;
      expect(
        tennisIsLocked(m.input, m.court, second, TennisRole.serve),
        isFalse,
      );
      expect(
        tennisIsLocked(m.input, m.court, opener, TennisRole.serve),
        isTrue,
      );
      expect(m.hint, TennisHint.pickServer);
    },
  );

  test(
    'TC-TENNIS-SERVE-16 tapping the other team before the first point changes the toss',
    () {
      final m = _started();
      m.apply(tennisPickServer(m.input, m.court, 2, 1));
      expect(m.court.firstServerTeam, 2);
      expect(m.server, 'B2');
      expect(m.court.choiceAt(0).serveFirstOf(1), isNull);
    },
  );

  test('TC-TENNIS-SERVE-17 JSON keeps the shared contract', () {
    final m = _started()..point(1);
    m.apply(tennisFixReceiver(m.input, m.court, 2, 1));
    m.court = tennisToggleEnds(m.court);
    final json = m.court.toJson();
    expect(json, {
      'version': 1,
      'kind': 'TENNIS',
      'firstServerTeam': 1,
      'sets': [
        {
          'serveFirst': {'team1': 0, 'team2': null},
          'receiveRight': {'team1': null, 'team2': null},
        },
      ],
      'gameFix': {'set': 0, 'game': 0, 'team': 2, 'playerIndex': 1},
      'decidingReceiver': null,
      'endsFlipped': true,
    });
    final back = TennisCourtState.fromJson({
      ...json,
      'updatedAt': '2026-11-22T00:00:00Z',
      'updatedBy': 'u1',
    });
    expect(back, m.court);
  });

  test('TC-TENNIS-SERVE-18 missing or invalid court state means defaults', () {
    const empty = TennisCourtState();
    expect(TennisCourtState.fromJson(null), empty);
    expect(TennisCourtState.fromJson('x'), empty);
    expect(TennisCourtState.fromJson({'kind': 'PICKLEBALL'}), empty);
    final bad = TennisCourtState.fromJson({
      'kind': 'TENNIS',
      'firstServerTeam': 3,
      'sets': [
        {
          'serveFirst': {'team1': 5, 'team2': 1},
        },
        'oops',
      ],
      'gameFix': {'set': -1, 'game': 0, 'team': 1, 'playerIndex': 0},
      'endsFlipped': 'yes',
    });
    expect(bad.firstServerTeam, isNull);
    expect(bad.choiceAt(0).serveFirstOf(1), isNull);
    expect(bad.choiceAt(0).serveFirstOf(2), 1);
    expect(bad.choiceAt(1).serveFirstOf(2), isNull);
    expect(bad.gameFix, isNull);
    expect(bad.endsFlipped, isFalse);
    expect(empty.toJson()['sets'], hasLength(1));
  });

  test(
    'TC-TENNIS-SERVE-19 cell menu: free picks first, corrections once locked',
    () {
      final m = _started();
      expect(_kinds(m, 1, 1), [
        TennisCellActionKind.pickServer,
        TennisCellActionKind.switchEnds,
      ]);
      expect(_kinds(m, 1, 0), [TennisCellActionKind.switchEnds]);
      expect(_kinds(m, 2, 0), [
        TennisCellActionKind.pickServer,
        TennisCellActionKind.pickReceiveRight,
        TennisCellActionKind.switchEnds,
      ]);
      m.point(1);
      expect(_kinds(m, 1, 1), [
        TennisCellActionKind.correctServer,
        TennisCellActionKind.switchEnds,
      ]);
      final receive = tennisCellActions(m.input, m.court, 2, 0);
      expect(
        [for (final a in receive) a.kind],
        [TennisCellActionKind.fixReceiver, TennisCellActionKind.switchEnds],
      );
      // The swap targets the partner of today's right-court receiver.
      expect(receive.first.playerIndex, 1);
    },
  );

  test('TC-TENNIS-SERVE-20 apply dispatches every action', () {
    final m = _started();
    TennisCellAction act(TennisCellActionKind kind, int team, int player) =>
        TennisCellAction(kind, team: team, playerIndex: player);
    m.apply(
      tennisApplyAction(
        m.input,
        m.court,
        act(TennisCellActionKind.pickReceiveRight, 2, 1),
      ),
    );
    expect(m.receiver, 'B2');
    m.apply(
      tennisApplyAction(
        m.input,
        m.court,
        act(TennisCellActionKind.switchEnds, 1, 0),
      ),
    );
    expect(m.court.endsFlipped, isTrue);
    expect(
      tennisApplyAction(
        m.input,
        m.court,
        act(TennisCellActionKind.correctServer, 2, 0),
      ),
      isNull,
    );
  });

  test(
    'TC-TENNIS-SERVE-21 set server: free pick, then 27c, never the other team mid-game',
    () {
      final m = _Sim();
      m.apply(tennisSetServer(m.input, m.court, 2, 1));
      expect(m.server, 'B2');
      m.point(1);
      expect(tennisSetServer(m.input, m.court, 1, 0), isNull);
      m.apply(tennisSetServer(m.input, m.court, 2, 0));
      expect(m.server, 'B1');
    },
  );
}
