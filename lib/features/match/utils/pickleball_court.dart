/// Logic thuần cho sơ đồ sân pickleball: không Flutter, không gọi mạng.
/// Hợp đồng: local://pickleball-court-spec.md (mục 2–3).
library;

import 'dart:math' as math;

/// Ô trên một nửa sân, tính theo hướng nhìn của đội về phía lưới.
enum CourtCell { right, left }

/// Chế độ chấm: side-out (có quyền giao) hoặc rally (mỗi điểm đổi đội giao).
enum CourtScoringMode { sideOut, rally }

/// Ngữ cảnh tại thời điểm tính: điểm set hiện tại + cấu hình trận.
///
/// Rally: [servingTeam] là đội vừa được cộng điểm gần nhất (caller suy ra),
/// `null` khi chưa quan sát được điểm nào trong phiên.
class CourtContext {
  const CourtContext({
    required this.score1,
    required this.score2,
    required this.isDoubles,
    required this.team1PlayerCount,
    required this.team2PlayerCount,
    required this.servingTeam,
    required this.serverNumber,
    required this.scoringMode,
    required this.setIndex,
    required this.targetPoints,
    required this.isDecidingSet,
  });

  final int score1;
  final int score2;
  final bool isDoubles;
  final int team1PlayerCount;
  final int team2PlayerCount;
  final int? servingTeam;
  final int serverNumber;
  final CourtScoringMode scoringMode;

  /// Số set đã đóng (0-based cho set hiện tại).
  final int setIndex;
  final int? targetPoints;
  final bool isDecidingSet;

  int scoreOf(int team) => team == 1 ? score1 : score2;

  int playerCountOf(int team) =>
      team == 1 ? team1PlayerCount : team2PlayerCount;

  /// Số giao có nghĩa: chỉ đôi side-out dùng 1|2, các trường hợp khác là 1.
  int get effectiveServerNumber =>
      scoringMode == CourtScoringMode.sideOut && isDoubles && serverNumber == 2
      ? 2
      : 1;
}

/// Lượt giao hiện tại (side-out). Ghi khi đổi đội giao hoặc đổi số giao 1→2.
class CourtTurnStart {
  const CourtTurnStart({
    required this.team,
    required this.serverNumber,
    required this.teamScoreAtStart,
    required this.serverPlayerIndex,
  });

  final int team;
  final int serverNumber;
  final int teamScoreAtStart;
  final int serverPlayerIndex;

  CourtTurnStart withServerNumber(int number) => CourtTurnStart(
    team: team,
    serverNumber: number,
    teamScoreAtStart: teamScoreAtStart,
    serverPlayerIndex: serverPlayerIndex,
  );

  Map<String, dynamic> toJson() => {
    'team': team,
    'serverNumber': serverNumber,
    'teamScoreAtStart': teamScoreAtStart,
    'serverPlayerIndex': serverPlayerIndex,
  };

