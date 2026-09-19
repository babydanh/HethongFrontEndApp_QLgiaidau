import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Painter vẽ hiệu ứng tia laser quét tạo sân đấu 3D Isometric
/// và chuyển dịch co tụ (morph) thành vòng hào quang năng lượng bao quanh logo
class CourtLaser3DPainter extends CustomPainter {
  /// Tiến trình laser vẽ sân đấu (0.0 -> 1.0)
  final double laserProgress;

  /// Tiến trình đường sân đấu co lại thành vòng tròn hào quang (0.0 -> 1.0)
  final double morphProgress;

  /// Hiệu ứng sóng chấn động khi bóng tiếp đất (0.0 -> 1.0)
  final double impactProgress;

  CourtLaser3DPainter({
    required this.laserProgress,
    required this.morphProgress,
    required this.impactProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Kích thước hình học của sân Pickleball 3D nghiêng
    const widthBack = 150.0;
    const widthFront = 230.0;
    const courtHeight = 90.0;
    const courtYOffset = 30.0; // Tọa độ Y trung tâm sân

    final courtCenter = Offset(center.dx, center.dy + courtYOffset);

    // 4 góc của sân đấu trong không gian phối cảnh 3D
    final pBackLeft = Offset(courtCenter.dx - widthBack / 2, courtCenter.dy - courtHeight / 2);
    final pBackRight = Offset(courtCenter.dx + widthBack / 2, courtCenter.dy - courtHeight / 2);
    final pFrontLeft = Offset(courtCenter.dx - widthFront / 2, courtCenter.dy + courtHeight / 2);
    final pFrontRight = Offset(courtCenter.dx + widthFront / 2, courtCenter.dy + courtHeight / 2);

    // Vạch lưới giữa sân (Net Line)
    final pNetLeft = Offset.lerp(pBackLeft, pFrontLeft, 0.5)!;
    final pNetRight = Offset.lerp(pBackRight, pFrontRight, 0.5)!;

    // Vạch giao bóng bên trái & bên phải (NVZ / Service lines)
    final pKitchenLeft = Offset.lerp(pBackLeft, pFrontLeft, 0.68)!;
    final pKitchenRight = Offset.lerp(pBackRight, pFrontRight, 0.68)!;

    // Điểm chính giữa vạch giao bóng (nơi quả bóng đáp xuống)
    final centerServePoint = Offset.lerp(pKitchenLeft, pKitchenRight, 0.5)!;
    final pCenterBottom = Offset.lerp(pFrontLeft, pFrontRight, 0.5)!;

    // 1. Vẽ vòng sóng chấn động tỏa ra khi quả bóng nảy xuống (Impact Ripple)
    if (impactProgress > 0.0 && impactProgress < 1.0) {
      final rippleRadius = 60.0 * impactProgress;
      final rippleAlpha = (1.0 - impactProgress) * 0.7;

      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - impactProgress)
        ..color = AppTheme.primary.withValues(alpha: rippleAlpha);

      canvas.drawOval(
        Rect.fromCenter(
          center: centerServePoint,
          width: rippleRadius * 2.2,
          height: rippleRadius * 0.8, // Nghiêng theo góc phối cảnh 3D
        ),
        ripplePaint,
      );
    }

    // 2. Chuyển đổi (Morph) các đường line sân sang vòng hào quang elip
    final laserPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (1.8 * (1.0 - morphProgress * 0.3)).clamp(1.0, 2.2);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    // Danh sách các đoạn thẳng của sân đấu: [Điểm đầu, Điểm cuối, Thứ tự vẽ]
    final lines = [
      // 4 đường biên ngoài
      _CourtSegment(pBackLeft, pBackRight, 0.0, 0.3),
      _CourtSegment(pBackRight, pFrontRight, 0.2, 0.55),
      _CourtSegment(pFrontRight, pFrontLeft, 0.45, 0.75),
      _CourtSegment(pFrontLeft, pBackLeft, 0.65, 0.95),
      // Lưới giữa sân
      _CourtSegment(pNetLeft, pNetRight, 0.35, 0.7),
      // Vạch giao bóng & vạch chia trung tâm
      _CourtSegment(pKitchenLeft, pKitchenRight, 0.5, 0.85),
      _CourtSegment(centerServePoint, pCenterBottom, 0.65, 1.0),
    ];

    final baseColor = AppTheme.primary;
    final sparkColor = const Color(0xFF00E5FF);

    for (int i = 0; i < lines.length; i++) {
      final seg = lines[i];

      // Tính toán tiến trình vẽ của từng đoạn theo laserProgress
      final segProgress = ((laserProgress - seg.start) / (seg.end - seg.start)).clamp(0.0, 1.0);
      if (segProgress <= 0.0) continue;

      // Khi morphProgress tăng: các điểm kéo co tụ về vòng elip hào quang ở trung tâm
      final angleA = (i / lines.length) * math.pi * 2;
      final angleB = ((i + 1) / lines.length) * math.pi * 2;
      const ringRadiusX = 85.0;
      const ringRadiusY = 28.0;

      final targetA = Offset(
        center.dx + math.cos(angleA) * ringRadiusX,
        center.dy + courtYOffset * 0.4 + math.sin(angleA) * ringRadiusY,
      );
      final targetB = Offset(
        center.dx + math.cos(angleB) * ringRadiusX,
        center.dy + courtYOffset * 0.4 + math.sin(angleB) * ringRadiusY,
      );

      final currentP1 = Offset.lerp(seg.p1, targetA, morphProgress)!;
      final currentP2 = Offset.lerp(seg.p2, targetB, morphProgress)!;

      final drawnP2 = Offset.lerp(currentP1, currentP2, segProgress)!;

      final currentAlpha = ((1.0 - morphProgress * 0.65) * (segProgress > 0 ? 1.0 : 0.0)).clamp(0.0, 1.0);

      // Vẽ lớp hào quang laser phát sáng (Glow)
      glowPaint.color = sparkColor.withValues(alpha: currentAlpha * 0.45);
      canvas.drawLine(currentP1, drawnP2, glowPaint);

      // Vẽ tia laser sắc nét (Core line)
      laserPaint.color = baseColor.withValues(alpha: currentAlpha * 0.85);
      canvas.drawLine(currentP1, drawnP2, laserPaint);

      // Đốm sáng laser lướt ở đầu mút (Spark head)
      if (segProgress > 0.05 && segProgress < 1.0 && morphProgress < 0.2) {
        final sparkPaint = Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawCircle(drawnP2, 2.2, sparkPaint);
      }
    }

    // 3. Khi morph gần hoàn tất: Hiện vòng hào quang tròn mềm mại tinh tế
    if (morphProgress > 0.3) {
      final ringAlpha = ((morphProgress - 0.3) / 0.7).clamp(0.0, 1.0);
      final haloPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = SweepGradient(
          colors: [
            baseColor.withValues(alpha: 0.1),
            baseColor.withValues(alpha: ringAlpha * 0.7),
            sparkColor.withValues(alpha: ringAlpha * 0.9),
            baseColor.withValues(alpha: ringAlpha * 0.7),
            baseColor.withValues(alpha: 0.1),
          ],
        ).createShader(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + courtYOffset * 0.4),
            width: 170,
            height: 56,
          ),
        );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + courtYOffset * 0.4),
          width: 170,
          height: 56,
        ),
        haloPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CourtLaser3DPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress ||
        oldDelegate.morphProgress != morphProgress ||
        oldDelegate.impactProgress != impactProgress;
  }
}

class _CourtSegment {
  final Offset p1;
  final Offset p2;
  final double start;
  final double end;
  const _CourtSegment(this.p1, this.p2, this.start, this.end);
}
