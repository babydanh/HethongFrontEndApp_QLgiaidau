import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/features/auth/widgets/pickleball_rally_court.dart';

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

    // Timeline tổng thể 3000ms:
    // 0.00 - 0.50 (0 - 1500ms)  : Vợt vung đánh bóng qua lưới, bóng nảy nảy lửa ("đánh tùm lum")
    // 0.50 - 0.72 (1500 - 2160ms): Xoay góc chuyển hóa sang Hình 2 & thu gọn kích thước
    // 0.72 - 0.88 (2160 - 2640ms): Hình 2 (sân vuông 3D compact) xoay nhẹ tại chỗ lơ lửng
    // 0.88 - 1.00 (2640 - 3000ms): Chuyển cảnh êm ái sang Trang chủ (/home)
    _animController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _animController.forward();

    // Khởi tạo Auth song song từ sớm
    Future.delayed(const Duration(milliseconds: 1400), () {
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
          final val = _animController.value;

          // ----------------------------------------------------
          // 1. PHA ĐÁNH BÓNG TRÊN SÂN 3D (0.0 -> 0.50)
          // ----------------------------------------------------
          // Tiến trình rally: hoàn thành 2 pha đánh bóng (uốn quanh 0..1 hai lần)
          final rallyProgress = (val / 0.50).clamp(0.0, 1.0);

          // Sân 3D xuất hiện ban đầu nảy nhẹ
          final courtIntroScale = Tween<double>(begin: 0.70, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.0, 0.22, curve: Curves.easeOutBack),
            ).value,
          );
          final courtIntroFade = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
            ).value,
          );

          // ----------------------------------------------------
          // 2. PHA XOAY CHUYỂN SANG HÌNH 2 & THU GỌN (0.50 -> 0.72)
          // ----------------------------------------------------
          final morphProgress = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.50, 0.70, curve: Curves.easeInOutCubic),
            ).value,
          );

          // Thu gọn kích thước từ 230px xuống 125px
          final courtSize = 230.0 - (morphProgress * 105.0);

          // Xoay nhẹ góc phối cảnh 3D khi chuyển (không quay 360 vòng tròn)
          final turnAngle = math.sin(morphProgress * math.pi) * 0.25;

          // ----------------------------------------------------
          // 3. PHA HÌNH 2 XOAY LƠ LỬNG TẠI CHỖ (0.72 -> 0.88)
          // ----------------------------------------------------
          final inPlaceT = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.70, 0.90, curve: Curves.easeInOut),
            ).value,
          );
          final inPlaceRotY = math.sin(inPlaceT * math.pi * 2) * 0.12;
          final inPlaceFloat = math.sin(inPlaceT * math.pi * 2) * 4.0;

          final totalRotY = turnAngle + inPlaceRotY;

          // ----------------------------------------------------
          // 4. LOGO SPORTO MINI TRƯỢT LÊN
          // ----------------------------------------------------
          final logoFade = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.25, 0.50, curve: Curves.easeOut),
            ).value,
          );
          final logoSlide = Tween<Offset>(
            begin: const Offset(0.0, 0.35),
            end: Offset.zero,
          ).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.25, 0.50, curve: Curves.easeOutCubic),
            ).value,
          );

          // ----------------------------------------------------
          // 5. CHUYỂN TIẾP VÀO MÀN HÌNH CHÍNH (0.88 -> 1.0)
          // ----------------------------------------------------
          final exitFade = Tween<double>(begin: 1.0, end: 0.0).transform(
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
            opacity: exitFade.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: exitScale,
              child: Stack(
                children: [
                  // Nền chuyển sắc chuẩn Vibe Web SportO
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE8F3FF),
                            Color(0xFFF7FAFD),
                            Colors.white,
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Vầng sáng hào quang trung tâm
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

                  // Khối trung tâm
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cụm Sân 3D: Đánh bóng -> Xoay góc chuyển hóa -> Thu gọn thành Hình 2
                        Transform.translate(
                          offset: Offset(0, inPlaceFloat - 8),
                          child: Transform.scale(
                            scale: courtIntroScale,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(totalRotY),
                              child: Container(
                                width: courtSize,
                                height: courtSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.16 + (morphProgress * 0.10),
                                      ),
                                      blurRadius: 28 - (morphProgress * 6),
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 1. GIAI ĐOẠN 1: SÂN 3D VỚI VỢT ĐÁNH BÓNG QUA LƯỚI ("ĐÁNH TÙM LUM")
                                    if (morphProgress < 1.0)
                                      Opacity(
                                        opacity: ((1.0 - morphProgress) * courtIntroFade).clamp(0.0, 1.0),
                                        child: CustomPaint(
                                          size: Size(courtSize, courtSize),
                                          painter: PickleballRallyCourtPainter(
                                            rallyProgress: rallyProgress,
                                            courtOpacity: 1.0,
                                          ),
                                        ),
                                      ),

                                    // 2. GIAI ĐOẠN 2 & 3: ICON SÂN 3D VUÔNG (HÌNH 2) THU GỌN VÀ XOAY TẠI CHỖ
                                    if (morphProgress > 0.0)
                                      Opacity(
                                        opacity: morphProgress.clamp(0.0, 1.0),
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

                        const SizedBox(height: 28),

                        // Logo chính thức SportO "Chơi cùng nhau" SVG mini
                        SlideTransition(
                          position: AlwaysStoppedAnimation(logoSlide),
                          child: Opacity(
                            opacity: logoFade.clamp(0.0, 1.0),
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

                                // 3 chấm năng lượng xanh Sport Blue
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
