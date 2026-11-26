import 'dart:async';

import 'package:app_quanly_giaidau/domain/services/camera_rtsp_url.dart';
import 'package:app_quanly_giaidau/features/camera_bridge/camera_bridge_notifier.dart';
import 'package:app_quanly_giaidau/features/camera_bridge/ffmpeg_runner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for FFmpeg: records what it was asked to run and lets the test
/// push events into the running stream.
class FakeFfmpegRunner implements FfmpegRunner {
  final List<({String rtsp, String rtmp})> runs = [];
  final List<StreamController<BridgeEvent>> controllers = [];
  int stops = 0;

  StreamController<BridgeEvent> get current => controllers.last;

  @override
  Stream<BridgeEvent> run(String rtspUrl, String rtmpUrl) {
    runs.add((rtsp: rtspUrl, rtmp: rtmpUrl));
    final controller = StreamController<BridgeEvent>();
    controllers.add(controller);
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
    if (controllers.isNotEmpty && !current.isClosed) await current.close();
  }
}

const _params = BridgeStartParams(
  brand: CameraBrand.dahua,
  host: '192.168.1.50',
  port: 554,
  user: 'admin',
  password: 'secret',
  mainStream: true,
  rtmpServer: 'rtmp://media.example.net/live',
  rtmpStreamKey: 'key123',
);

const _cam = 'cam-1';

Future<void> pump() => Future<void>.delayed(Duration.zero);

