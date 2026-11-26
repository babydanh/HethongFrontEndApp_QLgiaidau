import 'dart:async';

import 'package:app_quanly_giaidau/domain/services/camera_rtsp_url.dart';
import 'package:app_quanly_giaidau/features/camera_bridge/ffmpeg_runner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BridgeStatus { idle, connecting, live, error }

/// What the user typed for one camera plus the push address the backend issued
/// for it. The password lives only in memory: it is never persisted or logged.
class BridgeStartParams {
  const BridgeStartParams({
    required this.brand,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.mainStream,
    required this.rtmpServer,
    required this.rtmpStreamKey,
  });

  final CameraBrand brand;
  final String host;
  final int port;
  final String user;
  final String password;
  final bool mainStream;
  final String rtmpServer;
  final String rtmpStreamKey;

  BridgeStartParams copyWith({String? host}) => BridgeStartParams(
    brand: brand,
    host: host ?? this.host,
    port: port,
    user: user,
    password: password,
    mainStream: mainStream,
    rtmpServer: rtmpServer,
    rtmpStreamKey: rtmpStreamKey,
  );
}

class CameraBridgeState {
  const CameraBridgeState({
    this.status = BridgeStatus.idle,
    this.failure,
    this.attempt = 0,
  });

  final BridgeStatus status;

  /// Set only while [status] is [BridgeStatus.error].
  final BridgeFailure? failure;

  /// Reconnect attempts since the stream was last live.
  final int attempt;
}

/// Makes one FFmpeg runner per camera, so two cameras never share a process.
final ffmpegRunnerFactoryProvider = Provider<FfmpegRunner Function()>(
  (ref) =>
      () => throw UnimplementedError('No FFmpeg runner is wired in yet'),
);

/// Waits between reconnect attempts; replaced in tests.
final bridgeDelayProvider = Provider<Future<void> Function(Duration)>(
  (ref) => Future<void>.delayed,
);

/// One bridge per camera id; the family keeps each alive while the user moves
/// between screens.
final cameraBridgeProvider =
    NotifierProvider.family<CameraBridgeNotifier, CameraBridgeState, String>(
      CameraBridgeNotifier.new,
    );

const _maxBackoff = Duration(seconds: 30);

/// 2s, 4s, 8s, 16s, then 30s for every later attempt.
Duration cameraBridgeBackoff(int attempt) {
  if (attempt >= 5) return _maxBackoff;
  return Duration(seconds: 1 << attempt);
}

class CameraBridgeNotifier extends Notifier<CameraBridgeState> {
  CameraBridgeNotifier(this.cameraId);

  final String cameraId;
  FfmpegRunner? _runner;

  /// Bumped by every start and stop; a loop that sees another value is stale.
  int _runId = 0;
  int _attempt = 0;

  @override
  CameraBridgeState build() {
    ref.onDispose(() {
      _runId++;
      unawaited(_runner?.stop());
    });
    return const CameraBridgeState();
  }

  /// Returns when the bridge ends: after [stop], or on a failure retrying
  /// cannot fix. A second call while running is ignored.
  Future<void> start(BridgeStartParams params) async {
    final status = state.status;
    if (status != BridgeStatus.idle && status != BridgeStatus.error) return;

    final String rtspUrl;
    try {
      rtspUrl = buildCameraRtspUrl(
        brand: params.brand,
        host: params.host,
        port: params.port,
        user: params.user,
        password: params.password,
        mainStream: params.mainStream,
      );
    } on ArgumentError {
      state = const CameraBridgeState(
        status: BridgeStatus.error,
        failure: BridgeFailure.invalidInput,
      );
      return;
    }
    final server = params.rtmpServer.replaceAll(RegExp(r'/+$'), '');
    final rtmpUrl = '$server/${params.rtmpStreamKey}';

    final FfmpegRunner runner;
    try {
      runner = ref.read(ffmpegRunnerFactoryProvider)();
    } on UnimplementedError {
      state = const CameraBridgeState(
        status: BridgeStatus.error,
        failure: BridgeFailure.unsupported,
      );
      return;
    }
    final runId = ++_runId;
    _attempt = 0;
    _runner = runner;
    state = const CameraBridgeState(status: BridgeStatus.connecting);
    await _loop(rtspUrl, rtmpUrl, runId);
  }

  Future<void> stop() async {
    if (state.status == BridgeStatus.idle) return;
    _runId++;
    await _runner?.stop();
    state = const CameraBridgeState();
  }

  Future<void> _loop(String rtspUrl, String rtmpUrl, int runId) async {
    while (runId == _runId) {
      final failure = await _runOnce(rtspUrl, rtmpUrl, runId);
      if (runId != _runId) return;
      if (failure != null && !failure.retryable) {
        state = CameraBridgeState(status: BridgeStatus.error, failure: failure);
        return;
      }
      _attempt++;
      state = CameraBridgeState(
        status: BridgeStatus.connecting,
        attempt: _attempt,
      );
      await ref.read(bridgeDelayProvider)(cameraBridgeBackoff(_attempt));
    }
  }

  /// Runs FFmpeg once. Returns the reported failure, or null when the stream
  /// simply ended (a dropped connection).
  Future<BridgeFailure?> _runOnce(
    String rtspUrl,
    String rtmpUrl,
    int runId,
  ) async {
    final runner = _runner!;
    BridgeFailure? failure;
    await for (final event in runner.run(rtspUrl, rtmpUrl)) {
      switch (event) {
        case BridgeLive():
          _attempt = 0;
          if (runId == _runId) {
            state = const CameraBridgeState(status: BridgeStatus.live);
          }
        case BridgeFailed(failure: final reported):
          failure = reported;
      }
      if (failure != null) break;
    }
    // Stop only after leaving the loop: a runner that waits for its stream to
    // close would otherwise wait on this very subscription.
    if (failure != null) await runner.stop();
    return failure;
  }
}
