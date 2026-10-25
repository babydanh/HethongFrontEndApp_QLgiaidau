/// Port các util "sport rules" của Web phục vụ sheet hạng mục
/// (OpenSpec `quan-ly-giai-web-parity` task 2.1):
/// - Preset nhanh theo môn: Web `src/features/tournaments/sport-rules/ui-guidance.ts`
///   (`getSportRulePresets`).
/// - Mặc định theo môn + resolve cấu hình đã lưu: `defaults.ts`, `normalize.ts`.
/// - Payload luật gửi API: `payload.ts` (`buildSportRulesPayload`).
///
/// File thuần Dart (không Flutter) để test được độc lập với widget.
/// Nhãn hiển thị (label/description preset, tên lựa chọn set) nằm ở lớp UI
/// vì cần `AppLocalizations`.
library;

/// Loại luật theo môn — đủ 6 giá trị Web (tách Pickleball rally/side-out,
/// khác `SportRuleKind` trong `sport_rule_service.dart` chỉ dùng để chấm điểm).
enum SportRulePresetKind {
  badminton('BADMINTON'),
  tableTennis('TABLE_TENNIS'),
  pickleballRally('PICKLEBALL_RALLY'),
  pickleballSideOut('PICKLEBALL_SIDE_OUT'),
  tennis('TENNIS'),
  football('FOOTBALL');

  final String apiValue;
  const SportRulePresetKind(this.apiValue);

  /// Port `normalizeKind` (normalize.ts): `PICKLEBALL` cũ quy về rally;
  /// giá trị lạ trả null để nơi gọi dùng fallback.
  static SportRulePresetKind? fromApi(Object? raw) {
    if (raw is! String) return null;
    final normalized = raw.trim().toUpperCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    if (normalized == 'PICKLEBALL') return SportRulePresetKind.pickleballRally;
    for (final kind in SportRulePresetKind.values) {
      if (kind.apiValue == normalized) return kind;
    }
    return null;
  }
}

/// Một preset nhanh theo môn (port `SportRulePreset` của ui-guidance.ts).
/// Label/description do lớp UI dịch theo [SportRulePreset.id].
class SportRulePreset {
  const SportRulePreset({
    required this.id,
    required this.setsToWin,
    required this.pointsPerSet,
    required this.winByTwo,
    required this.maxPoints,
    required this.tiebreakPoints,
  });

  final String id;
  final int setsToWin;
  final int pointsPerSet;
  final bool winByTwo;
  final int maxPoints;

  /// null = preset không đặt mốc tiebreak riêng.
  final int? tiebreakPoints;
}

const List<SportRulePreset> _badmintonPresets = [
  SportRulePreset(
    id: 'badminton-quick',
    setsToWin: 1,
    pointsPerSet: 21,
    winByTwo: true,
    maxPoints: 30,
    tiebreakPoints: null,
  ),
  SportRulePreset(
    id: 'badminton-standard',
    setsToWin: 2,
    pointsPerSet: 21,
    winByTwo: true,
    maxPoints: 30,
    tiebreakPoints: null,
  ),
  SportRulePreset(
    id: 'badminton-short',
    setsToWin: 2,
    pointsPerSet: 15,
    winByTwo: true,
    maxPoints: 21,
    tiebreakPoints: null,
  ),
];

const List<SportRulePreset> _tableTennisPresets = [
  SportRulePreset(
    id: 'table-tennis-bo3',
    setsToWin: 2,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 99,
    tiebreakPoints: null,
  ),
  SportRulePreset(
    id: 'table-tennis-bo5',
    setsToWin: 3,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 99,
    tiebreakPoints: null,
  ),
  SportRulePreset(
    id: 'table-tennis-single',
    setsToWin: 1,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 99,
    tiebreakPoints: null,
  ),
];

