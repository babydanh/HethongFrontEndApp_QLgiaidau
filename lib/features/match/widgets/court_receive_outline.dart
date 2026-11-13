import 'dart:math' as math;

import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_palette.dart';
import 'package:flutter/material.dart';

/// Dashed white outline inside a court cell: marks the player who receives.
/// Shared by the pickleball court and the badminton / tennis court.
class CourtReceiveOutline extends CustomPainter {
  const CourtReceiveOutline();

  static const _inset = 7.0;
  static const _dash = 9.0;
  static const _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect((Offset.zero & size).deflate(_inset));
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        canvas.drawPath(
          metric.extractPath(at, math.min(at + _dash, metric.length)),
          paint,
        );
        at += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(CourtReceiveOutline oldDelegate) => false;
}

/// Small pill on a cell: "RECEIVE" (translucent) or, with [ball], the
/// server's chip with the yellow ring.
class CourtCellTag extends StatelessWidget {
  const CourtCellTag({super.key, required this.text, this.ball = false});

  final String text;
  final bool ball;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: ball ? 1 : 0.7),
        borderRadius: BorderRadius.circular(8),
        border: ball ? Border.all(color: courtBallColor, width: 2) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: courtNavy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
