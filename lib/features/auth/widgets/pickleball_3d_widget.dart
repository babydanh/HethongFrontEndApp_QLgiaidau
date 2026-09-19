import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Đại diện cho một điểm trong không gian 3 chiều (x, y, z) trên hình cầu đơn vị
class Point3D {
  final double x;
  final double y;
  final double z;
  const Point3D(this.x, this.y, this.z);

  Point3D rotate(double yaw, double pitch, double roll) {
    // Xoay quanh trục Y (Yaw)
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final x1 = x * cosY + z * sinY;
    final y1 = y;
    final z1 = -x * sinY + z * cosY;

    // Xoay quanh trục X (Pitch)
    final cosX = math.cos(pitch);
    final sinX = math.sin(pitch);
    final x2 = x1;
    final y2 = y1 * cosX - z1 * sinX;
    final z2 = y1 * sinX + z1 * cosX;

    // Xoay quanh trục Z (Roll)
    final cosZ = math.cos(roll);
    final sinZ = math.sin(roll);
    final x3 = x2 * cosZ - y2 * sinZ;
    final y3 = x2 * sinZ + y2 * cosZ;
    final z3 = z2;

    return Point3D(x3, y3, z3);
  }
}

/// Widget hiển thị trái bóng Pickleball 3D với chuyển động xoay Blender phong cách thể thao
class Pickleball3DWidget extends StatelessWidget {
  final double size;
  final double rotationY;
  final double rotationX;
  final double rotationZ;
  final Color primaryColor;
  final Color highlightColor;
  final Color shadowColor;
  final bool showGlow;
  final bool showGroundShadow;

