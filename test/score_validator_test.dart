import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
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
      isSetComplete(const SetScoreData(score1: 22, score2: 20), rallyConfig),
      isTrue,
    );
  });

  test('rally point chưa kết thúc khi deuce chưa cách hai', () {
    expect(
      isSetComplete(const SetScoreData(score1: 22, score2: 21), rallyConfig),
      isFalse,
    );
  });

  test('rally point kết thúc tại điểm trần dù chỉ cách một', () {
    expect(
      isSetComplete(const SetScoreData(score1: 30, score2: 29), rallyConfig),
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
      isSetComplete(const SetScoreData(score1: 11, score2: 10), config),
      isTrue,
    );
  });

  test('preset nhanh không bị nhầm thành sản phẩm Super Lite', () {
    expect(isLiteScoringMode(sportRules: {'mode': 'LITE'}), isTrue);
    expect(
      isLiteScoringMode(tournamentConfig: {'scoringMode': 'FREE'}),
      isTrue,
    );
    expect(
      isSuperLiteTournament(
        tournamentConfig: {'isLite': false, 'mode': 'STRICT'},
      ),
      isFalse,
    );
  });

  test('preset tự do không có BO3 ngầm trong bộ luật điểm', () {
    final config = resolveSportConfig({
      'kind': 'BADMINTON',
      'scoringMode': 'FREE',
      'bestOf': 3,
      'setsToWin': 2,
    });

    expect(config.isOpenScoring, isTrue);
    expect(
      isMatchComplete(config, [
        const SetScoreData(score1: 21, score2: 15, isFinished: true),
        const SetScoreData(score1: 21, score2: 18, isFinished: true),
        const SetScoreData(score1: 21, score2: 19, isFinished: true),
        const SetScoreData(score1: 21, score2: 17, isFinished: true),
        const SetScoreData(score1: 21, score2: 16, isFinished: true),
      ]),
      isFalse,
    );
  });

  test('đọc BO5 khi API chỉ trả bestOf mà không trả setsToWin', () {
    final config = resolveSportConfig({
      'kind': 'BADMINTON',
      'bestOf': 5,
      'pointsPerSet': 21,
    });

    expect(config.bestOf, 5);
    expect(config.setsToWin, 3);
  });

  test('BO5 ưu tiên bestOf khi API còn gửi kèm setsToWin BO3 cũ', () {
    final config = resolveSportConfig({
      'kind': 'BADMINTON',
      'bestOf': 5,
      'setsToWin': 2,
    });

    expect(config.bestOf, 5);
    expect(config.setsToWin, 3);
  });

  test('Super Lite canonical flag mở đúng nhận diện sản phẩm', () {
    expect(
      isSuperLiteTournament(tournamentConfig: {'isLite': true, 'mode': 'LITE'}),
      isTrue,
    );
  });

  test('Super Lite không tự khóa sau khi chốt một set', () {
    const state = ScorePanelState(
      config: rallyConfig,
      isLite: true,
      finishedSets: [SetScoreData(score1: 11, score2: 7, isFinished: true)],
    );

    expect(state.team1SetWins, 1);
    expect(state.isMatchComplete, isFalse);
  });

  test('Quick/Lite không tự khóa theo BO3 dù đã chốt nhiều set', () {
    const state = ScorePanelState(
      config: rallyConfig,
      isLite: true,
      finishedSets: [
        SetScoreData(score1: 21, score2: 15, isFinished: true),
        SetScoreData(score1: 21, score2: 18, isFinished: true),
        SetScoreData(score1: 21, score2: 19, isFinished: true),
      ],
    );

    expect(state.team1SetWins, 3);
    expect(state.winnerTeam, 0);
    expect(state.isMatchComplete, isFalse);
  });

  test('state vẫn mở khi chỉ có SportConfig đánh dấu preset tự do', () {
    final config = resolveSportConfig({
      'kind': 'BADMINTON',
      'mode': 'STRICT',
      'scoringMode': 'FREE',
      'bestOf': 3,
      'setsToWin': 2,
    });
    final state = ScorePanelState(
      config: config,
      finishedSets: const [
        SetScoreData(score1: 21, score2: 15, isFinished: true),
        SetScoreData(score1: 21, score2: 18, isFinished: true),
        SetScoreData(score1: 21, score2: 19, isFinished: true),
      ],
    );

    expect(state.isOpenScoring, isTrue);
    expect(state.isMatchComplete, isFalse);
  });

  test('strict BO5 chỉ hoàn thành khi đạt 3 set thắng', () {
    final config = resolveSportConfig({
      'kind': 'BADMINTON',
      'mode': 'STRICT',
      'bestOf': 5,
    });
    final state = ScorePanelState(
      config: config,
      finishedSets: const [
        SetScoreData(score1: 21, score2: 15, isFinished: true),
        SetScoreData(score1: 21, score2: 18, isFinished: true),
      ],
    );

    expect(config.bestOf, 5);
    expect(config.setsToWin, 3);
    expect(state.isMatchComplete, isFalse);
  });

  test('Tennis Lite giữ luật game nhưng không khóa theo BO3', () {
    final config = resolveSportConfig({
      'kind': 'TENNIS',
      'mode': 'LITE',
      'scoringModel': 'TENNIS_SET',
      'bestOf': 3,
      'setsToWin': 2,
      'pointsPerSet': 6,
      'maxPoints': 7,
    });
    final state = ScorePanelState(
      config: config,
      finishedSets: const [
        SetScoreData(score1: 6, score2: 4, isFinished: true),
        SetScoreData(score1: 6, score2: 0, isFinished: true),
        SetScoreData(score1: 7, score2: 5, isFinished: true),
      ],
    );

    expect(config.scoringModel, SportScoringModel.tennisSet);
    expect(config.isOpenScoring, isTrue);
    expect(state.isMatchComplete, isFalse);
    expect(state.winnerTeam, 0);
  });
}
