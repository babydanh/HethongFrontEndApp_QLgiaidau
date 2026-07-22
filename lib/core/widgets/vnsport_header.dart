import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

import 'package:flutter_svg/flutter_svg.dart';

class VnsportHeader extends StatelessWidget {
  final bool isLoggedIn;
  final int elo;
  final double winRate;
  final String rank;
  final int notificationsCount;
  final VoidCallback onLoginTap;
  final VoidCallback onNotificationTap;

  const VnsportHeader({
    super.key,
    required this.isLoggedIn,
    this.elo = 0,
    this.winRate = 0.0,
    this.rank = "",
    this.notificationsCount = 0,
    required this.onLoginTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hero(
          tag: "vnsport_header_bg",
          child: CustomPaint(
            size: const Size(double.infinity, 240),
            painter: VnsportHeaderPainter(isLoggedIn: isLoggedIn, colors: context.colors),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WSPORT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1.2,
                      ),
                    ),
                    _buildNotificationBell(context),
                  ],
                ),
                const SizedBox(height: 20),
                if (isLoggedIn)
                  _buildStatsCard(context)
                else
                  _buildLoginPill(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return GestureDetector(
      onTap: onNotificationTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            if (notificationsCount > 0)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    notificationsCount > 9 ? "9+" : "$notificationsCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPill(BuildContext context) {
    return GestureDetector(
      onTap: onLoginTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              "Đăng nhập / Đăng ký",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    // Calculated win rate progress value (0.0 to 1.0)
    final progress = (winRate / 100.0).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Left: Circular Elo Progress Gauge Ring
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Ring
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 4.5,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    // Foreground Active Gradient Progress Ring
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : 0.05,
                        strokeWidth: 4.5,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)), // Gold / Neon Yellow
                      ),
                    ),
                    // Center Star Icon / Badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB300),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66FFD700),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Middle: ELO Value & Tier Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$elo ELO",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rank.isNotEmpty ? rank : "Xếp hạng Quốc gia",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Stats Columns (Trận, Thắng, Rate)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderStatColumn("0", "Trận"),
                  const SizedBox(width: 14),
                  _buildHeaderStatColumn("0", "Thắng"),
                  const SizedBox(width: 14),
                  _buildHeaderStatColumn(
                    "${winRate.toStringAsFixed(0)}%",
                    "Rate",
                    isRate: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStatColumn(String value, String label, {bool isRate = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: isRate ? const Color(0xFF4ADE80) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.0,
      height: 24.0,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

class VnsportHeaderPainter extends CustomPainter {
  final bool isLoggedIn;
  final AppColorsExtension colors;

  VnsportHeaderPainter({required this.isLoggedIn, required this.colors});

  bool get _isDark => colors.bgDark == const Color(0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final gradientColors = _isDark
        ? const [Color(0xFF000000), Color(0xFF131313)]
        : const [Color(0xFF2563EB), Color(0xFF1D4ED8)];

    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final Paint circlePaint1 = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.02 : 0.05);
    canvas.drawCircle(Offset(size.width * 0.85, 30.0), 72.0, circlePaint1);

    final Paint circlePaint2 = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.015 : 0.04);
    canvas.drawCircle(Offset(size.width * 0.08, 175.0), 52.0, circlePaint2);

    _drawRacket(canvas, size);
    _drawShuttlecock(canvas, size);
    _drawWaves(canvas, size);
  }

  void _drawRacket(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width - 95, 45.0);
    canvas.rotate(-28 * 3.1415926535 / 180);

    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.12 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawOval(const Rect.fromLTWH(0, 0, 56, 76), paint);

    final Paint thinPaint = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.07 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(const Rect.fromLTWH(4, 4, 48, 68), thinPaint);

    for (double y = 18.0; y <= 62; y += 7) {
      canvas.drawLine(Offset(8.0, y), Offset(47.0, y), thinPaint);
    }
    for (double x = 12.0; x <= 43; x += 7) {
      canvas.drawLine(Offset(x, 14.0), Offset(x, 62.0), thinPaint);
    }

    final Paint shaftPaint = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.12 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(28, 76), const Offset(28, 130), shaftPaint);

    final Paint handlePaint = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.12 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 130, 8, 30), const Radius.circular(2)), handlePaint);

    final Paint capPaint = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.12 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(23, 160, 10, 4), const Radius.circular(1)), capPaint);
    canvas.restore();
  }

  void _drawShuttlecock(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(14.0, 115.0);
    canvas.rotate(12 * 3.1415926535 / 180);

    final Paint thinPaint = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.07 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: _isDark ? 0.12 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawOval(const Rect.fromLTWH(0, 0, 24, 14), paint);
    canvas.drawOval(const Rect.fromLTWH(4, 28, 16, 24), paint);
    canvas.drawLine(const Offset(4, 10), const Offset(4, 28), thinPaint);
    canvas.drawLine(const Offset(8, 12), const Offset(8, 28), thinPaint);
    canvas.drawLine(const Offset(12, 13), const Offset(12, 28), thinPaint);
    canvas.drawLine(const Offset(16, 12), const Offset(16, 28), thinPaint);
    canvas.drawLine(const Offset(20, 10), const Offset(20, 28), thinPaint);

    canvas.restore();
  }

  void _drawWaves(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Color w1Color = _isDark
        ? const Color(0xFF161616).withValues(alpha: 0.5)
        : const Color(0xFF1D4ED8).withValues(alpha: 0.5);

    final Color w2Color = _isDark
        ? const Color(0xFF222222).withValues(alpha: 0.3)
        : const Color(0xFF1E40AF).withValues(alpha: 0.3);

    final Color w3Color = colors.bgDark;

    final Paint wave1Paint = Paint()
      ..color = w1Color
      ..style = PaintingStyle.fill;
    final Path path1 = Path();
    path1.moveTo(0.0, h - 54);
    path1.cubicTo(w * 0.125, h - 54, w * 0.25, h - 14, w * 0.406, h - 20);
    path1.cubicTo(w * 0.547, h - 26, w * 0.656, h - 50, w * 0.8125, h - 44);
    path1.cubicTo(w * 0.89, h - 41, w * 0.95, h - 30, w, h - 34);
    path1.lineTo(w, h);
    path1.lineTo(0.0, h);
    path1.close();
    canvas.drawPath(path1, wave1Paint);

    final Paint wave2Paint = Paint()
      ..color = w2Color
      ..style = PaintingStyle.fill;
    final Path path2 = Path();
    path2.moveTo(0.0, h - 40);
    path2.cubicTo(w * 0.094, h - 10, w * 0.265, h, w * 0.453, h - 8);
    path2.cubicTo(w * 0.61, h - 15, w * 0.75, h - 34, w * 0.906, h - 26);
    path2.cubicTo(w * 0.95, h - 23, w * 0.98, h - 18, w, h - 20);
    path2.lineTo(w, h);
    path2.lineTo(0.0, h);
    path2.close();
    canvas.drawPath(path2, wave2Paint);

    final Paint wave3Paint = Paint()
      ..color = w3Color
      ..style = PaintingStyle.fill;
    final Path path3 = Path();
    path3.moveTo(0.0, h - 26);
    path3.cubicTo(w * 0.156, h - 2, w * 0.344, h + 3, w * 0.547, h - 4);
    path3.cubicTo(w * 0.703, h - 10, w * 0.844, h - 22, w, h - 12);
    path3.lineTo(w, h);
    path3.lineTo(0.0, h);
    path3.close();
    canvas.drawPath(path3, wave3Paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