  static CourtTurnStart? tryFromJson(Object? raw) {
    final json = _asMap(raw);
    if (json == null) return null;
    final team = _asInt(json['team']);
    final serverNumber = _asInt(json['serverNumber']);
    final teamScore = _asInt(json['teamScoreAtStart']);
    final playerIndex = _asInt(json['serverPlayerIndex']);
    if (!_isTeam(team) ||
        !_isServerNumber(serverNumber) ||
        teamScore == null ||
        teamScore < 0 ||
        !_isPlayerIndex(playerIndex)) {
      return null;
    }
    return CourtTurnStart(
      team: team!,
      serverNumber: serverNumber!,
      teamScoreAtStart: teamScore,
      serverPlayerIndex: playerIndex!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CourtTurnStart &&
      other.team == team &&
      other.serverNumber == serverNumber &&
      other.teamScoreAtStart == teamScoreAtStart &&
      other.serverPlayerIndex == serverPlayerIndex;

  @override
  int get hashCode =>
      Object.hash(team, serverNumber, teamScoreAtStart, serverPlayerIndex);
}

/// Trọng tài chỉ định người đang giao. Bị xoá khi lượt giao kế tiếp bắt đầu.
class CourtServerOverride {
  const CourtServerOverride({required this.team, required this.playerIndex});

  final int team;
  final int playerIndex;

  Map<String, dynamic> toJson() => {'team': team, 'playerIndex': playerIndex};

  static CourtServerOverride? tryFromJson(Object? raw) {
    final json = _asMap(raw);
    if (json == null) return null;
    final team = _asInt(json['team']);
    final playerIndex = _asInt(json['playerIndex']);
    if (!_isTeam(team) || !_isPlayerIndex(playerIndex)) return null;
    return CourtServerOverride(team: team!, playerIndex: playerIndex!);
  }

  @override
  bool operator ==(Object other) =>
      other is CourtServerOverride &&
      other.team == team &&
      other.playerIndex == playerIndex;

  @override
  int get hashCode => Object.hash(team, playerIndex);
}

/// Cài đặt sân của một trận, lưu lên server tại `match.scoreDetails.courtState`.
///
/// [history] chứa snapshot (không chứa history), tối đa [historyLimit], mới
/// nhất ở cuối. Mọi thay đổi do trọng tài làm qua hàm có tiền tố action
/// (vd [setStartingRight]) sẽ đẩy snapshot vào history.
class CourtState {
  const CourtState({
    this.startingRightTeam1 = 0,
    this.startingRightTeam2 = 0,
    this.endsOverride,
    this.autoSwitchEnds = true,
    this.midSetSwitchDone = false,
    this.serverOverride,
    this.turnStart,
    this.history = const [],
    this.updatedAt,
    this.updatedBy,
  });

  static const int currentVersion = 1;
  static const int historyLimit = 20;

  final int startingRightTeam1;
  final int startingRightTeam2;

  /// null = tự động; true/false = trọng tài ép trạng thái đổi sân.
  final bool? endsOverride;
  final bool autoSwitchEnds;

  /// Đã lật ở mốc giữa set quyết định (chỉ lật một lần).
  final bool midSetSwitchDone;
  final CourtServerOverride? serverOverride;
  final CourtTurnStart? turnStart;
  final List<CourtState> history;

  /// Server gán; client không tự đặt.
  final String? updatedAt;
  final String? updatedBy;

  int startingRightOf(int team) =>
      team == 1 ? startingRightTeam1 : startingRightTeam2;

  /// Snapshot để đưa vào history: chỉ giữ cài đặt, không history/meta.
  CourtState get snapshot => CourtState(
    startingRightTeam1: startingRightTeam1,
    startingRightTeam2: startingRightTeam2,
    endsOverride: endsOverride,
    autoSwitchEnds: autoSwitchEnds,
    midSetSwitchDone: midSetSwitchDone,
    serverOverride: serverOverride,
    turnStart: turnStart,
  );

  /// So sánh cài đặt, bỏ qua history và meta. Dùng để biết có cần ghi server.
  bool sameSettings(CourtState other) =>
      startingRightTeam1 == other.startingRightTeam1 &&
      startingRightTeam2 == other.startingRightTeam2 &&
      endsOverride == other.endsOverride &&
      autoSwitchEnds == other.autoSwitchEnds &&
      midSetSwitchDone == other.midSetSwitchDone &&
      serverOverride == other.serverOverride &&
      turnStart == other.turnStart;

  CourtState copyWith({
    int? startingRightTeam1,
    int? startingRightTeam2,
    bool? endsOverride,
    bool clearEndsOverride = false,
    bool? autoSwitchEnds,
    bool? midSetSwitchDone,
    CourtServerOverride? serverOverride,
    bool clearServerOverride = false,
    CourtTurnStart? turnStart,
    List<CourtState>? history,
  }) => CourtState(
    startingRightTeam1: startingRightTeam1 ?? this.startingRightTeam1,
    startingRightTeam2: startingRightTeam2 ?? this.startingRightTeam2,
    endsOverride: clearEndsOverride ? null : (endsOverride ?? this.endsOverride),
    autoSwitchEnds: autoSwitchEnds ?? this.autoSwitchEnds,
    midSetSwitchDone: midSetSwitchDone ?? this.midSetSwitchDone,
    serverOverride: clearServerOverride
        ? null
        : (serverOverride ?? this.serverOverride),
    turnStart: turnStart ?? this.turnStart,
    history: history ?? this.history,
    updatedAt: updatedAt,
    updatedBy: updatedBy,
  );

  /// JSON đúng hợp đồng server. `version` luôn là [currentVersion].
  Map<String, dynamic> toJson() => {
    'version': currentVersion,
    ...toSettingsJson(),
    'history': [for (final item in history) item.toSettingsJson()],
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (updatedBy != null) 'updatedBy': updatedBy,
  };

  Map<String, dynamic> toSettingsJson() => {
    'startingRight': {'team1': startingRightTeam1, 'team2': startingRightTeam2},
    'endsOverride': endsOverride,
    'autoSwitchEnds': autoSwitchEnds,
    'midSetSwitchDone': midSetSwitchDone,
    'serverOverride': serverOverride?.toJson(),
    'turnStart': turnStart?.toJson(),
  };

  /// Thiếu, sai kiểu, hoặc khác [currentVersion] đều về mặc định.
  /// Giá trị lệch trong từng field được chuẩn hoá về mặc định của field đó.
  static CourtState fromJson(Object? raw) {
    final json = _asMap(raw);
    if (json == null || _asInt(json['version']) != currentVersion) {
      return const CourtState();
    }
    final snapshots = <CourtState>[];
    final rawHistory = json['history'];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        final map = _asMap(item);
        if (map != null) snapshots.add(_settingsFromJson(map));
      }
    }
    final settings = _settingsFromJson(json);
    return CourtState(
      startingRightTeam1: settings.startingRightTeam1,
      startingRightTeam2: settings.startingRightTeam2,
      endsOverride: settings.endsOverride,
      autoSwitchEnds: settings.autoSwitchEnds,
      midSetSwitchDone: settings.midSetSwitchDone,
      serverOverride: settings.serverOverride,
      turnStart: settings.turnStart,
      history: _trimHistory(snapshots),
      updatedAt: _asString(json['updatedAt']),
      updatedBy: _asString(json['updatedBy']),
    );
  }