const List<SportRulePreset> _pickleballRallyPresets = [
  SportRulePreset(
    id: 'pickleball-rally-quick',
    setsToWin: 1,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 15,
    tiebreakPoints: null,
  ),
  SportRulePreset(
    id: 'pickleball-rally-standard',
    setsToWin: 2,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 15,
    tiebreakPoints: null,
  ),
  SportRulePreset(
    id: 'pickleball-rally-extended',
    setsToWin: 2,
    pointsPerSet: 15,
    winByTwo: true,
    maxPoints: 21,
    tiebreakPoints: null,
  ),
];

const List<SportRulePreset> _pickleballSideOutPresets = [
  SportRulePreset(
    id: 'pickleball-sideout-standard',
    setsToWin: 1,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 15,
    tiebreakPoints: 11,
  ),
  SportRulePreset(
    id: 'pickleball-sideout-15',
    setsToWin: 1,
    pointsPerSet: 15,
    winByTwo: true,
    maxPoints: 21,
    tiebreakPoints: 15,
  ),
  SportRulePreset(
    id: 'pickleball-sideout-finals',
    setsToWin: 2,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 15,
    tiebreakPoints: 11,
  ),
];

const List<SportRulePreset> _tennisPresets = [
  SportRulePreset(
    id: 'tennis-pro-set',
    setsToWin: 1,
    pointsPerSet: 8,
    winByTwo: true,
    maxPoints: 9,
    tiebreakPoints: 7,
  ),
  SportRulePreset(
    id: 'tennis-standard',
    setsToWin: 2,
    pointsPerSet: 6,
    winByTwo: true,
    maxPoints: 7,
    tiebreakPoints: 7,
  ),
  SportRulePreset(
    id: 'tennis-short-set',
    setsToWin: 1,
    pointsPerSet: 4,
    winByTwo: true,
    maxPoints: 5,
    tiebreakPoints: 7,
  ),
];

const List<SportRulePreset> _footballPresets = [
  SportRulePreset(
    id: 'football-standard',
    setsToWin: 1,
    pointsPerSet: 1,
    winByTwo: false,
    maxPoints: 99,
    tiebreakPoints: null,
  ),
];

/// Port `getSportRulePresets`: danh sách preset theo môn (đúng thứ tự Web).
List<SportRulePreset> getSportRulePresets(SportRulePresetKind kind) =>
    switch (kind) {
      SportRulePresetKind.badminton => _badmintonPresets,
      SportRulePresetKind.tableTennis => _tableTennisPresets,
      SportRulePresetKind.pickleballRally => _pickleballRallyPresets,
      SportRulePresetKind.pickleballSideOut => _pickleballSideOutPresets,
      SportRulePresetKind.tennis => _tennisPresets,
      SportRulePresetKind.football => _footballPresets,
    };

/// Port `setOptions` của presentation.ts: số set có thể chọn theo môn.
List<int> sportRuleSetOptions(SportRulePresetKind kind) => switch (kind) {
  SportRulePresetKind.football => const [1],
  SportRulePresetKind.tableTennis => const [1, 2, 3, 4],
  _ => const [1, 2, 3],
};

/// Mặc định luật theo môn (port `DEFAULT_SPORT_RULES` của defaults.ts).
class SportRuleDefaults {
  const SportRuleDefaults({
    required this.kind,
    required this.scoringModel,
    required this.setsToWin,
    required this.pointsPerSet,
    required this.winByTwo,
    required this.maxPoints,
    required this.tiebreakPoints,
    this.format,
  });

  final SportRulePresetKind kind;
  final String scoringModel;
  final int setsToWin;
  final int pointsPerSet;
  final bool winByTwo;
  final int maxPoints;

  /// null = mặc định không đặt mốc tiebreak riêng.
  final int? tiebreakPoints;

  /// Khối `format` riêng của môn (side-out, bóng đá); null = không gửi.
  final Map<String, dynamic>? format;
}

