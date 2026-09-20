import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

import 'package:app_quanly_giaidau/core/widgets/pickleball_rally_animation.dart';

enum SportoLoadingVariant {
  /// Mẫu 1: 5 quả bóng Pickleball vàng Neon nảy sóng nhịp điệu (Wave Bounce 5 Balls)
  pickleballWave5,

  /// Mẫu 2: Vòng xoay quỹ đạo Sport Blue + Logo SportO nhịp thở (Đồng bộ 100% Web)
  orbit,

  /// Mẫu 3: Trận đấu Pickleball 2D sống động (2 vợt xanh & cam đánh qua lưới, bóng nảy)
  rally,

  /// Mẫu 4: Quả bóng Pickleball vàng nảy sóng năng lượng (Flat Motion đơn)
  bounce,

  /// Backward compatible
  court3d,
}

class SportoLoadingWidget extends StatefulWidget {
  final double size;
  final String? message;
  final Color? textColor;
  final SportoLoadingVariant variant;

  const SportoLoadingWidget({
    super.key,
    this.size = 110.0,
    this.message,
    this.textColor,
    this.variant = SportoLoadingVariant.pickleballWave5,
  });

  @override
  State<SportoLoadingWidget> createState() => _SportoLoadingWidgetState();
}

class _SportoLoadingWidgetState extends State<SportoLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == SportoLoadingVariant.court3d) {
      return _buildOrbitLoader();
    }

    if (widget.variant == SportoLoadingVariant.rally) {
      final rallyW = widget.size * 2.2;
      final rallyH = widget.size * 1.1;
      return PickleballRallyAnimation(
        width: rallyW.clamp(180.0, 320.0),
        height: rallyH.clamp(90.0, 160.0),
        message: widget.message,
        textColor: widget.textColor ?? context.colors.textSecondary,
      );
    }

    if (widget.variant == SportoLoadingVariant.pickleballWave5) {
      final waveW = (widget.size * 1.8).clamp(160.0, 240.0);
      final waveH = (widget.size * 0.55).clamp(50.0, 80.0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: waveW,
            height: waveH,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(waveW, waveH),
                  painter: _Pickleball5WavePainter(progress: _controller.value),
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
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: widget.textColor ?? context.colors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (widget.variant == SportoLoadingVariant.bounce) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _NeonBouncePainter(progress: _controller.value),
                );
              }
              return _buildOrbitLoader();
            },
          ),
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: widget.textColor ?? context.colors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }

  /// Mẫu 1: Vòng xoay quỹ đạo sắc sảo + Logo SportO nhịp thở ở trung tâm (Chuẩn Web)
  Widget _buildOrbitLoader() {
    final t = _controller.value;
    // Nhịp thở logo (Pulse)
    final breathScale = 0.95 + (math.sin(t * 2 * math.pi) + 1) * 0.06; // 0.95 -> 1.07
    final logoSize = widget.size * 0.46;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Vòng tròn xoay quỹ đạo
        Transform.rotate(
          angle: t * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _OrbitRingPainter(),
          ),
        ),

        // Logo SportO nhịp thở ở tâm
        Transform.scale(
          scale: breathScale,
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(logoSize * 0.28),
            ),
            padding: EdgeInsets.all(logoSize * 0.18),
            child: SvgPicture.asset(
              'assets/images/sporto_v1.svg',
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Image.asset(
                'assets/images/sporto_v1.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Vẽ vòng xoay quỹ đạo mỏng thanh lịch (Orbit Ring)
class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3.0;

    // Vòng tròn xám nhạt nền
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, radius, trackPaint);

    // Cung xoay gradient xanh Sport Blue năng lượng
    final arcPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 1.6,
        colors: [
          Colors.transparent,
          Color(0xFF38BDF8), // Xanh sky tươi
          Color(0xFF1D8EF8), // Xanh Sport Blue chính thức
        ],
        stops: [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.0,
      math.pi * 1.5,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mẫu 2: Vẽ Quả bóng Pickleball nảy sóng năng lượng (Flat Motion)
class _NeonBouncePainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0

  _NeonBouncePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w * 0.5;
    final floorY = h * 0.82;

    // Chu kỳ nảy parabol: chạm đất ở t = 0 và t = 1, lên đỉnh ở t = 0.5
    final t = progress;
    final bounceCurve = math.sin(t * math.pi); // 0 -> 1 -> 0
    final maxJump = h * 0.45;
    final ballY = floorY - (bounceCurve * maxJump);

    // Squash & Stretch: bẹt ngang khi chạm đất, dãn dọc khi bay
    final double squashX;
    final double squashY;
    if (bounceCurve < 0.15) {
      final touch = 1.0 - (bounceCurve / 0.15);
      squashX = 1.0 + touch * 0.25;
      squashY = 1.0 - touch * 0.25;
    } else {
      squashX = 0.94;
      squashY = 1.06;
    }

    final ballR = (w * 0.16).clamp(10.0, 24.0);

    // 1. Vòng sóng năng lượng lan tỏa khi chạm đất (Ripple)
    if (bounceCurve < 0.35) {
      final rippleProgress = (0.35 - bounceCurve) / 0.35; // 0..1
      final ripplePaint = Paint()
        ..color = const Color(0xFF1D8EF8).withValues(alpha: (1.0 - rippleProgress) * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - rippleProgress) * 2.0;
      final rippleRect = Rect.fromCenter(
        center: Offset(centerX, floorY),
        width: ballR * 2.2 + rippleProgress * 24.0,
        height: (ballR * 0.7 + rippleProgress * 8.0),
      );
      canvas.drawOval(rippleRect, ripplePaint);
    }

    // 2. Bóng đổ trên sàn
    final shadowScale = (1.2 - bounceCurve * 0.55).clamp(0.65, 1.2);
    final shadowAlpha = ((1.0 - bounceCurve * 0.6) * 0.35).clamp(0.1, 0.4);
    final shadowRect = Rect.fromCenter(
      center: Offset(centerX, floorY),
      width: ballR * 2.0 * shadowScale * squashX,
      height: ballR * 0.65 * shadowScale * squashY,
    );
    final shadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: shadowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(shadowRect, shadowPaint);

    // 3. Quả bóng Pickleball vàng Neon
    canvas.save();
    canvas.translate(centerX, ballY - ballR);
    canvas.scale(squashX, squashY);

    final ballPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFEA00),
          Color(0xFFFFB300),
          Color(0xFFE65100),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: ballR));
    canvas.drawCircle(Offset.zero, ballR, ballPaint);

    // Vết phản chiếu ánh sáng (Specular Glint)
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(-ballR * 0.32, -ballR * 0.32), ballR * 0.20, glintPaint);

    // Lỗ bóng pickleball tinh tế
    final dimplePaint = Paint()..color = const Color(0xFFB45309).withValues(alpha: 0.45);
    final dimpleR = ballR * 0.12;
    canvas.drawCircle(Offset(ballR * 0.22, -ballR * 0.25), dimpleR, dimplePaint);
    canvas.drawCircle(Offset(ballR * 0.38, ballR * 0.10), dimpleR, dimplePaint);
    canvas.drawCircle(Offset(-ballR * 0.08, ballR * 0.32), dimpleR, dimplePaint);
    canvas.drawCircle(Offset(-ballR * 0.32, ballR * 0.08), dimpleR, dimplePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeonBouncePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Mẫu 1: Vẽ 5 quả bóng Pickleball vàng Neon nảy sóng nhịp điệu liên hoàn (Wave Motion)
class _Pickleball5WavePainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0

  _Pickleball5WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const int count = 5;
    final w = size.width;
    final h = size.height;
    final floorY = h * 0.82;
    final maxJump = h * 0.48;

    final ballR = (w / (count * 2.8)).clamp(8.0, 14.0);
    final spacing = w / (count + 1);

    for (int i = 0; i < count; i++) {
      final centerX = spacing * (i + 1);

      // Lệch pha theo sóng sine (Wave Delay) giữa 5 bóng
      final phase = (progress * 2 * math.pi) - (i * 0.65);
      // Chu kỳ nảy mượt mà từ 0.0 -> 1.0 -> 0.0
      final bounceFactor = (math.sin(phase) + 1.0) / 2.0; // 0..1
      final curvedBounce = math.pow(bounceFactor, 1.4).toDouble();

      final ballY = floorY - (curvedBounce * maxJump);

      // Squash & Stretch: bẹt khi chạm đất, dãn dọc khi lên đỉnh
      final double squashX;
      final double squashY;
      if (curvedBounce < 0.12) {
        final touch = 1.0 - (curvedBounce / 0.12);
        squashX = 1.0 + touch * 0.22;
        squashY = 1.0 - touch * 0.20;
      } else {
        squashX = 0.94;
        squashY = 1.05;
      }

      // 1. Bóng đổ bóng đen mờ dưới sàn
      final shadowScale = (1.1 - curvedBounce * 0.5).clamp(0.55, 1.1);
      final shadowAlpha = ((1.0 - curvedBounce * 0.65) * 0.30).clamp(0.08, 0.35);
      final shadowRect = Rect.fromCenter(
        center: Offset(centerX, floorY),
        width: ballR * 2.0 * shadowScale * squashX,
        height: ballR * 0.55 * shadowScale,
      );
      final shadowPaint = Paint()
        ..color = const Color(0xFF0F172A).withValues(alpha: shadowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawOval(shadowRect, shadowPaint);

      // 2. Vẽ quả bóng Pickleball vàng Neon
      canvas.save();
      canvas.translate(centerX, ballY - ballR);
      canvas.scale(squashX, squashY);

      final ballPaint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            Color(0xFFFFFDE7),
            Color(0xFFFFEA00),
            Color(0xFFFFB300),
            Color(0xFFE65100),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: ballR));
      canvas.drawCircle(Offset.zero, ballR, ballPaint);

      // Điểm sáng phản quang (Specular Glint)
      final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      canvas.drawCircle(
        Offset(-ballR * 0.32, -ballR * 0.32),
        ballR * 0.20,
        glintPaint,
      );

      // Lỗ tròn đặc trưng của bóng Pickleball
      final dimplePaint = Paint()
        ..color = const Color(0xFFB45309).withValues(alpha: 0.45);
      final dimpleR = ballR * 0.12;
      canvas.drawCircle(Offset(ballR * 0.22, -ballR * 0.25), dimpleR, dimplePaint);
      canvas.drawCircle(Offset(ballR * 0.36, ballR * 0.10), dimpleR, dimplePaint);
      canvas.drawCircle(Offset(-ballR * 0.08, ballR * 0.30), dimpleR, dimplePaint);
      canvas.drawCircle(Offset(-ballR * 0.32, ballR * 0.08), dimpleR, dimplePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Pickleball5WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