  static CourtState _settingsFromJson(Map<String, dynamic> json) {
    final startingRight = _asMap(json['startingRight']) ?? const {};
    return CourtState(
      startingRightTeam1: _asSide(startingRight['team1']),
      startingRightTeam2: _asSide(startingRight['team2']),
      endsOverride: _asBool(json['endsOverride']),
      autoSwitchEnds: _asBool(json['autoSwitchEnds']) ?? true,
      midSetSwitchDone: _asBool(json['midSetSwitchDone']) ?? false,
      serverOverride: CourtServerOverride.tryFromJson(json['serverOverride']),
      turnStart: CourtTurnStart.tryFromJson(json['turnStart']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CourtState &&
      sameSettings(other) &&
      updatedAt == other.updatedAt &&
      updatedBy == other.updatedBy &&
      _sameHistory(history, other.history);

  @override
  int get hashCode => Object.hash(
    startingRightTeam1,
    startingRightTeam2,
    endsOverride,
    autoSwitchEnds,
    midSetSwitchDone,
    serverOverride,
    turnStart,
    updatedAt,
    updatedBy,
    Object.hashAll(history),
  );
}

/// Vị trí các VĐV trong một đội: index VĐV đứng từng ô, null nếu ô trống.
class CourtTeamSlots {
  const CourtTeamSlots({this.rightPlayerIndex, this.leftPlayerIndex});

  final int? rightPlayerIndex;
  final int? leftPlayerIndex;

  int? playerIn(CourtCell cell) =>
      cell == CourtCell.right ? rightPlayerIndex : leftPlayerIndex;
}

/// Kết quả suy vị trí để vẽ. Không chứa màu/kích thước.
class CourtLayout {
  const CourtLayout({
    required this.team1First,
    required this.team1,
    required this.team2,
    required this.servingTeam,
    required this.serverPlayerIndex,
    required this.serverCell,
    required this.callServerNumber,
    required this.servingScore,
    required this.receivingScore,
  });

  /// true: đội 1 nằm nửa đầu (trên/trái). false: đội 2 nằm nửa đầu.
  final bool team1First;
  final CourtTeamSlots team1;
  final CourtTeamSlots team2;

  /// null khi chưa biết đội giao (rally chưa có điểm trong phiên).
  final int? servingTeam;

  /// Người giao, là index trong đội giao.
  final int? serverPlayerIndex;

  /// Ô mà người giao đang đứng; dùng để làm sáng ô giao.
  final CourtCell? serverCell;

  /// 1|2 cho đôi side-out, còn lại null.
  final int? callServerNumber;
  final int? servingScore;
  final int? receivingScore;

  CourtTeamSlots slotsOf(int team) => team == 1 ? team1 : team2;
}

/// Đồng bộ trạng thái tự động: lượt giao (side-out) và mốc giữa set quyết định.
///
/// Idempotent: cùng [state] và [context] cho cùng kết quả. Không ghi history.
/// Rally không ghi lượt giao: đội giao suy tại chỗ từ [CourtContext.servingTeam].
CourtState reconcileCourtState(CourtState state, CourtContext context) {
  var next = state;
  if (context.scoringMode == CourtScoringMode.sideOut) {
    next = _reconcileTurn(next, context);
  }
  return _reconcileMidSet(next, context);
}

/// true khi cần ghi server: cài đặt đổi do thao tác của trọng tài, do lượt giao
/// đổi, hoặc do cờ lật giữa set đổi.
bool needsServerWrite(CourtState before, CourtState after) =>
    !before.sameSettings(after);

/// Đổi sân hiển thị: override thắng; không tự đổi thì không lật.
/// Set lẻ (0-based) lật, giữa set quyết định lật thêm một lần.
bool endsFlipped(CourtState reconciled, CourtContext context) {
  final override = reconciled.endsOverride;
  if (override != null) return override;
  if (!reconciled.autoSwitchEnds) return false;
  final setFlip = context.setIndex % 2 == 1;
  return setFlip != reconciled.midSetSwitchDone;
}

/// Suy vị trí để vẽ từ [state] và [context]. Không đổi input.
CourtLayout resolveCourtLayout(CourtState state, CourtContext context) {
  final s = reconcileCourtState(state, context);
  final flipped = endsFlipped(s, context);
  final team1 = _slotsFor(1, s, context);
  final team2 = _slotsFor(2, s, context);
  final servingTeam = context.servingTeam;
  if (servingTeam == null) {
    return CourtLayout(
      team1First: !flipped,
      team1: team1,
      team2: team2,
      servingTeam: null,
      serverPlayerIndex: null,
      serverCell: null,
      callServerNumber: null,
      servingScore: null,
      receivingScore: null,
    );
  }
  final serverIndex = _serverPlayerIndex(servingTeam, s, context);
  return CourtLayout(
    team1First: !flipped,
    team1: team1,
    team2: team2,
    servingTeam: servingTeam,
    serverPlayerIndex: serverIndex,
    serverCell: _cellOfPlayer(servingTeam, serverIndex, s, context),
    callServerNumber:
        context.scoringMode == CourtScoringMode.sideOut && context.isDoubles
        ? context.effectiveServerNumber
        : null,
    servingScore: context.scoreOf(servingTeam),
    receivingScore: context.scoreOf(servingTeam == 1 ? 2 : 1),
  );
}

/// Đổi VĐV xuất phát ô phải của một đội. Ghi history.
CourtState setStartingRight(
  CourtState state,
  CourtContext context,
  int team,
  int playerIndex,
) {
  _checkTeam(team);
  _checkPlayerIndex(playerIndex);
  final base = reconcileCourtState(state, context);
  final next = _recordChange(
    base,
    (s) => _withStartingRight(s, context, team, playerIndex),
  );
  return reconcileCourtState(next, context);
}

CourtState _withStartingRight(
  CourtState s,
  CourtContext c,
  int team,
  int playerIndex,
) {
  final updated = team == 1
      ? s.copyWith(startingRightTeam1: playerIndex)
      : s.copyWith(startingRightTeam2: playerIndex);
  final turn = updated.turnStart;
  if (!c.isDoubles || turn == null || turn.team != team) return updated;
  // Lượt đang mở: người giao là VĐV ô phải tại điểm bắt đầu lượt (lượt 2 là
  // đồng đội). Tính lại theo cài đặt mới để đính chính đúng người giao.
  final right = _doublesRightIndex(turn.teamScoreAtStart, playerIndex);
  final serverPlayer = turn.serverNumber == 2 ? 1 - right : right;
  return updated.copyWith(
    turnStart: CourtTurnStart(
      team: turn.team,
      serverNumber: turn.serverNumber,
      teamScoreAtStart: turn.teamScoreAtStart,
      serverPlayerIndex: serverPlayer,
    ),
  );
}

/// Đổi sân ngay: đảo trạng thái đang hiển thị và ép bằng endsOverride. Ghi history.
CourtState swapEndsNow(CourtState state, CourtContext context) {
  final base = reconcileCourtState(state, context);
  final next = _recordChange(
    base,
    (s) => s.copyWith(endsOverride: !endsFlipped(s, context)),
  );
  return reconcileCourtState(next, context);
}

/// Bật/tắt tự đổi sân. Ghi history.
CourtState setAutoSwitchEnds(CourtState state, CourtContext context, bool value) {
  final base = reconcileCourtState(state, context);
  final next = _recordChange(
    base,
    (s) => s.copyWith(autoSwitchEnds: value),
  );
  return reconcileCourtState(next, context);
}

/// Chỉ định người đang giao. Chỉ có tác dụng khi đúng đội đang giao. Ghi history.
CourtState setServerOverride(
  CourtState state,
  CourtContext context,
  int team,
  int playerIndex,
) {
  _checkTeam(team);
  _checkPlayerIndex(playerIndex);
  final base = reconcileCourtState(state, context);
  final next = _recordChange(
    base,
    (s) => s.copyWith(
      serverOverride: CourtServerOverride(team: team, playerIndex: playerIndex),
    ),
  );
  return reconcileCourtState(next, context);
}

/// Khôi phục tự động: xoá endsOverride và serverOverride, bật tự đổi sân,
/// xoá cờ lật giữa set (để tính lại theo luật). Giữ startingRight và turnStart.
CourtState restoreAutomaticCourt(CourtState state, CourtContext context) {
  final base = reconcileCourtState(state, context);
  final next = _recordChange(
    base,
    (s) => s.copyWith(
      clearEndsOverride: true,
      clearServerOverride: true,
      autoSwitchEnds: true,
      midSetSwitchDone: false,
    ),
  );
  return reconcileCourtState(next, context);
}

/// Hoàn tác một thay đổi của trọng tài. Không có gì để hoàn tác thì trả lại
/// nguyên trạng. Không dùng cho đồng bộ tự động.
CourtState undoCourtChange(CourtState state) {
  if (state.history.isEmpty) return state;
  final last = state.history.last;
  return last.copyWith(
    history: state.history.sublist(0, state.history.length - 1),
  );
}

// ─── Nội bộ ───

CourtState _reconcileTurn(CourtState state, CourtContext c) {
  final servingTeam = c.servingTeam;
  if (servingTeam == null) return state;
  final number = c.effectiveServerNumber;
  final prev = state.turnStart;
  if (prev == null || prev.team != servingTeam) {
    return _startTurn(
      state,
      c,
      servingTeam,
      number,
      _turnStartPlayerIndex(servingTeam, state, c),
    );
  }
  if (prev.serverNumber == 1 && number == 2) {
    return _startTurn(
      state,
      c,
      servingTeam,
      2,
      c.isDoubles ? 1 - prev.serverPlayerIndex : 0,
    );
  }
  if (prev.serverNumber == 2 && number == 1) {
    // Điểm thắng reset số giao về 1 nhưng không mở lượt mới.
    return state.copyWith(turnStart: prev.withServerNumber(1));
  }
  return state;
}

CourtState _startTurn(
  CourtState state,
  CourtContext c,
  int team,
  int number,
  int playerIndex,
) => state.copyWith(
  turnStart: CourtTurnStart(
    team: team,
    serverNumber: number,
    teamScoreAtStart: c.scoreOf(team),
    serverPlayerIndex: playerIndex,
  ),
  clearServerOverride: true,
);

CourtState _reconcileMidSet(CourtState state, CourtContext c) {
  if (!c.isDecidingSet) {
    return state.midSetSwitchDone
        ? state.copyWith(midSetSwitchDone: false)
        : state;
  }
  if (!state.autoSwitchEnds || state.midSetSwitchDone) return state;
  final target = c.targetPoints;
  if (target == null || target <= 0) return state;
  final mark = (target + 1) ~/ 2;
  return math.max(c.score1, c.score2) >= mark
      ? state.copyWith(midSetSwitchDone: true)
      : state;
}

CourtState _recordChange(
  CourtState base,
  CourtState Function(CourtState) change,
) {
  final next = change(base);
  if (next.sameSettings(base)) return base;
  final snapshots = [...base.history, base.snapshot];
  final trimmed = _trimHistory(snapshots);
  return next.copyWith(history: trimmed);
}

List<CourtState> _trimHistory(List<CourtState> snapshots) =>
    snapshots.length > CourtState.historyLimit
    ? snapshots.sublist(snapshots.length - CourtState.historyLimit)
    : snapshots;

/// Chỉ số VĐV đứng ở [cell] của đội có [score] điểm; null nếu ô trống.
int? _playerIndexInCell({
  required CourtCell cell,
  required int score,
  required bool isDoubles,
  required int startingRight,
}) {
  if (!isDoubles) {
    return (cell == CourtCell.right) == score.isEven ? 0 : null;
  }
  final rightIdx = _doublesRightIndex(score, startingRight);
  return cell == CourtCell.right ? rightIdx : 1 - rightIdx;
}

int _doublesRightIndex(int score, int startingRight) =>
    score.isEven ? startingRight : 1 - startingRight;

CourtCell _parityCell(int score) =>
    score.isEven ? CourtCell.right : CourtCell.left;

/// Ô của VĐV [playerIndex] theo công thức, không phụ thuộc số VĐV có tên.
CourtCell _cellOfPlayer(
  int team,
  int playerIndex,
  CourtState s,
  CourtContext c,
) {
  final score = c.scoreOf(team);
  if (!c.isDoubles) return _parityCell(score);
  return playerIndex == _doublesRightIndex(score, s.startingRightOf(team))
      ? CourtCell.right
      : CourtCell.left;
}

int _turnStartPlayerIndex(int team, CourtState s, CourtContext c) {
  if (!c.isDoubles) return 0;
  return _doublesRightIndex(c.scoreOf(team), s.startingRightOf(team));
}

int _serverPlayerIndex(int team, CourtState s, CourtContext c) {
  final override = s.serverOverride;
  if (override != null && override.team == team) return override.playerIndex;
  final turn = s.turnStart;
  if (c.scoringMode == CourtScoringMode.sideOut &&
      turn != null &&
      turn.team == team) {
    return turn.serverPlayerIndex;
  }
  // Rally, hoặc chưa có lượt: người đứng đúng ô theo chẵn/lẻ điểm đội giao.
  return _playerIndexInCell(
        cell: _parityCell(c.scoreOf(team)),
        score: c.scoreOf(team),
        isDoubles: c.isDoubles,
        startingRight: s.startingRightOf(team),
      ) ??
      0;
}

CourtTeamSlots _slotsFor(int team, CourtState s, CourtContext c) {
  final count = c.playerCountOf(team);
  int? visible(CourtCell cell) {
    final idx = _playerIndexInCell(
      cell: cell,
      score: c.scoreOf(team),
      isDoubles: c.isDoubles,
      startingRight: s.startingRightOf(team),
    );
    return idx != null && idx < count ? idx : null;
  }

  return CourtTeamSlots(
    rightPlayerIndex: visible(CourtCell.right),
    leftPlayerIndex: visible(CourtCell.left),
  );
}

bool _sameHistory(List<CourtState> a, List<CourtState> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void _checkTeam(int team) {
  if (!_isTeam(team)) {
    throw ArgumentError.value(team, 'team', 'phải là 1 hoặc 2');
  }
}

void _checkPlayerIndex(int index) {
  if (!_isPlayerIndex(index)) {
    throw ArgumentError.value(index, 'playerIndex', 'phải là 0 hoặc 1');
  }
}

bool _isTeam(int? v) => v == 1 || v == 2;
bool _isServerNumber(int? v) => v == 1 || v == 2;
bool _isPlayerIndex(int? v) => v == 0 || v == 1;

Map<String, dynamic>? _asMap(Object? raw) => raw is Map
    ? raw.map((key, value) => MapEntry(key.toString(), value))
    : null;

int? _asInt(Object? raw) => raw is int ? raw : null;
bool? _asBool(Object? raw) => raw is bool ? raw : null;
String? _asString(Object? raw) => raw is String ? raw : null;
int _asSide(Object? raw) => raw == 1 ? 1 : 0;
