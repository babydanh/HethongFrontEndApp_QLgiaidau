import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hoạt họa Sân Pickleball 3D đỉnh cao vẽ 100% bằng Flutter Canvas (Pure Code):
/// - Không dùng file PNG ảnh tĩnh (không bao giờ bị lỗi 2 quả bóng hay viền xám mốc).
/// - Khối sân 3D Isometric đa chiều, mặt sân men bóng sang trọng chuẩn giải đấu quốc tế.
/// - Lưới 3D đứng thẳng ở giữa sân với cột lưới và viền tape trắng.
/// - Quả bóng Pickleball vàng Neon 3D nảy bổng theo phối cảnh:
///   + Bay lên cao về phía người xem -> **TO RA GẤP ĐÔI (1.75x)**.
///   + Lao xuống mặt sân -> **NHỎ LẠI (1.0x)** và **NHÚN BẸT (Squash & Stretch)**.
/// - Hiệu ứng chạm sân: Sóng chấn động Neon (Shockwave Ripple), mặt sân rung đàn hồi, tia lửa tóe sáng.
/// - Có thể chạm (Tap) để đập bóng Smash cực đã tay với phản hồi rung Haptic!
class Pickleball3DCourtAnimation extends StatefulWidget {
  final double size;
  final bool autoPlay;
  final String? message;
  final Color? textColor;
  final VoidCallback? onTap;

  const Pickleball3DCourtAnimation({
    super.key,
    this.size = 180,
    this.autoPlay = true,
    this.message,
    this.textColor,
    this.onTap,
  });

  @override
  State<Pickleball3DCourtAnimation> createState() =>
      _Pickleball3DCourtAnimationState();
}

