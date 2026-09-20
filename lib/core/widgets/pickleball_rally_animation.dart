import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Hoạt họa Trận đấu Pickleball 2D Flat Motion:
/// - 2 cây vợt Pickleball (Team Sport Blue & Team Sun Orange) đối kháng qua lưới.
/// - Tấm lưới Pickleball ở giữa với cột lưới và viền tape trắng.
/// - Quả bóng Pickleball vàng Neon bay qua bay lại theo quỹ đạo vòng cung parabol tự nhiên.
/// - Hiệu ứng rung phản lực (recoil) khi vợt chạm bóng và hạt tia sáng (spark burst).
/// - Bóng đổ di động trên mặt sàn theo độ cao của quả bóng.
class PickleballRallyAnimation extends StatefulWidget {
  final double width;
  final double height;
  final String? message;
  final Color? textColor;

  const PickleballRallyAnimation({
    super.key,
    this.width = 240,
    this.height = 130,
    this.message,
    this.textColor,
  });

  @override
  State<PickleballRallyAnimation> createState() => _PickleballRallyAnimationState();
}

class _PickleballRallyAnimationState extends State<PickleballRallyAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _PickleballRallyPainter(progress: _controller.value),
              );
            },
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
              color: widget.textColor ?? const Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _PickleballRallyPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0

  _PickleballRallyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Đường cơ sở mặt sàn (Floor line)
    final floorY = h * 0.82;
    final centerX = w * 0.5;

    // Tọa độ 2 cây vợt
    final leftPaddleX = w * 0.16;
    final rightPaddleX = w * 0.84;
    final paddleCenterY = floorY - 26.0;

    // Chiều cao và vị trí lưới
    final netHeight = 28.0;
    final netTopY = floorY - netHeight;

    // ─── 1. VẼ MẶT SÀN VÀ ĐƯỜNG KẺ THỂ THAO MỜ ───
    final floorPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.06, floorY), Offset(w * 0.94, floorY), floorPaint);

    // Vạch kitchen zone mờ
    final kitchenPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(centerX - 36, floorY), Offset(centerX - 36, floorY - 6), kitchenPaint);
    canvas.drawLine(Offset(centerX + 36, floorY), Offset(centerX + 36, floorY - 6), kitchenPaint);

    // ─── 2. VẼ TẤM LƯỚI PICKLEBALL Ở GIỮA ───
    _drawNet(canvas, centerX, netTopY, floorY);

    // ─── 3. TÍNH TOÁN QUỸ ĐẠO BÓNG VÀ CHUYỂN ĐỘNG VỢT ───
    // progress: 0..0.5 (Trái -> Phải), 0.5..1.0 (Phải -> Trái)
    final bool goingRight = progress < 0.5;
    final double halfProgress = goingRight ? (progress / 0.5) : ((progress - 0.5) / 0.5);

    // Tọa độ bóng theo trục X (nội suy mượt easeInOut)
    final double startX = goingRight ? (leftPaddleX + 14.0) : (rightPaddleX - 14.0);
    final double targetX = goingRight ? (rightPaddleX - 14.0) : (leftPaddleX + 14.0);
    // Smooth cosine interpolation
    final double tX = 0.5 - 0.5 * math.cos(halfProgress * math.pi);
    final double ballX = startX + (targetX - startX) * tX;

    // Tọa độ bóng theo trục Y: Parabol vồng cao qua lưới
    final double arcHeight = 44.0;
    final double ballBaseY = paddleCenterY;
    // Parabol đỉnh ở t=0.5: 4 * t * (1 - t)
    final double arc = 4.0 * halfProgress * (1.0 - halfProgress);
    final double ballY = ballBaseY - (arc * arcHeight);

    // Góc nảy của 2 vợt (Swing & Recoil)
    double leftPaddleAngle = 0.18; // góc nghiêng nghỉ tự nhiên (~10 độ)
    double rightPaddleAngle = -0.18;

    // Vợt trái đánh lúc t gần 0 hoặc gần 1
    if (progress < 0.10) {
      final punch = math.sin((progress / 0.10) * math.pi);
      leftPaddleAngle += punch * 0.22; // vung tới
    } else if (progress > 0.90) {
      final prep = (progress - 0.90) / 0.10;
      leftPaddleAngle -= prep * 0.10; // lùi lấy đà
    }

    // Vợt phải đánh lúc t gần 0.5
    if (progress >= 0.45 && progress <= 0.55) {
      final punch = math.sin(((progress - 0.45) / 0.10) * math.pi);
      rightPaddleAngle -= punch * 0.22; // vung tới
    }

    // ─── 4. VẼ VỢT BÊN TRÁI (Team Sport Blue) ───
    _drawPaddle(
      canvas: canvas,
      x: leftPaddleX,
      y: paddleCenterY,
      angle: leftPaddleAngle,
      isLeft: true,
      faceColor: const Color(0xFF1D8EF8),
      edgeColor: const Color(0xFF0284C7),
      gripColor: const Color(0xFF334155),
    );

    // ─── 5. VẼ VỢT BÊN PHẢI (Team Sun Orange) ───
    _drawPaddle(
      canvas: canvas,
      x: rightPaddleX,
      y: paddleCenterY,
      angle: rightPaddleAngle,
      isLeft: false,
      faceColor: const Color(0xFFF97316),
      edgeColor: const Color(0xFFEA580C),
      gripColor: const Color(0xFF334155),
    );

    // ─── 6. BÓNG ĐỔ CỦA QUẢ BÓNG TRÊN SÀN (Shadow) ───
    final double ballHeightAboveFloor = (floorY - ballY).clamp(8.0, 70.0);
    final double shadowScale = (1.0 - (ballHeightAboveFloor / 80.0)).clamp(0.4, 1.0);
    final double shadowAlpha = (0.28 * shadowScale).clamp(0.08, 0.28);

    final shadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: shadowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ballX, floorY),
        width: 14.0 * shadowScale,
        height: 5.0 * shadowScale,
      ),
      shadowPaint,
    );

    // ─── 7. VỆT BAY MỜ CỦA BÓNG (Motion Trail) ───
    final double trailOffset = goingRight ? -10.0 : 10.0;
    final trailPaint = Paint()
      ..color = const Color(0xFFFACC15).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(ballX, ballY),
      Offset(ballX + trailOffset * 0.8, ballY + 4.0),
      trailPaint,
    );

    // ─── 8. VẼ QUẢ BÓNG PICKLEBALL ───
    _drawPickleball(canvas, Offset(ballX, ballY), radius: 8.5, rotation: progress * 6 * math.pi);

    // ─── 9. TIA HẠT VA CHẠM (Sparks on Hit) ───
    if (progress < 0.12) {
      final sparkT = progress / 0.12;
      _drawSparks(canvas, Offset(leftPaddleX + 10, paddleCenterY), sparkT, const Color(0xFF38BDF8));
    } else if (progress >= 0.48 && progress <= 0.60) {
      final sparkT = (progress - 0.48) / 0.12;
      _drawSparks(canvas, Offset(rightPaddleX - 10, paddleCenterY), sparkT, const Color(0xFFFB923C));
    }
  }

  /// Vẽ tấm lưới Pickleball
  void _drawNet(Canvas canvas, double centerX, double topY, double bottomY) {
    const netWidth = 24.0;
    final netRect = Rect.fromCenter(
      center: Offset(centerX, (topY + bottomY) / 2),
      width: netWidth,
      height: bottomY - topY,
    );

    // Thân lưới màu trắng đục có viền
    final netBodyPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawRect(netRect, netBodyPaint);

    // Kẻ ô lưới tinh tế
    final gridPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;

    // Đường ngang lưới
    const rows = 4;
    final rowStep = (bottomY - topY) / rows;
    for (int i = 1; i < rows; i++) {
      final y = topY + i * rowStep;
      canvas.drawLine(Offset(centerX - netWidth / 2, y), Offset(centerX + netWidth / 2, y), gridPaint);
    }
    // Đường dọc lưới
    canvas.drawLine(Offset(centerX - 4, topY), Offset(centerX - 4, bottomY), gridPaint);
    canvas.drawLine(Offset(centerX + 4, topY), Offset(centerX + 4, bottomY), gridPaint);

    // Cột lưới (Posts) 2 bên
    final postPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(centerX - netWidth / 2, topY - 2), Offset(centerX - netWidth / 2, bottomY), postPaint);
    canvas.drawLine(Offset(centerX + netWidth / 2, topY - 2), Offset(centerX + netWidth / 2, bottomY), postPaint);

    // Băng mép trên đỉnh lưới (White Top Tape)
    final tapePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(centerX - netWidth / 2 - 1, topY), Offset(centerX + netWidth / 2 + 1, topY), tapePaint);
    // Viền mép tape
    final tapeBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawLine(Offset(centerX - netWidth / 2, topY + 1.5), Offset(centerX + netWidth / 2, topY + 1.5), tapeBorderPaint);
  }

  /// Vẽ 1 cây vợt Pickleball thể thao hoàn chỉnh (Mặt vợt + Viền + Tay cầm)
  void _drawPaddle({
    required Canvas canvas,
    required double x,
    required double y,
    required double angle,
    required bool isLeft,
    required Color faceColor,
    required Color edgeColor,
    required Color gripColor,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    // Hướng xoay: Nếu là vợt phải thì lật ngang
    if (!isLeft) {
      canvas.scale(-1, 1);
    }

    // Đổ bóng của vợt
    final paddleShadow = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -26, 20, 34),
        const Radius.circular(7.0),
      ),
      paddleShadow,
    );

    // 1. Tay cầm vợt (Handle / Grip)
    final handlePaint = Paint()..color = gripColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.0, 8, 6.0, 22.0),
        const Radius.circular(3.0),
      ),
      handlePaint,
    );

    // Các đường quấn grip chéo thể thao
    final gripLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 4; i++) {
      final gy = 12.0 + i * 4.5;
      canvas.drawLine(Offset(-2.8, gy), Offset(2.8, gy + 2.0), gripLinePaint);
    }

    // Đáy tay cầm (Handle Butt Cap)
    final buttCapPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.8, 28, 7.6, 3.5),
        const Radius.circular(1.5),
      ),
      buttCapPaint,
    );

    // Cổ vợt (Throat transition)
    final throatPath = Path()
      ..moveTo(-3.5, 8)
      ..lineTo(-7.0, 0)
      ..lineTo(7.0, 0)
      ..lineTo(3.5, 8)
      ..close();
    final throatPaint = Paint()..color = edgeColor;
    canvas.drawPath(throatPath, throatPaint);

    // 2. Viền cạnh bảo vệ vợt (Edge Guard)
    final edgePaint = Paint()..color = edgeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10.5, -28.0, 21.0, 32.0),
        const Radius.circular(7.5),
      ),
      edgePaint,
    );

    // 3. Mặt vợt chính (Paddle Face)
    final faceRect = const Rect.fromLTWH(-9.0, -26.5, 18.0, 29.0);
    final facePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          faceColor.withValues(alpha: 0.95),
          faceColor,
        ],
      ).createShader(faceRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, const Radius.circular(6.0)),
      facePaint,
    );

    // Sweet Spot / Vòng nhận diện thương hiệu ở trung tâm mặt vợt
    final sweetSpotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(const Offset(0, -12), 4.5, sweetSpotPaint);

    // Vệt bóng sáng mặt vợt (Glint)
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-6.0, -23.0), const Offset(-2.0, -23.0), glintPaint);

    canvas.restore();
  }

  /// Vẽ quả bóng Pickleball chuẩn màu vàng Neon với các lỗ đặc trưng
  void _drawPickleball(Canvas canvas, Offset center, {required double radius, required double rotation}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Gradient hình cầu 3D
    final ballPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [
          Color(0xFFFFFDE7), // Điểm sáng trắng vàng
          Color(0xFFFFEA00), // Vàng Neon tươi
          Color(0xFFFFB300), // Vàng cam ấm
          Color(0xFFE65100), // Viền đổ bóng
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    canvas.drawCircle(Offset.zero, radius, ballPaint);

    // Vết phản chiếu ánh sáng (Specular Highlight)
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(-radius * 0.32, -radius * 0.32), radius * 0.22, highlightPaint);

    // Các lỗ bóng Pickleball tròn đặc trưng
    final holePaint = Paint()..color = const Color(0xFFB45309).withValues(alpha: 0.45);
    final holeR = radius * 0.13;
    canvas.drawCircle(Offset(radius * 0.28, -radius * 0.28), holeR, holePaint);
    canvas.drawCircle(Offset(radius * 0.40, radius * 0.15), holeR, holePaint);
    canvas.drawCircle(Offset(-radius * 0.12, radius * 0.36), holeR, holePaint);
    canvas.drawCircle(Offset(-radius * 0.36, radius * 0.10), holeR, holePaint);

    canvas.restore();
  }

  /// Vẽ tia hạt lóe sáng khi chạm vợt
  void _drawSparks(Canvas canvas, Offset hitPos, double t, Color color) {
    if (t > 1.0 || t < 0.0) return;
    final sparkPaint = Paint()
      ..color = color.withValues(alpha: (1.0 - t).clamp(0.0, 1.0))
      ..strokeWidth = (1.0 - t) * 2.0
      ..strokeCap = StrokeCap.round;

    final distance = t * 14.0;
    const angles = [-0.6, -0.2, 0.2, 0.6];
    for (final a in angles) {
      final start = Offset(hitPos.dx + math.cos(a) * (distance * 0.4), hitPos.dy + math.sin(a) * (distance * 0.4));
      final end = Offset(hitPos.dx + math.cos(a) * distance, hitPos.dy + math.sin(a) * distance);
      canvas.drawLine(start, end, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PickleballRallyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
