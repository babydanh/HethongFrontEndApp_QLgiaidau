import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter vẽ sân Pickleball 3D Isometric chuẩn thi đấu với:
/// - Khối đế 3D có độ dày và viền sáng neon
/// - Lưới 3D ở chính giữa sân với 2 cọc trụ
/// - Cây vợt Pickleball 3D vung đập bóng sống động (Rally swing)
/// - Quả bóng Pickleball vàng bay vồng qua lưới, nảy xuống sân có bóng đổ và vệt sáng (Motion trail)
class PickleballRallyCourtPainter extends CustomPainter {
  /// Tiến trình đánh bóng: 0.0 -> 1.0 (chu kỳ 2 pha đánh qua lại)
  final double rallyProgress;

  /// Độ mở mờ của sân (dùng khi intro hoặc morph sang hình 2)
  final double courtOpacity;

  PickleballRallyCourtPainter({
    required this.rallyProgress,
    this.courtOpacity = 1.0,
  });

  // Chuyển đổi tọa độ sân (u: dọc sân -1..1, v: ngang sân -0.5..0.5, h: độ cao thẳng đứng >= 0)
  // sang tọa độ màn hình (screenX, screenY)
  Offset _toScreen(Offset center, double u, double v, [double h = 0.0]) {
    // Chiều dài dọc sân chạy theo hướng chéo xuống phải (Tây Bắc -> Đông Nam)
    const lengthDx = 86.0;
    const lengthDy = 50.0;
    // Chiều rộng ngang sân chạy theo hướng chéo lên phải (Tây Nam -> Đông Bắc)
    const widthDx = 48.0;
    const widthDy = -28.0;

    final x = center.dx + (u * lengthDx) + (v * widthDx);
    final y = center.dy + (u * lengthDy) + (v * widthDy) - h;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (courtOpacity <= 0.001) return;

    final center = Offset(size.width / 2, size.height / 2 - 2);

    // ==========================================
    // 1. VẼ ĐẾ SÂN 3D (COURT 3D SLAB & DEPTH)
    // ==========================================
    final cTopLeft = _toScreen(center, -1.0, -0.5);
    final cTopRight = _toScreen(center, -1.0, 0.5);
    final cBottomRight = _toScreen(center, 1.0, 0.5);
    final cBottomLeft = _toScreen(center, 1.0, -0.5);

    const slabDepth = 14.0; // Độ dày khối đế 3D

    // Mặt bên dưới (Thành sân 3D mặt Đông Nam & Tây Nam)
    final sidePath = Path()
      ..moveTo(cBottomLeft.dx, cBottomLeft.dy)
      ..lineTo(cBottomRight.dx, cBottomRight.dy)
      ..lineTo(cBottomRight.dx, cBottomRight.dy + slabDepth)
      ..lineTo(cBottomLeft.dx, cBottomLeft.dy + slabDepth)
      ..close();

    final sidePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF092347),
          Color(0xFF040E1E),
        ],
      ).createShader(Rect.fromLTWH(cBottomLeft.dx, cBottomLeft.dy, 200, slabDepth + 10))
      ..color = Colors.white.withValues(alpha: courtOpacity);

    canvas.drawPath(sidePath, sidePaint);

    final leftSidePath = Path()
      ..moveTo(cTopLeft.dx, cTopLeft.dy)
      ..lineTo(cBottomLeft.dx, cBottomLeft.dy)
      ..lineTo(cBottomLeft.dx, cBottomLeft.dy + slabDepth)
      ..lineTo(cTopLeft.dx, cTopLeft.dy + slabDepth)
      ..close();

    final leftSidePaint = Paint()
      ..color = const Color(0xFF061A36).withValues(alpha: courtOpacity);

    canvas.drawPath(leftSidePath, leftSidePaint);

    // Mặt trên sân thi đấu (Court Surface)
    final courtPath = Path()
      ..moveTo(cTopLeft.dx, cTopLeft.dy)
      ..lineTo(cTopRight.dx, cTopRight.dy)
      ..lineTo(cBottomRight.dx, cBottomRight.dy)
      ..lineTo(cBottomLeft.dx, cBottomLeft.dy)
      ..close();

    final courtPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E88E5), // Xanh thể thao Sport Blue rực rỡ
          Color(0xFF1565C0),
          Color(0xFF0D47A1),
        ],
      ).createShader(Rect.fromLTWH(cTopLeft.dx, cTopLeft.dy, 200, 150))
      ..color = Colors.white.withValues(alpha: courtOpacity);

    canvas.drawPath(courtPath, courtPaint);

    // Viền sáng Neon ngoài sân (Court Border Glow)
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90 * courtOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(courtPath, borderPaint);

    // ==========================================
    // 2. VẼ CÁC VẠCH KẺ SÂN PICKLEBALL CHUẨN
    // ==========================================
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * courtOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Vạch bếp (Kitchen line - non-volley zone) sân trên: u = -0.32
    final k1Left = _toScreen(center, -0.32, -0.5);
    final k1Right = _toScreen(center, -0.32, 0.5);
    canvas.drawLine(k1Left, k1Right, linePaint);

    // Vạch bếp sân dưới: u = +0.32
    final k2Left = _toScreen(center, 0.32, -0.5);
    final k2Right = _toScreen(center, 0.32, 0.5);
    canvas.drawLine(k2Left, k2Right, linePaint);

    // Vạch chia đôi sân trên (Centerline): từ u = -1.0 đến u = -0.32 ở v = 0
    final c1Start = _toScreen(center, -1.0, 0.0);
    final c1End = _toScreen(center, -0.32, 0.0);
    canvas.drawLine(c1Start, c1End, linePaint);

    // Vạch chia đôi sân dưới: từ u = 0.32 đến u = 1.0 ở v = 0
    final c2Start = _toScreen(center, 0.32, 0.0);
    final c2End = _toScreen(center, 1.0, 0.0);
    canvas.drawLine(c2Start, c2End, linePaint);

    // ==========================================
    // 3. VẼ LƯỚI PICKLEBALL 3D Ở GIỮA SÂN (u = 0)
    // ==========================================
    const netHeight = 22.0; // Chiều cao lưới
    final netBottomLeft = _toScreen(center, 0.0, -0.54);
    final netBottomRight = _toScreen(center, 0.0, 0.54);
    final netTopLeft = _toScreen(center, 0.0, -0.54, netHeight);
    final netTopRight = _toScreen(center, 0.0, 0.54, netHeight);

    // Hai cột lưới (Posts)
    final postPaint = Paint()
      ..color = const Color(0xFF263238).withValues(alpha: courtOpacity)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(netBottomLeft, netTopLeft, postPaint);
    canvas.drawLine(netBottomRight, netTopRight, postPaint);

    // Mặt lưới bán trong suốt có vân mắt lưới
    final netPath = Path()
      ..moveTo(netBottomLeft.dx, netBottomLeft.dy)
      ..lineTo(netBottomRight.dx, netBottomRight.dy)
      ..lineTo(netTopRight.dx, netTopRight.dy)
      ..lineTo(netTopLeft.dx, netTopLeft.dy)
      ..close();

    final netFillPaint = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.40 * courtOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(netPath, netFillPaint);

    // Dải băng mép trên lưới (White Net Tape)
    final netTapePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95 * courtOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawLine(netTopLeft, netTopRight, netTapePaint);

    // Các sợi lưới đứng
    final netMeshPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 * courtOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 8; i++) {
      final frac = -0.54 + (1.08 / 9.0) * i;
      final bPos = _toScreen(center, 0.0, frac);
      final tPos = _toScreen(center, 0.0, frac, netHeight);
      canvas.drawLine(bPos, tPos, netMeshPaint);
    }

    // ==========================================
    // 4. MÔ PHỎNG VẬT LÝ VỢT & BÓNG ĐÁNH QUA LẠI ("ĐÁNH TÙM LUM")
    // ==========================================
    // Chu kỳ đánh bóng gồm 2 pha (Rally 1 & Rally 2):
    // Phase 1 (0.0 -> 0.50): Vợt 1 ở sân trên đánh bóng bay qua lưới sang sân dưới, bóng nảy
    // Phase 2 (0.50 -> 1.00): Vợt 2 ở sân dưới đánh trả bóng bay ngược lại qua lưới sang sân trên, bóng nảy
    final t = rallyProgress % 1.0;
    final isPhase1 = t < 0.50;
    final phaseT = isPhase1 ? (t / 0.50) : ((t - 0.50) / 0.50); // 0.0 -> 1.0 trong từng pha

    double ballU, ballV, ballH;
    double paddle1Swing = 0.0;
    double paddle2Swing = 0.0;

    if (isPhase1) {
      // Vợt 1 vung đánh ở đầu pha (phaseT = 0.0 -> 0.20)
      if (phaseT < 0.20) {
        paddle1Swing = math.sin((phaseT / 0.20) * math.pi);
      }

      // Quỹ đạo bóng từ sân trên (u = -0.72) sang sân dưới (u = +0.68)
      ballU = -0.72 + (1.40 * phaseT);
      ballV = -0.15 + (0.30 * phaseT);

      // Độ cao Parabol: Bay qua lưới ở phaseT = 0.45, tiếp đất nảy ở phaseT = 0.75
      if (phaseT < 0.75) {
        final flightT = phaseT / 0.75;
        // Parabol đạt đỉnh h = 38px ngay trên lưới (flightT ~ 0.55)
        ballH = 14.0 + math.sin(flightT * math.pi) * 26.0;
      } else {
        // Nhịp nảy (Bounce) sau khi tiếp đất
        final bounceT = (phaseT - 0.75) / 0.25;
        ballH = math.sin(bounceT * math.pi) * 12.0;
      }
    } else {
      // Vợt 2 vung đánh trả ở đầu pha 2 (phaseT = 0.0 -> 0.20)
      if (phaseT < 0.20) {
        paddle2Swing = math.sin((phaseT / 0.20) * math.pi);
      }

      // Quỹ đạo bóng bay ngược từ sân dưới (u = +0.68) về sân trên (u = -0.72)
      ballU = 0.68 - (1.40 * phaseT);
      ballV = 0.15 - (0.30 * phaseT);

      if (phaseT < 0.75) {
        final flightT = phaseT / 0.75;
        ballH = 14.0 + math.sin(flightT * math.pi) * 26.0;
      } else {
        final bounceT = (phaseT - 0.75) / 0.25;
        ballH = math.sin(bounceT * math.pi) * 12.0;
      }
    }

    final ballPos = _toScreen(center, ballU, ballV, ballH);
    final ballGroundPos = _toScreen(center, ballU, ballV, 0.0);

    // ==========================================
    // 5. VẼ BÓNG ĐỔ CỦA QUẢ BÓNG TRÊN MẶT SÂN
    // ==========================================
    final shadowScale = (1.0 - (ballH / 50.0).clamp(0.0, 0.55));
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: (0.28 * shadowScale * courtOpacity).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawOval(
      Rect.fromCenter(
        center: ballGroundPos,
        width: 14.0 * shadowScale,
        height: 7.0 * shadowScale,
      ),
      shadowPaint,
    );

    // ==========================================
    // 6. VẼ VỆT SÁNG CỦA QUẢ BÓNG (MOTION TRAIL)
    // ==========================================
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    const trailSteps = 5;
    for (int i = 1; i <= trailSteps; i++) {
      final trailFraction = (phaseT - (i * 0.03)).clamp(0.0, 1.0);
      double prevU, prevV, prevH;

      if (isPhase1) {
        prevU = -0.72 + (1.40 * trailFraction);
        prevV = -0.15 + (0.30 * trailFraction);
        if (trailFraction < 0.75) {
          prevH = 14.0 + math.sin((trailFraction / 0.75) * math.pi) * 26.0;
        } else {
          prevH = math.sin(((trailFraction - 0.75) / 0.25) * math.pi) * 12.0;
        }
      } else {
        prevU = 0.68 - (1.40 * trailFraction);
        prevV = 0.15 - (0.30 * trailFraction);
        if (trailFraction < 0.75) {
          prevH = 14.0 + math.sin((trailFraction / 0.75) * math.pi) * 26.0;
        } else {
          prevH = math.sin(((trailFraction - 0.75) / 0.25) * math.pi) * 12.0;
        }
      }

      final prevPos = _toScreen(center, prevU, prevV, prevH);
      final alpha = ((1.0 - (i / trailSteps)) * 0.55 * courtOpacity).clamp(0.0, 1.0);
      trailPaint.color = Colors.white.withValues(alpha: alpha);
      trailPaint.strokeWidth = (trailSteps - i + 1) * 0.7;

      canvas.drawLine(prevPos, ballPos, trailPaint);
    }

    // ==========================================
    // 7. VẼ CÂY VỢT PICKLEBALL 1 (SÂN TRÊN)
    // ==========================================
    final paddle1Pos = _toScreen(center, -0.78, -0.18, 16.0);
    _drawPaddle(
      canvas: canvas,
      position: paddle1Pos,
      swingAngle: paddle1Swing * -0.65, // Vung vợt về trước đập bóng
      isTopPlayer: true,
      opacity: courtOpacity,
    );

    // ==========================================
    // 8. VẼ CÂY VỢT PICKLEBALL 2 (SÂN DƯỚI)
    // ==========================================
    final paddle2Pos = _toScreen(center, 0.76, 0.18, 16.0);
    _drawPaddle(
      canvas: canvas,
      position: paddle2Pos,
      swingAngle: paddle2Swing * 0.65, // Vung vợt đón bóng đập trả
      isTopPlayer: false,
      opacity: courtOpacity,
    );

    // ==========================================
    // 9. VẼ QUẢ BÓNG PICKLEBALL VÀNG 3D
    // ==========================================
    const ballRadius = 6.8;

    // Hào quang vàng neon của quả bóng
    final ballGlowPaint = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.45 * courtOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(ballPos, ballRadius + 2.0, ballGlowPaint);

    // Thân quả bóng với Radial Gradient 3D
    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: [
          const Color(0xFFFFFF8D), // Điểm sáng bóng loáng
          const Color(0xFFFFD600), // Vàng chanh đặc trưng bóng pickleball
          const Color(0xFFFF9100), // Vùng đổ bóng 3D
        ],
      ).createShader(Rect.fromCircle(center: ballPos, radius: ballRadius))
      ..color = Colors.white.withValues(alpha: courtOpacity);

    canvas.drawCircle(ballPos, ballRadius, ballPaint);

    // Các chấm đen đặc trưng của bóng Pickleball
    final dotPaint = Paint()
      ..color = const Color(0xFF37474F).withValues(alpha: 0.65 * courtOpacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(ballPos + const Offset(-1.8, -1.2), 0.9, dotPaint);
    canvas.drawCircle(ballPos + const Offset(1.8, -1.5), 0.9, dotPaint);
    canvas.drawCircle(ballPos + const Offset(-0.2, 1.8), 0.9, dotPaint);
    canvas.drawCircle(ballPos + const Offset(2.2, 1.2), 0.9, dotPaint);
  }

  /// Hàm vẽ cây vợt Pickleball 3D chuyên nghiệp
  void _drawPaddle({
    required Canvas canvas,
    required Offset position,
    required double swingAngle,
    required bool isTopPlayer,
    required double opacity,
  }) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(swingAngle + (isTopPlayer ? -0.25 : 0.25));

    // 1. Cán vợt (Handle / Grip)
    final handlePaint = Paint()
      ..color = const Color(0xFFECEFF1).withValues(alpha: opacity)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final gripOffset = isTopPlayer ? const Offset(-12, -14) : const Offset(12, 14);
    canvas.drawLine(Offset.zero, gripOffset, handlePaint);

    // 2. Mặt vợt Pickleball (Paddle Face)
    final faceRect = isTopPlayer
        ? const Rect.fromLTWH(-3, -3, 20, 15)
        : const Rect.fromLTWH(-17, -12, 20, 15);

    // Lớp mặt graphite màu đen than
    final facePaint = Paint()
      ..color = const Color(0xFF212121).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(faceRect, const Radius.circular(5.0)), facePaint);

    // Viền bảo vệ cạnh vợt màu xanh Neon Sport Blue
    final rimPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.95 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(RRect.fromRectAndRadius(faceRect, const Radius.circular(5.0)), rimPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PickleballRallyCourtPainter oldDelegate) {
    return oldDelegate.rallyProgress != rallyProgress ||
        oldDelegate.courtOpacity != courtOpacity;
  }
}
