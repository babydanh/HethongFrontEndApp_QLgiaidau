import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Timeline chính tổng thời gian 2700ms với các giai đoạn chuẩn xác:
    // 0.00 - 0.28 (~0 - 750ms)   : Hình 1 (sân có vợt đánh bóng qua lưới) bung mở, nảy nhẹ
    // 0.28 - 0.58 (~750 - 1550ms): Xoay góc chuyển hóa (morph transition) từ Hình 1 sang Hình 2
    // 0.58 - 0.88 (~1550 - 2350ms): Hình 2 xoay lắc nhẹ tại chỗ & thu gọn kích thước thành icon vuông
    // 0.88 - 1.00 (~2350 - 2700ms): Chuyển cảnh êm ái sang Trang chủ (/home)
    _animController = AnimationController(
      duration: const Duration(milliseconds: 2700),
      vsync: this,
    );

    _animController.forward();

    // Kích hoạt nạp auth song song từ 1200ms
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _preWarmAuth();
      }
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _preWarmAuth() async {
    try {
      await ref.read(authProvider.notifier).init().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[SplashScreen] Auth init timed out, proceeding to /home');
        },
      );
    } catch (e, stack) {
      debugPrint('[SplashScreen] Error during auth init: $e\n$stack');
    }
  }

  void _navigateToNextScreen() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    try {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        final tournamentId = auth.tournamentId;
        if (tournamentId != null && tournamentId.isNotEmpty) {
          final route = switch (auth.role) {
            UserRole.admin => '/admin/tournament/$tournamentId',
            UserRole.referee => '/referee',
            UserRole.viewer => '/viewer',
            _ => '/home',
          };
          context.go(route);
          return;
        }
      }
    } catch (e) {
      debugPrint('[SplashScreen] Navigation error: $e');
    }

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          // --- GIAI ĐOẠN 1 (0.0 -> 0.28): SÂN HÌNH 1 BUNG MỞ ---
          // Độ mờ Hình 1
          final fig1Opacity = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
            ).value,
          );
          // Scale xuất hiện ban đầu
          final introScale = Tween<double>(begin: 0.75, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.0, 0.28, curve: Curves.easeOutBack),
            ).value,
          );

          // --- GIAI ĐOẠN 2 (0.28 -> 0.58): XOAY CHUYỂN GÓC SANG HÌNH 2 & CROSS-FADE ---
          // Morph chuyển từ Hình 1 sang Hình 2 (0.0: thuần hình 1, 1.0: thuần hình 2)
          final morph = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.30, 0.54, curve: Curves.easeInOut),
            ).value,
          );

          // Góc xoay phối cảnh khi chuyển (chỉ xoay góc nghiêng nhẹ, tuyệt đối KHÔNG xoay 360 độ vòng tròn)
          final transitionAngle = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.28, 0.56, curve: Curves.easeInOutCubic),
            ).value,
          );
          // Nghiêng nhẹ trục Y từ 0° lên ~16° rồi hạ về 0°
          final morphRotY = math.sin(transitionAngle * math.pi) * 0.28;
          // Nghiêng nhẹ trục Z
          final morphRotZ = math.sin(transitionAngle * math.pi) * 0.06;

          // --- GIAI ĐOẠN 3 (0.58 -> 0.88): HÌNH 2 XOAY TẠI CHỖ & THU GỌN THÀNH ICON VUÔNG ---
          // Thu gọn kích thước từ 190px xuống 125px
          final shrinkProgress = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.50, 0.82, curve: Curves.easeInOutCubic),
            ).value,
          );
          final courtSize = 190.0 - (shrinkProgress * 65.0); // 190px -> 125px

          // Xoay nhẹ nhàng tại chỗ (in-place 3D floating tilt) của Hình 2
          final inPlaceProgress = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.56, 0.88, curve: Curves.easeInOut),
            ).value,
          );
          // Xoay lắc nhẹ tại chỗ quanh trục Y từ -8° tới +8°
          final inPlaceRotY = math.sin(inPlaceProgress * math.pi * 2) * 0.14;
          // Bồng bềnh nhẹ 4px
          final inPlaceFloat = math.sin(inPlaceProgress * math.pi * 2) * 4.0;

          // Tổng hợp góc xoay 3D (êm ái, chân thực, giữ trọn vẹn phối cảnh 3D của ảnh)
          final totalRotY = morphRotY + inPlaceRotY;
          final totalRotZ = morphRotZ + (math.sin(inPlaceProgress * math.pi * 2) * 0.03);

          // --- LOGO SPORTO MINI ---
          final logoOpacity = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.35, 0.60, curve: Curves.easeOut),
            ).value,
          );
          final logoSlide = Tween<Offset>(
            begin: const Offset(0.0, 0.35),
            end: Offset.zero,
          ).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.35, 0.60, curve: Curves.easeOutCubic),
            ).value,
          );

          // --- THOÁT MÀN HÌNH (0.88 -> 1.0) ---
          final exitOpacity = Tween<double>(begin: 1.0, end: 0.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
            ).value,
          );
          final exitScale = Tween<double>(begin: 1.0, end: 1.08).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.88, 1.0, curve: Curves.easeInOutCubic),
            ).value,
          );

          return Opacity(
            opacity: exitOpacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: exitScale,
              child: Stack(
                children: [
                  // 1. Nền chuyển sắc chuẩn Vibe Web SportO (Trắng sáng & Xanh thể thao trang nhã)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE8F3FF), // Sóng xanh nhẹ ở đỉnh
                            Color(0xFFF7FAFD),
                            Colors.white,      // Trắng sáng sang trọng
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Vầng sáng hào quang trung tâm (Radial Glow)
                  Center(
                    child: Container(
                      width: 290,
                      height: 290,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.12),
                            AppTheme.secondary.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 2. Khối trung tâm: Sân 3D Model chuyển hóa + Logo SportO
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cụm Sân 3D: Xoay tại chỗ & Thu gọn chuyển hóa
                        Transform.translate(
                          offset: Offset(0, inPlaceFloat - 8),
                          child: Transform.scale(
                            scale: introScale,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // Phối cảnh chiều sâu 3D tinh tế
                                ..rotateY(totalRotY)
                                ..rotateZ(totalRotZ),
                              child: Container(
                                width: courtSize,
                                height: courtSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.18 + (shrinkProgress * 0.08),
                                      ),
                                      blurRadius: 26 - (shrinkProgress * 6),
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // HÌNH 1: Sân thi đấu có vợt đánh bóng qua lưới
                                    if (morph < 1.0)
                                      Opacity(
                                        opacity: ((1.0 - morph) * fig1Opacity).clamp(0.0, 1.0),
                                        child: Image.asset(
                                          'assets/images/pickleball_court_3d_match.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),

                                    // HÌNH 2: Sân 3D vuông icon (thu gọn)
                                    if (morph > 0.0)
                                      Opacity(
                                        opacity: morph.clamp(0.0, 1.0),
                                        child: Image.asset(
                                          'assets/images/pickleball_court_3d_icon.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // Logo chính thức SportO "Chơi cùng nhau" SVG mini sắc nét
                        SlideTransition(
                          position: AlwaysStoppedAnimation(logoSlide),
                          child: Opacity(
                            opacity: logoOpacity.clamp(0.0, 1.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 38,
                                  child: SvgPicture.asset(
                                    'assets/images/sporto_v1_with_text.svg',
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (context) => Image.asset(
                                      'assets/images/sporto_v1_with_text.png',
                                      height: 38,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // 3 chấm năng lượng mini màu xanh SportO (Vibe Web)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(3, (index) {
                                    final delay = index * 0.22;
                                    final t = (_animController.value * 3.5 + delay) % 1.0;
                                    final dotOpacity = 0.25 + 0.75 * math.sin(t * math.pi);
                                    final dotScale = 0.8 + 0.35 * math.sin(t * math.pi);

                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                                      width: 5.0 * dotScale,
                                      height: 5.0 * dotScale,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.primary.withValues(
                                          alpha: dotOpacity.clamp(0.2, 1.0),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary.withValues(alpha: 0.30),
                                            blurRadius: 4,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