const Map<SportRulePresetKind, SportRuleDefaults> _sportRuleDefaults = {
  SportRulePresetKind.badminton: SportRuleDefaults(
    kind: SportRulePresetKind.badminton,
    scoringModel: 'RALLY_POINT_SET',
    setsToWin: 2,
    pointsPerSet: 21,
    winByTwo: true,
    maxPoints: 30,
    tiebreakPoints: null,
  ),
  SportRulePresetKind.tableTennis: SportRuleDefaults(
    kind: SportRulePresetKind.tableTennis,
    scoringModel: 'RALLY_POINT_SET',
    setsToWin: 3,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 99,
    tiebreakPoints: null,
  ),
  SportRulePresetKind.pickleballRally: SportRuleDefaults(
    kind: SportRulePresetKind.pickleballRally,
    scoringModel: 'RALLY_POINT_SET',
    setsToWin: 2,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 15,
    tiebreakPoints: null,
  ),
  SportRulePresetKind.pickleballSideOut: SportRuleDefaults(
    kind: SportRulePresetKind.pickleballSideOut,
    scoringModel: 'PICKLEBALL_SIDE_OUT',
    setsToWin: 1,
    pointsPerSet: 11,
    winByTwo: true,
    maxPoints: 15,
    tiebreakPoints: 11,
    format: {
      'gamePoint': 11,
      'firstServerRule': 'STANDARD',
      'doublesServeFlow': 'TWO_SERVER',
    },
  ),
  SportRulePresetKind.tennis: SportRuleDefaults(
    kind: SportRulePresetKind.tennis,
    scoringModel: 'TENNIS_SET',
    setsToWin: 2,
    pointsPerSet: 6,
    winByTwo: true,
    maxPoints: 7,
    tiebreakPoints: 7,
  ),
  SportRulePresetKind.football: SportRuleDefaults(
    kind: SportRulePresetKind.football,
    scoringModel: 'RALLY_POINT_SET',
    setsToWin: 1,
    pointsPerSet: 1,
    winByTwo: false,
    maxPoints: 99,
    tiebreakPoints: null,
    format: {'halvesCount': 2, 'halfDuration': 20, 'allowDraw': true},
  ),
};

SportRuleDefaults sportRuleDefaults(SportRulePresetKind kind) =>
    _sportRuleDefaults[kind]!;

/// Kết quả resolve cấu hình luật đã lưu (port `ResolvedSportRuleView`).
class SportRuleView {
  const SportRuleView({
    required this.mode,
    required this.kind,
    required this.scoringModel,
    required this.setsToWin,
    required this.bestOf,
    required this.pointsPerSet,
    required this.winByTwo,
    required this.maxPoints,
    required this.hasCustomTiebreakTarget,
    required this.tiebreakPoints,
    required this.roundsToPlay,
    required this.tiebreakerMode,
  });

  final String mode; // 'LITE' | 'STRICT'
  final SportRulePresetKind kind;
  final String scoringModel;
  final int setsToWin;
  final int bestOf;
  final int pointsPerSet;
  final bool winByTwo;
  final int maxPoints;
  final bool hasCustomTiebreakTarget;
  final int tiebreakPoints;
  final int roundsToPlay;
  final String tiebreakerMode; // 'split' | 'playoff'
}

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

int? _readNumber(Map<String, dynamic>? source, List<String> keys) {
  if (source == null) return null;
  for (final key in keys) {
    final value = source[key];
    if (value is num && value.isFinite) return value.toInt();
  }
  return null;
}

bool? _readBoolean(Map<String, dynamic>? source, List<String> keys) {
  if (source == null) return null;
  for (final key in keys) {
    final value = source[key];
    if (value is bool) return value;
  }
  return null;
}

int _truncPositive(num value) => value < 1 ? 1 : value.toInt();

