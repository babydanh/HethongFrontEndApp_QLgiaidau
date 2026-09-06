// ─── Sport Rule Kinds ───

enum SportRuleKind {
  badminton('BADMINTON'),
  tableTennis('TABLE_TENNIS'),
  pickleball('PICKLEBALL'),
  tennis('TENNIS'),
  football('FOOTBALL');

  final String value;
  const SportRuleKind(this.value);

  static SportRuleKind fromString(String? s) {
    if (s == null) return SportRuleKind.badminton;
    final normalized = s.trim().toUpperCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
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
      case 'FOOTBALL':
      case 'BONG DA':
        return SportRuleKind.football;
      default:
        return SportRuleKind.badminton;
    }
  }
}

// ─── Scoring Models ───

enum SportScoringModel {
  rallyPointSet('RALLY_POINT_SET'), // badminton, table tennis, pickleball rally
  tennisSet('TENNIS_SET'), // tennis game-based
  pickleballSideOut('PICKLEBALL_SIDE_OUT'); // pickleball side-out

  final String value;
  const SportScoringModel(this.value);

  static SportScoringModel fromString(String s) {
    switch (s.toUpperCase()) {
      case 'TENNIS_SET':
        return SportScoringModel.tennisSet;
      case 'PICKLEBALL_SIDE_OUT':
        return SportScoringModel.pickleballSideOut;
      default:
        return SportScoringModel.rallyPointSet;
    }
  }
}

// ─── Sport Config ───

class SportConfig {
  final SportRuleKind kind;
  final SportScoringModel scoringModel;

  /// Open/Free scorecards have no BO cap. Strict presets still use
  /// [bestOf]/[setsToWin] as their match-completion contract.
  final bool isOpenScoring;
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
    this.isOpenScoring = false,
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
      'SportConfig(kind=$kind, model=$scoringModel, '
      '${isOpenScoring ? 'OPEN' : 'BO$bestOf'}, ${pointsPerSet}pts, '
      'winBy2=$mustWinByTwo)';
}

/// Xác định một trận dùng cách tính điểm Lite/open-score.
///
/// Preset nhanh có thể dùng cùng cách tính điểm mở nhưng không vì vậy mà trở
/// thành sản phẩm Super Lite. Vì thế hàm này chỉ phục vụ cách hiển thị/nhập
/// điểm; quyền mở bàn và quyền cập nhật dữ liệu được kiểm tra riêng.
bool isLiteScoringMode({
  Map<String, dynamic>? tournamentConfig,
  Map<String, dynamic>? sportRules,
  bool tournamentIsLite = false,
}) {
  bool hasLiteMarker(Map<String, dynamic>? source) {
    if (source == null) return false;
    if (source['isLite'] == true) return true;
    final mode = source['mode']?.toString().trim().toUpperCase();
    if (mode == 'LITE' || mode == 'OPEN' || mode == 'FREE') return true;
    final scoringMode = (source['scoringMode'] ?? source['scoring_mode'])
        ?.toString()
        .trim()
        .toUpperCase();
    // `scoringMode=FREE` is used by Quick tournaments in tournamentConfig.
    // It describes the scorecard contract only; it never grants Super Lite
    // access because that check is kept in isSuperLiteTournament().
    if (scoringMode == 'LITE' ||
        scoringMode == 'OPEN' ||
        scoringMode == 'FREE') {
      return true;
    }
    final preset = source['rulesPreset']?.toString().trim().toUpperCase();
    return preset == 'LITE' || preset == 'OPEN' || preset == 'FREE';
  }

  if (tournamentIsLite ||
      hasLiteMarker(tournamentConfig) ||
      hasLiteMarker(sportRules)) {
    return true;
  }

  final nestedScoring = sportRules?['scoring'];
  return nestedScoring is Map &&
      hasLiteMarker(Map<String, dynamic>.from(nestedScoring));
}

