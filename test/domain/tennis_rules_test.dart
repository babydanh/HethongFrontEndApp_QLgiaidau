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
}
