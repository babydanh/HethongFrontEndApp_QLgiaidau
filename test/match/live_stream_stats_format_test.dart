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

  group('formatLivePing', () {
    test('chưa đo được thì hiện —', () {
      expect(formatLivePing(null), '—');
    });

    test('đã đo thì hiện số ms nguyên', () {
      expect(formatLivePing(42), '42 ms');
    });
  });
}
