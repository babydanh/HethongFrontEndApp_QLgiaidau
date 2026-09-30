import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

enum LiveZoom { fit, half, full }

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
    this.onToggleChat,
  });

  final String url;

  /// Tên sân/camera, hiện ở góc phải. Rỗng thì không hiện.
  final String? label;

  /// Bật/tắt khung thảo luận. Rỗng thì ẩn nút chat, khớp web.
  final VoidCallback? onToggleChat;

  @override
  State<LiveVideoPlayer> createState() => _LiveVideoPlayerState();
}

class _LiveVideoPlayerState extends State<LiveVideoPlayer> {
  static const _hideDelay = Duration(seconds: 3);

  VideoPlayerController? _controller;
  Timer? _hideTimer;
  LiveZoom _zoom = LiveZoom.fit;
  bool _muted = true;
  bool _playing = false;
  double _volume = 1;
  bool _fullscreen = false;
  bool _chatOpen = false;
  bool _controlsVisible = true;
  String? _error;

  double get _scale => switch (_zoom) {
        LiveZoom.fit => 1,
        LiveZoom.half => 1.5,
        LiveZoom.full => 2,
      };

  @override
  void initState() {
    super.initState();
    _initPlayer();
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
      _zoom = LiveZoom.fit;
      _error = null;
    });
    // Nút play/pause phải phản ánh trạng thái thật của player (đã tự dừng khi
    // hết luồng, người dùng điều khiển ở nơi khác…) chứ không chỉ khi bấm.
    controller.addListener(() {
      if (!mounted) return;
      final playing = controller.value.isPlaying;
      if (playing != _playing) setState(() => _playing = playing);
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

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : 1);
    _revealControls();
  }

  void _cycleZoom() {
    setState(() {
      _zoom = switch (_zoom) {
        LiveZoom.fit => LiveZoom.half,
        LiveZoom.half => LiveZoom.full,
        LiveZoom.full => LiveZoom.fit,
      };
    });
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

  void _setVolume(double value) {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _volume = value.clamp(0, 1);
      _muted = _volume == 0;
      controller.setVolume(_volume);
    });
    _revealControls();
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    SystemChrome.setEnabledSystemUIMode(
      _fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    _revealControls();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final visible = _controlsVisible || !ready;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: GestureDetector(
        onTap: _revealControls,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              color: Colors.black,
              width: constraints.maxWidth,
              height: constraints.maxWidth * 9 / 16,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ready)
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: Transform.scale(
                          scale: _scale,
                          child: VideoPlayer(controller),
                        ),
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

                  if (widget.label != null && widget.label!.isNotEmpty)
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

                  // Thanh điều khiển: đúng bố cục web
                  // (`SportOLivePlayer.tsx:465-558`) — trái: play, âm lượng +
                  // thanh trượt, chấm TRỰC TIẾP; phải: phóng, chat, toàn màn.
                  // Nút 48dp và thanh trượt cao 44dp, không thu nhỏ.
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
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              _ControlButton(
                                icon: _playing
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                label: _playing ? 'Tạm dừng' : 'Phát',
                                onPressed: _togglePlay,
                              ),
                              _ControlButton(
                                icon: _muted || _volume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                label: _muted ? 'Bật tiếng' : 'Tắt tiếng',
                                onPressed: _toggleMute,
                              ),
                              // Vùng chạm 44dp dù thanh trượt chỉ mảnh, đúng
                              // web: slider mảnh nhưng vùng bấm rộng.
                              SizedBox(
                                width: 80,
                                height: 44,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    thumbShape:
                                        const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor:
                                        Colors.white.withValues(alpha: 0.25),
                                    thumbColor: Colors.white,
                                    overlayShape:
                                        SliderComponentShape.noOverlay,
                                  ),
                                  child: Slider(
                                    value: _muted ? 0 : _volume,
                                    onChanged: _setVolume,
                                    onChangeEnd: (_) => _revealControls(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Tín hiệu live nằm cùng hàng nút như web.
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'TRỰC TIẾP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _ControlButton(
                                icon: _zoom == LiveZoom.fit
                                    ? Icons.zoom_in_map
                                    : Icons.zoom_out_map,
                                label: 'Phóng to',
                                onPressed: _cycleZoom,
                              ),
                              if (widget.onToggleChat != null)
                                _ControlButton(
                                  icon: _chatOpen
                                      ? Icons.chat
                                      : Icons.chat_bubble_outline,
                                  label: _chatOpen
                                      ? 'Ẩn thảo luận'
                                      : 'Xem thảo luận',
                                  onPressed: () {
                                    setState(() => _chatOpen = !_chatOpen);
                                    widget.onToggleChat!();
                                    _revealControls();
                                  },
                                ),
                              _ControlButton(
                                icon: _fullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                label: _fullscreen ? 'Thoát toàn màn' : 'Toàn màn',
                                onPressed: _toggleFullscreen,
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
  final VoidCallback onPressed;

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
            child: Icon(icon, color: const Color(0xFFCBD5E1), size: 20),
          ),
        ),
      ),
    );
  }
}
