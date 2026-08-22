import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

enum ScoreValidationCode {
  tie,
  minimumScore,
  deuceMargin,
  exactTarget,
  maximumScore,
  tennisSet,
  tennisTiebreak,
  sideOutDeuceMargin,
  sideOutTarget,
  sideOutExactTarget,
  sideOutMaximumScore,
}

class ScoreValidationException extends FormatException {
  final ScoreValidationCode code;
  final int setNumber;
  final int score1;
  final int score2;
  final int target;
  final int maxPoints;

  ScoreValidationException({
    required this.code,
    required this.setNumber,
    required this.score1,
    required this.score2,
    this.target = 0,
    this.maxPoints = 0,
  }) : super(_buildToken(code, setNumber, score1, score2, target, maxPoints));

  String get token => message;

  static String _buildToken(
    ScoreValidationCode code,
    int setNumber,
    int score1,
    int score2,
    int target,
    int maxPoints,
  ) =>
      'scoreValidation|${code.name}|$setNumber|$score1|$score2|$target|$maxPoints';
}

void validateRallyPointSet(
  SetScoreData set,
  SportConfig config, {
  required int setNumber,
}) {
  final maxScore = set.score1 > set.score2 ? set.score1 : set.score2;
  final minScore = set.score1 < set.score2 ? set.score1 : set.score2;
  final diff = maxScore - minScore;

  if (set.score1 == set.score2) {
    throw ScoreValidationException(
      code: ScoreValidationCode.tie,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }
  if (maxScore < config.pointsPerSet) {
    throw ScoreValidationException(
      code: ScoreValidationCode.minimumScore,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }

  if (config.mustWinByTwo) {
    if (minScore >= config.tiebreakAt) {
      if (diff != 2) {
        throw ScoreValidationException(
          code: ScoreValidationCode.deuceMargin,
          setNumber: setNumber,
          score1: set.score1,
          score2: set.score2,
          target: config.pointsPerSet,
          maxPoints: config.maxPoints,
        );
      }
    } else if (maxScore != config.pointsPerSet) {
      throw ScoreValidationException(
        code: ScoreValidationCode.exactTarget,
        setNumber: setNumber,
        score1: set.score1,
        score2: set.score2,
        target: config.pointsPerSet,
        maxPoints: config.maxPoints,
      );
    }
  } else if (maxScore != config.pointsPerSet) {
    throw ScoreValidationException(
      code: ScoreValidationCode.exactTarget,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }

  if (maxScore > config.maxPoints) {
    throw ScoreValidationException(
      code: ScoreValidationCode.maximumScore,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }
}

void validateTennisSet(
  SetScoreData set,
  SportConfig config, {
  required int setNumber,
}) {
  final maxScore = set.score1 > set.score2 ? set.score1 : set.score2;
  final minScore = set.score1 < set.score2 ? set.score1 : set.score2;
  final diff = maxScore - minScore;

  if (set.score1 == set.score2) {
    throw ScoreValidationException(
      code: ScoreValidationCode.tie,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }
  if (maxScore < config.pointsPerSet) {
    throw ScoreValidationException(
      code: ScoreValidationCode.minimumScore,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }
  if (maxScore > config.maxPoints) {
    throw ScoreValidationException(
      code: ScoreValidationCode.maximumScore,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }

  if (maxScore == config.pointsPerSet) {
    if (diff < 2 || minScore > config.pointsPerSet - 2) {
      throw ScoreValidationException(
        code: ScoreValidationCode.tennisSet,
        setNumber: setNumber,
        score1: set.score1,
        score2: set.score2,
        target: config.pointsPerSet,
        maxPoints: config.maxPoints,
      );
    }
    return;
  }

  if (maxScore == config.maxPoints) {
    if (minScore != maxScore - 2 && minScore != maxScore - 1) {
      throw ScoreValidationException(
        code: ScoreValidationCode.tennisTiebreak,
        setNumber: setNumber,
        score1: set.score1,
        score2: set.score2,
        target: config.pointsPerSet,
        maxPoints: config.maxPoints,
      );
    }
    return;
  }

  throw ScoreValidationException(
    code: ScoreValidationCode.tennisSet,
    setNumber: setNumber,
    score1: set.score1,
    score2: set.score2,
    target: config.pointsPerSet,
    maxPoints: config.maxPoints,
  );
}

void validatePickleballSideOutSet(
  SetScoreData set,
  SportConfig config, {
  required int setNumber,
}) {
  final maxScore = set.score1 > set.score2 ? set.score1 : set.score2;
  final minScore = set.score1 < set.score2 ? set.score1 : set.score2;
  final diff = maxScore - minScore;

  if (set.score1 == set.score2) {
    throw ScoreValidationException(
      code: ScoreValidationCode.tie,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }
  if (maxScore < config.pointsPerSet) {
    throw ScoreValidationException(
      code: ScoreValidationCode.minimumScore,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }

  if (config.mustWinByTwo) {
    if (minScore >= config.tiebreakAt) {
      if (diff != 2) {
        throw ScoreValidationException(
          code: ScoreValidationCode.sideOutDeuceMargin,
          setNumber: setNumber,
          score1: set.score1,
          score2: set.score2,
          target: config.pointsPerSet,
          maxPoints: config.maxPoints,
        );
      }
    } else if (maxScore != config.pointsPerSet) {
      throw ScoreValidationException(
        code: ScoreValidationCode.sideOutTarget,
        setNumber: setNumber,
        score1: set.score1,
        score2: set.score2,
        target: config.pointsPerSet,
        maxPoints: config.maxPoints,
      );
    }
  } else if (maxScore != config.pointsPerSet) {
    throw ScoreValidationException(
      code: ScoreValidationCode.sideOutExactTarget,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }

  if (maxScore > config.maxPoints && config.maxPoints > 0) {
    throw ScoreValidationException(
      code: ScoreValidationCode.sideOutMaximumScore,
      setNumber: setNumber,
      score1: set.score1,
      score2: set.score2,
      target: config.pointsPerSet,
      maxPoints: config.maxPoints,
    );
  }
}

bool isSetComplete(SetScoreData set, SportConfig config) {
  final maxScore = set.score1 > set.score2 ? set.score1 : set.score2;
  final minScore = set.score1 < set.score2 ? set.score1 : set.score2;
  final diff = maxScore - minScore;

  if (maxScore < config.pointsPerSet || diff == 0) {
    return false;
  }
  if (config.maxPoints > 0 && maxScore >= config.maxPoints) {
    return true;
  }
  if (!config.mustWinByTwo) {
    return true;
  }

  switch (config.scoringModel) {
    case SportScoringModel.tennisSet:
      return diff >= 2;
    case SportScoringModel.pickleballSideOut:
      return diff >= 2;
    case SportScoringModel.rallyPointSet:
      return diff >= 2;
  }
}

void validateAllSets(List<SetScoreData> sets, SportConfig config) {
  for (int i = 0; i < sets.length; i++) {
    final setNumber = i + 1;
    switch (config.scoringModel) {
      case SportScoringModel.tennisSet:
        validateTennisSet(sets[i], config, setNumber: setNumber);
        break;
      case SportScoringModel.pickleballSideOut:
        validatePickleballSideOutSet(sets[i], config, setNumber: setNumber);
        break;
      case SportScoringModel.rallyPointSet:
        validateRallyPointSet(sets[i], config, setNumber: setNumber);
        break;
    }
  }
}
