import 'package:app_quanly_giaidau/domain/services/camera_rtsp_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCameraRtspUrl', () {
    test('TC-CAMBR-01 dahua main stream uses realmonitor subtype 0', () {
      final url = buildCameraRtspUrl(
        brand: CameraBrand.dahua,
        host: '192.168.1.50',
        port: 554,
        user: 'admin',
        password: 'secret',
        mainStream: true,
      );
      expect(
        url,
        'rtsp://admin:secret@192.168.1.50:554/cam/realmonitor?channel=1&subtype=0',
      );
    });

    test('TC-CAMBR-02 dahua sub stream uses subtype 1', () {
      final url = buildCameraRtspUrl(
        brand: CameraBrand.dahua,
        host: '192.168.1.50',
        port: 554,
        user: 'admin',
        password: 'secret',
        mainStream: false,
      );
      expect(url, endsWith('/cam/realmonitor?channel=1&subtype=1'));
    });

    test('TC-CAMBR-03 hikvision main and sub stream channels', () {
      String build(bool main) => buildCameraRtspUrl(
            brand: CameraBrand.hikvision,
            host: '10.0.0.8',
            port: 554,
            user: 'admin',
            password: 'secret',
            mainStream: main,
          );
      expect(build(true), 'rtsp://admin:secret@10.0.0.8:554/Streaming/Channels/101');
      expect(build(false), 'rtsp://admin:secret@10.0.0.8:554/Streaming/Channels/102');
    });

    test('TC-CAMBR-04 special characters in user and password are percent-encoded', () {
      final url = buildCameraRtspUrl(
        brand: CameraBrand.dahua,
        host: '192.168.1.50',
        port: 554,
        user: 'ad@min',
        password: 'p:a/s@s',
        mainStream: true,
      );
      expect(url, startsWith('rtsp://ad%40min:p%3Aa%2Fs%40s@192.168.1.50:554/'));
      // The userinfo must still split into exactly one host.
      expect(Uri.parse(url).host, '192.168.1.50');
      expect(Uri.parse(url).port, 554);
    });

    test('TC-CAMBR-05 blank host is rejected', () {
      expect(
        () => buildCameraRtspUrl(
          brand: CameraBrand.dahua,
          host: '  ',
          port: 554,
          user: 'admin',
          password: 'x',
          mainStream: true,
        ),
        throwsArgumentError,
      );
    });

    test('TC-CAMBR-06 port outside 1..65535 is rejected', () {
      expect(
        () => buildCameraRtspUrl(
          brand: CameraBrand.dahua,
          host: '192.168.1.50',
          port: 70000,
          user: 'admin',
          password: 'x',
          mainStream: true,
        ),
        throwsArgumentError,
      );
    });
  });

  group('redactRtspCredentials', () {
    test('TC-CAMBR-07 removes userinfo from every rtsp url in a log line', () {
      const line =
          'Error opening input rtsp://admin:secret@192.168.1.50:554/cam/realmonitor?channel=1&subtype=0: '
          'Server returned 401 (rtsp://u:p%40ss@10.0.0.8:554/x)';
      final safe = redactRtspCredentials(line);
      expect(safe, isNot(contains('secret')));
      expect(safe, isNot(contains('p%40ss')));
      expect(safe, contains('rtsp://***@192.168.1.50:554/'));
      expect(safe, contains('rtsp://***@10.0.0.8:554/'));
    });

    test('TC-CAMBR-08 leaves text without credentials unchanged', () {
      const line = 'Input #0, rtsp, from camera';
      expect(redactRtspCredentials(line), line);
    });
  });
}