  const Pickleball3DWidget({
    super.key,
    this.size = 140,
    required this.rotationY,
    this.rotationX = -0.35, // Độ nghiêng trục 3D tự nhiên
    this.rotationZ = 0.25,
    this.primaryColor = const Color(0xFFD8F800), // Vàng chanh Neon đặc trưng Pickleball
    this.highlightColor = const Color(0xFFF7FFA8),
    this.shadowColor = const Color(0xFF5F8500),
    this.showGlow = true,
    this.showGroundShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 40,
      height: size + (showGroundShadow ? 60 : 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Đổ bóng nền 3D dưới đáy quả bóng (Ground Contact Shadow)
          if (showGroundShadow)
            Positioned(
              bottom: 8,
              child: Container(
                width: size * 0.75,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(size * 0.75, 18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

          // Vầng hào quang phát sáng Neon xung quanh (Blender Specular Glow)
          if (showGlow)
            Container(
              width: size * 0.95,
              height: size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2), // Pha chút ánh sáng xanh thể thao
                    blurRadius: 48,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),

          // Khối cầu 3D Pickleball vẽ bằng CustomPainter
          CustomPaint(
            size: Size(size, size),
            painter: _Pickleball3DPainter(
              yaw: rotationY,
              pitch: rotationX,
              roll: rotationZ,
              primaryColor: primaryColor,
              highlightColor: highlightColor,
              shadowColor: shadowColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pickleball3DPainter extends CustomPainter {
  final double yaw;
  final double pitch;
  final double roll;
  final Color primaryColor;
  final Color highlightColor;
  final Color shadowColor;

  static final List<Point3D> _sphereHoles = _generateFibonacciSphereHoles(38);

  _Pickleball3DPainter({
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.primaryColor,
    required this.highlightColor,
    required this.shadowColor,
  });

  /// Thuật toán phân bổ lỗ đồng đều trên quả cầu 3D (Fibonacci Sphere Algorithm)
  static List<Point3D> _generateFibonacciSphereHoles(int count) {
    final List<Point3D> points = [];
    final phi = math.pi * (3.0 - math.sqrt(5.0)); // Góc vàng Golden Angle (~2.399 rad)

    for (int i = 0; i < count; i++) {
      final y = 1.0 - (i / (count - 1)) * 2.0; // Từ 1 xuống -1
      final radius = math.sqrt(1.0 - y * y);
      final theta = phi * i;

      final x = math.cos(theta) * radius;
      final z = math.sin(theta) * radius;

      points.add(Point3D(x, y, z));
    }
    return points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2.0;
    final center = Offset(radius, radius);

    // Bọc toàn bộ trong clip hình cầu để tuyệt đối không có chi tiết nào lòi ra ngoài mép bóng
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // 1. Thân cầu 3D với dải sáng Radial chuyển mượt tươi sáng
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.38),
        radius: 0.95,
        colors: [
          highlightColor,
          primaryColor,
          Color.lerp(primaryColor, shadowColor, 0.5)!,
          shadowColor,
          const Color(0xFF526D00),
        ],
        stops: const [0.0, 0.38, 0.72, 0.92, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // 2. Các lỗ tròn đặc trưng của bóng Pickleball 3D
    final holeRadius = radius * 0.125;
    final interiorCavityColor = const Color(0xFF2E4500); // Màu rêu đậm mềm mại của ruột bóng, không dùng đen

    for (final rawPoint in _sphereHoles) {
      final rotated = rawPoint.rotate(yaw, pitch, roll);

      // Chỉ vẽ các lỗ hướng về mặt trước
      if (rotated.z > 0.08) {
        final holeCenter = Offset(
          center.dx + rotated.x * radius * 0.90,
          center.dy + rotated.y * radius * 0.90,
        );

        // Phối cảnh 3D chuẩn: trục hướng tâm bị nén theo z (cosin góc nhìn), trục tiếp tuyến giữ nguyên
        final depthScale = math.max(0.18, rotated.z);
        final currentHoleRadius = holeRadius * (0.88 + 0.12 * rotated.z);
        final normalAngle = math.atan2(rotated.y, rotated.x);

        canvas.save();
        canvas.translate(holeCenter.dx, holeCenter.dy);
        canvas.rotate(normalAngle);

        // width bị nén theo depthScale (hướng tâm), height giữ nguyên (tiếp tuyến)
        final holeRect = Rect.fromCenter(
          center: Offset.zero,
          width: currentHoleRadius * 2 * depthScale,
          height: currentHoleRadius * 2,
        );

        // Khoang bên trong lỗ
        final holeInteriorPaint = Paint()
          ..color = interiorCavityColor
          ..style = PaintingStyle.fill;
        canvas.drawOval(holeRect, holeInteriorPaint);

        // Đổ bóng viền lỗ mềm mại
        final innerShadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, radius * 0.02)
          ..color = const Color(0xFF1B2C00).withValues(alpha: 0.5 * depthScale);
        canvas.drawOval(holeRect, innerShadowPaint);

        // Viền sáng hốc lỗ phía hướng sáng
        if (rotated.z > 0.3) {
          final rimHolePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.5, radius * 0.015)
            ..color = highlightColor.withValues(alpha: 0.45 * rotated.z);

          canvas.drawArc(
            holeRect.deflate(0.2),
            math.pi * 0.5,
            math.pi,
            false,
            rimHolePaint,
          );
        }

        canvas.restore();
      }
    }

    // 3. Phản quang bề mặt bóng nhựa Specular Highlight
    final specularPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(center.dx - radius * 0.36, center.dy - radius * 0.38),
          radius: radius * 0.32,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.35, center.dy - radius * 0.36),
        width: radius * 0.50,
        height: radius * 0.32,
      ),
      specularPaint,
    );

    // 4. Viền mép cầu phản xạ ánh sáng (Rim Light)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, radius * 0.035)
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: [
          highlightColor.withValues(alpha: 0.7),
          primaryColor.withValues(alpha: 0.2),
          const Color(0xFF00E5FF).withValues(alpha: 0.35),
          shadowColor.withValues(alpha: 0.1),
          highlightColor.withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius - 0.5, rimPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Pickleball3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.roll != roll ||
        oldDelegate.primaryColor != primaryColor;
  }
}
