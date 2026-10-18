import 'dart:async';

import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_playback_repository.dart';
import 'package:app_quanly_giaidau/features/match/utils/live_stream_stats_format.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Đo Ping của [url] (ms), hoặc null nếu lỗi, quá hạn hoặc manifest quá lớn.
typedef LiveStreamPingProbe = Future<int?> Function(Dio dio, String url);

/// Điểm nối để test thay probe thật. Mặc định đo bằng GET thật.
final liveStreamPingProbeProvider = Provider<LiveStreamPingProbe>(
  (ref) => measureManifestPingMs,
);

/// Giới hạn đọc manifest. HLS manifest nhỏ; vượt mức này thì huỷ và coi như lỗi.
const liveManifestMaxBytes = 64 * 1024;

/// Tổng thời gian tối đa cho một lần đo Ping.
const livePingTimeout = Duration(seconds: 4);

/// GET [url] (manifest HLS) bằng [dio] riêng của huy hiệu, không interceptor và
/// không token. Ping là thời gian tính từ lúc gửi tới khi nhận xong manifest.
/// Nếu đọc quá [liveManifestMaxBytes] hoặc quá [livePingTimeout] thì huỷ bằng
/// [CancelToken] và trả null.
Future<int?> measureManifestPingMs(Dio dio, String url) async {
  final cancelToken = CancelToken();
  final watch = Stopwatch()..start();
  try {
    await dio
        .get<String>(
          url,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.plain,
            headers: const {'Cache-Control': 'no-cache'},
          ),
          onReceiveProgress: (received, _) {
            if (received > liveManifestMaxBytes) {
              cancelToken.cancel('manifest quá lớn');
            }
          },
        )
        .timeout(
          livePingTimeout,
          onTimeout: () {
            cancelToken.cancel('ping quá hạn');
            throw TimeoutException('ping quá hạn');
          },
        );
    watch.stop();
    return watch.elapsedMilliseconds;
  } on Object {
    if (!cancelToken.isCancelled) cancelToken.cancel();
    return null;
  }
}

/// Huy hiệu Ping · Trễ · FPS đè góc trên trái khung video (chỉ owner/admin).
///
/// - Ping: chỉ đo khi URL là HLS `.m3u8`. Luồng khác (ví dụ HTTP-FLV) không gọi
///   mạng và hiện `—`.
/// - Trễ: phần đã tải trước điểm đang phát (buffer), không phải độ trễ camera.
/// - FPS: số máy media báo qua stream-info. Chưa đo được thì `—`.
class LiveStreamStatsBadge extends ConsumerStatefulWidget {
  const LiveStreamStatsBadge({
    super.key,
    required this.matchId,
    required this.url,
    required this.controller,
  });

  final String matchId;
  final String url;

  /// Controller của player; null khi player chưa khởi tạo xong.
  final VideoPlayerController? controller;

  @override
  ConsumerState<LiveStreamStatsBadge> createState() =>
      _LiveStreamStatsBadgeState();
}

class _LiveStreamStatsBadgeState extends ConsumerState<LiveStreamStatsBadge> {
  static const _pingInterval = Duration(seconds: 5);
  static const _latencyInterval = Duration(seconds: 1);
  static const _fpsInterval = Duration(seconds: 10);

  final Dio _probeDio = Dio(
    BaseOptions(
      connectTimeout: livePingTimeout,
      receiveTimeout: livePingTimeout,
    ),
  );

  Timer? _pingTimer;
  Timer? _latencyTimer;
  Timer? _fpsTimer;
  int? _pingMs;
  int? _latencyMs;
  double? _fps;
  bool _pingBusy = false;
  bool _fpsBusy = false;

  // Tăng mỗi lần đổi nguồn/trận: kết quả đo của lần trước bị bỏ qua.
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant LiveStreamStatsBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.matchId != widget.matchId) {
      _restart();
    } else if (oldWidget.controller != widget.controller) {
      // Đang trong build nên chỉ gán field, không gọi setState.
      _latencyMs = _currentLatencyMs();
    }
  }

  @override
  void dispose() {
    _epoch++;
    _pingTimer?.cancel();
    _latencyTimer?.cancel();
    _fpsTimer?.cancel();
    _probeDio.close(force: true);
    super.dispose();
  }

  /// Đặt lại số liệu và lịch đo khi đổi nguồn hoặc trận.
  void _restart() {
    _epoch++;
    _pingTimer?.cancel();
    _latencyTimer?.cancel();
    _fpsTimer?.cancel();
    _pingBusy = false;
    _fpsBusy = false;
    _pingMs = null;
    _fps = null;
    _latencyMs = _currentLatencyMs();

    _pingTimer = Timer.periodic(_pingInterval, (_) => _probePing());
    _latencyTimer = Timer.periodic(_latencyInterval, (_) => _onLatencyTick());
    _fpsTimer = Timer.periodic(_fpsInterval, (_) => _loadFps());
    _probePing();
    _loadFps();
  }

  void _probePing() {
    // Không phải HLS manifest: không gọi mạng, Ping giữ `—`.
    if (_pingBusy || !shouldMeasurePingFor(widget.url)) return;
    _pingBusy = true;
    final probe = ref.read(liveStreamPingProbeProvider);
    unawaited(_runPingProbe(probe, widget.url, _epoch));
  }

  Future<void> _runPingProbe(
    LiveStreamPingProbe probe,
    String url,
    int epoch,
  ) async {
    int? ms;
    try {
      ms = await probe(_probeDio, url);
    } on Object {
      ms = null;
    }
    if (epoch != _epoch) return;
    _pingBusy = false;
    if (!mounted) return;
    setState(() => _pingMs = ms);
  }

  void _loadFps() {
    if (_fpsBusy) return;
    _fpsBusy = true;
    final repository = ApiMatchPlaybackRepository(ref.read(dioClientProvider));
    unawaited(_runFpsLoad(repository, widget.matchId, _epoch));
  }

  Future<void> _runFpsLoad(
    ApiMatchPlaybackRepository repository,
    String matchId,
    int epoch,
  ) async {
    double? fps;
    try {
      fps = (await repository.getMatchStreamInfo(matchId)).fps;
    } on Object {
      fps = null;
    }
    if (epoch != _epoch) return;
    _fpsBusy = false;
    if (!mounted) return;
    setState(() => _fps = fps);
  }

  void _onLatencyTick() {
    final ms = _currentLatencyMs();
    if (ms != _latencyMs) setState(() => _latencyMs = ms);
  }

  /// Trễ = phần đã buffer phía trước vị trí phát (không phải độ trễ camera).
  int? _currentLatencyMs() {
    final value = widget.controller?.value;
    if (value == null || value.buffered.isEmpty) return null;
    return liveLatencyMs(
      bufferedEnd: value.buffered.last.end,
      position: value.position,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = formatLiveStreamStats(
      pingMs: _pingMs,
      latencyMs: _latencyMs,
      fps: _fps,
    );
    final label = l10n.liveStreamStatsBadge(text.ping, text.latency, text.fps);
    return IgnorePointer(
      key: const ValueKey('live-stream-stats'),
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
