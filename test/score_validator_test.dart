import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rallyConfig = SportConfig(
    kind: SportRuleKind.badminton,
    scoringModel: SportScoringModel.rallyPointSet,
    bestOf: 3,
    setsToWin: 2,
    pointsPerSet: 21,
    mustWinByTwo: true,
    maxPoints: 30,
    tiebreakAt: 20,
  );

  test('rally point kết thúc khi thắng cách hai', () {
    expect(
      isSetComplete(
        const SetScoreData(score1: 22, score2: 20),
        rallyConfig,
      ),
      isTrue,
    );
  });

  test('rally point chưa kết thúc khi deuce chưa cách hai', () {
    expect(
      isSetComplete(
        const SetScoreData(score1: 22, score2: 21),
        rallyConfig,
      ),
      isFalse,
    );
  });

  test('rally point kết thúc tại điểm trần dù chỉ cách một', () {
    expect(
      isSetComplete(
        const SetScoreData(score1: 30, score2: 29),
        rallyConfig,
      ),
      isTrue,
    );
  });

  test('không yêu cầu cách hai khi setting tắt win-by-two', () {
    const config = SportConfig(
      kind: SportRuleKind.pickleball,
      scoringModel: SportScoringModel.rallyPointSet,
      bestOf: 3,
      setsToWin: 2,
      pointsPerSet: 11,
      mustWinByTwo: false,
      maxPoints: 15,
      tiebreakAt: 10,
    );
    expect(
      isSetComplete(
        const SetScoreData(score1: 11, score2: 10),
        config,
      ),
      isTrue,
    );
  });
}
