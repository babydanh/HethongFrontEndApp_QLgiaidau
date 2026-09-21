import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Widget vẽ hiệu ứng nền bản đồ giao thông đô thị cách điệu (Vector Blurred Map Pattern)
/// Tạo cảm giác bản đồ mờ phía dưới giống như các app bản đồ / gọi xe hiện đại (Xanh SM, Grab, v.v.).
///
/// Họa tiết gồm:
/// - Các khối khu dân cư / công viên mờ (soft blocks)
/// - Mạng lưới trục đường chính (arterial roads) & đường nhánh (local roads) cách điệu
/// - Vòng xoay giao thông (roundabout) & nút giao uốn lượn
/// - Lớp phủ gradient và backdrop blur để nội dung phía trước luôn nổi bật, rõ ràng
class BlurredMapBackground extends StatelessWidget {
  final Widget? child;
  final double opacity;
  final bool isDark;

  const BlurredMapBackground({
    super.key,
    this.child,
    this.opacity = 1.0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark || Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Lớp nền cơ sở
        Container(
          color: effectiveDark
              ? const Color(0xFF0B111E)
              : const Color(0xFFF8FAFC),
        ),

        // 2. Lớp họa tiết bản đồ vẽ bằng CustomPainter
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              painter: _StylizedCityMapPainter(isDark: effectiveDark),
            ),
          ),
        ),

        // 3. Lớp kính mờ (BackdropFilter) nhẹ làm dịu các đường nét
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
            child: const SizedBox.shrink(),
          ),
        ),

        // 4. Lớp gradient phủ trên và dưới để hòa quyện vào nội dung app
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: effectiveDark
                    ? [
                        const Color(0xFF0B111E).withValues(alpha: 0.85),
                        const Color(0xFF0B111E).withValues(alpha: 0.40),
                        const Color(0xFF0B111E).withValues(alpha: 0.65),
                        const Color(0xFF0B111E).withValues(alpha: 0.92),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.88),
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.60),
                        Colors.white.withValues(alpha: 0.90),
                      ],
                stops: const [0.0, 0.25, 0.75, 1.0],
              ),
            ),
          ),
        ),

        // 5. Nội dung con
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

class _StylizedCityMapPainter extends CustomPainter {
  final bool isDark;

