import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

enum LiveZoom { fit, half, full }

/// Trình phát luồng trực tiếp.
///
/// Vùng chạm nút đặt 48dp — chuẩn Material cho mục tiêu chạm, nhỏ hơn thì dễ
/// trượt khi xem bằng một tay. Nút chỉ dùng icon, nhãn nằm trong
/// [Semantics] để trình đọc màn hình vẫn đọc được chứ không chỉ dựa vào hình.
class LiveVideoPlayer extends StatefulWidget {
  const LiveVideoPlayer({super.key, required this.url, this.label});

  final String url;

  /// Tên sân/camera, hiện ở góc phải. Rỗng thì không hiện.
  final String? label;

  @override
  State<LiveVideoPlayer> createState() => _LiveVideoPlayerState();
}

class _LiveVideoPlayerState extends State<LiveVideoPlayer> {
  static const _hideDelay = Duration(seconds: 3);

  VideoPlayerController? _controller;
  Timer? _hideTimer;
  LiveZoom _zoom = LiveZoom.fit;
  bool _muted = true;
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

                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: AnimatedOpacity(
                      opacity: visible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ControlButton(
                            icon: _zoom == LiveZoom.fit
                                ? Icons.zoom_in_map
                                : Icons.zoom_out_map,
                            label: 'Phóng to',
                            onPressed: _cycleZoom,
                          ),
                          const SizedBox(width: 6),
                          _ControlButton(
                            icon: _muted
                                ? Icons.volume_off_outlined
                                : Icons.volume_up_outlined,
                            label: _muted ? 'Bật tiếng' : 'Tắt tiếng',
                            onPressed: _toggleMute,
                          ),
                        ],
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
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          // 48dp chuẩn Material: nhỏ hơn thì dễ trượt khi xem bằng một tay.
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
