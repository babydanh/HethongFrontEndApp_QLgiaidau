import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Bộ lọc trạng thái trận dùng chung cho feed trang chủ, card giải và
/// `/matches`: một nơi ánh xạ khóa UI sang tham số server và điều kiện client,
/// để trận qua lọc client không bị server loại (và ngược lại).
enum MatchStatusFilter {
  live,
  scheduled,
  completed,
  all;

  static MatchStatusFilter parse(String key) => switch (key) {
    'live' => live,
    'scheduled' => scheduled,
    'completed' => completed,
    _ => all,
  };

  /// Giá trị `status` gửi lên `GET /matches`; `null` = không lọc.
  String? toServerParam() => switch (this) {
    live => 'ONGOING',
    scheduled => 'SCHEDULED',
    completed => 'COMPLETED',
    all => null,
  };

  bool accepts(MatchModel match) => switch (this) {
    live => match.isLive,
    scheduled => match.isScheduled && !match.isCompleted,
    completed => match.isCompleted,
    all => true,
  };
}