/// Xác định loại sản phẩm Super Lite của giải.
///
/// Chỉ cờ `isLite` (top-level hoặc tournamentConfig) mới mở quyền Live cho
/// tài khoản đã đăng nhập. `sportRules.mode=LITE` có thể chỉ là preset nhanh
/// nên tuyệt đối không được dùng làm quyền truy cập.
bool isSuperLiteTournament({
  Map<String, dynamic>? tournamentConfig,
  bool tournamentIsLite = false,
}) {
  if (tournamentIsLite || tournamentConfig?['isLite'] == true) return true;

  // Tương thích dữ liệu Super Lite cũ trước khi có cờ canonical.
  final mode = tournamentConfig?['mode']?.toString().trim().toUpperCase();
  return mode == 'LITE' && tournamentConfig?['hideAdvancedSettings'] == true;
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
  SportRuleKind.football: SportConfig(
    kind: SportRuleKind.football,
    scoringModel: SportScoringModel.rallyPointSet,
    bestOf: 1,
    setsToWin: 1,
    pointsPerSet: 1,
    mustWinByTwo: false,
    maxPoints: 99,
    tiebreakAt: 90,
  ),
};

// ─── Resolve ───

/// Giải SportConfig từ tournament sportRules (Map từ BE JSONB) hoặc fallback
SportConfig resolveSportConfig(
  Map<String, dynamic>? sportRules, [
  SportRuleKind fallback = SportRuleKind.badminton,
]) {
  if (sportRules == null || sportRules.isEmpty) {
    return _sportDefaults[fallback]!;
  }

  // Some API responses wrap scoring fields under `scoring`, while older
  // responses keep them at the top level. Flatten both shapes before reading
  // BO/sets so a configured BO5 cannot silently fall back to BO3.
  final nestedScoring = sportRules['scoring'];
  final source = nestedScoring is Map
      ? {...sportRules, ...Map<String, dynamic>.from(nestedScoring)}
      : sportRules;
  final kind = SportRuleKind.fromString(source['kind']?.toString());
  final defaults = _sportDefaults[kind]!;

  // Nếu sportRules có scoringModel override
  final rawModel = source['scoringModel']?.toString();
  final scoringModel = rawModel != null
      ? SportScoringModel.fromString(rawModel)
      : defaults.scoringModel;

  final configuredBestOf = _readInt(source, 'bestOf');
  final configuredSetsToWin = _readInt(source, 'setsToWin');
  final isOpenScoring = isLiteScoringMode(sportRules: source);
  final bestOf =
      configuredBestOf ??
      (configuredSetsToWin != null
          ? configuredSetsToWin * 2 - 1
          : defaults.bestOf);
  // `bestOf` is canonical when both fields are sent. Older match snapshots
  // can still contain the stale BO3 companion value `setsToWin: 2`; letting
  // it win would make a BO5 close after two sets in the app while the backend
  // correctly waits for three wins.
  final setsToWin = configuredBestOf != null
      ? ((bestOf + 1) ~/ 2)
      : (configuredSetsToWin ?? ((bestOf + 1) ~/ 2));

  return SportConfig(
    kind: kind,
    scoringModel: scoringModel,
    isOpenScoring: isOpenScoring,
    bestOf: bestOf,
    setsToWin: setsToWin,
    pointsPerSet: _readInt(source, 'pointsPerSet') ?? defaults.pointsPerSet,
    mustWinByTwo: _readBool(source, 'mustWinByTwo') ?? defaults.mustWinByTwo,
    maxPoints: _readInt(source, 'maxPoints') ?? defaults.maxPoints,
    tiebreakAt: _readInt(source, 'tiebreakAt') ?? defaults.tiebreakAt,
    tiebreakPoints:
        _readInt(source, 'tiebreakPoints') ?? defaults.tiebreakPoints,
  );
}

/// Đếm sets thắng của mỗi bên từ list sets
(int team1Sets, int team2Sets) computeMatchSetsWon(List<SetScoreData> sets) {
  int t1 = 0, t2 = 0;
  for (final s in sets) {
    if (s.score1 > s.score2) {
      t1++;
    } else if (s.score2 > s.score1) {
      t2++;
    }
  }
  return (t1, t2);
}

/// Kiểm tra match đã kết thúc chưa
bool isMatchComplete(SportConfig config, List<SetScoreData> sets) {
  if (config.isOpenScoring) return false;
  final (t1, t2) = computeMatchSetsWon(sets);
  return t1 >= config.setsToWin || t2 >= config.setsToWin;
}

int? getMatchWinnerIndex(SportConfig config, List<SetScoreData> sets) {
  if (config.isOpenScoring) return null;
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

  SetScoreData copyWith({int? score1, int? score2, bool? isFinished}) =>
      SetScoreData(
        score1: score1 ?? this.score1,
        score2: score2 ?? this.score2,
        isFinished: isFinished ?? this.isFinished,
      );
}
