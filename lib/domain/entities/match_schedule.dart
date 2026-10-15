/// Trường lịch của trận có thể được xoá (gửi JSON null) khi cập nhật.
///
/// Mọi trường không nằm trong danh sách xoá và không được truyền giá trị sẽ
/// giữ nguyên trên server, nên một lần ghi không vô tình xoá trường khác.
enum MatchScheduleField {
  courtId('courtId'),
  courtName('courtName'),
  courtAddress('courtAddress'),
  scheduledAt('scheduledAt');

  const MatchScheduleField(this.wireName);

  /// Tên trường trong body PATCH `/matches/:id/schedule`.
  final String wireName;
}

/// Lịch mà server đang lưu sau khi ghi. Có thể khác lịch đã yêu cầu vì server
/// tự dời trận khi trùng sân hoặc trùng người chơi.
typedef MatchScheduleSnapshot = ({
  DateTime? scheduledAt,
  String? courtId,
  String? courtName,
});

/// Một trận được xếp vào sân và giờ trong bản xem trước.
typedef SchedulePlanAssignment = ({
  String matchId,
  String courtId,
  DateTime scheduledAt,
});

/// Trận bị bỏ qua khi xếp tự động, kèm lý do do server trả về.
typedef SchedulePlanSkip = ({String matchId, String reason});

/// Kết quả xem trước xếp tự động. Chỉ là bản nháp, chưa ghi gì xuống server.
class SchedulePlanPreview {
  const SchedulePlanPreview({
    required this.durationMinutes,
    required this.assignments,
    required this.skipped,
    required this.eligibleCount,
  });

  /// Thời lượng server đã dùng để tính khung giờ; khi áp dụng phải ghi đúng
  /// thời lượng này để lịch trên lưới khớp với lúc server tính.
  final int durationMinutes;
  final List<SchedulePlanAssignment> assignments;
  final List<SchedulePlanSkip> skipped;
  final int eligibleCount;
}
