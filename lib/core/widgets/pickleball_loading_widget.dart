import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class PickleballLoadingWidget extends StatefulWidget {
  final double size;
  final String? message;
  final Color? textColor;

  const PickleballLoadingWidget({
    super.key,
    this.size = 80,
    this.message,
    this.textColor,
  });

  @override
  State<PickleballLoadingWidget> createState() => _PickleballLoadingWidgetState();
}

class _PickleballLoadingWidgetState extends State<PickleballLoadingWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/pickleball_loading.mp4',
    )..initialize().then((_) {
        if (mounted) {
          _controller.setLooping(true);
          _controller.setVolume(0.0);
          _controller.play();
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((e) {
        debugPrint('[PickleballLoadingWidget] Video error: $e');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.25),
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : Center(
                  child: SizedBox(
                    width: widget.size * 0.35,
                    height: widget.size * 0.35,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                ),
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.textColor ?? context.colors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
