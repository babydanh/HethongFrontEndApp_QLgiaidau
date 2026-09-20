import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_icons.dart';

/// Hoạt họa chuyển cảnh đỉnh cao Choreographed Morphing Loader -> Navigation Bar:
/// 1. Màn Loading: 4 chấm tròn thể thao nảy sóng nhịp điệu ở giữa màn hình cùng Logo SportO.
/// 2. Khi tải xong: 4 chấm tròn phóng vút lên rồi lượn vòng cung parabol bay xuống chính xác 4 vị trí của thanh Bottom Nav.
/// 3. Chạm đáy: Thanh Nav bung mở, 4 chấm nở bung (bloom) thành 4 icon điều hướng (Trang chủ, Giải đấu, Khám phá, Cá nhân).
class MorphingNavLoaderOverlay extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool autoStart;

  /// Đảm bảo màn hình hiệu ứng loading chuyển cảnh chỉ chạy DUY NHẤT 1 LẦN khi mở app (cold boot).
  /// Khi người dùng chuyển tab, vào hồ sơ rồi quay ra hoặc chuyển sang nav khác, tuyệt đối không hiện lại màn loading.
  static bool hasCompletedInitialLoad = false;

  const MorphingNavLoaderOverlay({
    super.key,
    this.onCompleted,
    this.autoStart = true,
  });

  @override
  State<MorphingNavLoaderOverlay> createState() =>
      MorphingNavLoaderOverlayState();
}

