import 'package:app_quanly_giaidau/domain/services/rally_serve_rules.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors the cases in openspec/changes/cach-bam-diem-cac-mon/reference/
// scoring-engine.test.js (badminton and table tennis). Teams are 1 and 2.
RallyServe _bd({
  int p1 = 0,
  int p2 = 0,
  int gameIndex = 0,
  bool doubles = false,
  int firstServer = 1,
  int? lastWinner,
  int? prevGameWinner,
  int? swaps1,
  int? swaps2,
}) => rallyServe(
  kind: SportRuleKind.badminton,
  p1: p1,
  p2: p2,
  gameIndex: gameIndex,
  doubles: doubles,
  firstServer: firstServer,
  lastWinner: lastWinner,
  prevGameWinner: prevGameWinner,
  swaps1: swaps1,
  swaps2: swaps2,
);

int? _tt(int p1, int p2, {int gameIndex = 0, int firstServer = 1}) =>
    rallyServe(
      kind: SportRuleKind.tableTennis,
      p1: p1,
      p2: p2,
      gameIndex: gameIndex,
      doubles: false,
      firstServer: firstServer,
    ).serverTeam;

void main() {
  group('TC-CBD-RALLY-01 badminton: first server of the match', () {
    test('0-0 in game 1 is served by the configured first server', () {
      expect(_bd().serverTeam, 1);
      expect(_bd(firstServer: 2).serverTeam, 2);
    });

    test('the opening server stands in the right court at 0', () {
      expect(_bd().rightCourt, isTrue);
    });
  });

  group('TC-CBD-RALLY-02 badminton: the winner of the rally serves', () {
    test('serving team follows the last rally winner', () {
      expect(_bd(p1: 0, p2: 1, lastWinner: 2).serverTeam, 2);
      expect(_bd(p1: 1, p2: 1, lastWinner: 1).serverTeam, 1);
    });

    test('court follows the server score: even right, odd left', () {
      expect(_bd(p1: 4, p2: 3, lastWinner: 1).rightCourt, isTrue);
      expect(_bd(p1: 3, p2: 4, lastWinner: 2).rightCourt, isTrue);
      expect(_bd(p1: 3, p2: 5, lastWinner: 2).rightCourt, isFalse);
      expect(_bd(p1: 5, p2: 2, lastWinner: 1).rightCourt, isFalse);
    });

    test('unknown last winner after the first point hides the server', () {
      final serve = _bd(p1: 2, p2: 1);
      expect(serve.serverTeam, isNull);
      expect(serve.rightCourt, isNull);
    });
  });

  group('TC-CBD-RALLY-03 badminton doubles: players swap courts', () {
    test('singles and unknown history give no player number', () {
      expect(_bd(p1: 1, lastWinner: 1, swaps1: 1).serverPlayer, isNull);
      expect(_bd(p1: 1, lastWinner: 1, doubles: true).serverPlayer, isNull);
    });

    test('player 1 opens from the right court', () {
      final serve = _bd(doubles: true, swaps1: 0, swaps2: 0);
      expect(serve.serverPlayer, 1);
    });

    test('winning on serve swaps the pair: same player serves from left', () {
      final serve = _bd(
        p1: 1,
        doubles: true,
        lastWinner: 1,
        swaps1: 1,
        swaps2: 0,
      );
      expect(serve.rightCourt, isFalse);
      expect(serve.serverPlayer, 1);
    });

    test('after two wins on serve the partner is on the right at even', () {
      final serve = _bd(
        p1: 2,
        doubles: true,
        lastWinner: 1,
        swaps1: 2,
        swaps2: 0,
      );
      expect(serve.rightCourt, isTrue);
      expect(serve.serverPlayer, 1);
      final afterOneSwap = _bd(
        p1: 2,
        doubles: true,
        lastWinner: 1,
        swaps1: 1,
        swaps2: 0,
      );
      expect(afterOneSwap.serverPlayer, 2);
    });
  });

  group('TC-CBD-RALLY-04 badminton: first server of later games', () {
    test('the winner of the previous game serves first', () {
      expect(_bd(gameIndex: 1, prevGameWinner: 2).serverTeam, 2);
      expect(_bd(gameIndex: 2, prevGameWinner: 1).serverTeam, 1);
    });

    test('unknown previous winner hides the server at 0-0', () {
      expect(_bd(gameIndex: 1).serverTeam, isNull);
    });
  });

  group('TC-CBD-RALLY-05 table tennis: serve changes every 2 points', () {
    test('team 1 opens, then 2, 2, 1, 1, 2', () {
      expect(_tt(0, 0), 1);
      expect(_tt(1, 0), 1);
      expect(_tt(1, 1), 2);
      expect(_tt(2, 1), 2);
      expect(_tt(2, 2), 1);
      expect(_tt(3, 2), 1);
      expect(_tt(3, 3), 2);
    });

    test('a second opening server flips every team', () {
      expect(_tt(0, 0, firstServer: 2), 2);
      expect(_tt(1, 1, firstServer: 2), 1);
    });
  });

  group('TC-CBD-RALLY-06 table tennis: from 10-10 serve every point', () {
    test('10-10 keeps the even-total server, then alternates', () {
      expect(_tt(10, 10), 1);
      expect(_tt(11, 10), 2);
      expect(_tt(11, 11), 1);
      expect(_tt(12, 11), 2);
    });

    test('10-9 is still on the every-2-points rhythm', () {
      expect(_tt(10, 9), 2);
      expect(_tt(9, 9), 2);
    });
  });

  group('TC-CBD-RALLY-07 table tennis: first server alternates per game', () {
    test('game 2 opens with the other team, game 3 with the first again', () {
      expect(_tt(0, 0, gameIndex: 1), 2);
      expect(_tt(0, 0, gameIndex: 2), 1);
      expect(_tt(1, 1, gameIndex: 1), 1);
    });
  });

  group('TC-CBD-RALLY-08 breaks, banners and other sports', () {
    RallyBreak bd({
      int p1 = 0,
      int p2 = 0,
      int gameIndex = 0,
      int? lastWinner,
    }) => rallyServeBanner(
      kind: SportRuleKind.badminton,
      p1: p1,
      p2: p2,
      gameIndex: gameIndex,
      lastWinner: lastWinner,
    );

    test('badminton: 60s when the leader first reaches 11', () {
      expect(bd(p1: 11, p2: 4, lastWinner: 1), RallyBreak.interval60);
      expect(bd(p1: 9, p2: 11, lastWinner: 2), RallyBreak.interval60);
    });

    test('badminton: no 60s when it is not the first side at 11', () {
      expect(bd(p1: 11, p2: 11, lastWinner: 1), RallyBreak.none);
      expect(bd(p1: 12, p2: 4, lastWinner: 1), RallyBreak.none);
      expect(bd(p1: 11, p2: 4), RallyBreak.none);
    });

    test('badminton: game 3 also reminds to change ends at 11', () {
      expect(
        bd(p1: 11, p2: 6, gameIndex: 2, lastWinner: 1),
        RallyBreak.interval60ChangeEnds,
      );
    });

    test('badminton: 120s rest at the start of the next game', () {
      expect(bd(gameIndex: 1), RallyBreak.betweenGames);
      expect(bd(gameIndex: 0), RallyBreak.none);
      expect(bd(p1: 1, gameIndex: 1, lastWinner: 1), RallyBreak.none);
    });

    test('table tennis: change ends at 5 only in the last game', () {
      RallyBreak tt(int p1, int p2, int gameIndex, int lastWinner) =>
          rallyServeBanner(
            kind: SportRuleKind.tableTennis,
            p1: p1,
            p2: p2,
            gameIndex: gameIndex,
            bestOf: 5,
            lastWinner: lastWinner,
          );
      expect(tt(5, 2, 4, 1), RallyBreak.changeEnds);
      expect(tt(5, 2, 3, 1), RallyBreak.none);
      expect(tt(5, 5, 4, 1), RallyBreak.none);
      expect(tt(6, 2, 4, 1), RallyBreak.none);
    });

    test('other sports show nothing', () {
      for (final kind in [
        SportRuleKind.pickleball,
        SportRuleKind.tennis,
        SportRuleKind.football,
      ]) {
        final serve = rallyServe(
          kind: kind,
          p1: 3,
          p2: 2,
          gameIndex: 0,
          doubles: false,
          lastWinner: 1,
        );
        expect(serve.serverTeam, isNull);
        expect(
          rallyServeBanner(
            kind: kind,
            p1: 11,
            p2: 2,
            gameIndex: 0,
            lastWinner: 1,
          ),
          RallyBreak.none,
        );
      }
    });
  });

  group('TC-RACKET-B-01 set point team', () {
    int sp(int a, int b, {int target = 21, bool two = true, int cap = 30}) =>
        rallySetPointTeam(
          p1: a,
          p2: b,
          target: target,
          winByTwo: two,
          cap: cap,
        );

    test('20-17 is a set point for team 1, 17-20 for team 2', () {
      expect(sp(20, 17), 1);
      expect(sp(17, 20), 2);
    });
    test('mid game and a one point lead at 20-20 have none', () {
      expect(sp(5, 3), 0);
      expect(sp(20, 20), 0);
      expect(sp(0, 0), 0);
    });
    test('21-20 is a set point (win by 2 needs 22)', () {
      expect(sp(21, 20), 1);
    });
    test('29-29: either team wins with the next point, so none is named', () {
      expect(sp(29, 29), 0);
    });
    test('30-29 cannot happen as a lead, 29-28 is a set point at the cap', () {
      expect(sp(29, 28), 1);
    });
  });

  group('TC-RACKET-B-02 golden point', () {
    test('only at cap-1 all', () {
      expect(rallyGoldenPoint(p1: 29, p2: 29, cap: 30), isTrue);
      expect(rallyGoldenPoint(p1: 28, p2: 29, cap: 30), isFalse);
      expect(rallyGoldenPoint(p1: 20, p2: 20, cap: 30), isFalse);
    });
    test('no cap means no golden point', () {
      expect(rallyGoldenPoint(p1: 29, p2: 29, cap: 0), isFalse);
    });
  });
}
