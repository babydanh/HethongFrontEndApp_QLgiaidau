part of '../screens/club_detail_screen.dart';

class _AthleticBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Diagonal sweep line (thick)
    final sweepPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-20, h + 20), Offset(w * 0.75, -20), sweepPaint);

    // Diagonal thin line
    final thinLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(10, h + 10), Offset(w * 0.85, -15), thinLinePaint);

    // Court border
    final courtPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final courtRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, 12, w - 32, h - 24),
      const Radius.circular(8),
    );
    canvas.drawRRect(courtRect, courtPaint);

    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.36, courtPaint);

    // Center dashed line
    final centerLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w / 2, 12), Offset(w / 2, h - 12), centerLinePaint);

    // Corner accents
    final accentPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Top-left corner
    final pathTl = Path()
      ..moveTo(16, 28)
      ..lineTo(16, 12)
      ..lineTo(32, 12);
    canvas.drawPath(pathTl, accentPaint);

    // Bottom-right corner
    final pathBr = Path()
      ..moveTo(w - 16, h - 28)
      ..lineTo(w - 16, h - 12)
      ..lineTo(w - 32, h - 12);
    canvas.drawPath(pathBr, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Form tham gia CLB được tách thành một route widget độc lập.
///
/// `showDialog` hoàn tất Future ngay khi Navigator nhận lệnh pop, nhưng route
/// còn reverse transition. Vì vậy controller phải được sở hữu bởi State của
/// dialog và chỉ dispose trong `State.dispose`, sau khi route đã tháo xong.
