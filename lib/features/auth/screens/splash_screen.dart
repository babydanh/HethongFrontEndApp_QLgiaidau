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
    with TickerProviderStateMixin {
  // 1. Sân 3D Hình 1 (có vợt và bóng đánh qua lưới) xuất hiện nảy nhẹ
  late AnimationController _introController;
  late Animation<double> _introScaleAnimation;
  late Animation<double> _introFadeAnimation;

  // 2. Xoay 3D tại chỗ và chuyển hóa từ Hình 1 (sân dài) sang Hình 2 (sân vuông compact)
  late AnimationController _turnController;

  // 3. Nhịp thở lơ lửng bồng bềnh (Floating / Breathing)
  late AnimationController _floatController;

  // 4. Logo chính thức SportO SVG mini xuất hiện
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  // 5. Chuyển tiếp êm ái sang Trang chủ
  late AnimationController _exitController;
  late Animation<double> _exitFadeAnimation;
  late Animation<double> _exitScaleAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Hình 1 xuất hiện (750ms)
    _introController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    _introScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _introFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeIn),
    );

    // 2. Xoay 3D tại chỗ chuyển hóa sang Hình 2 (1100ms)
    _turnController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    // 3. Nhịp thở lơ lửng
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    // 4. Logo SportO mini trượt lên
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // 5. Thoát màn hình
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
    );

    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    // === KỊCH BẢN CHUYỂN ĐỘNG (TIMELINE) ===
    // 0ms: Sân 3D có vợt và bóng (Hình 1) bung mở ra
    _introController.forward();

    // 700ms: Sân bắt đầu xoay 3D tại chỗ và thu gọn chuyển hóa sang Hình 2
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _turnController.forward();
      }
    });

    // 1200ms: Logo SportO mini trượt lên tinh tế bên dưới
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _logoController.forward();
      }
    });

    // 2400ms: Nạp Auth xong chuyển tiếp êm ái sang Trang chủ
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        _initAuth();
      }
    });
  }

  Future<void> _initAuth() async {
    if (_isNavigating) return;

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

    if (!mounted) return;

    _isNavigating = true;

    await _exitController.forward();

    if (!mounted) return;

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
    _introController.dispose();
    _turnController.dispose();
    _floatController.dispose();
    _logoController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _introController,
          _turnController,
          _floatController,
          _logoController,
          _exitController,
        ]),
        builder: (context, child) {
          final floatOffset = math.sin(_floatController.value * math.pi) * 5.0;
          final turn = _turnController.value; // 0.0 -> 1.0

          // Góc xoay 3D (xoay quanh trục Y và nghiêng nhẹ Z)
          final rotationY = turn * math.pi * 2;
          final isSecondHalf = turn >= 0.5; // Nửa đầu hiển thị Hình 1, nửa sau hiển thị Hình 2

          // Thu gọn kích thước từ Hình 1 (175px) sang Hình 2 (125px)
          final courtSize = Tween<double>(begin: 175.0, end: 125.0)
              .transform(CurvedAnimation(parent: _turnController, curve: Curves.easeInOutCubic).value);

          return FadeTransition(
            opacity: _exitFadeAnimation,
            child: Transform.scale(
              scale: _exitScaleAnimation.value,
              child: Stack(
                children: [
                  // 1. Nền chuyển sắc chuẩn Vibe Web SportO (Trắng & Xanh thể thao dịu mắt)
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
                      width: 280,
                      height: 280,
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
                        // Cụm Sân 3D xoay tại chỗ và biến hình
                        Transform.translate(
                          offset: Offset(0, floatOffset - 10),
                          child: FadeTransition(
                            opacity: _introFadeAnimation,
                            child: Transform.scale(
                              scale: _introScaleAnimation.value,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0012) // Phối cảnh chiều sâu 3D
                                  ..rotateY(rotationY)
                                  ..rotateZ(math.sin(rotationY) * 0.08),
                                child: Container(
                                  width: courtSize,
                                  height: courtSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.20),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: isSecondHalf
                                      // Giai đoạn 2: Thu gọn thành Hình 2 (Sân vuông 3D compact)
                                      ? Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()..rotateY(math.pi), // Giữ mặt chính khi xoay tiếp
                                          child: Image.asset(
                                            'assets/images/pickleball_court_3d_icon.png',
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      // Giai đoạn 1: Sân 3D đầy đủ có vợt đánh bóng qua lưới
                                      : Image.asset(
                                          'assets/images/pickleball_court_3d_match.png',
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Logo chính thức SportO "Chơi cùng nhau" SVG mini sắc nét
                        SlideTransition(
                          position: _logoSlideAnimation,
                          child: FadeTransition(
                            opacity: _logoFadeAnimation,
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
                                    final delay = index * 0.25;
                                    final t = (_floatController.value * 2 + delay) % 1.0;
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
