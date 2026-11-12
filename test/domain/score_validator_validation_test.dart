import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _badminton = SportConfig(
  kind: SportRuleKind.badminton,
  scoringModel: SportScoringModel.rallyPointSet,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 21,
  mustWinByTwo: true,
  maxPoints: 30,
  tiebreakAt: 20,
);

const _firstTo11 = SportConfig(
  kind: SportRuleKind.football,
  scoringModel: SportScoringModel.rallyPointSet,
  bestOf: 1,
  setsToWin: 1,
  pointsPerSet: 11,
  mustWinByTwo: false,
  maxPoints: 99,
  tiebreakAt: 90,
);

const _tennis = SportConfig(
  kind: SportRuleKind.tennis,
  scoringModel: SportScoringModel.tennisSet,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 6,
  mustWinByTwo: true,
  maxPoints: 7,
  tiebreakAt: 6,
);

const _sideOut = SportConfig(
  kind: SportRuleKind.pickleball,
  scoringModel: SportScoringModel.pickleballSideOut,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 11,
  mustWinByTwo: true,
  maxPoints: 0, // 0 = no cap
  tiebreakAt: 10,
);

SetScoreData _set(int a, int b) => SetScoreData(score1: a, score2: b);

/// Runs [validate] and returns the code it rejects with, or null when valid.
ScoreValidationCode? _codeOf(void Function() validate) {
  try {
    validate();
    return null;
  } on ScoreValidationException catch (e) {
    return e.code;
  }
}

ScoreValidationCode? _rally(int a, int b, [SportConfig config = _badminton]) =>
    _codeOf(() => validateRallyPointSet(_set(a, b), config, setNumber: 1));

ScoreValidationCode? _tennisCode(int a, int b, [SportConfig config = _tennis]) =>
    _codeOf(() => validateTennisSet(_set(a, b), config, setNumber: 1));

ScoreValidationCode? _side(int a, int b, [SportConfig config = _sideOut]) =>
    _codeOf(
      () => validatePickleballSideOutSet(_set(a, b), config, setNumber: 1),
    );

