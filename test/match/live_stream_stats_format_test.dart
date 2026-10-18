import 'package:app_quanly_giaidau/features/match/utils/live_stream_stats_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldMeasurePingFor', () {
    test('đo khi đường dẫn kết thúc .m3u8, query bị bỏ qua', () {
      expect(
        shouldMeasurePingFor('https://cdn.example.test/live/index.m3u8'),
        isTrue,
      );
      expect(
        shouldMeasurePingFor(
          'https://cdn.example.test/live/index.m3u8?token=abc',
        ),
        isTrue,
      );
      expect(
        shouldMeasurePingFor('https://cdn.example.test/live/INDEX.M3U8'),
        isTrue,
      );
    });

    test('luồng không phải HLS (ví dụ .flv) không đo, không gọi mạng', () {
      expect(
        shouldMeasurePingFor('https://cdn.example.test/live/stream.flv'),
        isFalse,
      );
      expect(
        shouldMeasurePingFor('https://cdn.example.test/live/stream.flv?m3u8=1'),
        isFalse,
      );
    });

    test('URL thiếu host hoặc scheme không phải http(s) thì không đo', () {
      expect(shouldMeasurePingFor('index.m3u8'), isFalse);
      expect(
        shouldMeasurePingFor('ftp://cdn.example.test/index.m3u8'),
        isFalse,
      );
    });
  });

  group('liveLatencyMs', () {
    test('trễ là phần đã tải trước điểm đang phát, tính bằng ms', () {
      expect(
        liveLatencyMs(
          bufferedEnd: const Duration(seconds: 12),
          position: const Duration(seconds: 10),
        ),
        2000,
      );
    });

    test('chưa có vùng buffer thì trả null', () {
      expect(
        liveLatencyMs(bufferedEnd: null, position: const Duration(seconds: 10)),
        isNull,
      );
    });

    test('điểm phát vượt mép buffer thì trả null, không trả số âm', () {
      expect(
        liveLatencyMs(
          bufferedEnd: const Duration(seconds: 9),
          position: const Duration(seconds: 10),
        ),
        isNull,
      );
    });
  });

  group('formatLiveStreamStats', () {
    test('chưa đo được thì mọi chỉ số hiện —', () {
      final text = formatLiveStreamStats();
      expect(text.ping, '—');
      expect(text.latency, '—');
      expect(text.fps, '—');
    });

    test('FPS nguyên không có phần thập phân, FPS lẻ giữ 2 chữ số', () {
      final whole = formatLiveStreamStats(pingMs: 42, latencyMs: 1500, fps: 30);
      expect(whole.ping, '42 ms');
      expect(whole.latency, '1500 ms');
      expect(whole.fps, '30');

      final fractional = formatLiveStreamStats(fps: 29.97);
      expect(fractional.fps, '29.97');
    });
  });
}
