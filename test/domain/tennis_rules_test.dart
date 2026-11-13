import 'package:app_quanly_giaidau/domain/services/tennis_rules.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors the tennis cases in openspec/changes/cach-bam-diem-cac-mon/reference/
// scoring-engine.test.js. Points are raw counts (0,1,2,3 = 0,15,30,40).
void main() {
  group('TC-CBD-TN-01 game won with advantage', () {
    test('4-0 and 4-2 win, 4-3 needs one more point', () {
      bool won(int a, int b) =>
          tennisGameWon(a: a, b: b, noAd: false, tiebreak: false);
      expect(won(4, 0), isTrue);
      expect(won(4, 2), isTrue);
      expect(won(4, 3), isFalse);
      expect(won(3, 3), isFalse);
      expect(won(5, 3), isTrue);
    });
  });

  group('TC-CBD-TN-02 No-Ad', () {
    test('the next point at 40-40 decides the game', () {
      expect(tennisGameWon(a: 4, b: 3, noAd: true, tiebreak: false), isTrue);
      expect(tennisGameWon(a: 4, b: 3, noAd: false, tiebreak: false), isFalse);
    });

    test('before 40-40 it plays like a normal game', () {
      expect(tennisGameWon(a: 3, b: 2, noAd: true, tiebreak: false), isFalse);
      expect(tennisGameWon(a: 4, b: 2, noAd: true, tiebreak: false), isTrue);
    });

    test('No-Ad never changes a tie-break', () {
      expect(tennisGameWon(a: 7, b: 6, noAd: true, tiebreak: true), isFalse);
    });
  });

  group('TC-CBD-TN-03 tie-break needs the target and a 2 point lead', () {
    bool won(int a, int b, int target) => tennisGameWon(
      a: a,
      b: b,
      noAd: false,
      tiebreak: true,
      tiebreakTarget: target,
    );

    test('target 7', () {
      expect(won(7, 5, 7), isTrue);
      expect(won(7, 6, 7), isFalse);
      expect(won(8, 6, 7), isTrue);
      expect(won(6, 0, 7), isFalse);
    });

    test('target 10', () {
      expect(won(10, 8, 10), isTrue);
      expect(won(10, 9, 10), isFalse);
      expect(won(11, 9, 10), isTrue);
      expect(won(7, 0, 10), isFalse);
    });

    test('the default target is 7', () {
      expect(tennisGameWon(a: 7, b: 5, noAd: false, tiebreak: true), isTrue);
    });
  });

  group('TC-CBD-TN-04 set plan from the configuration', () {
    TennisSetPlan plan({
      TennisFinalSetMode final_ = TennisFinalSetMode.standard,
      TennisTiebreakMode mode = TennisTiebreakMode.standard,
      int points = 7,
      bool deciding = false,
    }) => tennisSetPlan(
      finalSetMode: final_,
      tiebreakMode: mode,
      tiebreakPoints: points,
      decidingSet: deciding,
    );

    test('no configuration keeps the old tie-break 7 at 6-6', () {
      final p = plan(deciding: true);
      expect(p.tiebreakEnabled, isTrue);
      expect(p.tiebreakTarget, 7);
      expect(p.matchTiebreak, isFalse);
    });

    test('tiebreakPoints sets the target of a normal tie-break', () {
      expect(plan(points: 10).tiebreakTarget, 10);
    });

    test('SUPER_10 makes every tie-break 10 points', () {
      expect(plan(mode: TennisTiebreakMode.super10).tiebreakTarget, 10);
    });

    test('tiebreakMode NONE plays on without a tie-break', () {
      expect(plan(mode: TennisTiebreakMode.none).tiebreakEnabled, isFalse);
    });

    test('NO_TIEBREAK drops the tie-break only in the deciding set', () {
      const f = TennisFinalSetMode.noTiebreak;
      expect(plan(final_: f, deciding: true).tiebreakEnabled, isFalse);
      expect(plan(final_: f).tiebreakEnabled, isTrue);
    });

    test(
      'SUPER_TIEBREAK replaces the deciding set by a 10 point tie-break',
      () {
        const f = TennisFinalSetMode.matchTiebreak;
        final p = plan(final_: f, deciding: true);
        expect(p.matchTiebreak, isTrue);
        expect(p.tiebreakEnabled, isTrue);
        expect(p.tiebreakTarget, 10);
        expect(plan(final_: f).matchTiebreak, isFalse);
      },
    );

    test('a 10 point tie-break at 6-6 of the deciding set', () {
      const f = TennisFinalSetMode.tb10Final;
      expect(plan(final_: f, deciding: true).tiebreakTarget, 10);
      expect(plan(final_: f).tiebreakTarget, 7);
    });

    test('Backend and short names parse to the same modes', () {
      expect(
        parseTennisFinalSetMode('SUPER_TIEBREAK'),
        TennisFinalSetMode.matchTiebreak,
      );
      expect(
        parseTennisFinalSetMode('MATCH_TB10'),
        TennisFinalSetMode.matchTiebreak,
      );
      expect(
        parseTennisFinalSetMode('NO_TIEBREAK'),
        TennisFinalSetMode.noTiebreak,
      );
      expect(
        parseTennisFinalSetMode('NO_TB_FINAL'),
        TennisFinalSetMode.noTiebreak,
      );
      expect(parseTennisFinalSetMode('STANDARD'), TennisFinalSetMode.standard);
      expect(parseTennisFinalSetMode('TB7'), TennisFinalSetMode.standard);
      expect(
        parseTennisFinalSetMode('TB10_FINAL'),
        TennisFinalSetMode.tb10Final,
      );
      expect(parseTennisFinalSetMode('bogus'), isNull);
      expect(parseTennisTiebreakMode('SUPER_10'), TennisTiebreakMode.super10);
      expect(parseTennisTiebreakMode('NONE'), TennisTiebreakMode.none);
      expect(
        parseTennisTiebreakMode('STANDARD_7'),
        TennisTiebreakMode.standard,
      );
      expect(parseTennisTiebreakMode(null), isNull);
    });

    test('the deciding set needs both sides one set short of winning', () {
      expect(tennisIsDecidingSet(1, 1, 2), isTrue);
      expect(tennisIsDecidingSet(1, 0, 2), isFalse);
      expect(tennisIsDecidingSet(0, 0, 1), isFalse);
      expect(tennisIsDecidingSet(2, 2, 3), isTrue);
    });
  });

  group('TC-CBD-TN-05 who serves', () {
    int game(int played) => tennisServer(gamesPlayed: played, tiebreak: false);

    test('the serve changes every game', () {
      expect(game(0), 1);
      expect(game(1), 2);
      expect(game(2), 1);
      expect(game(13), 2);
    });

    test('a different first server flips every game', () {
      expect(tennisServer(gamesPlayed: 0, tiebreak: false, firstServer: 2), 2);
      expect(tennisServer(gamesPlayed: 1, tiebreak: false, firstServer: 2), 1);
    });

    test('tie-break: first point by the game server, then 2 points each', () {
      int tb(int points) =>
          tennisServer(gamesPlayed: 12, tiebreak: true, tiebreakPoints: points);
      expect(tb(0), 1);
      expect(tb(1), 2);
      expect(tb(2), 2);
      expect(tb(3), 1);
      expect(tb(4), 1);
      expect(tb(5), 2);
    });
  });

  group('TC-RACKET-T-01 serve court follows the points of the game', () {
    test('even points: right court, odd points: left court', () {
      expect(tennisServeRight(0), isTrue);
      expect(tennisServeRight(1), isFalse);
      expect(tennisServeRight(2), isTrue);
      expect(tennisServeRight(5), isFalse);
    });
  });

  group('TC-RACKET-T-02 game point team', () {
    int gp(int a, int b, {bool noAd = false, bool tb = false}) =>
        tennisGamePointTeam(p1: a, p2: b, noAd: noAd, tiebreak: tb);

    test('40-30 is a game point for the leader', () {
      expect(gp(3, 2), 1);
      expect(gp(1, 3), 2);
    });
    test('0-0, 30-30 and 40-40 (advantage game) have none', () {
      expect(gp(0, 0), 0);
      expect(gp(2, 2), 0);
      expect(gp(3, 3), 0);
    });
    test('advantage: the team with the advantage', () {
      expect(gp(4, 3), 1);
      expect(gp(3, 4), 2);
    });
    test('No-Ad at 40-40 both teams are one point from the game', () {
      expect(gp(3, 3, noAd: true), 0);
      expect(gp(3, 2, noAd: true), 1);
    });
    test('tie-break to 7 needs a 2 point lead', () {
      expect(gp(6, 5, tb: true), 1);
      expect(gp(6, 6, tb: true), 0);
      expect(gp(5, 6, tb: true), 2);
    });
  });

  group('TC-RACKET-T-03 change of ends', () {
    test('after an odd game of the set', () {
      expect(tennisChangeEndsAfterGame(1), isTrue);
      expect(tennisChangeEndsAfterGame(2), isFalse);
      expect(tennisChangeEndsAfterGame(13), isTrue);
    });
    test('tie-break: every 6 points', () {
      expect(tennisTiebreakChangeEnds(0), isFalse);
      expect(tennisTiebreakChangeEnds(5), isFalse);
      expect(tennisTiebreakChangeEnds(6), isTrue);
      expect(tennisTiebreakChangeEnds(12), isTrue);
    });
  });

  group('TC-RACKET-T-04 service games of a team', () {
    int sg(int played, int team, {int first = 1}) => tennisTeamServiceGames(
      gamesPlayed: played,
      team: team,
      firstServer: first,
    );
    test('counts the games the team already served', () {
      expect(sg(0, 1), 0);
      expect(sg(1, 1), 1);
      expect(sg(1, 2), 0);
      expect(sg(4, 1), 2);
      expect(sg(4, 2), 2);
      expect(sg(5, 1), 3);
    });
    test('respects a different first server', () {
      expect(sg(1, 2, first: 2), 1);
      expect(sg(1, 1, first: 2), 0);
    });
  });

  group('TC-RACKET-T-05 doubles server alternates per service game', () {
    test('first player serves the first service game, the partner the next', () {
      expect(tennisServerPlayerIndex(teamServiceGames: 0), 0);
      expect(tennisServerPlayerIndex(teamServiceGames: 1), 1);
      expect(tennisServerPlayerIndex(teamServiceGames: 2), 0);
    });
    test('starts from the picked first player', () {
      expect(tennisServerPlayerIndex(teamServiceGames: 0, firstPlayer: 1), 1);
      expect(tennisServerPlayerIndex(teamServiceGames: 1, firstPlayer: 1), 0);
    });
  });

  group('TC-RACKET-T-06 tie-break doubles rotation', () {
    int turns(int points, {required bool gameServer}) =>
        tennisTiebreakTurnsServed(
          tiebreakPoints: points,
          isGameServer: gameServer,
        );
    test('the game server serves point 0, then the other team 1-2, 3-4...', () {
      expect(turns(0, gameServer: true), 0);
      expect(turns(1, gameServer: false), 0);
      expect(turns(3, gameServer: true), 1);
      expect(turns(5, gameServer: false), 1);
    });
    test('the second turn of a team uses the partner', () {
      final first = tennisServerPlayerIndex(teamServiceGames: 2);
      final second = tennisServerPlayerIndex(
        teamServiceGames: 2,
        tiebreakTurnsServed: turns(3, gameServer: true),
      );
      expect(second, isNot(first));
    });
  });
}