void main() {
  group('validateRallyPointSet', () {
    test('accepts a straightforward win and a two-point deuce finish', () {
      expect(_rally(21, 15), isNull);
      expect(_rally(15, 21), isNull); // either side may win
      expect(_rally(22, 20), isNull);
      expect(_rally(25, 23), isNull);
    });

    test('rejects a tie before anything else', () {
      expect(_rally(21, 21), ScoreValidationCode.tie);
      expect(_rally(0, 0), ScoreValidationCode.tie);
    });

    test('rejects a winner below the target', () {
      expect(_rally(20, 10), ScoreValidationCode.minimumScore);
    });

    test('before deuce the winner must stop exactly on the target', () {
      expect(_rally(22, 15), ScoreValidationCode.exactTarget);
    });

    test('in deuce the margin must be exactly two', () {
      expect(_rally(21, 20), ScoreValidationCode.deuceMargin);
      expect(_rally(23, 20), ScoreValidationCode.deuceMargin);
    });

    test('a score above the cap is rejected', () {
      expect(_rally(31, 29), ScoreValidationCode.maximumScore);
    });

    test('without win-by-two the winner must hit the target exactly', () {
      expect(_rally(11, 10, _firstTo11), isNull);
      expect(_rally(11, 0, _firstTo11), isNull);
      expect(_rally(12, 5, _firstTo11), ScoreValidationCode.exactTarget);
    });

    test('the exception carries the set context and a stable token', () {
      late ScoreValidationException error;
      try {
        validateRallyPointSet(_set(21, 21), _badminton, setNumber: 2);
      } on ScoreValidationException catch (e) {
        error = e;
      }

      expect(error.setNumber, 2);
      expect(error.score1, 21);
      expect(error.target, 21);
      expect(error.maxPoints, 30);
      expect(error.token, 'scoreValidation|tie|2|21|21|21|30');
      expect(error, isA<FormatException>());
    });
  });

  group('validateTennisSet', () {
    test('accepts 6-x by two games and the 7-5 / 7-6 finishes', () {
      expect(_tennisCode(6, 4), isNull);
      expect(_tennisCode(6, 0), isNull);
      expect(_tennisCode(7, 5), isNull);
      expect(_tennisCode(7, 6), isNull);
      expect(_tennisCode(4, 6), isNull);
    });

    test('rejects ties, short sets and oversize scores', () {
      expect(_tennisCode(6, 6), ScoreValidationCode.tie);
      expect(_tennisCode(5, 3), ScoreValidationCode.minimumScore);
      expect(_tennisCode(8, 6), ScoreValidationCode.maximumScore);
    });

    test('6-5 is not a finished set', () {
      expect(_tennisCode(6, 5), ScoreValidationCode.tennisSet);
    });

    test('a 7-x set must end 7-5 or 7-6', () {
      expect(_tennisCode(7, 4), ScoreValidationCode.tennisTiebreak);
      expect(_tennisCode(7, 3), ScoreValidationCode.tennisTiebreak);
    });

    test('a score strictly between target and cap is not a tennis set', () {
      const longSet = SportConfig(
        kind: SportRuleKind.tennis,
        scoringModel: SportScoringModel.tennisSet,
        bestOf: 3,
        setsToWin: 2,
        pointsPerSet: 6,
        mustWinByTwo: true,
        maxPoints: 9,
        tiebreakAt: 6,
      );

      expect(_tennisCode(7, 5, longSet), ScoreValidationCode.tennisSet);
      expect(_tennisCode(9, 7, longSet), isNull);
      expect(_tennisCode(9, 3, longSet), ScoreValidationCode.tennisTiebreak);
    });
  });

  group('validatePickleballSideOutSet', () {
    test('accepts a win at the target and a two-point deuce finish', () {
      expect(_side(11, 5), isNull);
      expect(_side(11, 9), isNull);
      expect(_side(12, 10), isNull);
      expect(_side(30, 28), isNull); // maxPoints 0 means uncapped
    });

    test('uses the side-out specific codes', () {
      expect(_side(5, 5), ScoreValidationCode.tie);
      expect(_side(10, 3), ScoreValidationCode.minimumScore);
      expect(_side(11, 10), ScoreValidationCode.sideOutDeuceMargin);
      expect(_side(13, 10), ScoreValidationCode.sideOutDeuceMargin);
      expect(_side(12, 8), ScoreValidationCode.sideOutTarget);
    });

    test('without win-by-two an overshoot is sideOutExactTarget', () {
      const strict = SportConfig(
        kind: SportRuleKind.pickleball,
        scoringModel: SportScoringModel.pickleballSideOut,
        bestOf: 1,
        setsToWin: 1,
        pointsPerSet: 11,
        mustWinByTwo: false,
        maxPoints: 0,
        tiebreakAt: 10,
      );

      expect(_side(11, 7, strict), isNull);
      expect(_side(12, 7, strict), ScoreValidationCode.sideOutExactTarget);
    });

    test('a positive cap rejects scores above it', () {
      const capped = SportConfig(
        kind: SportRuleKind.pickleball,
        scoringModel: SportScoringModel.pickleballSideOut,
        bestOf: 3,
        setsToWin: 2,
        pointsPerSet: 11,
        mustWinByTwo: true,
        maxPoints: 15,
        tiebreakAt: 10,
      );

      expect(_side(16, 14, capped), ScoreValidationCode.sideOutMaximumScore);
      expect(_side(12, 10, capped), isNull);
    });
  });

  group('isSetComplete', () {
    test('is false below the target or on a tie', () {
      expect(isSetComplete(_set(20, 5), _badminton), isFalse);
      expect(isSetComplete(_set(25, 25), _badminton), isFalse);
    });

    test('is true as soon as the cap is reached', () {
      expect(isSetComplete(_set(30, 29), _badminton), isTrue);
    });

    test('without win-by-two reaching the target ends the set', () {
      expect(isSetComplete(_set(11, 10), _firstTo11), isTrue);
    });

    test('with win-by-two every scoring model needs a two-point lead', () {
      expect(isSetComplete(_set(7, 5), _tennis), isTrue);
      expect(isSetComplete(_set(6, 5), _tennis), isFalse);
      expect(isSetComplete(_set(12, 10), _sideOut), isTrue);
      expect(isSetComplete(_set(11, 10), _sideOut), isFalse);
      expect(isSetComplete(_set(22, 20), _badminton), isTrue);
      expect(isSetComplete(_set(22, 21), _badminton), isFalse);
    });
  });

  group('validateAllSets', () {
    test('passes valid sets and numbers the failing set from one', () {
      validateAllSets([_set(21, 10), _set(21, 19)], _badminton);

      late ScoreValidationException error;
      try {
        validateAllSets([_set(21, 10), _set(21, 21)], _badminton);
      } on ScoreValidationException catch (e) {
        error = e;
      }
      expect(error.setNumber, 2);
      expect(error.code, ScoreValidationCode.tie);
    });

    test('dispatches on the scoring model', () {
      expect(
        _codeOf(() => validateAllSets([_set(6, 5)], _tennis)),
        ScoreValidationCode.tennisSet,
      );
      expect(
        _codeOf(() => validateAllSets([_set(11, 10)], _sideOut)),
        ScoreValidationCode.sideOutDeuceMargin,
      );
      expect(
        _codeOf(() => validateAllSets([_set(22, 15)], _badminton)),
        ScoreValidationCode.exactTarget,
      );
    });

    test('an empty list is valid', () {
      validateAllSets(const [], _badminton);
    });
  });
}