({
  ProviderContainer container,
  FakeFfmpegRunner runner,
  List<FakeFfmpegRunner> runners,
  List<Duration> delays,
})
_setup() {
  // The first camera gets [runner]; every other camera gets a fresh fake.
  final runner = FakeFfmpegRunner();
  final runners = <FakeFfmpegRunner>[runner];
  var created = 0;
  final delays = <Duration>[];
  final container = ProviderContainer(
    overrides: [
      ffmpegRunnerFactoryProvider.overrideWithValue(() {
        if (created++ == 0) return runner;
        final next = FakeFfmpegRunner();
        runners.add(next);
        return next;
      }),
      bridgeDelayProvider.overrideWithValue((d) async {
        delays.add(d);
        await pump();
      }),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, runner: runner, runners: runners, delays: delays);
}

void main() {
  group('CameraBridgeNotifier', () {
    test('TC-CAMBR-10 start builds both urls, goes connecting then live', () async {
      final s = _setup();
      final notifier = s.container.read(cameraBridgeProvider(_cam).notifier);

      unawaited(notifier.start(_params));
      await pump();

      expect(s.container.read(cameraBridgeProvider(_cam)).status, BridgeStatus.connecting);
      expect(s.runner.runs, hasLength(1));
      expect(
        s.runner.runs.single.rtsp,
        'rtsp://admin:secret@192.168.1.50:554/cam/realmonitor?channel=1&subtype=0',
      );
      expect(s.runner.runs.single.rtmp, 'rtmp://media.example.net/live/key123');

      s.runner.current.add(const BridgeLive());
      await pump();
      expect(s.container.read(cameraBridgeProvider(_cam)).status, BridgeStatus.live);
    });

    test('TC-CAMBR-11 double start runs a single ffmpeg process', () async {
      final s = _setup();
      final notifier = s.container.read(cameraBridgeProvider(_cam).notifier);

      unawaited(notifier.start(_params));
      unawaited(notifier.start(_params));
      await pump();

      expect(s.runner.runs, hasLength(1));
    });

    test('TC-CAMBR-12 blank host fails without running ffmpeg', () async {
      final s = _setup();
      final notifier = s.container.read(cameraBridgeProvider(_cam).notifier);

      await notifier.start(_params.copyWith(host: ' '));

      final state = s.container.read(cameraBridgeProvider(_cam));
      expect(state.status, BridgeStatus.error);
      expect(state.failure, BridgeFailure.invalidInput);
      expect(s.runner.runs, isEmpty);
    });

    test('TC-CAMBR-13 auth failure stops without retrying', () async {
      final s = _setup();
      final notifier = s.container.read(cameraBridgeProvider(_cam).notifier);

      unawaited(notifier.start(_params));
      await pump();
      s.runner.current.add(const BridgeFailed(BridgeFailure.auth));
      await pump();
      await pump();

      final state = s.container.read(cameraBridgeProvider(_cam));
      expect(state.status, BridgeStatus.error);
      expect(state.failure, BridgeFailure.auth);
      expect(s.runner.runs, hasLength(1));
      expect(s.delays, isEmpty);
    });

    test('TC-CAMBR-14 a dropped stream is retried with backoff, one process at a time', () async {
      final s = _setup();
      final notifier = s.container.read(cameraBridgeProvider(_cam).notifier);

      unawaited(notifier.start(_params));
      await pump();
      s.runner.current.add(const BridgeLive());
      await pump();

      // Network drop: the stream ends on its own.
      await s.runner.current.close();
      await pump();
      await pump();

      expect(s.delays, [const Duration(seconds: 2)]);
      expect(s.runner.runs, hasLength(2));
      expect(s.container.read(cameraBridgeProvider(_cam)).status, BridgeStatus.connecting);

      s.runner.current.add(const BridgeLive());
      await pump();
      expect(s.container.read(cameraBridgeProvider(_cam)).status, BridgeStatus.live);
    });

    test('TC-CAMBR-15 stop returns to idle and stops retrying', () async {
      final s = _setup();
      final notifier = s.container.read(cameraBridgeProvider(_cam).notifier);

      unawaited(notifier.start(_params));
      await pump();
      s.runner.current.add(const BridgeLive());
      await pump();

      await notifier.stop();
      await pump();
      await pump();

      expect(s.container.read(cameraBridgeProvider(_cam)).status, BridgeStatus.idle);
      expect(s.runner.stops, 1);
      expect(s.runner.runs, hasLength(1));
    });

    test('TC-CAMBR-16 start works again after an error', () async {
      final s = _setup();
      final notifier = s.container.read(cameraBridgeProvider(_cam).notifier);

      unawaited(notifier.start(_params));
      await pump();
      s.runner.current.add(const BridgeFailed(BridgeFailure.auth));
      await pump();
      await pump();

      unawaited(notifier.start(_params));
      await pump();

      expect(s.runner.runs, hasLength(2));
      expect(s.container.read(cameraBridgeProvider(_cam)).status, BridgeStatus.connecting);
    });
  });

  group('without a real ffmpeg runner', () {
    test('TC-CAMBR-22 start reports unsupported instead of throwing', () async {
      final container = ProviderContainer(
        overrides: [
          ffmpegRunnerFactoryProvider.overrideWithValue(
            () => throw UnimplementedError(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(cameraBridgeProvider(_cam).notifier);

      await notifier.start(_params);

      final state = container.read(cameraBridgeProvider(_cam));
      expect(state.status, BridgeStatus.error);
      expect(state.failure, BridgeFailure.unsupported);
      expect(BridgeFailure.unsupported.retryable, isFalse);
    });
  });

  group('two cameras of one tournament', () {
    test('TC-CAMBR-20 each camera runs and stops on its own', () async {
      final s = _setup();
      final cam1 = s.container.read(cameraBridgeProvider('cam-1').notifier);
      final cam2 = s.container.read(cameraBridgeProvider('cam-2').notifier);

      unawaited(cam1.start(_params));
      unawaited(cam2.start(_params.copyWith(host: '192.168.1.51')));
      await pump();

      expect(s.runners, hasLength(2));
      expect(s.runners[0].runs.single.rtsp, contains('@192.168.1.50:'));
      expect(s.runners[1].runs.single.rtsp, contains('@192.168.1.51:'));

      s.runners[0].current.add(const BridgeLive());
      s.runners[1].current.add(const BridgeLive());
      await pump();

      await cam1.stop();
      await pump();

      expect(
        s.container.read(cameraBridgeProvider('cam-1')).status,
        BridgeStatus.idle,
      );
      expect(
        s.container.read(cameraBridgeProvider('cam-2')).status,
        BridgeStatus.live,
      );
      expect(s.runners[0].stops, 1);
      expect(s.runners[1].stops, 0);
    });

    test('TC-CAMBR-21 one camera failing does not stop the other', () async {
      final s = _setup();
      final cam1 = s.container.read(cameraBridgeProvider('cam-1').notifier);
      final cam2 = s.container.read(cameraBridgeProvider('cam-2').notifier);

      unawaited(cam1.start(_params));
      unawaited(cam2.start(_params));
      await pump();
      s.runners[1].current.add(const BridgeLive());
      s.runners[0].current.add(const BridgeFailed(BridgeFailure.auth));
      await pump();
      await pump();

      expect(
        s.container.read(cameraBridgeProvider('cam-1')).status,
        BridgeStatus.error,
      );
      expect(
        s.container.read(cameraBridgeProvider('cam-2')).status,
        BridgeStatus.live,
      );
    });
  });

  group('cameraBridgeBackoff', () {
    test('TC-CAMBR-17 doubles from 2s and caps at 30s', () {
      expect(cameraBridgeBackoff(1), const Duration(seconds: 2));
      expect(cameraBridgeBackoff(2), const Duration(seconds: 4));
      expect(cameraBridgeBackoff(4), const Duration(seconds: 16));
      expect(cameraBridgeBackoff(5), const Duration(seconds: 30));
      expect(cameraBridgeBackoff(40), const Duration(seconds: 30));
    });
  });

  group('classifyFfmpegLog', () {
    test('TC-CAMBR-18 maps ffmpeg output to a failure kind', () {
      expect(classifyFfmpegLog('Server returned 401 Unauthorized'), BridgeFailure.auth);
      expect(classifyFfmpegLog('Connection timed out'), BridgeFailure.unreachable);
      expect(classifyFfmpegLog('No route to host'), BridgeFailure.unreachable);
      expect(classifyFfmpegLog('Stream #0:0: Video: hevc (Main)'), BridgeFailure.codec);
      expect(classifyFfmpegLog('something else entirely'), BridgeFailure.other);
    });

    test('TC-CAMBR-19 failure kinds say whether a retry can help', () {
      expect(BridgeFailure.auth.retryable, isFalse);
      expect(BridgeFailure.codec.retryable, isFalse);
      expect(BridgeFailure.invalidInput.retryable, isFalse);
      expect(BridgeFailure.unreachable.retryable, isTrue);
      expect(BridgeFailure.other.retryable, isTrue);
    });
  });
}