class MorphingNavLoaderOverlayState extends State<MorphingNavLoaderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isFinished = false;
  bool _controllerInitialized = false;

  // Cấu hình 5 chấm tròn thể thao: 4 tab bên trái + 1 nút tiện ích bên phải
  static const List<({String label, Color color, IconData icon})> _tabs = [
    (label: 'Trang chủ', color: Color(0xFF1D8EF8), icon: AppIcons.home),
    (label: 'Giải đấu', color: Color(0xFFF59E0B), icon: AppIcons.trophy),
    (label: 'Khám phá', color: Color(0xFF06B6D4), icon: AppIcons.explore),
    (label: 'Hộp thư', color: Color(0xFF10B981), icon: AppIcons.chat),
    (label: 'Tiện ích', color: Color(0xFF8B5CF6), icon: AppIcons.chevronsUpDown),
  ];

  @override
  void initState() {
    super.initState();
    if (MorphingNavLoaderOverlay.hasCompletedInitialLoad) {
      _isFinished = true;
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _controllerInitialized = true;

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        MorphingNavLoaderOverlay.hasCompletedInitialLoad = true;
        if (mounted) {
          setState(() => _isFinished = true);
          widget.onCompleted?.call();
        }
      }
    });

    if (widget.autoStart) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (!_controllerInitialized) return;
    setState(() => _isFinished = false);
    _controller.forward(from: 0.0);
  }

  /// Kích hoạt chạy lại animation bất cứ lúc nào
  void replay() {
    if (!_controllerInitialized) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      );
      _controllerInitialized = true;
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          MorphingNavLoaderOverlay.hasCompletedInitialLoad = true;
          if (mounted) {
            setState(() => _isFinished = true);
            widget.onCompleted?.call();
          }
        }
      });
    }
    MorphingNavLoaderOverlay.hasCompletedInitialLoad = false;
    _startAnimation();
  }

  @override
  void dispose() {
    if (_controllerInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MorphingNavLoaderOverlay.hasCompletedInitialLoad || _isFinished) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final screenH = media.size.height;
    final safeAreaBottom = media.padding.bottom;

    // Tọa độ thanh Bottom Nav trên màn hình (theo chuẩn FloatingBottomNav):
    // Khối trái: left: 16, bottom: 12 + safeAreaBottom, width: 252, height: 44
    // Khối phải (Tiện ích): right: 16, bottom: 12 + safeAreaBottom, width: 44, height: 44
    const double barWidth = 252.0;
    const double barHeight = 44.0;
    const double slotWidth = barWidth / 4.0;
    const double navBarLeft = 16.0;
    final double navBarBottom = 12.0 + safeAreaBottom;
    final double navBarCenterY = screenH - navBarBottom - (barHeight / 2.0);

    // Tọa độ đích (Target Slot) của 5 icon: 4 slot thanh trái + 1 tâm nút tiện ích bên phải
    final targetPositions = List.generate(5, (i) {
      if (i < 4) {
        final slotCenterX = navBarLeft + (i * slotWidth) + (slotWidth / 2.0);
        return Offset(slotCenterX, navBarCenterY);
      } else {
        // Tab thứ 5: Nút tiện ích hình tròn bên phải (right: 16, width: 44)
        return Offset(screenW - 16.0 - 22.0, navBarCenterY);
      }
    });

    // Tâm màn hình loading
    final centerX = screenW / 2.0;
    final centerY = screenH * 0.44;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0.0 -> 1.0

        // ─── GIAI ĐOẠN 1: LOADING 5 BÓNG PICKLEBALL NẢY SÓNG (t: 0.0 -> 0.50) ───
        // ─── GIAI ĐOẠN 2: 5 BÓNG PHÓNG VÒNG CUNG VÀO NAV (t: 0.50 -> 0.82) ───
        // ─── GIAI ĐOẠN 3: BUNG NỞ THÀNH NAV BAR & 5 ICON (t: 0.82 -> 1.0) ───

        // Độ mờ của nền trắng che phủ
        double overlayOpacity = 1.0;
        if (t > 0.88) {
          overlayOpacity = ((1.0 - t) / 0.12).clamp(0.0, 1.0);
        }

        // Độ mờ của logo SportO ở giữa
        double centerContentOpacity = 1.0;
        if (t > 0.48) {
          centerContentOpacity = ((0.56 - t) / 0.08).clamp(0.0, 1.0);
        }

        // Tiến độ bay vòng cung (flightProgress: 0.0 -> 1.0)
        double flightProgress = 0.0;
        if (t >= 0.50 && t <= 0.82) {
          final rawFlight = (t - 0.50) / 0.32;
          flightProgress = Curves.easeInOutCubic.transform(rawFlight);
        } else if (t > 0.82) {
          flightProgress = 1.0;
        }

        // Tiến độ nở hoa biến hình thành Nav (bloomProgress: 0.0 -> 1.0)
        double bloomProgress = 0.0;
        if (t >= 0.80) {
          final rawBloom = (t - 0.80) / 0.20;
          bloomProgress = Curves.easeOutBack.transform(
            rawBloom.clamp(0.0, 1.0),
          );
        }

        // Tính tọa độ hiện tại của 5 quả bóng pickleball
        final dotPositions = <Offset>[];
        for (int i = 0; i < 5; i++) {
          // 5 quả bóng Pickleball căn đều ở giữa màn hình (dưới Logo SportO), khoảng cách 38px
          final startX = centerX - 76.0 + (i * 38.0);
          final wavePhase = (t < 0.50)
              ? ((t / 0.50) * 5 * math.pi) - (i * 0.65)
              : 0.0;
          final waveOffset = (t < 0.50)
              ? -math.pow((math.sin(wavePhase) + 1.0) / 2.0, 1.4).toDouble() * 26.0
              : 0.0;
          final startY = centerY + 42.0 + waveOffset;

          final target = targetPositions[i];

          // Đường cong Bézier bay vút lên rồi lượn xuống đáy:
          // Quả bóng thứ 5 vung sang phải mạnh mẽ để đáp trúng tâm nút tiện ích
          final controlPt = Offset(
            startX + (target.dx - startX) * 0.35,
            startY - 150.0 + (i * 12.0),
          );

          // Nội suy Quadratic Bézier: B(p) = (1-p)^2 * P0 + 2(1-p)p * P1 + p^2 * P2
          final p = flightProgress;
          final curX =
              (1 - p) * (1 - p) * startX +
              2 * (1 - p) * p * controlPt.dx +
              p * p * target.dx;
          final curY =
              (1 - p) * (1 - p) * startY +
              2 * (1 - p) * p * controlPt.dy +
              p * p * target.dy;

          dotPositions.add(Offset(curX, curY));
        }

        // Kích hoạt rung haptic phản hồi xúc giác khi các bóng đáp xuống trúng đích
        if (t >= 0.80 && t <= 0.83) {
          HapticFeedback.lightImpact();
        }

        return Material(
          type: MaterialType.transparency,
          child: IgnorePointer(
            ignoring: t > 0.90,
            child: Stack(
              children: [
                // 1. NỀN TRẮNG PHỦ TRÊN (FADE OUT DẦN KHI GẦN XONG)
                Positioned.fill(
                  child: Opacity(
                    opacity: overlayOpacity,
                    child: Container(color: Colors.white),
                  ),
                ),

                // 2. LOGO SPORTO NGUYÊN BẢN Ở TRUNG TÂM
                if (centerContentOpacity > 0.01)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: centerY - 65,
                    child: Opacity(
                      opacity: centerContentOpacity,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/sporto_v1.svg',
                          width: 220,
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => Image.asset(
                            'assets/images/sporto_v1.png',
                            width: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. VẼ VỆT SÁNG BAY THEO ĐƯỜNG CỦA 5 TRÁI BÓNG
                if (flightProgress > 0.05 && flightProgress < 0.95)
                  CustomPaint(
                    size: Size(screenW, screenH),
                    painter: _FlightTrailsPainter(
                      dotPositions: dotPositions,
                      tabs: _tabs,
                      flightProgress: flightProgress,
                    ),
                  ),

                // 4a. KHUNG THANH NAVIGATION BAR TRÁI (252x44) BUNG MỞ KHI 4 BÓNG CHẠM ĐÁY
                if (bloomProgress > 0.01)
                  Positioned(
                    left: navBarLeft,
                    bottom: navBarBottom,
                    child: Opacity(
                      opacity: bloomProgress.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.88 + (bloomProgress * 0.12),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: barWidth,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(barHeight / 2),
                            border: Border.all(
                              color: const Color(
                                0xFFE2E8F0,
                              ).withValues(alpha: 0.9),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: AppTheme.primary.withValues(
                                  alpha: 0.10 * bloomProgress,
                                ),
                                blurRadius: 12,
                                spreadRadius: 0.5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Khối màu xanh nhạt hover/active của Tab 0 (Trang chủ)
                              Positioned(
                                left: 4.0,
                                top: 4.0,
                                child: Container(
                                  width: slotWidth - 8.0,
                                  height: barHeight - 8.0,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(
                                      (barHeight - 8.0) / 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 4b. KHUNG NÚT TIỆN ÍCH TRÒN BÊN PHẢI (44x44) BUNG MỞ KHI QUẢ BÓNG THỨ 5 CHẠM ĐÁY
                if (bloomProgress > 0.01)
                  Positioned(
                    right: 16.0,
                    bottom: navBarBottom,
                    child: Opacity(
                      opacity: bloomProgress.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.88 + (bloomProgress * 0.12),
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(
                                0xFFE2E8F0,
                              ).withValues(alpha: 0.9),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.10 * bloomProgress),
                                blurRadius: 12,
                                spreadRadius: 0.5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 5. 5 QUẢ BÓNG PICKLEBALL NẢY, PHÓNG VÀ BIẾN HÌNH (MORPH) THÀNH ICON
                ...List.generate(5, (i) {
                  final pos = dotPositions[i];
                  final item = _tabs[i];

                  // Khi nảy sóng: bán kính bóng to rõ 16.0px để thấy rõ các lỗ Pickleball và màu sắc riêng
                  // Khi bay đến Nav: co lại vừa vặn 11.5px để hòa vào icon
                  final double initialRadius = (1.0 - flightProgress) * 16.5 + flightProgress * 12.0;
                  final double ballRadius = (initialRadius * (1.0 - (bloomProgress * 0.3))).clamp(6.0, 16.5);
                  final iconScale = (bloomProgress * 1.15).clamp(0.0, 1.0);

                  return Positioned(
                    left: pos.dx - 25,
                    top: pos.dy - 25,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Sóng năng lượng xung kích tỏa ra khi bóng tiếp đất (Impact Ripple)
                          if (bloomProgress > 0.05 && bloomProgress < 0.80)
                            Container(
                              width: 48 * bloomProgress,
                              height: 48 * bloomProgress,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: item.color.withValues(
                                    alpha: 1.0 - bloomProgress,
                                  ),
                                  width: 2.2,
                                ),
                              ),
                            ),

                          // Quả bóng Pickleball đa sắc chuẩn thi đấu sống động (Fades out khi Icon xuất hiện)
                          if (bloomProgress < 0.88)
                            Opacity(
                              opacity: (1.0 - (bloomProgress * 1.25)).clamp(
                                0.0,
                                1.0,
                              ),
                              child: CustomPaint(
                                size: Size(ballRadius * 2, ballRadius * 2),
                                painter: _MorphPickleballPainter(
                                  radius: ballRadius,
                                  palette: _ballPalettes[i % _ballPalettes.length],
                                ),
                              ),
                            ),

                          // Icon Navigation & Tiện ích nở bung ra từ quả bóng
                          if (bloomProgress > 0.15)
                            Transform.scale(
                              scale: iconScale,
                              child: Icon(
                                item.icon,
                                color: i == 0
                                    ? AppTheme.primary
                                    : const Color(0xFF64748B),
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Palette màu thể thao cho từng quả bóng Pickleball
class PickleballBallPalette {
  final Color highlight;
  final Color base;
  final Color shade;
  final Color deep;
  final Color dimple;
  final Color trail;

  const PickleballBallPalette({
    required this.highlight,
    required this.base,
    required this.shade,
    required this.deep,
    required this.dimple,
    required this.trail,
  });
}

const List<PickleballBallPalette> _ballPalettes = [
  // 1. Neon Volt Yellow (Vàng chanh Neon đặc trưng Pickleball thi đấu quốc tế)
  PickleballBallPalette(
    highlight: Color(0xFFFFFFE0),
    base: Color(0xFFFFEA00),
    shade: Color(0xFFFFC400),
    deep: Color(0xFFE65100),
    dimple: Color(0xFFB45309),
    trail: Color(0xFFFFD600),
  ),
  // 2. Neon Solar Orange (Cam Neon thi đấu trong nhà)
  PickleballBallPalette(
    highlight: Color(0xFFFFF3E0),
    base: Color(0xFFFF6D00),
    shade: Color(0xFFE65100),
    deep: Color(0xFFBF360C),
    dimple: Color(0xFF7F1D1D),
    trail: Color(0xFFFF6D00),
  ),
  // 3. Electric Lime Green (Xanh lá chuối dạ quang cực kỳ nổi tiếng)
  PickleballBallPalette(
    highlight: Color(0xFFF1F8E9),
    base: Color(0xFF76FF03),
    shade: Color(0xFF64DD17),
    deep: Color(0xFF1B5E20),
    dimple: Color(0xFF14532D),
    trail: Color(0xFF76FF03),
  ),
  // 4. Cyan Flash Blue (Xanh lơ biển dạ quang USAPA)
  PickleballBallPalette(
    highlight: Color(0xFFE0F7FA),
    base: Color(0xFF00E5FF),
    shade: Color(0xFF00B0FF),
    deep: Color(0xFF01579B),
    dimple: Color(0xFF0C4A6E),
    trail: Color(0xFF00E5FF),
  ),
  // 5. Hot Lava Magenta / Neon Pink (Hồng dạ quang trẻ trung, tab Tiện ích)
  PickleballBallPalette(
    highlight: Color(0xFFFCE4EC),
    base: Color(0xFFFF4081),
    shade: Color(0xFFF50057),
    deep: Color(0xFF880E4F),
    dimple: Color(0xFF701A75),
    trail: Color(0xFFFF4081),
  ),
];

/// CustomPainter vẽ 1 quả bóng Pickleball chuẩn thi đấu siêu thực:
/// Vỏ nhựa dẻo đàn hồi, đường gân khuôn đúc, các lỗ tròn khoét xuyên thấu khí và ánh lóa
class _MorphPickleballPainter extends CustomPainter {
  final double radius;
  final PickleballBallPalette palette;

  _MorphPickleballPainter({
    required this.radius,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = radius;

    // 1. Bóng đổ sàn / tiếp xúc
    final shadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(Offset(center.dx, center.dy + 2.0), r * 0.96, shadowPaint);

    // 2. Thân bóng hình cầu bằng RadialGradient nhựa tổng hợp bóng bẩy
    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.88,
        colors: [
          palette.highlight,
          palette.base,
          palette.shade,
          palette.deep,
        ],
        stops: const [0.0, 0.35, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, ballPaint);

    // 3. Đường viền khuôn ép nhựa ở giữa quả bóng (Molding seam line) đặc trưng Pickleball
    final seamPaint = Paint()
      ..color = palette.deep.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(
      Rect.fromCenter(center: center, width: r * 2.0, height: r * 0.85),
      0,
      math.pi * 2,
      false,
      seamPaint,
    );

    // 4. Các lỗ khí khoét tròn đặc trưng của bóng Pickleball (Pickleball Dimple Holes):
    // Mỗi lỗ có viền khoét rãnh 3D và bóng đen bên trong lỗ khí
    final holeOffsets = [
      Offset(center.dx - r * 0.05, center.dy - r * 0.05), // Tâm giữa
      Offset(center.dx + r * 0.40, center.dy - r * 0.28), // Góc trên phải
      Offset(center.dx + r * 0.45, center.dy + r * 0.25), // Góc dưới phải
      Offset(center.dx - r * 0.15, center.dy + r * 0.45), // Dưới đáy
      Offset(center.dx - r * 0.46, center.dy + r * 0.18), // Góc dưới trái
      Offset(center.dx - r * 0.42, center.dy - r * 0.25), // Góc trên trái
      Offset(center.dx + r * 0.08, center.dy - r * 0.48), // Đỉnh trên
    ];

    final holeRadius = r * 0.14;

    for (final holePos in holeOffsets) {
      // Đáy lỗ (lỗ rỗng sâu vào ruột bóng)
      final holeInnerPaint = Paint()
        ..color = palette.dimple.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(holePos, holeRadius, holeInnerPaint);

      // Điểm tối tâm lỗ rỗng
      final holeCorePaint = Paint()
        ..color = const Color(0xFF0F172A).withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(holePos.dx - 0.2, holePos.dy - 0.2), holeRadius * 0.65, holeCorePaint);

      // Vát mép lỗ nhựa phản xạ ánh sáng trắng nhẹ góc trên bên trái
      final holeEdgePaint = Paint()
        ..color = palette.highlight.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: holePos, radius: holeRadius),
        math.pi * 0.75,
        math.pi * 0.8,
        false,
        holeEdgePaint,
      );
    }

    // 5. Điểm lóa sáng gương (Specular Highlight) trên đỉnh bóng
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    canvas.drawCircle(Offset(center.dx - r * 0.35, center.dy - r * 0.35), r * 0.20, glintPaint);

    final miniGlintPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(center.dx - r * 0.18, center.dy - r * 0.48), r * 0.08, miniGlintPaint);
  }

  @override
  bool shouldRepaint(covariant _MorphPickleballPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.palette != palette;
}

/// CustomPainter vẽ vệt sáng lượn vòng cung phía sau 5 bóng khi bay
class _FlightTrailsPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<({String label, Color color, IconData icon})> tabs;
  final double flightProgress;

  _FlightTrailsPainter({
    required this.dotPositions,
    required this.tabs,
    required this.flightProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < dotPositions.length; i++) {
      final pos = dotPositions[i];
      final palette = _ballPalettes[i % _ballPalettes.length];

      final trailPaint = Paint()
        ..color = palette.trail.withValues(
          alpha: (0.55 * (1.0 - flightProgress * 0.5)).clamp(0.0, 0.55),
        )
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      // Vệt ngắn kéo lùi sau đuôi theo hướng bay xuống
      canvas.drawLine(pos, Offset(pos.dx, pos.dy - 22.0), trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlightTrailsPainter oldDelegate) => true;
}
