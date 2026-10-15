import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';

/// Một ô lịch: sân và giờ bắt đầu.
class ScheduleSlot {
  const ScheduleSlot({
    required this.courtId,
    required this.courtName,
    required this.scheduledAt,
  });

  final String courtId;
  final String courtName;
  final DateTime scheduledAt;
}

/// Ô lịch hiện tại của trận, hoặc null nếu trận đang ở khay chờ.
ScheduleSlot? scheduleSlotOf(MatchModel match) {
  final courtId = match.courtId;
  final at = match.scheduledTime;
  if (courtId == null || courtId.isEmpty || at == null) return null;
  return ScheduleSlot(
    courtId: courtId,
    courtName: match.courtName ?? '',
    scheduledAt: at,
  );
}

/// Trận đang đấu hoặc đã kết thúc không đổi lịch bằng kéo thả, xếp nhanh hay
/// xếp tự động.
bool isScheduleLocked(MatchModel match) => match.isLive || match.isCompleted;

/// Thời lượng (phút) chọn nhanh cho ô lịch: xếp nhanh, hàng loạt và tự động.
const List<int> scheduleDurationOptions = [15, 30, 45, 60, 75, 90, 120];

/// Các mốc bắt đầu theo phút trong ngày, cách nhau [stepMinutes], nằm trong
/// khung giờ hoạt động `[startHour, endHour)`.
List<int> quickScheduleMinutes({
  required int startHour,
  required int endHour,
  int stepMinutes = 15,
}) => [
  for (var minute = startHour * 60; minute < endHour * 60; minute += stepMinutes)
    minute,
];

/// Bản nháp của trận sau khi xem trước xếp tự động: giữ nguyên trận, chỉ đổi
/// sân, giờ và thời lượng theo kế hoạch.
MatchModel scheduleDraftOf(
  MatchModel match, {
  required SchedulePlanAssignment assignment,
  required String courtName,
  required int durationMinutes,
}) => match.copyWith(
  scheduledTime: assignment.scheduledAt,
  courtId: assignment.courtId,
  courtName: courtName,
  court: courtName,
  durationMinutes: durationMinutes,
);

/// Ghi lịch một trận. [slot] null nghĩa là gỡ trận khỏi lịch. Trả về lịch server
/// đang lưu, hoặc null nếu ghi thất bại.
typedef ScheduleWriter =
    Future<MatchScheduleSnapshot?> Function(String matchId, ScheduleSlot? slot);

enum ScheduleSwapResult {
  /// Hai trận đã đổi chỗ xong.
  swapped,

  /// Không ghi được gì: trận đích chưa gỡ được nên không đổi gì.
  aborted,

  /// Ghi giữa chừng thất bại, các trận đã được trả về chỗ cũ.
  rolledBack,

  /// Ghi thất bại và cả bước hoàn tác cũng thất bại. Cần tải lại để xem thực tế.
  partial,
}

class ScheduleSwapReport {
  const ScheduleSwapReport({
    required this.result,
    required this.movedMatchIds,
  });

  final ScheduleSwapResult result;

  /// Các trận server đặt sang ô khác với ô đã yêu cầu (vì trùng lịch).
  final List<String> movedMatchIds;
}

/// Đổi chỗ trận [draggedId] với trận [targetId] (đang ở [targetSlot]).
///
/// [draggedSlot] null nghĩa là trận được kéo đang ở khay chờ: khi đó trận đích
/// được đưa về khay và trận kéo lấy ô của nó.
///
/// Thứ tự ghi phải tuân theo, vì server kiểm tra trùng sân khi ghi: gỡ trận đích
/// trước để nhường ô, đặt trận kéo vào ô đích, rồi đặt trận đích vào ô cũ của
/// trận kéo. Khi một bước thất bại, các bước đã làm được hoàn tác theo thứ tự
/// ngược lại.
Future<ScheduleSwapReport> runScheduleSwap({
  required String draggedId,
  required ScheduleSlot? draggedSlot,
  required String targetId,
  required ScheduleSlot targetSlot,
  required ScheduleWriter write,
}) async {
  final moved = <String>[];

  if (await write(targetId, null) == null) {
    return ScheduleSwapReport(
      result: ScheduleSwapResult.aborted,
      movedMatchIds: moved,
    );
  }

  final placedDragged = await write(draggedId, targetSlot);
  if (placedDragged == null) {
    final restored = (await write(targetId, targetSlot)) != null;
    return ScheduleSwapReport(
      result: restored ? ScheduleSwapResult.rolledBack : ScheduleSwapResult.partial,
      movedMatchIds: moved,
    );
  }
  _noteIfMoved(draggedId, targetSlot, placedDragged, moved);

  if (draggedSlot == null) {
    return ScheduleSwapReport(
      result: ScheduleSwapResult.swapped,
      movedMatchIds: moved,
    );
  }

  final placedTarget = await write(targetId, draggedSlot);
  if (placedTarget == null) {
    // Trả trận kéo về ô cũ trước; lúc đó ô của trận đích đã trống.
    final draggedBack = (await write(draggedId, draggedSlot)) != null;
    final targetBack =
        draggedBack && (await write(targetId, targetSlot)) != null;
    return ScheduleSwapReport(
      result: targetBack ? ScheduleSwapResult.rolledBack : ScheduleSwapResult.partial,
      movedMatchIds: moved,
    );
  }
  _noteIfMoved(targetId, draggedSlot, placedTarget, moved);

  return ScheduleSwapReport(
    result: ScheduleSwapResult.swapped,
    movedMatchIds: moved,
  );
}

void _noteIfMoved(
  String matchId,
  ScheduleSlot requested,
  MatchScheduleSnapshot placed,
  List<String> moved,
) {
  final at = placed.scheduledAt;
  final sameTime = at != null && at.isAtSameMomentAs(requested.scheduledAt);
  final sameCourt = placed.courtId == requested.courtId;
  if (!sameTime || !sameCourt) moved.add(matchId);
}
