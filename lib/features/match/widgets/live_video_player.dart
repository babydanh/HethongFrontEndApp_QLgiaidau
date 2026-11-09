import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/pip_service.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_stream_stats_badge.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// How far behind the live edge playback may drift before "Back to live" shows.
const liveEdgeThreshold = Duration(seconds: 8);

/// True when playback trails the live edge by more than [threshold]. An unknown
/// duration (non-seekable live stream) is never "behind".
bool isBehindLive({
  required Duration position,
  required Duration duration,
  Duration threshold = liveEdgeThreshold,
}) {
  if (duration <= Duration.zero) return false;
  return duration - position > threshold;
}

/// Trình phát luồng trực tiếp.
///
/// Vùng chạm nút đặt 48dp — chuẩn Material cho mục tiêu chạm, nhỏ hơn thì dễ
/// trượt khi xem bằng một tay. Nút chỉ dùng icon, nhãn nằm trong
/// [Semantics] để trình đọc màn hình vẫn đọc được chứ không chỉ dựa vào hình.
class LiveVideoPlayer extends StatefulWidget {
  const LiveVideoPlayer({
    super.key,
    required this.url,
    this.label,
    this.showStreamStats = false,
    this.fill = false,
    this.fullscreen = false,
    this.onToggleFullscreen,
    this.showLiveDot = false,
    this.onControlsVisibleChanged,
    this.pipService,
    this.onAspectRatioChanged,
  });

  final String url;

  /// Reports whether the control bar is up, so overlays can make room.
  final ValueChanged<bool>? onControlsVisibleChanged;

  /// Picture-in-picture bridge; defaults to the app-wide one.
  final PipService? pipService;

  /// Called with the stream's real width / height once it is known, so the
  /// page can lay its overlays over the picture itself.
  final ValueChanged<double>? onAspectRatioChanged;

  /// Fill the parent's bounded height instead of sizing by aspect ratio
  /// (landscape fullscreen).
  final bool fill;

  /// Current fullscreen state, only used to pick the button icon.
  final bool fullscreen;

  /// Shows a fullscreen button when set.
  final VoidCallback? onToggleFullscreen;

  /// Tên sân/camera, hiện ở góc phải. Rỗng thì không hiện.
  final String? label;

  /// Hiện huy hiệu Ping góc trên trái (màn live quyết định cờ này).
  final bool showStreamStats;

  /// Chấm LIVE cạnh nút âm thanh: đỏ khi đang ở mép trực tiếp, xám khi xem
  /// trễ (bấm để về live). Thay cho nhãn chữ "LIVE" ở header.
  final bool showLiveDot;

  @override
  State<LiveVideoPlayer> createState() => _LiveVideoPlayerState();
}

class _LiveVideoPlayerState extends State<LiveVideoPlayer> {
  static const _hideDelay = Duration(seconds: 3);

  VideoPlayerController? _controller;
  Timer? _hideTimer;
  // A phone has no autoplay block for sound, so the stream opens with sound
  // on like the Web replay; the sound button still mutes.
  bool _muted = false;
  bool? _reportedVisible;
  bool _pipSupported = false;

  PipService get _pip => widget.pipService ?? PipService.instance;