/// Port `resolveSportRuleView` (normalize.ts): đọc `roundConfig` đã lưu
/// (lẫn phẳng `scoring` lồng) thành các trường của editor, thiếu gì dùng
/// mặc định của môn [fallback].
SportRuleView resolveSportRuleView(
  Object? rawRules, [
  SportRulePresetKind fallback = SportRulePresetKind.badminton,
]) {
  final source = _asMap(rawRules);
  final scoring = _asMap(source?['scoring']);
  final merged = <String, dynamic>{...?source, ...?scoring};
  final kind = SportRulePresetKind.fromApi(merged['kind']) ?? fallback;
  final defaults = sportRuleDefaults(kind);
  final defaultMap = <String, dynamic>{
    'setsToWin': defaults.setsToWin,
    'pointsPerSet': defaults.pointsPerSet,
    'winByTwo': defaults.winByTwo,
    if (defaults.tiebreakPoints != null)
      'tiebreakPoints': defaults.tiebreakPoints,
    'maxPoints': defaults.maxPoints,
  };

  final rawSetsToWin = _readNumber(merged, const ['setsToWin', 'sets_to_win']);
  final rawBestOf = _readNumber(merged, const ['bestOf', 'best_of']);
  final defaultSetsToWin = _readNumber(defaultMap, const ['setsToWin']);
  int bestOf;
  int setsToWin;
  if (rawBestOf != null || rawSetsToWin != null) {
    bestOf = rawBestOf ?? (_truncPositive(rawSetsToWin ?? 1) * 2 - 1);
    if (bestOf < 1) bestOf = 1;
    setsToWin = (bestOf / 2).ceil();
  } else {
    bestOf = (defaultSetsToWin ?? 2) * 2 - 1;
    setsToWin = defaultSetsToWin ?? 2;
  }

  final pointsPerSet = _truncPositive(
    _readNumber(merged, const ['pointsPerSet', 'points_per_set']) ??
        _readNumber(defaultMap, const ['pointsPerSet']) ??
        21,
  );
  final winByTwo =
      _readBoolean(merged, const [
        'winByTwo',
        'mustWinByTwo',
        'deuceEnabled',
        'win_by_two',
        'must_win_by_two',
        'deuce_enabled',
      ]) ??
      _readBoolean(defaultMap, const ['winByTwo', 'mustWinByTwo']) ??
      true;
  // Math.max(pointsPerSet, raw ?? pointsPerSet) — đọc thấy bao nhiêu cũng
  // không thấp hơn điểm/set.
  final maxPointsRaw = _readNumber(merged, const [
    'maxPoints',
    'max_points',
    'maxDeucePoints',
    'maxPointsPerSet',
  ]);
  final maxPointsFallback = _readNumber(defaultMap, const ['maxPoints']);
  final maxPointsFinal =
      (maxPointsRaw ?? maxPointsFallback ?? pointsPerSet) > pointsPerSet
      ? (maxPointsRaw ?? maxPointsFallback ?? pointsPerSet)
      : pointsPerSet;
  final tiebreakPointsValue = _readNumber(merged, const [
    'tiebreakPoints',
    'tiebreak_points',
    'tiebreakAt',
    'tiebreak_at',
  ]);
  final tiebreakPoints = _truncPositive(
    tiebreakPointsValue ??
        _readNumber(defaultMap, const ['tiebreakPoints']) ??
        10,
  );
  final roundsToPlay = _truncPositive(
    _readNumber(merged, const ['roundsToPlay']) ?? 1,
  );
  final tiebreakerMode = merged['tiebreakerMode'] == 'playoff'
      ? 'playoff'
      : 'split';

  // Mode: port logic resolve của normalize.ts (isLite/explicit/scoringMode).
  final explicitIsLite =
      source?['isLite'] == true || scoring?['isLite'] == true;
  final rawScoringMode =
      (source?['scoringMode'] ??
              source?['scoring_mode'] ??
              scoring?['scoringMode'] ??
              scoring?['scoring_mode'])
          ?.toString();
  final normalizedScoringModeRaw = rawScoringMode?.trim().toUpperCase();
  final String? normalizedScoringMode = switch (normalizedScoringModeRaw) {
    'LITE' || 'OPEN' || 'FREE' => 'LITE',
    'STRICT' || 'ADVANCED' => 'STRICT',
    _ => null,
  };
  final explicitMode = (source?['mode'] ?? scoring?['mode'])?.toString();
  final String? normalizedMode = switch (explicitMode) {
    'LITE' => 'LITE',
    'STRICT' || 'ADVANCED' => 'STRICT',
    _ => null,
  };
  final mode = explicitIsLite
      ? 'LITE'
      : (normalizedScoringMode ?? normalizedMode ?? 'LITE');

  return SportRuleView(
    mode: mode,
    kind: kind,
    scoringModel: merged['scoringModel']?.toString() ?? defaults.scoringModel,
    setsToWin: setsToWin,
    bestOf: bestOf,
    pointsPerSet: pointsPerSet,
    winByTwo: winByTwo,
    maxPoints: maxPointsFinal,
    hasCustomTiebreakTarget: tiebreakPointsValue != null,
    tiebreakPoints: tiebreakPoints,
    roundsToPlay: roundsToPlay,
    tiebreakerMode: tiebreakerMode,
  );
}

