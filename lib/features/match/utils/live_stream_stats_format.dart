// Công thức và định dạng của huy hiệu thông số luồng.
//
// Thuần Dart (không import Flutter hay video_player) để test không cần player.

const _notMeasured = '—';

/// Chỉ đo Ping khi URL là HLS manifest (`.m3u8`, query bỏ qua khi so). Luồng
/// khác, ví dụ HTTP-FLV, tải mãi không dừng nên KHÔNG được gọi mạng; Ping hiển
/// thị `—`.
bool shouldMeasurePingFor(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasAuthority) return false;
  if (uri.scheme != 'https' && uri.scheme != 'http') return false;
  return uri.path.toLowerCase().endsWith('.m3u8');
}

/// Trễ trên App (ms) = phần đã tải trước điểm đang phát (mép cuối vùng buffer
/// trừ vị trí phát). Đây KHÔNG phải độ trễ từ camera tới người xem. Trả null khi
/// chưa có vùng buffer hoặc kết quả âm.
int? liveLatencyMs({
  required Duration? bufferedEnd,
  required Duration position,
}) {
  if (bufferedEnd == null) return null;
  final lag = bufferedEnd - position;
  if (lag.isNegative) return null;
  return lag.inMilliseconds;
}

/// Chuỗi hiển thị của từng chỉ số. Chưa đo được thì là `—`.
typedef LiveStreamStatsText = ({String ping, String latency, String fps});

LiveStreamStatsText formatLiveStreamStats({
  int? pingMs,
  int? latencyMs,
  double? fps,
}) {
  return (
    ping: pingMs == null ? _notMeasured : '$pingMs ms',
    latency: latencyMs == null ? _notMeasured : '$latencyMs ms',
    fps: fps == null ? _notMeasured : _formatFps(fps),
  );
}

/// FPS nguyên thì không có phần thập phân (30); còn lại giữ 2 chữ số (29.97).
String _formatFps(double fps) {
  if (fps == fps.roundToDouble()) return fps.toInt().toString();
  return fps.toStringAsFixed(2);
}
