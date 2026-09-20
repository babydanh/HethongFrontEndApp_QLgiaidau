import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Hoạt họa chuyển cảnh đỉnh cao Choreographed Morphing Loader -> Navigation Bar:
/// 1. Màn Loading: 4 chấm tròn thể thao nảy sóng nhịp điệu ở giữa màn hình cùng Logo SportO.
/// 2. Khi tải xong: 4 chấm tròn phóng vút lên rồi lượn vòng cung parabol bay xuống chính xác 4 vị trí của thanh Bottom Nav.
/// 3. Chạm đáy: Thanh Nav bung mở, 4 chấm nở bung (bloom) thành 4 icon điều hướng (Trang chủ, Giải đấu, Khám phá, Cá nhân).
class MorphingNavLoaderOverlay extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool autoStart;

  const MorphingNavLoaderOverlay({
    super.key,
    this.onCompleted,
    this.autoStart = true,
  });

  @override
  State<MorphingNavLoaderOverlay> createState() => MorphingNavLoaderOverlayState();
}

class MorphingNavLoaderOverlayState extends State<MorphingNavLoaderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isFinished = false;

  // Cấu hình 5 chấm tròn thể thao: 4 tab bên trái + 1 nút tiện ích bên phải
  static const List<({String label, Color color, IconData icon})> _tabs = [
    (label: 'Trang chủ', color: Color(0xFF1D8EF8), icon: Icons.home_rounded),
    (label: 'Giải đấu', color: Color(0xFFF59E0B), icon: Icons.emoji_events_rounded),
    (label: 'Khám phá', color: Color(0xFF06B6D4), icon: Icons.explore_rounded),
    (label: 'Cá nhân', color: Color(0xFF10B981), icon: Icons.person_rounded),
    (label: 'Tiện ích', color: Color(0xFF8B5CF6), icon: Icons.unfold_more_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
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
    setState(() => _isFinished = false);
    _controller.forward(from: 0.0);
  }

  /// Kích hoạt chạy lại animation bất cứ lúc nào
  void replay() {
    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final screenH = media.size.height;
    final safeAreaBottom = media.padding.bottom;

    // Tọa độ thanh Bottom Nav trên màn hình (theo chuẩn FloatingBottomNav):
    // Khối trái: left: 16, bottom: 14 + safeAreaBottom, width: 252, height: 50
    // Khối phải (Tiện ích): right: 16, bottom: 14 + safeAreaBottom, width: 50, height: 50
    const double barWidth = 252.0;
    const double barHeight = 50.0;
    const double slotWidth = barWidth / 4.0;
    const double navBarLeft = 16.0;
    final double navBarBottom = 14.0 + safeAreaBottom;
    final double navBarCenterY = screenH - navBarBottom - (barHeight / 2.0);

    // Tọa độ đích (Target Slot) của 5 icon: 4 slot thanh trái + 1 tâm nút tiện ích bên phải
    final targetPositions = List.generate(5, (i) {
      if (i < 4) {
        final slotCenterX = navBarLeft + (i * slotWidth) + (slotWidth / 2.0);
        return Offset(slotCenterX, navBarCenterY);
      } else {
        // Tab thứ 5: Nút tiện ích hình tròn bên phải (right: 16, width: 50)
        return Offset(screenW - 16.0 - 25.0, navBarCenterY);
      }
    });

    // Tâm màn hình loading
    final centerX = screenW / 2.0;
    final centerY = screenH * 0.44;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0.0 -> 1.0

        // ─── GIAI ĐOẠN 1: LOADING NẢY SÓNG (t: 0.0 -> 0.52) ───
        // ─── GIAI ĐOẠN 2: BAY VÒNG CUNG VÀO NAV (t: 0.52 -> 0.82) ───
        // ─── GIAI ĐOẠN 3: NỞ ICON & BIẾN HÌNH HOÀN THIỆN (t: 0.82 -> 1.0) ───

        // Độ mờ của nền trắng che phủ
        double overlayOpacity = 1.0;
        if (t > 0.88) {
          overlayOpacity = ((1.0 - t) / 0.12).clamp(0.0, 1.0);
        }

        // Độ mờ của logo SportO và chữ loading ở giữa
        double centerContentOpacity = 1.0;
        if (t > 0.50) {
          centerContentOpacity = ((0.58 - t) / 0.08).clamp(0.0, 1.0);
        }

        // Tiến độ bay vòng cung (flightProgress: 0.0 -> 1.0)
        double flightProgress = 0.0;
        if (t >= 0.52 && t <= 0.84) {
          final rawFlight = (t - 0.52) / 0.32;
          flightProgress = Curves.easeInOutCubic.transform(rawFlight);
        } else if (t > 0.84) {
          flightProgress = 1.0;
        }

        // Tiến độ nở hoa biến hình thành Nav (bloomProgress: 0.0 -> 1.0)
        double bloomProgress = 0.0;
        if (t >= 0.82) {
          final rawBloom = (t - 0.82) / 0.18;
          bloomProgress = Curves.easeOutBack.transform(rawBloom.clamp(0.0, 1.0));
        }

        // Tính tọa độ hiện tại của 5 chấm tròn thể thao
        final dotPositions = <Offset>[];
        for (int i = 0; i < 5; i++) {
          // 5 chấm căn đều ở giữa màn hình (dưới Logo SportO)
          final startX = centerX - 56.0 + (i * 28.0);
          final waveOffset = (t < 0.52)
              ? -math.sin(((t / 0.52) * 5 * math.pi) - (i * 0.75)).abs() * 20.0
              : 0.0;
          final startY = centerY + 36.0 + waveOffset;

          final target = targetPositions[i];

          // Đường cong Bézier bay vút lên rồi lượn xuống đáy:
          // Chấm thứ 5 vung sang phải mạnh mẽ để hạ cánh vào nút tiện ích
          final controlPt = Offset(
            startX + (target.dx - startX) * 0.35,
            startY - 140.0 + (i * 10.0),
          );

          // Nội suy Quadratic Bézier: B(p) = (1-p)^2 * P0 + 2(1-p)p * P1 + p^2 * P2
          final p = flightProgress;
          final curX = (1 - p) * (1 - p) * startX + 2 * (1 - p) * p * controlPt.dx + p * p * target.dx;
          final curY = (1 - p) * (1 - p) * startY + 2 * (1 - p) * p * controlPt.dy + p * p * target.dy;

          dotPositions.add(Offset(curX, curY));
        }

        // Kích hoạt rung khi các chấm chạm đích
        if (t >= 0.82 && t <= 0.85) {
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
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                ),

                // 2. LOGO SPORTO NGUYÊN BẢN (KHÔNG CHỮ THỪA, KHÔNG VÒNG TRÒN ÉP LOGO)
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
                          width: 230,
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => Image.asset(
                            'assets/images/sporto_v1.png',
                            width: 230,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

              // 3. VẼ VỆT SÁNG BAY THEO ĐƯỜNG CỦA 5 CHẤM THỂ THAO
              if (flightProgress > 0.05 && flightProgress < 0.95)
                CustomPaint(
                  size: Size(screenW, screenH),
                  painter: _FlightTrailsPainter(
                    dotPositions: dotPositions,
                    tabs: _tabs,
                    flightProgress: flightProgress,
                  ),
                ),

              // 4a. KHUNG THANH NAVIGATION BAR TRÁI (252x50) BUNG MỞ KHI 4 CHẤM TRÁI CHẠM ĐÁY
              if (bloomProgress > 0.01)
                Positioned(
                  left: navBarLeft,
                  bottom: navBarBottom,
                  child: Opacity(
                    opacity: bloomProgress.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.85 + (bloomProgress * 0.15),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: barWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.10 * bloomProgress),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 4b. KHUNG NÚT TIỆN ÍCH TRÒN BÊN PHẢI (50x50) BUNG MỞ KHI CHẤM THỨ 5 CHẠM ĐÁY
              if (bloomProgress > 0.01)
                Positioned(
                  right: 16.0,
                  bottom: navBarBottom,
                  child: Opacity(
                    opacity: bloomProgress.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.85 + (bloomProgress * 0.15),
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 50.0,
                        height: 50.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.10 * bloomProgress),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 5. 5 CHẤM TRÒN BAY & BIẾN HÌNH (MORPH) THÀNH 5 ICON ĐIỀU HƯỚNG & TIỆN ÍCH
              ...List.generate(5, (i) {
                final pos = dotPositions[i];
                final item = _tabs[i];

                // Khi bloomProgress tăng: Chấm tròn chuyển đổi kích thước và nở thành Icon
                final dotSize = (14.0 * (1.0 - (bloomProgress * 0.3))).clamp(8.0, 16.0);
                final iconScale = (bloomProgress * 1.15).clamp(0.0, 1.0);

                return Positioned(
                  left: pos.dx - 18,
                  top: pos.dy - 18,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Sóng xung kích tỏa ra khi chấm chạm đích (Impact Ripple)
                        if (bloomProgress > 0.05 && bloomProgress < 0.80)
                          Container(
                            width: 36 * bloomProgress,
                            height: 36 * bloomProgress,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: item.color.withValues(alpha: 1.0 - bloomProgress),
                                width: 2.0,
                              ),
                            ),
                          ),

                        // Chấm tròn thể thao 3D (Biến mất dần khi Icon xuất hiện)
                        if (bloomProgress < 0.90)
                          Opacity(
                            opacity: (1.0 - (bloomProgress * 1.2)).clamp(0.0, 1.0),
                            child: Container(
                              width: dotSize,
                              height: dotSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(-0.35, -0.35),
                                  radius: 0.85,
                                  colors: [
                                    Colors.white,
                                    item.color,
                                    item.color.withValues(alpha: 0.85),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.color.withValues(alpha: 0.55),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Icon Navigation & Tiện ích nở bung ra từ chấm tròn
                        if (bloomProgress > 0.15)
                          Transform.scale(
                            scale: iconScale,
                            child: Icon(
                              item.icon,
                              color: i == 0 ? AppTheme.primary : const Color(0xFF94A3B8),
                              size: 24,
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

/// CustomPainter vẽ vệt sáng lượn vòng cung phía sau 4 chấm khi bay
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
      final color = tabs[i].color;

      final trailPaint = Paint()
        ..color = color.withValues(alpha: (0.45 * (1.0 - flightProgress * 0.5)).clamp(0.0, 0.45))
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      // Vệt ngắn kéo lùi sau đuôi theo hướng bay xuống
      canvas.drawLine(
        pos,
        Offset(pos.dx, pos.dy - 18.0),
        trailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlightTrailsPainter oldDelegate) => true;
}
