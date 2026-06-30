import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

/// Validate set score cho rally-point model (badminton, table tennis, pickleball)
void validateRallyPointSet(SetScoreData set, SportConfig config, {required String label}) {
  final maxScore = set.score1 > set.score2 ? set.score1 : set.score2;
  final minScore = set.score1 < set.score2 ? set.score1 : set.score2;
  final diff = maxScore - minScore;

  if (set.score1 == set.score2) {
    throw FormatException('$label: Hiệp không được hòa ($maxScore-$minScore)');
  }
  if (maxScore < config.pointsPerSet) {
    throw FormatException('$label: Người thắng phải đạt tối thiểu ${config.pointsPerSet} điểm');
  }

  if (config.mustWinByTwo) {
    if (minScore >= config.tiebreakAt) {
      if (diff != 2) {
        throw FormatException('$label: Deuce yêu cầu thắng cách 2 điểm');
      }
    } else if (maxScore != config.pointsPerSet) {
      throw FormatException('$label: Người thắng phải đạt đúng ${config.pointsPerSet} điểm (không deuce)');
    }
  } else {
    if (maxScore != config.pointsPerSet) {
      throw FormatException('$label: Win-by-2 tắt, người thắng phải đạt đúng ${config.pointsPerSet}');
    }
  }

  if (maxScore > config.maxPoints) {
    throw FormatException('$label: Điểm số vượt quá giới hạn ${config.maxPoints}');
  }
}

/// Validate set score cho tennis (game-based)
void validateTennisSet(SetScoreData set, SportConfig config, {required String label}) {
  final maxScore = set.score1 > set.score2 ? set.score1 : set.score2;
  final minScore = set.score1 < set.score2 ? set.score1 : set.score2;
  final diff = maxScore - minScore;

  if (set.score1 == set.score2) {
    throw FormatException('$label: Tennis không cho phép set hòa');
  }
  if (maxScore < config.pointsPerSet) {
    throw FormatException('$label: Người thắng phải đạt ít nhất ${config.pointsPerSet} game');
  }
  if (maxScore > config.maxPoints) {
    throw FormatException('$label: Số game không vượt quá ${config.maxPoints}');
  }

  if (maxScore == config.pointsPerSet) {
    if (diff < 2 || minScore > config.pointsPerSet - 2) {
      throw FormatException('$label: Kết quả ${set.score1}-${set.score2} không hợp lệ cho tennis');
    }
    return;
  }

  if (maxScore == config.maxPoints) {
    // Tiebreak case: 7-5, 7-6
    if (minScore != maxScore - 2 && minScore != maxScore - 1) {
      throw FormatException('$label: Kết quả tiebreak ${set.score1}-${set.score2} không hợp lệ');
    }
    return;
  }

  throw FormatException('$label: Kết quả ${set.score1}-${set.score2} không hợp lệ cho tennis');
}

/// Validate set score cho pickleball side-out
void validatePickleballSideOutSet(SetScoreData set, SportConfig config, {required String label}) {
  final maxScore = set.score1 > set.score2 ? set.score1 : set.score2;
  final minScore = set.score1 < set.score2 ? set.score1 : set.score2;
  final diff = maxScore - minScore;

  if (set.score1 == set.score2) {
    throw FormatException('$label: Game không được hòa');
  }
  if (maxScore < config.pointsPerSet) {
    throw FormatException('$label: Đội thắng phải đạt tối thiểu ${config.pointsPerSet} điểm');
  }

  if (config.mustWinByTwo) {
    if (minScore >= config.tiebreakAt) {
      if (diff != 2) {
        throw FormatException('$label: Side-out yêu cầu thắng cách 2 điểm ở giai đoạn cuối');
      }
    } else if (maxScore != config.pointsPerSet) {
      throw FormatException('$label: Điểm đích chuẩn side-out là ${config.pointsPerSet}');
    }
  } else if (maxScore != config.pointsPerSet) {
    throw FormatException('$label: Khi tắt win-by-2, đội thắng phải chạm ${config.pointsPerSet}');
  }

  if (maxScore > config.maxPoints && config.maxPoints > 0) {
    throw FormatException('$label: Điểm vượt ngưỡng ${config.maxPoints}');
  }
}

/// Kiểm tra set đã hoàn thành chưa dựa vào config môn
bool isSetComplete(SetScoreData set, SportConfig config) {
  final maxScore = set.score1 > set.score2 ? set.score1 : set.score2;
  final minScore = set.score1 < set.score2 ? set.score1 : set.score2;
  final diff = maxScore - minScore;

  switch (config.scoringModel) {
    case SportScoringModel.tennisSet:
      // Tennis: set kết thúc khi ai đó đạt >= pointsPerSet và cách 2, hoặc tiebreak
      if (maxScore >= config.pointsPerSet && diff >= 2) return true;
      if (maxScore == config.maxPoints && diff >= 1) return true;
      return false;

    case SportScoringModel.pickleballSideOut:
      // Side-out: chỉ 1 game, kết thúc khi ai đó đạt pointsPerSet và cách 2
      if (maxScore >= config.pointsPerSet && diff >= 2) return true;
      if (maxScore >= config.tiebreakAt && diff >= 2) return true;
      return false;

    case SportScoringModel.rallyPointSet:
      // Rally point: set kết thúc khi đạt pointsPerSet và cách 2 (deuce)
      if (maxScore >= config.pointsPerSet && diff >= 2) return true;
      // Deuce cap: ai đó đạt maxPoints
      if (maxScore >= config.maxPoints && diff >= 1) return true;
      return false;
  }
}

/// Validate toàn bộ sets theo đúng scoring model
void validateAllSets(List<SetScoreData> sets, SportConfig config) {
  for (int i = 0; i < sets.length; i++) {
    final label = config.scoringModel == SportScoringModel.tennisSet
        ? 'Set ${i + 1}'
        : config.scoringModel == SportScoringModel.pickleballSideOut
            ? 'Game ${i + 1}'
            : 'Hiệp ${i + 1}';

    switch (config.scoringModel) {
      case SportScoringModel.tennisSet:
        validateTennisSet(sets[i], config, label: label);
        break;
      case SportScoringModel.pickleballSideOut:
        validatePickleballSideOutSet(sets[i], config, label: label);
        break;
      case SportScoringModel.rallyPointSet:
        validateRallyPointSet(sets[i], config, label: label);
        break;
    }
  }
}
