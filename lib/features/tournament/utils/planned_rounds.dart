import 'dart:math' as math;

/// Loại một vòng dự kiến (port `DivisionRoundRulesSection` của Web).
enum PlannedRoundKind {
  /// Vòng bảng dùng chung (vòng 0): luật ghi lên chính `roundConfig`.
  groupShared,

  /// Lượt `leg_N` của vòng bảng: luật ghi vào `rounds['leg_N']`.
  groupLeg,

  /// Vòng loại trực tiếp: luật ghi vào `rounds['<số vòng>']` (số vòng từ 1).
  knockout,
}

/// Một vòng dự kiến khi hạng mục chưa có sơ đồ. [number] là 0 cho vòng bảng
/// dùng chung; [totalKnockoutRounds] chỉ có nghĩa với vòng knockout (để
/// dựng nhãn Chung kết/Bán kết… từ cuối).
class PlannedRound {
  const PlannedRound({
    required this.kind,
    required this.number,
    this.totalKnockoutRounds = 0,
  });

  final PlannedRoundKind kind;
  final int number;
  final int totalKnockoutRounds;

  /// Khóa trong `roundConfig.rounds`; null với vòng bảng dùng chung.
  String? get roundKey => switch (kind) {
    PlannedRoundKind.groupShared => null,
    PlannedRoundKind.groupLeg => 'leg_$number',
    PlannedRoundKind.knockout => '$number',
  };
}

const int _maxBracketSize = 64;

/// Kích thước sơ đồ: lũy thừa 2 gần nhất không nhỏ hơn [teamCount], chặn 64
/// như Web `getBracketSize`; 0 khi dưới 2 đội.
int plannedBracketSize(int teamCount) {
  if (teamCount < 2) return 0;
  var size = 2;
  while (size < teamCount && size < _maxBracketSize) {
    size *= 2;
  }
  return size;
}

/// Số lượt vòng bảng: `groupsConfig.roundsToPlay` và lượt `leg_N` đã lưu
/// trong `roundConfig.rounds`, tối thiểu 1 (Web `configuredGroupRounds`).
int plannedGroupLegs(Map<String, dynamic>? roundConfig) {
  final groupsConfig = roundConfig?['groupsConfig'];
  final persisted = groupsConfig is Map ? groupsConfig['roundsToPlay'] : null;
  var legs = persisted is num && persisted.toInt() >= 1 ? persisted.toInt() : 1;
  final rounds = roundConfig?['rounds'];
  for (final key in rounds is Map ? rounds.keys : const []) {
    final match = RegExp(r'^leg_(\d+)$').firstMatch('$key');
    if (match != null) {
      legs = math.max(legs, int.tryParse(match.group(1) ?? '') ?? 1);
    }
  }
  return legs;
}

/// Danh sách vòng dự kiến theo thể thức và số đội (Web: nhánh không có stage
/// thật của `DivisionRoundRulesSection`).
///
/// - `SWISS` và số đội dưới 2: rỗng.
/// - `ROUND_ROBIN`: chỉ vòng bảng (dùng chung + các lượt).
/// - `GROUP_STAGE_KNOCKOUT`: vòng bảng + knockout theo
///   `groupCount × teamsAdvancing`.
/// - Còn lại: knockout theo [maxParticipants].
///
/// Khóa đã lưu của vòng không còn tồn tại không bị xóa, chỉ không hiện.
List<PlannedRound> computePlannedRounds({
  required String bracketType,
  required int? maxParticipants,
  int? groupCount,
  int? teamsAdvancing,
  Map<String, dynamic>? roundConfig,
}) {
  final type = bracketType.toUpperCase();
  if (type == 'SWISS') return const [];
  final groupRounds = [
    const PlannedRound(kind: PlannedRoundKind.groupShared, number: 0),
    for (var leg = 1; leg <= plannedGroupLegs(roundConfig); leg++)
      PlannedRound(kind: PlannedRoundKind.groupLeg, number: leg),
  ];
  if (type == 'ROUND_ROBIN') return groupRounds;
  final isGroupKnockout = type == 'GROUP_STAGE_KNOCKOUT';
  final int teamCount = isGroupKnockout
      ? math.max<int>(0, groupCount ?? 0) *
            math.max<int>(0, teamsAdvancing ?? 0)
      : math.max<int>(0, maxParticipants ?? 0);
  final bracketSize = plannedBracketSize(teamCount);
  final total = bracketSize == 0 ? 0 : bracketSize.bitLength - 1;
  final knockout = [
    for (var index = 1; index <= total; index++)
      PlannedRound(
        kind: PlannedRoundKind.knockout,
        number: index,
        totalKnockoutRounds: total,
      ),
  ];
  return isGroupKnockout ? [...groupRounds, ...knockout] : knockout;
}

/// [computePlannedRounds] đọc thẳng từ một hạng mục của
/// `GET /tournaments/:id/divisions` (`groupsConfig.numGroups`,
/// `advancementConfig.teamsAdvancing` nằm trong `roundConfig`).
List<PlannedRound> plannedRoundsOfDivision(Map<String, dynamic> division) {
  final raw = division['roundConfig'];
  final roundConfig = raw is Map ? Map<String, dynamic>.from(raw) : null;
  final groups = roundConfig?['groupsConfig'];
  final advancement = roundConfig?['advancementConfig'];
  return computePlannedRounds(
    bracketType: (division['bracketType'] ?? '').toString(),
    maxParticipants: _asInt(division['maxParticipants']),
    groupCount: _asInt(groups is Map ? groups['numGroups'] : null),
    teamsAdvancing: _asInt(
      advancement is Map ? advancement['teamsAdvancing'] : null,
    ),
    roundConfig: roundConfig,
  );
}

int? _asInt(Object? value) => value is num ? value.toInt() : null;
