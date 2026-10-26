/// Dây chuyền lịch trên một sân: port `court-schedule-cascade.ts` của Web
/// (OpenSpec `quan-ly-giai-web-parity`, task 4.1) kèm helper xếp nối tiếp.
///
/// Server (`updateSchedule`) coi trận chưa khai thời lượng là 30 phút và không
/// cho trận nào ngắn hơn 15 phút. Phía App phải tính đúng như vậy, nếu không
/// server thấy trùng giờ và tự dời trận đi chỗ khác.
library;

const int serverMinDurationMinutes = 15;
const int serverDefaultDurationMinutes = 30;

/// Thời lượng server thực sự áp dụng: thiếu hoặc <= 0 tính 30, dưới 15 nâng
/// lên 15 (`serverEffectiveDurationMinutes` của Web).
int serverEffectiveDurationMinutes(int? durationMinutes) {
  final value = durationMinutes ?? serverDefaultDurationMinutes;
  if (value <= 0) return serverDefaultDurationMinutes;
  return value < serverMinDurationMinutes ? serverMinDurationMinutes : value;
}

/// Một trận đã xếp trên sân, đầu vào của [planDurationCascade].
class CascadeCourtMatch {
  const CascadeCourtMatch({
    required this.id,
    required this.startMs,
    this.durationMinutes,
    this.status,
  });

  final String id;

  /// Giờ bắt đầu (epoch milliseconds).
  final int startMs;
  final int? durationMinutes;
  final String? status;
}

/// Một lần dời trận: từ [fromMs] sang [toMs] trên cùng sân.
class CascadeMove {
  const CascadeMove({
    required this.id,
    required this.fromMs,
    required this.toMs,
  });

  final String id;
  final int fromMs;
  final int toMs;
}

/// Kết quả [planDurationCascade]: `ok` kèm các lần cần dời, hoặc `blocked` khi
/// chạm trận đã/đang đấu.
sealed class CascadePlan {
  const CascadePlan();
}

class CascadePlanOk extends CascadePlan {
  const CascadePlanOk(this.moves);

  final List<CascadeMove> moves;
}

class CascadePlanBlocked extends CascadePlan {
  const CascadePlanBlocked(this.blockedById);

  final String blockedById;
}

/// Trận đã hủy không chiếm sân.
bool _occupiesCourt(String? status) =>
    (status ?? '').trim().toUpperCase() != 'CANCELLED';

/// Chỉ trận chưa đấu mới được dời.
bool _isMovable(String? status) {
  final normalized = (status ?? '').trim().toUpperCase();
  return normalized.isEmpty || normalized == 'SCHEDULED';
}

/// Trả về các trận cần dời (theo thứ tự giờ) để trận [targetId] có thời lượng
/// [newDurationMinutes] mà không trận nào trên sân bị đè. Dây chuyền dừng ở
/// trận đầu tiên không còn bị đè. Chạm trận đã/đang đấu thì trả
/// [CascadePlanBlocked].
///
/// [courtMatches] phải gồm mọi trận đã xếp trên cùng sân (kể cả trận bị bộ lọc
/// vòng/giai đoạn ẩn), vì server kiểm trùng trên toàn giải.
CascadePlan planDurationCascade(
  String targetId,
  int newDurationMinutes,
  List<CascadeCourtMatch> courtMatches,
) {
  CascadeCourtMatch? target;
  for (final item in courtMatches) {
    if (item.id == targetId) {
      target = item;
      break;
    }
  }
  if (target == null) return const CascadePlanOk([]);

  final later =
      [
        for (final item in courtMatches)
          if (item.id != targetId &&
              item.startMs > target.startMs &&
              _occupiesCourt(item.status))
            item,
      ]..sort((a, b) {
        final byStart = a.startMs.compareTo(b.startMs);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });

  final moves = <CascadeMove>[];
  var previousEndMs =
      target.startMs +
      serverEffectiveDurationMinutes(newDurationMinutes) * 60000;

  for (final item in later) {
    if (item.startMs >= previousEndMs) break;
    if (!_isMovable(item.status)) return CascadePlanBlocked(item.id);
    moves.add(
      CascadeMove(id: item.id, fromMs: item.startMs, toMs: previousEndMs),
    );
    previousEndMs +=
        serverEffectiveDurationMinutes(item.durationMinutes) * 60000;
  }

  return CascadePlanOk(moves);
}

/// Giờ bắt đầu nối tiếp của một loạt trận từ ô [start]: trận đầu bắt đầu tại
/// [start], trận sau bắt đầu sau khi trận trước kết thúc (thời lượng tính theo
/// [serverEffectiveDurationMinutes]); giữa hai trận cách [gapMinutes] phút.
///
/// Dùng cho sheet xếp nhiều trận từ một ô (task 4.1): hiện giờ dự kiến từng
/// trận và ghi tuần tự theo đúng chuỗi này.
List<DateTime> cascadeStartTimes(
  DateTime start,
  List<int> minutes, {
  int gapMinutes = 0,
}) {
  final starts = <DateTime>[];
  var cursor = start;
  for (final duration in minutes) {
    starts.add(cursor);
    cursor = cursor.add(
      Duration(minutes: serverEffectiveDurationMinutes(duration) + gapMinutes),
    );
  }
  return starts;
}