  /// Tỉ lệ khung hình của luồng. Lúc stream chưa có metadata thì tạm dùng 16/9,
  /// rồi thay bằng tỉ lệ thật ngay khi player khởi tạo xong.
  double _aspectRatio = 16 / 9;
  bool _playing = false;
  bool _controlsVisible = true;
  bool _behindLive = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pip.active.addListener(_onPipChanged);
    _pip.isSupported().then((supported) {
      if (mounted && supported) setState(() => _pipSupported = true);
    });
    _initPlayer();
  }

  void _onPipChanged() {
    if (mounted) setState(() {});
  }

  /// The button only works once a frame exists to float.
  bool get _hasFrame {
    final value = _controller?.value;
    return value != null && value.isInitialized && value.size.width > 0;
  }

  Future<void> _enterPip() async {
    _revealControls();
    await _pip.enter();
  }

  @override
  void didUpdateWidget(covariant LiveVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      // Đổi trận là đổi nguồn phát: dựng lại controller, đưa zoom về mức đầu để
      // khán giả không bị ảnh phóng to kẹt từ trận trước.
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    _hideTimer?.cancel();
    final previous = _controller;
    _controller = null;

    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      // Tỉ lệ thật chỉ có sau khi metadata về — đặt trong setState để khung
      // đổi chiều cao một lần thay vì kẹp cứng 16/9 (camera sân hay 4:3).
      final size = controller.value.size;
      if (size.width > 0 && size.height > 0) {
        final ratio = size.width / size.height;
        if ((ratio - _aspectRatio).abs() > 0.01) {
          setState(() => _aspectRatio = ratio);
          widget.onAspectRatioChanged?.call(ratio);
        }
      }
      await controller.setLooping(false);
      await controller.setVolume(_muted ? 0 : 1);
      await controller.play();
    } catch (_) {
      // Không khởi tạo được thì để nguyên: giao diện báo "chưa có tín hiệu" thay
      // vì ném lỗi ra ngoài làm cả màn hình sập.
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _error = 'Khong phat duoc luong');
      await controller.dispose();
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _error = null;
    });
    // Nút play/pause phải phản ánh trạng thái thật của player (đã tự dừng khi
    // hết luồng, người dùng điều khiển ở nơi khác…) chứ không chỉ khi bấm.
    controller.addListener(() {
      if (!mounted) return;
      final playing = controller.value.isPlaying;
      final behind = isBehindLive(
        position: controller.value.position,
        duration: controller.value.duration,
      );
      if (playing != _playing || behind != _behindLive) {
        setState(() {
          _playing = playing;
          _behindLive = behind;
        });
      }
    });
    _scheduleHide();
    await previous?.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _revealControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  /// Tells the page when the bar changes, so overlays can make room.
  void _reportControlsVisible(bool visible) {
    if (_reportedVisible == visible) return;
    _reportedVisible = visible;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onControlsVisibleChanged?.call(visible);
    });
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : 1);
    _revealControls();
  }

  void _goLive() {
    final controller = _controller;
    if (controller == null) return;
    controller
      ..seekTo(controller.value.duration)
      ..play();
    _revealControls();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    _revealControls();
  }

  @override
  void dispose() {
    _pip.active.removeListener(_onPipChanged);
    _hideTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    // In the small window only the picture is left.
    final inPip = _pip.active.value;
    final visible = (_controlsVisible || !ready) && !inPip;
    _reportControlsVisible(visible);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.fill ? 0 : AppTheme.radiusXL),
      child: GestureDetector(
        onTap: _revealControls,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              color: Colors.black,
              width: constraints.maxWidth,
              // Cao theo tỉ lệ thật của luồng, chỉ fallback 16/9 lúc stream chưa
              // có metadata. Ép cứng 16/9 làm camera sân 4:3 bị dư viền đen.
              height: widget.fill && constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : constraints.maxWidth / _aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ready)
                    FittedBox(
                      // Always the whole picture, never cropped; the page
                      // decides where the spare black goes.
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_outlined,
                              color: Colors.white38,
                              size: 36,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _error ?? 'Chua co tin hieu phat truc tiep',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (!inPip &&
                      widget.label != null &&
                      widget.label!.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.label!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  if (!inPip && widget.showStreamStats)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: LiveStreamStatsBadge(url: widget.url),
                    ),

                  // Thanh điều khiển gọn: chỉ phát/dừng và tắt/bật tiếng.
                  // Đã bỏ phóng to, thanh trượt âm lượng, toàn màn và chat: người
                  // xem theo trận chỉ cần dừng/phát và tắt tiếng, các nút kia
                  // chỉ chật hơn và che khung hình trên màn hẹp.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: visible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !visible,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              _ControlButton(
                                icon: _playing ? Icons.pause : Icons.play_arrow,
                                label: _playing ? 'Tạm dừng' : 'Phát',
                                onPressed: _togglePlay,
                              ),
                              _ControlButton(
                                icon: _muted
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                label: _muted ? 'Bật tiếng' : 'Tắt tiếng',
                                onPressed: _toggleMute,
                              ),
                              if (widget.showLiveDot)
                                _LiveDot(
                                  behind: _behindLive,
                                  onTap: _behindLive ? _goLive : null,
                                )
                              else if (_behindLive)
                                TextButton(
                                  onPressed: _goLive,
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.liveBackToLive,
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (_pipSupported)
                                _ControlButton(
                                  icon: Icons.picture_in_picture_alt,
                                  label: AppLocalizations.of(
                                    context,
                                  )!.matchPictureInPicture,
                                  onPressed: _hasFrame ? _enterPip : null,
                                ),
                              if (widget.onToggleFullscreen != null)
                                _ControlButton(
                                  icon: widget.fullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  label: widget.fullscreen
                                      ? AppLocalizations.of(
                                          context,
                                        )!.liveExitFullscreen
                                      : AppLocalizations.of(
                                          context,
                                        )!.liveEnterFullscreen,
                                  onPressed: widget.onToggleFullscreen!,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;

  /// Null locks the button (dimmed, no tap).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Ghost như web (`SportOLivePlayer.tsx:621`): không viền, không nền đen,
    // chỉ đổi màu chữ/nền khi rê. Nền chip đen làm nút nặng và lệch bố cục.
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          // 48dp chuẩn Material: nhỏ hơn thì dễ trượt khi xem bằng một tay.
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: const Color(
                0xFFCBD5E1,
              ).withValues(alpha: onPressed == null ? 0.35 : 1),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Red dot while the viewer is at the live edge; grey (tap to jump back)
/// once they have fallen behind.
class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.behind, this.onTap});

  final bool behind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: onTap != null,
      label: behind ? l10n.liveBackToLive : l10n.matchLiveStatus,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox(
          width: 28,
          height: 48,
          child: Center(
            child: Container(
              key: const ValueKey('live-dot'),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: behind
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
