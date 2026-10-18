import 'dart:async';

import 'package:app_quanly_giaidau/features/match/utils/live_stream_stats_format.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Huy hiệu Ping đè góc trên trái khung video (chỉ owner/admin).
///
/// Ping chỉ đo khi URL là HLS `.m3u8`. Luồng khác (ví dụ HTTP-FLV) không gọi
/// mạng và hiện `—`.
class LiveStreamStatsBadge extends ConsumerStatefulWidget {
  const LiveStreamStatsBadge({super.key, required this.url});

  final String url;

  @override
  ConsumerState<LiveStreamStatsBadge> createState() =>
      _LiveStreamStatsBadgeState();
}

class _LiveStreamStatsBadgeState extends ConsumerState<LiveStreamStatsBadge> {
  static const _pingInterval = Duration(seconds: 5);

  final Dio _probeDio = Dio(
    BaseOptions(
      connectTimeout: livePingTimeout,
      receiveTimeout: livePingTimeout,
    ),
  );

  Timer? _pingTimer;
  int? _pingMs;
  bool _pingBusy = false;

  // Tăng mỗi lần đổi nguồn: kết quả đo của lần trước bị bỏ qua.
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant LiveStreamStatsBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _restart();
  }

  @override
  void dispose() {
    _epoch++;
    _pingTimer?.cancel();
    _probeDio.close(force: true);
    super.dispose();
  }

  /// Đặt lại số liệu và lịch đo khi đổi nguồn.
  void _restart() {
    _epoch++;
    _pingTimer?.cancel();
    _pingBusy = false;
    _pingMs = null;

    _pingTimer = Timer.periodic(_pingInterval, (_) => _probePing());
    _probePing();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = l10n.liveStreamStatsBadge(formatLivePing(_pingMs));
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
