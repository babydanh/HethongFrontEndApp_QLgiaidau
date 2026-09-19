import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget hoạt họa Sân Pickleball Isometric 3D vẽ hoàn toàn bằng code Flutter:
/// - Sân khối 3D Isometric màu xanh Sport Blue viền trắng chuẩn sân.
/// - Đường kẻ sân Pickleball (Centerline, Kitchen/NVZ line).
/// - Quả bóng Pickleball vàng có các lỗ tròn đặc trưng.
/// - Hiệu ứng bay nảy 3D: Bóng bay lên to ra (gần camera) rồi đập xuống sân nhỏ lại (xa camera).
/// - Vệt bóng đánh (smash/hit motion trail) uốn cong như ảnh mẫu.
class PickleballCourtAnimation extends StatefulWidget {
  final double size;
  final bool autoPlay;
  final VoidCallback? onTap;

  const PickleballCourtAnimation({
    super.key,
    this.size = 200,
    this.autoPlay = true,
    this.onTap,
  });

  @override
  State<PickleballCourtAnimation> createState() =>
      _PickleballCourtAnimationState();
}

class _PickleballCourtAnimationState extends State<PickleballCourtAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.autoPlay) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ??
          () {
            if (_controller.isAnimating) {
              _controller.stop();
            } else {
              _controller.repeat();
            }
          },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PickleballCourtPainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _PickleballCourtPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0

  _PickleballCourtPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.55);

    // Bán kính trục isometric
    final rx = w * 0.44;
    final ry = h * 0.28;
    const depth = 20.0;

    // 4 đỉnh mặt sân (Isometric diamond)
    final top = Offset(center.dx, center.dy - ry);
    final right = Offset(center.dx + rx, center.dy);
    final bottom = Offset(center.dx, center.dy + ry);
    final left = Offset(center.dx - rx, center.dy);

    // 1. Vẽ khối đế 3D dưới (Sườn sân bên trái & bên phải)
    final leftSidePath = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottom.dx, bottom.dy + depth)
      ..lineTo(left.dx, left.dy + depth)
      ..close();

    final leftSidePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(left.dx, left.dy, rx, ry + depth));
    canvas.drawPath(leftSidePath, leftSidePaint);

    final rightSidePath = Path()
      ..moveTo(bottom.dx, bottom.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(right.dx, right.dy + depth)
      ..lineTo(bottom.dx, bottom.dy + depth)
      ..close();

    final rightSidePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF090D16)],
      ).createShader(Rect.fromLTWH(bottom.dx, bottom.dy, rx, ry + depth));
    canvas.drawPath(rightSidePath, rightSidePaint);

    // 2. Viền ngoài trắng bo góc nhẹ của mặt sân
    final courtOuterPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final outerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(courtOuterPath, outerBorderPaint);

    // 3. Mặt sân màu xanh Sport Blue
    final courtSurfacePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1D8EF8),
          Color(0xFF1565C0),
        ],
      ).createShader(Rect.fromLTWH(left.dx, top.dy, rx * 2, ry * 2));
    canvas.drawPath(courtOuterPath, courtSurfacePaint);

    // 4. Các đường kẻ sân Pickleball (Lines)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    // Đường giữa dọc sân (Centerline)
    canvas.drawLine(top, bottom, linePaint);

    // Đường ngang lưới (Net line / Middle)
    canvas.drawLine(left, right, linePaint);

    // Đường Kitchen (Non-Volley Zone) song song lưới
    final kitchen1Start = Offset.lerp(left, top, 0.45)!;
    final kitchen1End = Offset.lerp(right, top, 0.45)!;
    canvas.drawLine(kitchen1Start, kitchen1End, linePaint);

    final kitchen2Start = Offset.lerp(left, bottom, 0.45)!;
    final kitchen2End = Offset.lerp(right, bottom, 0.45)!;
    canvas.drawLine(kitchen2Start, kitchen2End, linePaint);

    // ══════════════════════════════════════════════════════════
    //  HOẠT ẢNH BÓNG PICKLEBALL: NẢY & TO RA NHỎ LẠI THEO QUỸ ĐẠO
    // ══════════════════════════════════════════════════════════

    // Chu kỳ đánh bóng:
    // progress từ 0.0 -> 0.5: bóng bay từ sau ra trước (to dần lên) và đập xuống sân
    // progress từ 0.5 -> 1.0: bóng nảy lên cao rồi bay về sau (nhỏ lại)
    final t = progress; // 0..1
    final cycle = (t * 2 * math.pi);

    // Điểm bắt đầu (góc xa sân - nhỏ) và điểm kết thúc (góc gần sân - to)
    final startCourtPos = Offset(center.dx - rx * 0.45, center.dy - ry * 0.2);
    final bounceCourtPos = Offset(center.dx + rx * 0.1, center.dy + ry * 0.35);

    // Quỹ đạo ngang (X, Y trên mặt phẳng)
    final horizontalPhase = (math.sin(cycle - math.pi / 2) + 1) / 2; // 0..1
    final currentGroundPos = Offset.lerp(startCourtPos, bounceCourtPos, horizontalPhase)!;

    // Độ cao bóng bay khỏi mặt đất (Parabol bounce curve)
    // Khi chạm đất: bounceHeight = 0
    final bounceHeight = math.sin(horizontalPhase * math.pi).abs() * (h * 0.28);

    // Vị trí thực của quả bóng (bay lên cao = Y giảm)
    final ballCenter = Offset(currentGroundPos.dx, currentGroundPos.dy - bounceHeight);

    // Scale của quả bóng: khi bay lên cao và gần camera thì TO RA (scale 1.5),
    // khi ở xa chạm sân thì NHỎ LẠI (scale 0.85)
    final scale = 0.85 + (horizontalPhase * 0.35) + ((bounceHeight / (h * 0.28)) * 0.30);
    final ballRadius = 14.0 * scale;

    // 5. Bóng đổ (Shadow) trên mặt sân:
    // Khi bóng chạm đất: bóng đổ co lại nhỏ gọn, đậm màu
    // Khi bóng lên cao: bóng đổ nở rộng mờ nhạt
    final shadowScale = 0.7 + (1.0 - (bounceHeight / (h * 0.28))) * 0.3;
    final shadowOpacity = (0.55 - (bounceHeight / (h * 0.28)) * 0.35).clamp(0.15, 0.6);
    final shadowRect = Rect.fromCenter(
      center: currentGroundPos,
      width: ballRadius * 2.2 * shadowScale,
      height: ballRadius * 0.9 * shadowScale,
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(shadowRect, shadowPaint);

    // 6. Vệt bóng đánh (Smash Motion Trail) uốn cong như ảnh mẫu
    if (bounceHeight > 5) {
      final trailPath = Path();
      final trailStart = Offset(startCourtPos.dx - 10, startCourtPos.dy - (h * 0.15));
      final trailControl = Offset(
        (startCourtPos.dx + ballCenter.dx) / 2 - 15,
        ballCenter.dy - 20,
      );

      trailPath.moveTo(trailStart.dx, trailStart.dy);
      trailPath.quadraticBezierTo(
        trailControl.dx,
        trailControl.dy,
        ballCenter.dx - ballRadius * 0.7,
        ballCenter.dy,
      );
      trailPath.lineTo(ballCenter.dx - ballRadius * 0.4, ballCenter.dy + ballRadius * 0.5);
      trailPath.quadraticBezierTo(
        trailControl.dx + 10,
        trailControl.dy + 15,
        trailStart.dx + 8,
        trailStart.dy + 8,
      );
      trailPath.close();

      final trailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.75),
          ],
        ).createShader(Rect.fromPoints(trailStart, ballCenter));
      canvas.drawPath(trailPath, trailPaint);
    }

    // 7. Vẽ Quả bóng Pickleball màu Vàng
    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: const [
          Color(0xFFFFF176), // Highlight vàng sáng
          Color(0xFFFFD600), // Vàng tươi pickleball
          Color(0xFFF57F17), // Shadow cạnh bóng
        ],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius));
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);

    // 8. Các lỗ tròn đặc trưng trên bóng Pickleball
    final holePaint = Paint()
      ..color = const Color(0xFF212121).withValues(alpha: 0.85);

    // Tọa độ các lỗ theo góc 3D
    final holes = [
      Offset(ballCenter.dx - ballRadius * 0.35, ballCenter.dy - ballRadius * 0.25),
      Offset(ballCenter.dx + ballRadius * 0.15, ballCenter.dy - ballRadius * 0.45),
      Offset(ballCenter.dx + ballRadius * 0.40, ballCenter.dy - ballRadius * 0.1),
      Offset(ballCenter.dx - ballRadius * 0.1, ballCenter.dy + ballRadius * 0.15),
      Offset(ballCenter.dx - ballRadius * 0.45, ballCenter.dy + ballRadius * 0.25),
      Offset(ballCenter.dx + ballRadius * 0.3, ballCenter.dy + ballRadius * 0.35),
      Offset(ballCenter.dx - ballRadius * 0.05, ballCenter.dy + ballRadius * 0.55),
    ];

    final holeRadius = ballRadius * 0.15;
    for (final hole in holes) {
      canvas.drawCircle(hole, holeRadius, holePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PickleballCourtPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