/// Port `readExplicitScoringMode` của useManageState.ts: chỉ nhận cờ mode
/// ghi tường minh trong `roundConfig` ('LITE'/'STRICT'); không có thì null.
String? explicitScoringMode(Object? rawRules) {
  final source = _asMap(rawRules);
  if (source == null) return null;
  final scoring = _asMap(source['scoring']);
  final raw =
      source['mode'] ??
      source['rulesPreset'] ??
      source['isLite'] ??
      scoring?['mode'] ??
      scoring?['rulesPreset'] ??
      scoring?['isLite'];
  if (raw == true) return 'LITE';
  if (raw == false) return 'STRICT';
  final normalized = raw?.toString().trim().toUpperCase();
  if (normalized == 'LITE') return 'LITE';
  if (normalized == 'STRICT' || normalized == 'ADVANCED') return 'STRICT';
  return null;
}

int _toPositiveInteger(num value) => value < 1 ? 1 : value.toInt();

/// Port `buildSportRulesPayload` (payload.ts): sinh khối sport rules
/// (kèm `mode` Lite/Chuẩn và `roundsToPlay`) để nhét vào `roundConfig`.
Map<String, dynamic> buildSportRulesPayload({
  required SportRulePresetKind kind,
  required int setsToWin,
  required int pointsPerSet,
  required bool winByTwo,
  int? maxPoints,
  int? tiebreakPoints,
  int? roundsToPlay,
  String? mode,
}) {
  final base = sportRuleDefaults(kind);
  final safeSetsToWin = _toPositiveInteger(setsToWin);
  final safePointsPerSet = _toPositiveInteger(pointsPerSet);
  final safeMaxPoints = maxPoints == null
      ? null
      : _toPositiveInteger(maxPoints);
  final safeTiebreakPoints = tiebreakPoints == null
      ? null
      : _toPositiveInteger(tiebreakPoints);
  final bestOf = safeSetsToWin * 2 - 1;

  final payload = <String, dynamic>{
    'version': 1,
    'kind': kind.apiValue,
    'scoringModel': base.scoringModel,
    'setsToWin': safeSetsToWin,
    'pointsPerSet': safePointsPerSet,
    'winByTwo': winByTwo,
    // Khối scoring lồng như Web payload.ts: chép nguyên mặc định của môn
    // (kèm maxPoints/tiebreakPoints riêng nếu môn có) rồi ghi đè bằng lựa
    // chọn hiện tại và override ở dưới.
    'scoring': <String, dynamic>{
      'mode': 'LITE',
      'setsToWin': base.setsToWin,
      'pointsPerSet': base.pointsPerSet,
      'winByTwo': base.winByTwo,
      'maxPoints': base.maxPoints,
      if (base.tiebreakPoints != null) 'tiebreakPoints': base.tiebreakPoints,
    },
  };

  if (mode != null) payload['mode'] = mode;
  if (safeMaxPoints != null) payload['maxPoints'] = safeMaxPoints;
  if (safeTiebreakPoints != null) {
    payload['tiebreakPoints'] = safeTiebreakPoints;
  }
  if (roundsToPlay != null) {
    payload['roundsToPlay'] = _toPositiveInteger(roundsToPlay);
  }

  final scoring = payload['scoring'] as Map<String, dynamic>;
  scoring['setsToWin'] = safeSetsToWin;
  scoring['pointsPerSet'] = safePointsPerSet;
  scoring['winByTwo'] = winByTwo;
  if (safeMaxPoints != null) scoring['maxPoints'] = safeMaxPoints;
  if (safeTiebreakPoints != null) {
    scoring['tiebreakPoints'] = safeTiebreakPoints;
  }

  final baseFormat = base.format;
  final format = <String, dynamic>{...?baseFormat};
  switch (kind) {
    case SportRulePresetKind.tennis:
      format
        ..['bestOfSets'] = bestOf
        ..['gamesPerSet'] = safePointsPerSet
        ..['winByTwoGames'] = winByTwo;
      if (safeTiebreakPoints != null) {
        format['tiebreakPoints'] = safeTiebreakPoints;
      }
      payload['format'] = format;
    case SportRulePresetKind.pickleballSideOut:
      format
        ..['gamePoint'] = safePointsPerSet
        ..['winByTwo'] = winByTwo;
      payload['format'] = format;
    case SportRulePresetKind.football:
      format
        ..['halvesCount'] = 2
        ..['halfDuration'] = 20
        ..['allowDraw'] = true;
      payload['format'] = format;
    case SportRulePresetKind.badminton ||
        SportRulePresetKind.tableTennis ||
        SportRulePresetKind.pickleballRally:
      format
        ..['bestOf'] = bestOf
        ..['pointsPerGame'] = safePointsPerSet
        ..['winByTwo'] = winByTwo;
      if (safeMaxPoints != null) format['capAt'] = safeMaxPoints;
      payload['format'] = format;
  }

  return payload;
}

