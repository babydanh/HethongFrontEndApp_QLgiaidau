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
              painter: PickleballCourtPainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class PickleballCourtPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0

  PickleballCourtPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.52);

    // Kích thước chuẩn tỉ lệ sân Pickleball trong không gian 2D trước khi chiếu 3D
    final courtW = w * 0.62;
    final courtH = w * 0.58;
    const cornerRadius = 14.0;
    const podiumDepth = 18.0;

    // Góc nghiêng Isometric chuẩn
    const isoScaleY = 0.56;
    const isoAngle = -math.pi / 4; // 45 độ

    // ─── 0. Đổ bóng tổng thể của toàn bộ khối sân lên nền trắng (Floating Shadow) ───
    final groundShadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    canvas.save();
    canvas.translate(center.dx, center.dy + podiumDepth + 6);
    canvas.scale(1.0, isoScaleY);
    canvas.rotate(isoAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: courtW + 6, height: courtH + 6),
        const Radius.circular(cornerRadius + 4),
      ),
      groundShadowPaint,
    );
    canvas.restore();

    // ─── 1. Vẽ Khối Đế 3D (Podium Base) với sườn bo cong mượt mà ───
    // Dựng độ dày khối 3D bằng nhiều lớp lát mỏng liên tục để bo tròn các cạnh 3D hoàn hảo
    const sliceCount = 18;
    for (int i = sliceCount; i >= 0; i--) {
      final tSlice = i / sliceCount;
      final sliceY = center.dy + (podiumDepth * tSlice);
      // Đổ bóng gradient tối dần về phía đáy
      final sliceColor = Color.lerp(
        const Color(0xFF1E2D44), // Mặt trên xám xanh navy sang trọng
        const Color(0xFF0D1624), // Đáy sâu đậm nét
        tSlice,
      )!;

      final slicePaint = Paint()..color = sliceColor;

      canvas.save();
      canvas.translate(center.dx, sliceY);
      canvas.scale(1.0, isoScaleY);
      canvas.rotate(isoAngle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: courtW, height: courtH),
          const Radius.circular(cornerRadius),
        ),
        slicePaint,
      );
      canvas.restore();
    }

    // Viền sáng tinh tế ở mép gờ trên cùng của đế (Bevel Highlight)
    final bevelPaint = Paint()
      ..color = const Color(0xFF3B506D).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, isoScaleY);
    canvas.rotate(isoAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: courtW, height: courtH),
        const Radius.circular(cornerRadius),
      ),
      bevelPaint,
    );
    canvas.restore();

    // ─── 2. Mặt Sân Pickleball Màu Xanh Cobalt Rực Rỡ (Court Surface) ───
    final surfaceW = courtW - 6.0;
    final surfaceH = courtH - 6.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, isoScaleY);
    canvas.rotate(isoAngle);

    // Nền sân xanh gradient rực rỡ như ảnh mẫu Blender
    final surfacePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2688F5), // Xanh dương sáng rực phía bắt sáng
          Color(0xFF1562CA), // Xanh cobalt đậm đà phía dưới
        ],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: surfaceW, height: surfaceH));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: surfaceW, height: surfaceH),
        const Radius.circular(cornerRadius - 2),
      ),
      surfacePaint,
    );

    // ─── 3. Đường Kẻ Sân Trắng Chuẩn Thể Thao (White Court Markings) ───
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Đường biên trắng ngoài bo cong (Perimeter line)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: surfaceW - 8.0, height: surfaceH - 8.0),
        const Radius.circular(cornerRadius - 4),
      ),
      linePaint,
    );

    // Đường giữa sân dọc (Centerline) - Đúng luật Pickleball: CHỈ chạy từ đường Kitchen tới Baseline
    const kitchenOffset = 18.0;
    // Nửa sân xa (Opponent side)
    canvas.drawLine(
      Offset(0, -kitchenOffset),
      Offset(0, -(surfaceH - 8.0) / 2),
      linePaint,
    );
    // Nửa sân gần (Player side)
    canvas.drawLine(
      Offset(0, kitchenOffset),
      Offset(0, (surfaceH - 8.0) / 2),
      linePaint,
    );

    // Đường Kitchen ngang song song lưới (Non-Volley Zone lines)
    canvas.drawLine(
      Offset(-(surfaceW - 8.0) / 2, -kitchenOffset),
      Offset((surfaceW - 8.0) / 2, -kitchenOffset),
      linePaint..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(-(surfaceW - 8.0) / 2, kitchenOffset),
      Offset((surfaceW - 8.0) / 2, kitchenOffset),
      linePaint..strokeWidth = 1.8,
    );

    canvas.restore();

    // ─── 4. Dựng Lưới Thể Thao 3D Đứng Dọc Theo Đường Ngang (Standing 3D Net) ───
    final netLeft2D = _toScreenIso(Offset(-(surfaceW - 8.0) / 2, 0), center, isoScaleY, isoAngle);
    final netRight2D = _toScreenIso(Offset((surfaceW - 8.0) / 2, 0), center, isoScaleY, isoAngle);
    const netH = 13.0;

    final netMeshPath = Path()
      ..moveTo(netLeft2D.dx, netLeft2D.dy)
      ..lineTo(netLeft2D.dx, netLeft2D.dy - netH)
      ..lineTo(netRight2D.dx, netRight2D.dy - netH)
      ..lineTo(netRight2D.dx, netRight2D.dy)
      ..close();

    // Lưới thể thao xám đậm mờ
    final netMeshPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(netMeshPath, netMeshPaint);

    // Dải băng viền trắng trên đỉnh lưới (Net Top Tape)
    final netTapePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(netLeft2D.dx, netLeft2D.dy - netH),
      Offset(netRight2D.dx, netRight2D.dy - netH),
      netTapePaint,
    );

    // Cọc lưới hai bên (Net Posts)
    final postPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(netLeft2D, Offset(netLeft2D.dx, netLeft2D.dy - netH - 2), postPaint);
    canvas.drawLine(netRight2D, Offset(netRight2D.dx, netRight2D.dy - netH - 2), postPaint);

    // ─── 5. Quỹ Đạo Đánh Smash & Nảy Bóng Chân Thực ───
    final t = progress; // 0.0 -> 1.0

    // Điểm bóng xuất phát ở nửa sân xa (bên trái phía sau lưới)
    final startCourt2D = Offset(-surfaceW * 0.28, -surfaceH * 0.28);
    // Điểm bóng smash đập xuống sân gần (bên phải phía trước lưới)
    final hitCourt2D = Offset(surfaceW * 0.10, surfaceH * 0.16);

    // Giai đoạn:
    // 0.0 -> 0.65: Smash từ xa bay qua lưới cắm thẳng xuống đất
    // 0.65 -> 1.0: Bóng nảy lên bật cao sau cú chạm đất
    final bool isSmashing = t <= 0.65;
    final double currentFlyHeight;
    final Offset currentCourt2D;
    final double trailOpacity;
    final double squashX;
    final double squashY;

    final maxFlyHeight = h * 0.26;

    if (isSmashing) {
      final smashT = t / 0.65; // 0..1
      // Quỹ đạo ngang di chuyển từ điểm phát đến điểm đập
      currentCourt2D = Offset.lerp(startCourt2D, hitCourt2D, smashT)!;
      // Đường cong Parabol bay qua lưới rồi cắm xuống sân (cao nhất ở giữa quỹ đạo)
      currentFlyHeight = math.sin(smashT * math.pi).abs() * maxFlyHeight;
      trailOpacity = (1.0 - (smashT * 0.3)).clamp(0.0, 1.0);

      // Hiệu ứng Squash & Stretch: lúc sắp chạm đất thì dãn dài theo hướng rơi
      if (smashT > 0.85) {
        final touchT = (smashT - 0.85) / 0.15;
        squashX = 1.0 + touchT * 0.22; // Bẹt ngang khi chạm đất
        squashY = 1.0 - touchT * 0.22; // Nén dọc khi chạm đất
      } else {
        squashX = 0.95;
        squashY = 1.05;
      }
    } else {
      final reboundT = (t - 0.65) / 0.35; // 0..1
      // Bóng nảy lên tại chỗ (hoặc trôi nhẹ về trước)
      currentCourt2D = Offset.lerp(hitCourt2D, Offset(hitCourt2D.dx + 6, hitCourt2D.dy + 4), reboundT)!;
      // Độ cao nảy hồi phục (nảy lên khoảng 60% chiều cao ban đầu)
      currentFlyHeight = math.sin(reboundT * math.pi).abs() * (maxFlyHeight * 0.55);
      // Vệt trail mờ dần khi bóng nảy
      trailOpacity = (1.0 - reboundT * 1.5).clamp(0.0, 1.0);

      if (reboundT < 0.15) {
        // Đang phục hồi từ cú nén đất
        final unSquash = reboundT / 0.15;
        squashX = 1.22 - unSquash * 0.22;
        squashY = 0.78 + unSquash * 0.22;
      } else {
        squashX = 1.0;
        squashY = 1.0;
      }
    }

    final currentScreenGround = _toScreenIso(currentCourt2D, center, isoScaleY, isoAngle);
    final ballCenter = Offset(
      currentScreenGround.dx,
      currentScreenGround.dy - currentFlyHeight,
    );

    // ─── 6. Kích Thước Quả Bóng (Cân đối tinh tế, đúng tỉ lệ) ───
    final baseBallRadius = (w * 0.060).clamp(7.0, 14.0);
    final heightRatio = (currentFlyHeight / maxFlyHeight).clamp(0.0, 1.0);
    // Khi bay lên cao và gần camera thì to ra nhẹ (scale 1.25x), chạm đất thì scale 1.0x
    final scaleFactor = 1.0 + (heightRatio * 0.25);
    final ballR = baseBallRadius * scaleFactor;

    // ─── 7. Bóng Đổ Dưới Mặt Sân (Realistic Ground Shadow) ───
    final shadowScale = (1.15 - heightRatio * 0.45).clamp(0.70, 1.2);
    final shadowAlpha = ((1.0 - heightRatio * 0.55) * 0.45).clamp(0.16, 0.55);
    final shadowRect = Rect.fromCenter(
      center: currentScreenGround,
      width: ballR * 2.2 * shadowScale * squashX,
      height: ballR * 0.85 * shadowScale * squashY,
    );
    final shadowPaint = Paint()
      ..color = const Color(0xFF0A1220).withValues(alpha: shadowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawOval(shadowRect, shadowPaint);

    // Vòng sóng chấn động khi bóng smash đập sân (Impact Ripple)
    if (t >= 0.62 && t <= 0.78) {
      final impactPhase = (t - 0.62) / 0.16; // 0..1
      final hitScreen = _toScreenIso(hitCourt2D, center, isoScaleY, isoAngle);
      final ripplePaint = Paint()
        ..color = Colors.white.withValues(alpha: (1.0 - impactPhase) * 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - impactPhase) * 2.5;
      final rippleRect = Rect.fromCenter(
        center: hitScreen,
        width: (ballR * 2.0 + impactPhase * 30.0),
        height: (ballR * 0.85 + impactPhase * 13.0),
      );
      canvas.drawOval(rippleRect, ripplePaint);
    }

    // ─── 8. Vệt Đánh Smash Dạng Ống Cong 3D Uốn Lượn (3D Tubular Motion Trail) ───
    if (trailOpacity > 0.02) {
      final startScreen = _toScreenIso(startCourt2D, center, isoScaleY, isoAngle);
      final startAir = Offset(startScreen.dx - 6, startScreen.dy - 10);
      final apexAir = Offset(
        (startScreen.dx + hitCourt2D.dx) / 2 + 10,
        center.dy - maxFlyHeight - 8,
      );

      final tubePath = Path()
        ..moveTo(startAir.dx, startAir.dy)
        ..quadraticBezierTo(apexAir.dx, apexAir.dy, ballCenter.dx, ballCenter.dy);

      // Lớp 1: Vệt mờ ánh sáng bao quanh ống
      final tubeGlowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05 * trailOpacity),
            Colors.white.withValues(alpha: 0.35 * trailOpacity),
          ],
        ).createShader(Rect.fromPoints(startAir, ballCenter))
        ..style = PaintingStyle.stroke
        ..strokeWidth = ballR * 1.05
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(tubePath, tubeGlowPaint);

      // Lớp 2: Thân ống 3D chính màu trắng bạc bóng loáng
      final tubeBodyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE2E8F0).withValues(alpha: 0.20 * trailOpacity),
            Colors.white.withValues(alpha: 0.95 * trailOpacity),
          ],
        ).createShader(Rect.fromPoints(startAir, ballCenter))
        ..style = PaintingStyle.stroke
        ..strokeWidth = ballR * 0.65
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(tubePath, tubeBodyPaint);

      // Lớp 3: Đường sống phản quang sắc nét ở giữa ống (Specular Spine)
      final tubeHighlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.90 * trailOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ballR * 0.20
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(tubePath, tubeHighlightPaint);
    }

    // ─── 9. Quả Bóng Pickleball 3D Vàng Óng Ánh (Glossy 3D Sphere) ───
    canvas.save();
    canvas.translate(ballCenter.dx, ballCenter.dy);
    canvas.scale(squashX, squashY);

    final ballGradientPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.38, -0.38),
        radius: 0.85,
        colors: [
          Color(0xFFFFFDE7), // Điểm sáng bóng trắng vàng
          Color(0xFFFFEA00), // Vàng chanh tươi pickleball
          Color(0xFFFFB300), // Vàng cam ấm
          Color(0xFFE65100), // Bóng tối viền quả cầu
        ],
        stops: [0.0, 0.45, 0.80, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: ballR));

    canvas.drawCircle(Offset.zero, ballR, ballGradientPaint);

    // Vết phản chiếu ánh sáng trắng sắc nét (Specular Glint)
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    canvas.drawCircle(
      Offset(-ballR * 0.32, -ballR * 0.32),
      ballR * 0.18,
      glintPaint,
    );

    // ─── 10. Lỗ Tròn Đặc Trưng Pickleball (Hổ phách mờ, tự nhiên) ───
    final dimplePaint = Paint()
      ..color = const Color(0xFFB45309).withValues(alpha: 0.50);

    final dimpleOffsets = [
      Offset(ballR * 0.22, -ballR * 0.28),
      Offset(ballR * 0.44, ballR * 0.05),
      Offset(-ballR * 0.05, ballR * 0.32),
      Offset(ballR * 0.28, ballR * 0.35),
      Offset(-ballR * 0.35, ballR * 0.15),
      Offset(-ballR * 0.20, -ballR * 0.35),
    ];

    final dimpleR = ballR * 0.11;
    for (final offset in dimpleOffsets) {
      canvas.drawCircle(offset, dimpleR, dimplePaint);
    }

    canvas.restore();
  }

  /// Chuyển đổi tọa độ 2D trên mặt phẳng sân thành tọa độ màn hình theo phép chiếu Isometric
  Offset _toScreenIso(Offset p, Offset center, double scaleY, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    // Xoay 45 độ
    final rotX = p.dx * cosA - p.dy * sinA;
    final rotY = p.dx * sinA + p.dy * cosA;
    // Thu hẹp Y theo tỉ lệ phối cảnh Isometric
    return Offset(center.dx + rotX, center.dy + rotY * scaleY);
  }

  @override
  bool shouldRepaint(covariant PickleballCourtPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
