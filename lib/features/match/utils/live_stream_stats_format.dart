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

/// Chuỗi hiển thị của Ping. Chưa đo được thì là `—`.
String formatLivePing(int? pingMs) =>
    pingMs == null ? _notMeasured : '$pingMs ms';