class _Pickleball3DCourtAnimationState extends State<Pickleball3DCourtAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final courtSize = widget.size;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: courtSize,
            height: courtSize * 0.92,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(courtSize, courtSize * 0.92),
                  painter: _PureVector3DCourtPainter(progress: _controller.value),
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
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: widget.textColor ?? const Color(0xFF475569),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// CustomPainter vẽ toàn bộ Sân Pickleball 3D Isometric + Quả bóng nảy hoàn toàn bằng toán học Vector
class _PureVector3DCourtPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0

  _PureVector3DCourtPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Chuyển động bồng bềnh lơ lửng của toàn bộ khối sân (Floating)
    final floatY = math.sin(progress * 2 * math.pi) * (h * 0.025);

    // 2. Tính toán chu kỳ nảy của quả bóng:
    // t = 0.0 -> 0.45: Bóng nảy vút lên cao (Apex - TO RA)
    // t = 0.45 -> 1.0: Bóng rơi nhanh xuống đập sân (NHỎ LẠI & IMPACT)
    final double bounceRatio;
    if (progress < 0.45) {
      bounceRatio = math.sin((progress / 0.45) * (math.pi / 2));
    } else {
      bounceRatio = math.cos(((progress - 0.45) / 0.55) * (math.pi / 2));
    }

    // Tâm khối sân trên màn hình
    final cx = w * 0.50;
    final cy = h * 0.52 + floatY;

    // Kích thước hình thoi Isometric của mặt sân
    final courtW = w * 0.78;
    final courtH = courtW * 0.54; // Tỷ lệ góc nhìn 3D isometric 2:1
    final slabDepth = courtW * 0.12; // Độ dày cạnh khối 3D

    // 4 đỉnh mặt sân: Top, Right, Bottom, Left
    final topPt = Offset(cx, cy - courtH * 0.5);
    final rightPt = Offset(cx + courtW * 0.5, cy);
    final bottomPt = Offset(cx, cy + courtH * 0.5);
    final leftPt = Offset(cx - courtW * 0.5, cy);

    // ─── LỚP 0: ĐỔ BÓNG KHỐI TRÊN SÀN (Ground Soft Shadow) ───
    final groundShadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(
        alpha: (0.15 - floatY * 0.01).clamp(0.06, 0.22),
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, courtW * 0.10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + courtH * 0.5 + slabDepth * 0.7 - floatY * 0.3),
        width: courtW * 0.88,
        height: courtH * 0.48,
      ),
      groundShadowPaint,
    );

    // ─── LỚP 1: CẠNH TRÁI KHỐI 3D (Left 3D Slab Face - Vùng tối) ───
    final leftFacePath = Path()
      ..moveTo(leftPt.dx, leftPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy + slabDepth)
      ..lineTo(leftPt.dx, leftPt.dy + slabDepth)
      ..close();
    final leftFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF0F172A), // Slate 900
          Color(0xFF1E293B), // Slate 800
        ],
      ).createShader(leftFacePath.getBounds());
    canvas.drawPath(leftFacePath, leftFacePaint);

    // ─── LỚP 2: CẠNH PHẢI KHỐI 3D (Right 3D Slab Face - Vùng sáng vừa) ───
    final rightFacePath = Path()
      ..moveTo(bottomPt.dx, bottomPt.dy)
      ..lineTo(rightPt.dx, rightPt.dy)
      ..lineTo(rightPt.dx, rightPt.dy + slabDepth)
      ..lineTo(bottomPt.dx, bottomPt.dy + slabDepth)
      ..close();
    final rightFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF1E293B), // Slate 800
          Color(0xFF334155), // Slate 700
        ],
      ).createShader(rightFacePath.getBounds());
    canvas.drawPath(rightFacePath, rightFacePaint);

    // Vạch sáng viền dưới đáy khối 3D (Bevel Highlight)
    final bottomEdgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(leftPt.dx, leftPt.dy + slabDepth),
      Offset(bottomPt.dx, bottomPt.dy + slabDepth),
      bottomEdgePaint,
    );
    canvas.drawLine(
      Offset(bottomPt.dx, bottomPt.dy + slabDepth),
      Offset(rightPt.dx, rightPt.dy + slabDepth),
      bottomEdgePaint,
    );

    // ─── LỚP 3: MẶT SÂN CHÍNH (Top Surface - Royal Blue Sport Court) ───
    final topFacePath = Path()
      ..moveTo(topPt.dx, topPt.dy)
      ..lineTo(rightPt.dx, rightPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy)
      ..lineTo(leftPt.dx, leftPt.dy)
      ..close();

    // Gradient mặt sân bóng bẩy
    final topFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF0284C7), // Sky Blue 600
          Color(0xFF0369A1), // Sky Blue 700
          Color(0xFF1E40AF), // Blue 800
        ],
      ).createShader(topFacePath.getBounds());
    canvas.drawPath(topFacePath, topFacePaint);

    // Viền trắng bảo vệ quanh mép sân
    final outerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(topFacePath, outerBorderPaint);

    // ─── LỚP 4: VẠCH KẺ SÂN VÀ VÙNG KITCHEN ZONE ───
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Đường lưới chia đôi sân: từ trung điểm (Left-Top) sang (Right-Bottom)
    final midLT = Offset((leftPt.dx + topPt.dx) * 0.5, (leftPt.dy + topPt.dy) * 0.5);
    final midRB = Offset((rightPt.dx + bottomPt.dx) * 0.5, (rightPt.dy + bottomPt.dy) * 0.5);

    // Đường dọc giữa sân (Centerline): từ trung điểm (Top-Right) sang (Left-Bottom)
    final midTR = Offset((topPt.dx + rightPt.dx) * 0.5, (topPt.dy + rightPt.dy) * 0.5);
    final midLB = Offset((leftPt.dx + bottomPt.dx) * 0.5, (leftPt.dy + bottomPt.dy) * 0.5);
    canvas.drawLine(midTR, midLB, linePaint);

    // Vùng Non-Volley Kitchen Zone (song song với lưới 2 bên)
    final kitchenRatio = 0.22;
    final k1Start = Offset(midLT.dx + (topPt.dx - midLT.dx) * kitchenRatio, midLT.dy + (topPt.dy - midLT.dy) * kitchenRatio);
    final k1End = Offset(midRB.dx + (rightPt.dx - midRB.dx) * kitchenRatio, midRB.dy + (rightPt.dy - midRB.dy) * kitchenRatio);
    final k2Start = Offset(midLT.dx + (leftPt.dx - midLT.dx) * kitchenRatio, midLT.dy + (leftPt.dy - midLT.dy) * kitchenRatio);
    final k2End = Offset(midRB.dx + (bottomPt.dx - midRB.dx) * kitchenRatio, midRB.dy + (bottomPt.dy - midRB.dy) * kitchenRatio);
    canvas.drawLine(k1Start, k1End, linePaint);
    canvas.drawLine(k2Start, k2End, linePaint);

    // ─── LỚP 5: TẤM LƯỚI 3D ĐỨNG THẲNG Ở GIỮA SÂN ───
    final netH = courtW * 0.11;
    final netPath = Path()
      ..moveTo(midLT.dx, midLT.dy)
      ..lineTo(midRB.dx, midRB.dy)
      ..lineTo(midRB.dx, midRB.dy - netH)
      ..lineTo(midLT.dx, midLT.dy - netH)
      ..close();

    // Thân lưới trong suốt có ô
    final netPaint = Paint()
      ..color = const Color(0xFFF8FAFC).withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    canvas.drawPath(netPath, netPaint);

    // Viền mép tape trắng trên đỉnh lưới (Net White Tape)
    final netTapePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(midLT.dx, midLT.dy - netH),
      Offset(midRB.dx, midRB.dy - netH),
      netTapePaint,
    );

    // 2 Cột lưới 3D hai đầu (Net Posts)
    final postPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(midLT, Offset(midLT.dx, midLT.dy - netH - 2), postPaint);
    canvas.drawLine(midRB, Offset(midRB.dx, midRB.dy - netH - 2), postPaint);

    // ─── LỚP 6: TỌA ĐỘ VÀ VẬT LÝ QUẢ BÓNG PICKLEBALL ───
    // Vị trí chạm đất trên mặt sân bên phải
    final impactCourtX = cx + courtW * 0.16;
    final impactCourtY = cy + courtH * 0.12;

    // Độ cao bóng nảy (Z-axis jump)
    final maxJump = courtW * 0.38;
    final ballJump = bounceRatio * maxJump;

    // Tọa độ bóng trên màn hình (X di chuyển nhẹ theo vòng cung, Y bay vút lên)
    final ballX = impactCourtX + math.sin(progress * math.pi) * (courtW * 0.04);
    final ballY = impactCourtY - ballJump;

    // Độ TO RA - NHỎ LẠI theo phối cảnh 3D:
    // Khi chạm sân: scale = 1.0 (nhỏ gọn vừa khít sân)
    // Khi bay lên cao về phía người xem: scale = 1.75 (TO VÚT RA MẶT MÀN HÌNH!)
    final ballScale = 1.0 + (bounceRatio * 0.75);

    // Squash & Stretch: bẹp ngang khi chạm đất, dãn dọc khi bay
    double squashX = 1.0;
    double squashY = 1.0;
    if (bounceRatio < 0.14) {
      final touch = 1.0 - (bounceRatio / 0.14);
      squashX = 1.0 + touch * 0.28;
      squashY = 1.0 - touch * 0.25;
    } else {
      squashX = 0.94;
      squashY = 1.06;
    }

    // ─── LỚP 7: BÓNG ĐỔ TRÊN MẶT SÂN (Court Floor Shadow) ───
    final baseBallR = courtW * 0.042;
    final shadowScale = (1.2 - bounceRatio * 0.50).clamp(0.55, 1.25);
    final shadowAlpha = ((1.0 - bounceRatio * 0.65) * 0.45).clamp(0.10, 0.55);

    final ballShadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: shadowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(impactCourtX, impactCourtY),
        width: baseBallR * 2.4 * shadowScale * squashX,
        height: baseBallR * 1.1 * shadowScale * squashY,
      ),
      ballShadowPaint,
    );

    // ─── LỚP 8: SÓNG CHẤN ĐỘNG KHI CHẠM SÂN (Shockwave Ripple) ───
    if (bounceRatio < 0.32) {
      final rippleProgress = (0.32 - bounceRatio) / 0.32; // 0 -> 1
      final ripplePaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: (1.0 - rippleProgress) * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - rippleProgress) * 2.4;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(impactCourtX, impactCourtY),
          width: (baseBallR * 2.0) + (rippleProgress * courtW * 0.28),
          height: (baseBallR * 1.0) + (rippleProgress * courtH * 0.28),
        ),
        ripplePaint,
      );
    }

    // ─── LỚP 9: VỆT SÁNG NĂNG LƯỢNG KHI BÓNG LAO XUỐNG (Speed Trail) ───
    if (progress > 0.50 && bounceRatio > 0.15) {
      final trailPaint = Paint()
        ..color = const Color(0xFFFACC15).withValues(alpha: 0.35)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(ballX, ballY),
        Offset(ballX - 3.0, ballY - 14.0),
        trailPaint,
      );
    }

    // ─── LỚP 10: QUẢ BÓNG PICKLEBALL 3D VÀNG NEON (TO RA - NHỎ LẠI) ───
    canvas.save();
    canvas.translate(ballX, ballY);
    canvas.scale(ballScale * squashX, ballScale * squashY);
    canvas.rotate(progress * 4 * math.pi);

    // Vầng hào quang sáng của bóng (Ball Glow)
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD600).withValues(
        alpha: (0.25 + bounceRatio * 0.45).clamp(0.15, 0.70),
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseBallR * 0.6);
    canvas.drawCircle(Offset.zero, baseBallR * 1.2, glowPaint);

    // Cầu 3D vàng Neon
    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.88,
        colors: const [
          Color(0xFFFFFDE7), // Điểm sáng trắng vàng
          Color(0xFFFFEA00), // Vàng chanh rực rỡ
          Color(0xFFFFB300), // Vàng hổ phách
          Color(0xFFD97706), // Đổ bóng cạnh
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: baseBallR));
    canvas.drawCircle(Offset.zero, baseBallR, ballPaint);

    // Điểm phản quang Specular
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    canvas.drawCircle(
      Offset(-baseBallR * 0.32, -baseBallR * 0.32),
      baseBallR * 0.22,
      glintPaint,
    );

    // Các lỗ tròn đặc trưng của bóng Pickleball
    final holePaint = Paint()..color = const Color(0xFF78350F).withValues(alpha: 0.65);
    final holeR = baseBallR * 0.14;
    canvas.drawCircle(Offset(baseBallR * 0.26, -baseBallR * 0.26), holeR, holePaint);
    canvas.drawCircle(Offset(baseBallR * 0.38, baseBallR * 0.12), holeR, holePaint);
    canvas.drawCircle(Offset(-baseBallR * 0.14, baseBallR * 0.36), holeR, holePaint);
    canvas.drawCircle(Offset(-baseBallR * 0.36, baseBallR * 0.08), holeR, holePaint);
    canvas.drawCircle(Offset(baseBallR * 0.04, baseBallR * 0.04), holeR * 1.1, holePaint);

    canvas.restore();

    // ─── LỚP 11: TIA HẠT NĂNG LƯỢNG TÓE SÁNG KHI ĐẬP SÂN (Hit Sparks) ───
    if (bounceRatio < 0.18) {
      final sparkRatio = bounceRatio / 0.18;
      final sparkAlpha = (1.0 - sparkRatio).clamp(0.0, 1.0);
      final sparkPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: sparkAlpha)
        ..strokeWidth = (1.0 - sparkRatio) * 2.0
        ..strokeCap = StrokeCap.round;

      final sparkDist = sparkRatio * courtW * 0.16;
      const sparkAngles = [-0.8, -0.4, 0.0, 0.4, 0.8, 2.2, 2.6, 3.0];
      for (final a in sparkAngles) {
        final sx = impactCourtX + math.cos(a) * (sparkDist * 0.3);
        final sy = impactCourtY + math.sin(a) * (sparkDist * 0.18);
        final ex = impactCourtX + math.cos(a) * sparkDist;
        final ey = impactCourtY + math.sin(a) * (sparkDist * 0.6);
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PureVector3DCourtPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

