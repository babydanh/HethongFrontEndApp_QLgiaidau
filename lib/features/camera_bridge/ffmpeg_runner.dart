/// The seam between the bridge logic and the FFmpeg process. The notifier only
/// knows this interface, so the logic is testable without FFmpeg installed.
library;

enum BridgeFailure {
  /// Wrong username or password.
  auth(retryable: false),

  /// The camera is not reachable from this device (wrong IP, other network).
  unreachable(retryable: true),

  /// The stream is not H.264 (for example H.265), which RTMP cannot carry.
  codec(retryable: false),

  /// The camera data the user typed cannot form an address.
  invalidInput(retryable: false),

  other(retryable: true);

  const BridgeFailure({required this.retryable});

  /// Whether trying again can change the outcome.
  final bool retryable;
}

sealed class BridgeEvent {
  const BridgeEvent();
}

/// The first frame was pushed: the stream is live.
class BridgeLive extends BridgeEvent {
  const BridgeLive();
}

/// FFmpeg stopped with a known reason. The stream ending without this event
/// is treated as a dropped connection.
class BridgeFailed extends BridgeEvent {
  const BridgeFailed(this.failure);

  final BridgeFailure failure;
}

abstract class FfmpegRunner {
  /// Pulls [rtspUrl] and pushes it to [rtmpUrl] without re-encoding. The
  /// returned stream ends when the process ends. Both URLs hold credentials:
  /// implementations must never log them.
  Stream<BridgeEvent> run(String rtspUrl, String rtmpUrl);

  /// Ends the running process; the stream returned by [run] then completes.
  Future<void> stop();
}

/// Maps one line of FFmpeg output to a failure kind. The line is only
/// inspected, never stored or shown, because FFmpeg echoes the input URL.
BridgeFailure classifyFfmpegLog(String line) {
  final text = line.toLowerCase();
  if (text.contains('401') || text.contains('unauthorized')) {
    return BridgeFailure.auth;
  }
  if (text.contains('hevc') || text.contains('h.265')) {
    return BridgeFailure.codec;
  }
  if (text.contains('timed out') ||
      text.contains('no route to host') ||
      text.contains('connection refused') ||
      text.contains('network is unreachable')) {
    return BridgeFailure.unreachable;
  }
  return BridgeFailure.other;
}
