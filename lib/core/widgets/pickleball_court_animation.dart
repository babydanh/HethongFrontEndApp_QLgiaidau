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
    final center = Offset(w * 0.5, h * 0.54);

    // Bán kính trục isometric
    final rx = w * 0.44;
    final ry = h * 0.27;
    const depth = 22.0;

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
        colors: [Color(0xFF1E2E48), Color(0xFF0F1A2A)],
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
        colors: [Color(0xFF142033), Color(0xFF0B121E)],
      ).createShader(Rect.fromLTWH(bottom.dx, bottom.dy, rx, ry + depth));
    canvas.drawPath(rightSidePath, rightSidePaint);

    // 2. Viền ngoài trắng của mặt sân
    final courtOuterPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final outerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(courtOuterPath, outerBorderPaint);

    // 3. Mặt sân màu xanh Sport Blue (như hình mẫu Blender)
    final courtSurfacePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2584EE),
          Color(0xFF196FD6),
        ],
      ).createShader(Rect.fromLTWH(left.dx, top.dy, rx * 2, ry * 2));
    canvas.drawPath(courtOuterPath, courtSurfacePaint);

    // 4. Các đường kẻ sân Pickleball (Lines)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Đường giữa dọc sân (Centerline)
    canvas.drawLine(top, bottom, linePaint);

    // Đường Kitchen (Non-Volley Zone) song song lưới
    final kitchen1Start = Offset.lerp(left, top, 0.42)!;
    final kitchen1End = Offset.lerp(right, top, 0.42)!;
    canvas.drawLine(kitchen1Start, kitchen1End, linePaint);

    final kitchen2Start = Offset.lerp(left, bottom, 0.42)!;
    final kitchen2End = Offset.lerp(right, bottom, 0.42)!;
    canvas.drawLine(kitchen2Start, kitchen2End, linePaint);

    // 5. Dựng Lưới Pickleball 3D nổi (Vertical Net)
    const netHeight = 12.0;
    final netPath = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(left.dx, left.dy - netHeight)
      ..lineTo(right.dx, right.dy - netHeight)
      ..lineTo(right.dx, right.dy)
      ..close();

    final netMeshPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(netPath, netMeshPaint);

    // Viền trên đỉnh lưới (White tape band)
    final netBandPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(left.dx, left.dy - netHeight),
      Offset(right.dx, right.dy - netHeight),
      netBandPaint,
    );

    // ══════════════════════════════════════════════════════════
    //  HOẠT ẢNH BÓNG PICKLEBALL: NẢY & TO RA NHỎ LẠI THEO QUỸ ĐẠO
    // ══════════════════════════════════════════════════════════
    final t = progress; // 0..1
    final cycle = (t * 2 * math.pi);

    // Điểm bóng xuất phát ở nửa sân bên kia (xa camera) và nảy sang nửa sân bên này (gần camera)
    final startCourtPos = Offset(center.dx - rx * 0.40, center.dy - ry * 0.22);
    final bounceCourtPos = Offset(center.dx + rx * 0.08, center.dy + ry * 0.40);

    // Quỹ đạo ngang (X, Y trên mặt sân)
    final horizontalPhase = (math.sin(cycle - math.pi / 2) + 1) / 2; // 0..1
    final currentGroundPos = Offset.lerp(startCourtPos, bounceCourtPos, horizontalPhase)!;

    // Độ nảy Parabol: chạm đất khi horizontalPhase = 1, cao nhất khi ở giữa quỹ đạo (vượt qua lưới)
    final bounceHeight = math.sin(horizontalPhase * math.pi).abs() * (h * 0.30);

    // Vị trí thực của quả bóng (bay lên cao = Y giảm)
    final ballCenter = Offset(currentGroundPos.dx, currentGroundPos.dy - bounceHeight);

    // Scale của quả bóng: khi bay lên cao và gần camera thì TO RA (scale 1.55),
    // khi chạm đất thì NHỎ LẠI (scale 0.85)
    final scale = 0.85 + (horizontalPhase * 0.35) + ((bounceHeight / (h * 0.30)) * 0.35);
    final ballRadius = 13.5 * scale;

    // 6. Bóng đổ (Shadow) trên mặt sân:
    final shadowScale = 0.65 + (1.0 - (bounceHeight / (h * 0.30))) * 0.35;
    final shadowOpacity = (0.50 - (bounceHeight / (h * 0.30)) * 0.30).clamp(0.12, 0.55);
    final shadowRect = Rect.fromCenter(
      center: currentGroundPos,
      width: ballRadius * 2.2 * shadowScale,
      height: ballRadius * 0.85 * shadowScale,
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(shadowRect, shadowPaint);

    // 7. Vệt bóng đánh (Smash Motion Tube / Trail) uốn cong như ảnh mẫu Blender
    final arcStart = Offset(startCourtPos.dx - 4, startCourtPos.dy - 6);
    final arcPeak = Offset(
      (startCourtPos.dx + bounceCourtPos.dx) / 2 - 12,
      (startCourtPos.dy + bounceCourtPos.dy) / 2 - (h * 0.28),
    );
    final arcEnd = ballCenter;

    final trailPath = Path()
      ..moveTo(arcStart.dx, arcStart.dy)
      ..quadraticBezierTo(arcPeak.dx, arcPeak.dy, arcEnd.dx, arcEnd.dy);

    // Vẽ vệt tube cong dày 3D
    final trailTubePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromPoints(arcStart, arcEnd))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (ballRadius * 0.70).clamp(6.0, 14.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trailPath, trailTubePaint);

    // 8. Vẽ Quả bóng Pickleball màu Vàng
    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: const [
          Color(0xFFFFF59D), // Highlight vàng sáng
          Color(0xFFFFD600), // Vàng tươi pickleball
          Color(0xFFF57F17), // Shadow cạnh bóng
        ],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius));
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);

    // 9. Các lỗ tròn đặc trưng trên bóng Pickleball
    final holePaint = Paint()
      ..color = const Color(0xFF212121).withValues(alpha: 0.80);

    final holes = [
      Offset(ballCenter.dx - ballRadius * 0.35, ballCenter.dy - ballRadius * 0.25),
      Offset(ballCenter.dx + ballRadius * 0.15, ballCenter.dy - ballRadius * 0.45),
      Offset(ballCenter.dx + ballRadius * 0.40, ballCenter.dy - ballRadius * 0.1),
      Offset(ballCenter.dx - ballRadius * 0.1, ballCenter.dy + ballRadius * 0.15),
      Offset(ballCenter.dx - ballRadius * 0.45, ballCenter.dy + ballRadius * 0.25),
      Offset(ballCenter.dx + ballRadius * 0.3, ballCenter.dy + ballRadius * 0.35),
      Offset(ballCenter.dx - ballRadius * 0.05, ballCenter.dy + ballRadius * 0.55),
    ];

    final holeRadius = ballRadius * 0.14;
    for (final hole in holes) {
      canvas.drawCircle(hole, holeRadius, holePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PickleballCourtPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
