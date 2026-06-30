import 'package:app_quanly_giaidau/core/services/app_logger.dart';

// ─── Sport Rule Kinds ───

enum SportRuleKind {
  badminton('BADMINTON'),
  tableTennis('TABLE_TENNIS'),
  pickleball('PICKLEBALL'),
  tennis('TENNIS');

  final String value;
  const SportRuleKind(this.value);

  static SportRuleKind fromString(String? s) {
    if (s == null) return SportRuleKind.badminton;
    final normalized = s.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
    switch (normalized) {
      case 'BADMINTON':
      case 'CẦU LÔNG':
        return SportRuleKind.badminton;
      case 'TABLE_TENNIS':
      case 'BÓNG BÀN':
      case 'PING PONG':
        return SportRuleKind.tableTennis;
      case 'PICKLEBALL':
      case 'PICKLEBALL_RALLY':
      case 'PICKLEBALL_SIDE_OUT':
        return SportRuleKind.pickleball;
      case 'TENNIS':
      case 'QUẦN VỢT':
        return SportRuleKind.tennis;
      default:
        return SportRuleKind.badminton;
    }
  }
}

// ─── Scoring Models ───

enum SportScoringModel {
  rallyPointSet('RALLY_POINT_SET'),  // badminton, table tennis, pickleball rally
  tennisSet('TENNIS_SET'),           // tennis game-based
  pickleballSideOut('PICKLEBALL_SIDE_OUT'); // pickleball side-out

  final String value;
  const SportScoringModel(this.value);

  static SportScoringModel fromString(String s) {
    switch (s.toUpperCase()) {
      case 'TENNIS_SET': return SportScoringModel.tennisSet;
      case 'PICKLEBALL_SIDE_OUT': return SportScoringModel.pickleballSideOut;
      default: return SportScoringModel.rallyPointSet;
    }
  }
}

// ─── Sport Config ───

class SportConfig {
  final SportRuleKind kind;
  final SportScoringModel scoringModel;
  final int bestOf;
  final int setsToWin;
  final int pointsPerSet;
  final bool mustWinByTwo;
  final int maxPoints;
  final int tiebreakAt;
  final int? tiebreakPoints;

  const SportConfig({
    required this.kind,
    required this.scoringModel,
    required this.bestOf,
    required this.setsToWin,
    required this.pointsPerSet,
    required this.mustWinByTwo,
    required this.maxPoints,
    required this.tiebreakAt,
    this.tiebreakPoints,
  });

  @override
  String toString() =>
    'SportConfig(kind=$kind, model=$scoringModel, BO$bestOf, ${pointsPerSet}pts, winBy2=$mustWinByTwo)';
}

// ─── Defaults map ───

const _sportDefaults = <SportRuleKind, SportConfig>{
  SportRuleKind.badminton: SportConfig(
    kind: SportRuleKind.badminton,
    scoringModel: SportScoringModel.rallyPointSet,
    bestOf: 3,
    setsToWin: 2,
    pointsPerSet: 21,
    mustWinByTwo: true,
    maxPoints: 30,
    tiebreakAt: 20,
  ),
  SportRuleKind.tableTennis: SportConfig(
    kind: SportRuleKind.tableTennis,
    scoringModel: SportScoringModel.rallyPointSet,
    bestOf: 5,
    setsToWin: 3,
    pointsPerSet: 11,
    mustWinByTwo: true,
    maxPoints: 99,
    tiebreakAt: 10,
  ),
  SportRuleKind.pickleball: SportConfig(
    kind: SportRuleKind.pickleball,
    scoringModel: SportScoringModel.rallyPointSet,
    bestOf: 3,
    setsToWin: 2,
    pointsPerSet: 11,
    mustWinByTwo: true,
    maxPoints: 15,
    tiebreakAt: 10,
  ),
  SportRuleKind.tennis: SportConfig(
    kind: SportRuleKind.tennis,
    scoringModel: SportScoringModel.tennisSet,
    bestOf: 3,
    setsToWin: 2,
    pointsPerSet: 6,
    mustWinByTwo: true,
    maxPoints: 7,
    tiebreakAt: 6,
    tiebreakPoints: 7,
  ),
};

// ─── Resolve ───

/// Giải SportConfig từ tournament sportRules (Map từ BE JSONB) hoặc fallback
SportConfig resolveSportConfig(Map<String, dynamic>? sportRules, [SportRuleKind fallback = SportRuleKind.badminton]) {
  if (sportRules == null || sportRules.isEmpty) {
    return _sportDefaults[fallback]!;
  }

  final kind = SportRuleKind.fromString(sportRules['kind']?.toString());
  final defaults = _sportDefaults[kind]!;

  // Nếu sportRules có scoringModel override
  final rawModel = sportRules['scoringModel']?.toString();
  final scoringModel = rawModel != null ? SportScoringModel.fromString(rawModel) : defaults.scoringModel;

  return SportConfig(
    kind: kind,
    scoringModel: scoringModel,
    bestOf: _readInt(sportRules, 'bestOf') ?? defaults.bestOf,
    setsToWin: _readInt(sportRules, 'setsToWin') ?? defaults.setsToWin,
    pointsPerSet: _readInt(sportRules, 'pointsPerSet') ?? defaults.pointsPerSet,
    mustWinByTwo: _readBool(sportRules, 'mustWinByTwo') ?? defaults.mustWinByTwo,
    maxPoints: _readInt(sportRules, 'maxPoints') ?? defaults.maxPoints,
    tiebreakAt: _readInt(sportRules, 'tiebreakAt') ?? defaults.tiebreakAt,
    tiebreakPoints: _readInt(sportRules, 'tiebreakPoints') ?? defaults.tiebreakPoints,
  );
}

/// Đếm sets thắng của mỗi bên từ list sets
(int team1Sets, int team2Sets) computeMatchSetsWon(List<SetScoreData> sets) {
  int t1 = 0, t2 = 0;
  for (final s in sets) {
    if (s.score1 > s.score2) t1++;
    else if (s.score2 > s.score1) t2++;
  }
  return (t1, t2);
}

/// Kiểm tra match đã kết thúc chưa
bool isMatchComplete(SportConfig config, List<SetScoreData> sets) {
  final (t1, t2) = computeMatchSetsWon(sets);
  return t1 >= config.setsToWin || t2 >= config.setsToWin;
}

int? getMatchWinnerIndex(SportConfig config, List<SetScoreData> sets) {
  final (t1, t2) = computeMatchSetsWon(sets);
  if (t1 >= config.setsToWin) return 1;
  if (t2 >= config.setsToWin) return 2;
  return null;
}

int? _readInt(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v);
  return null;
}

bool? _readBool(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v.toLowerCase() == 'true';
  return null;
}

// ─── Set Score Data ───

class SetScoreData {
  final int score1;
  final int score2;
  final bool isFinished;

  const SetScoreData({
    required this.score1,
    required this.score2,
    this.isFinished = false,
  });

  Map<String, dynamic> toJson() => {
    'team1Score': score1,
    'team2Score': score2,
    'isFinished': isFinished,
  };

  factory SetScoreData.fromJson(Map<String, dynamic> json) => SetScoreData(
    score1: json['team1Score'] as int? ?? json['score1'] as int? ?? 0,
    score2: json['team2Score'] as int? ?? json['score2'] as int? ?? 0,
    isFinished: json['isFinished'] as bool? ?? false,
  );

  SetScoreData copyWith({int? score1, int? score2, bool? isFinished}) => SetScoreData(
    score1: score1 ?? this.score1,
    score2: score2 ?? this.score2,
    isFinished: isFinished ?? this.isFinished,
  );
}
