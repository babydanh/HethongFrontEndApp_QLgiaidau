import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

class StatusIndicator extends StatelessWidget {
  final String status;
  final double size;
  final bool animate;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 8.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatusHelper.getStatusColor(status, context);
    
    Widget indicator = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

    // Apply blinking animation if live
    if (animate && status == AppConstants.matchLive) {
      indicator = indicator
          .animate(onPlay: (controller) => controller.repeat())
          .scaleXY(end: 0.8, duration: 800.ms)
          .then(delay: 200.ms)
          .scaleXY(end: 1.0, duration: 800.ms);
    }

    return indicator;
  }
}
