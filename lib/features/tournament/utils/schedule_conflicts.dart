/// Phát hiện VĐV bị xếp trùng giờ trên hai sân khác nhau (OpenSpec
/// `quan-ly-giai-web-parity`, task 4.4): port `scheduleConflicts` của Web
/// (`CourtScheduleBoard.tsx` useMemo, dòng 1431) kèm các helper nhận diện
/// `isActiveScheduleStatus` (dòng 280) và `getScheduleParticipantEntries`
/// (dòng 287) + khoá nhận diện của `schedule-competitor-display.ts`.
library;

import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Trận chỉ tham gia phát hiện trùng lịch khi chưa đấu/kết thúc: status cũ có
/// thể thiếu, coi như chưa đấu (Web `isActiveScheduleStatus`). Trận LIVE của
/// Web không nằm trong tập này nên cũng bị loại.
bool scheduleStatusActive(String? status) {
  final normalized = (status ?? '').trim().toUpperCase();
  return normalized.isEmpty ||
      normalized == 'SCHEDULED' ||
      normalized == 'ONGOING';
}

/// Xung đột của một trận với MỘT trận khác: VĐV [competitorName] trùng cũng
/// đang có lịch tại sân [otherCourtName] lúc [otherTimeStr]. Thông điệp đúng
/// ba thành phần Web hiện trên dòng cảnh báo (dòng 6844).
class ScheduleConflict {
  const ScheduleConflict({
    required this.otherMatchId,
    required this.otherCourtName,
    required this.otherTimeStr,
    required this.competitorName,
  });

  /// Id trận kia.
  final String otherMatchId;

  /// Tên sân của trận kia; trống khi chưa có tên, giao diện tự hiện nhãn dịch
  /// `scheduleConflictOtherCourt`.
  final String otherCourtName;

  /// Giờ bắt đầu của trận kia, dạng `HH:MM` giờ máy.
  final String otherTimeStr;

  /// Tên VĐV/đội trùng người (Web `shared.label`).
  final String competitorName;
}

/// Một trận có xung đột, kèm danh sách xung đột của nó.
class ScheduleConflictGroup {
  const ScheduleConflictGroup({required this.match, required this.conflicts});

  /// Trận đang bị trùng người.
  final MatchModel match;

  final List<ScheduleConflict> conflicts;
}

/// Khoá nhận diện của một bên trận: id participant, `user:<id>` hoặc
/// `name:<tên>` của từng VĐV, và `team:<tên>` khi bên chưa có id (port
/// `identityKeysOf` của Web `schedule-competitor-display.ts`).
({List<String> keys, String label}) scheduleCompetitorOf(
  MatchModel match,
  int side,
) {
  final id = (side == 1 ? match.team1Id : match.team2Id).trim();
  final teamName = matchSideTeamName(match, side)?.trim() ?? '';
  final players = matchSidePlayers(match, side);
  final keys = <String>[
    if (id.isNotEmpty) 'id:$id',
    for (final player in players)
      player.userId != null && player.userId!.isNotEmpty
          ? 'user:${player.userId}'
          : 'name:${_normalizeText(player.fullName)}',
    if (id.isEmpty && teamName.isNotEmpty) 'team:${_normalizeText(teamName)}',
  ];
  // Nhãn hiển thị cùng quy ước thẻ lịch (Web `fullLabel` = participantLabel):
  // có tên đội thì hiện tên đội, không thì nối tên các VĐV.
  final label = matchSideLabel(match, side);
  return (keys: keys, label: label);
}

/// Hai bên của một trận tham gia phát hiện trùng lịch: bên chưa xác định
/// (không có id, không VĐV, không tên) không có khoá nên loại ra — cùng luật
/// Web `getScheduleParticipantEntries`.
List<({List<String> keys, String label})> scheduleParticipantsOf(
  MatchModel match,
) {
  final entries = <({List<String> keys, String label})>[];
  for (final side in const [1, 2]) {
    final competitor = scheduleCompetitorOf(match, side);
    if (competitor.keys.isNotEmpty) entries.add(competitor);
  }
  return entries;
}

/// Tên sân hiển thị của trận; trống khi chưa có tên sân.
String scheduleCourtNameOf(MatchModel match) {
  final name = match.courtName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return match.court.trim();
}