  _StylizedCityMapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Màu sắc các yếu tố bản đồ
    final blockColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.35)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.45);

    final greenAreaColor = isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.20)
        : const Color(0xFFDCFCE7).withValues(alpha: 0.40);

    final waterColor = isDark
        ? const Color(0xFF1E3A8A).withValues(alpha: 0.18)
        : const Color(0xFFE0F2FE).withValues(alpha: 0.50);

    final roadColor = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.45)
        : const Color(0xFFCBD5E1).withValues(alpha: 0.70);

    final mainRoadColor = isDark
        ? const Color(0xFF475569).withValues(alpha: 0.55)
        : const Color(0xFF94A3B8).withValues(alpha: 0.65);

    final highwayColor = isDark
        ? const Color(0xFF64748B).withValues(alpha: 0.40)
        : const Color(0xFFFCD34D).withValues(alpha: 0.45);

    // ── 1. Vẽ các mảng công viên / mặt nước ──
    final parkPaint = Paint()
      ..color = greenAreaColor
      ..style = PaintingStyle.fill;

    // Công viên phía tây bắc
    final parkPath1 = Path()
      ..moveTo(w * 0.05, h * 0.12)
      ..lineTo(w * 0.38, h * 0.10)
      ..quadraticBezierTo(w * 0.42, h * 0.18, w * 0.32, h * 0.24)
      ..lineTo(w * 0.08, h * 0.22)
      ..close();
    canvas.drawPath(parkPath1, parkPaint);

    // Khu sinh thái phía đông nam
    final parkPath2 = Path()
      ..moveTo(w * 0.65, h * 0.60)
      ..lineTo(w * 0.95, h * 0.58)
      ..lineTo(w * 0.92, h * 0.76)
      ..quadraticBezierTo(w * 0.75, h * 0.78, w * 0.62, h * 0.72)
      ..close();
    canvas.drawPath(parkPath2, parkPaint);

    // Mặt nước / Sông uốn lượn phong cách bản đồ
    final waterPaint = Paint()
      ..color = waterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(-20, h * 0.38)
      ..cubicTo(w * 0.30, h * 0.35, w * 0.50, h * 0.48, w * 0.75, h * 0.42)
      ..cubicTo(w * 0.88, h * 0.39, w * 0.95, h * 0.45, w + 30, h * 0.44);
    canvas.drawPath(riverPath, waterPaint);

    // ── 2. Vẽ các ô phố (Building / City Blocks) ──
    final blockPaint = Paint()
      ..color = blockColor
      ..style = PaintingStyle.fill;

    void drawBlock(double left, double top, double width, double height, [double radius = 4]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, height),
          Radius.circular(radius),
        ),
        blockPaint,
      );
    }

    // Một số ô phố mẫu đô thị
    drawBlock(w * 0.12, h * 0.28, w * 0.16, h * 0.06);
    drawBlock(w * 0.32, h * 0.27, w * 0.18, h * 0.07);
    drawBlock(w * 0.55, h * 0.22, w * 0.22, h * 0.08);
    drawBlock(w * 0.14, h * 0.48, w * 0.20, h * 0.08);
    drawBlock(w * 0.38, h * 0.52, w * 0.16, h * 0.07);
    drawBlock(w * 0.60, h * 0.46, w * 0.25, h * 0.09);
    drawBlock(w * 0.10, h * 0.68, w * 0.22, h * 0.10);
    drawBlock(w * 0.36, h * 0.70, w * 0.20, h * 0.09);

    // ── 3. Mạng lưới đường nhánh (Local roads - đường nét mảnh) ──
    final localRoadPaint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Các đường cắt ngang song song
    for (double y = h * 0.08; y < h; y += h * 0.09) {
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y + (math.sin(y) * 12)),
        localRoadPaint,
      );
    }

    // Các đường nhánh dọc
    for (double x = w * 0.10; x < w; x += w * 0.18) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 18, h),
        localRoadPaint,
      );
    }

    // ── 4. Các trục đường huyết mạch chính (Main arterial roads) ──
    final mainRoadPaint = Paint()
      ..color = mainRoadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Đường vành đai / Trục lớn cắt xiên
    final arterialPath1 = Path()
      ..moveTo(-10, h * 0.20)
      ..cubicTo(w * 0.35, h * 0.24, w * 0.60, h * 0.12, w + 20, h * 0.18);
    canvas.drawPath(arterialPath1, mainRoadPaint);

    final arterialPath2 = Path()
      ..moveTo(w * 0.25, -20)
      ..cubicTo(w * 0.30, h * 0.35, w * 0.22, h * 0.65, w * 0.45, h + 30);
    canvas.drawPath(arterialPath2, mainRoadPaint);

    final arterialPath3 = Path()
      ..moveTo(-20, h * 0.62)
      ..lineTo(w * 0.50, h * 0.58)
      ..cubicTo(w * 0.72, h * 0.56, w * 0.85, h * 0.68, w + 20, h * 0.80);
    canvas.drawPath(arterialPath3, mainRoadPaint);

    // ── 5. Đại lộ / Cao tốc chính (Highway với viền màu vàng cam nhạt) ──
    final highwayCasingPaint = Paint()
      ..color = isDark ? Colors.black38 : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final highwayPaint = Paint()
      ..color = highwayColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;

    final highwayPath = Path()
      ..moveTo(-20, h * 0.82)
      ..cubicTo(w * 0.30, h * 0.78, w * 0.55, h * 0.32, w + 30, h * 0.28);

    canvas.drawPath(highwayPath, highwayCasingPaint);
    canvas.drawPath(highwayPath, highwayPaint);

    // ── 6. Nút giao thông vòng xoay (Roundabouts) ──
    final roundaboutCenter1 = Offset(w * 0.50, h * 0.58);
    canvas.drawCircle(
      roundaboutCenter1,
      16,
      Paint()
        ..color = isDark ? const Color(0xFF0F172A) : Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      roundaboutCenter1,
      16,
      Paint()
        ..color = mainRoadColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );
    // Đảo cây xanh ở tâm bùng binh
    canvas.drawCircle(
      roundaboutCenter1,
      8,
      Paint()
        ..color = greenAreaColor
        ..style = PaintingStyle.fill,
    );

    // Vòng xoay thứ 2 góc trên
    final roundaboutCenter2 = Offset(w * 0.75, h * 0.22);
    canvas.drawCircle(
      roundaboutCenter2,
      14,
      Paint()
        ..color = isDark ? const Color(0xFF0F172A) : Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      roundaboutCenter2,
      14,
      Paint()
        ..color = mainRoadColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );
    canvas.drawCircle(
      roundaboutCenter2,
      6.5,
      Paint()
        ..color = greenAreaColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _StylizedCityMapPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