/// Port `inferSportRuleKindFromCategory` (normalize.ts): suy ra môn từ chuỗi
/// slug/tên (kể cả tiếng Việt), ưu tiên `ruleKind` trong `categoryConfig`.
SportRulePresetKind inferSportRuleKindFromText(
  Object? categoryConfig,
  String? text,
) {
  final direct = SportRulePresetKind.fromApi(
    categoryConfig is Map ? categoryConfig['ruleKind'] : null,
  );
  if (direct != null) return direct;

  final normalized = _normalizeCategoryText(text);
  final combined = normalized;
  if (combined.contains('badminton') || combined.contains('cau long')) {
    return SportRulePresetKind.badminton;
  }
  if (combined.contains('table tennis') ||
      combined.contains('bong ban') ||
      combined.contains('ping pong')) {
    return SportRulePresetKind.tableTennis;
  }
  if (combined.contains('pickleball')) {
    return SportRulePresetKind.pickleballRally;
  }
  if (combined.contains('tennis') || combined.contains('quan vot')) {
    return SportRulePresetKind.tennis;
  }
  if (combined.contains('football') ||
      combined.contains('bong da') ||
      combined.contains('soccer')) {
    return SportRulePresetKind.football;
  }
  return SportRulePresetKind.badminton;
}

/// Bỏ dấu tiếng Việt + chữ đ/Đ để khớp slug (Web dùng NFD normalize).
String _normalizeCategoryText(Object? value) {
  var text = (value ?? '').toString().toLowerCase().trim();
  const accented =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const plain =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final index = accented.indexOf(char);
    buffer.write(index >= 0 ? plain[index] : char);
  }
  return buffer.toString().replaceAll(RegExp(r'[-_]+'), ' ').trim();
}