String scheduleConflictTimeText(DateTime at) {
  final local = at.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _normalizeText(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Thời lượng server thực áp dụng cho phát hiện trùng lịch: thiếu hoặc <= 0
/// tính bằng bước ô của lưới ([defaultStepMinutes] — Web `Math.max(15,
/// Number(m.durationMinutes) || defaultStepMinutes)`), dưới 15 phút nâng lên
/// 15 (giới hạn của server khi ghi lịch).
int scheduleConflictDuration(int? durationMinutes, int defaultStepMinutes) {
  final value = (durationMinutes == null || durationMinutes <= 0)
      ? defaultStepMinutes
      : durationMinutes;
  return value < 15 ? 15 : value;
}

/// Danh sách xung đột VĐV của từng trận đã xếp trong [matches].
///
/// Chỉ xét trận khác sân (trùng sân cùng giờ server tự chặn khi ghi) và trận
/// đã có sân + giờ + trạng thái chưa đấu. Trả về theo thứ tự trận xuất hiện;
/// trận có cặp xung đột hai chiều đều nhận dòng cảnh báo như Web.
List<ScheduleConflictGroup> scheduleConflictGroups(
  List<MatchModel> matches, {
  required int defaultStepMinutes,
}) {
  final scheduled = [
    for (final match in matches)
      if (match.courtId != null &&
          match.courtId!.isNotEmpty &&
          match.scheduledTime != null &&
          scheduleStatusActive(match.status))
        match,
  ];
  final groups = <ScheduleConflictGroup>[];
  final conflictsByMatch = <String, List<ScheduleConflict>>{};
  final participantsCache =
      <String, List<({List<String> keys, String label})>>{};

  List<({List<String> keys, String label})> participantsOf(MatchModel match) {
    final cached = participantsCache[match.id];
    if (cached != null) return cached;
    final value = scheduleParticipantsOf(match);
    participantsCache[match.id] = value;
    return value;
  }

  ({List<String> keys, String label})? findShared(
    List<({List<String> keys, String label})> p1,
    List<({List<String> keys, String label})> p2,
  ) {
    for (final participant in p1) {
      for (final other in p2) {
        for (final key in other.keys) {
          if (participant.keys.contains(key)) return participant;
        }
      }
    }
    return null;
  }

  ScheduleConflict conflictOf(MatchModel from, MatchModel other, String label) {
    final otherCourtName = scheduleCourtNameOf(other);
    return ScheduleConflict(
      otherMatchId: other.id,
      otherCourtName: otherCourtName,
      otherTimeStr: scheduleConflictTimeText(other.scheduledTime!),
      competitorName: label,
    );
  }

  void record(MatchModel match, ScheduleConflict conflict) {
    conflictsByMatch
        .putIfAbsent(match.id, () => <ScheduleConflict>[])
        .add(conflict);
  }

  for (var i = 0; i < scheduled.length; i++) {
    final first = scheduled[i];
    final start1 = first.scheduledTime!.millisecondsSinceEpoch;
    final end1 =
        start1 +
        scheduleConflictDuration(first.durationMinutes, defaultStepMinutes) *
            60000;
    final p1 = participantsOf(first);
    if (p1.isEmpty) continue;

    for (var j = i + 1; j < scheduled.length; j++) {
      final second = scheduled[j];
      if (first.courtId == second.courtId) continue;
      // Trùng giờ chặt: hai trận cùng đang diễn ra trong cùng khoảng thời gian
      // (`Math.max(t1, t2) < Math.min(end1, end2)` của Web) — trận này kết thúc
      // đúng lúc trận kia bắt đầu thì không tính.
      final start2 = second.scheduledTime!.millisecondsSinceEpoch;
      final end2 =
          start2 +
          scheduleConflictDuration(second.durationMinutes, defaultStepMinutes) *
              60000;
      final overlapStart = start1 > start2 ? start1 : start2;
      final overlapEnd = end1 < end2 ? end1 : end2;
      if (overlapStart >= overlapEnd) continue;

      final p2 = participantsOf(second);
      final shared = findShared(p1, p2);
      if (shared == null) continue;
      record(first, conflictOf(first, second, shared.label));
      record(second, conflictOf(second, first, shared.label));
    }
  }

  for (final match in scheduled) {
    final conflicts = conflictsByMatch[match.id];
    if (conflicts == null || conflicts.isEmpty) continue;
    groups.add(ScheduleConflictGroup(match: match, conflicts: conflicts));
  }
  return groups;
}
