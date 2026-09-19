import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/features/auth/widgets/pickleball_3d_widget.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // 1. Quả bóng Pickleball mini bay chéo xuống và nảy nhẹ đàn hồi
  late AnimationController _swoopController;
  late Animation<Offset> _swoopOffsetAnimation;
  late Animation<double> _swoopScaleAnimation;
  late Animation<double> _swoopOpacityAnimation;

  // 2. Vòng sóng ánh sáng lan tỏa nhẹ khi bóng chạm tâm (Shockwave Ripple)
  late AnimationController _rippleController;

  // 3. Quả bóng xoay 3D loading liên tục
  late AnimationController _spinController;

  // 4. Nhịp thở lơ lửng bồng bềnh
  late AnimationController _floatController;

  // 5. Logo chính thức SportO SVG mini trượt lên
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  // 6. Thoát màn hình chuyển vào Home mượt mà
  late AnimationController _exitController;
  late Animation<double> _exitFadeAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Bay chéo xuống tâm màn hình (850ms)
    _swoopController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );

    _swoopOffsetAnimation = Tween<Offset>(
      begin: const Offset(1.3, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swoopController,
      curve: Curves.easeOutBack, // Hiệu ứng nảy nhẹ tự nhiên khi đáp
    ));

    _swoopScaleAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swoopController,
      curve: Curves.easeOutCubic,
    ));

    _swoopOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swoopController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));

    // 2. Vòng sóng ánh sáng lan tỏa nhẹ khi bóng chạm đất (600ms)
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 3. Xoay 3D liên tục (Looping Spin)
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat();

    // 4. Nhịp thở lơ lửng (Floating)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    // 5. Logo SportO mini hiện ra
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

    // 6. Thoát màn hình
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
    );

    // Bắt đầu chuỗi animation
    _swoopController.forward();

    // Khi bóng chạm tâm (khoảng 600ms) -> tỏa vòng sóng ánh sáng nhẹ
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _rippleController.forward();
      }
    });

    // Hiện logo SportO mini
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _logoController.forward();
      }
    });

    // Chuyển màn hình sau khi nạp auth
    Future.delayed(const Duration(milliseconds: 2200), () {
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
    _swoopController.dispose();
    _rippleController.dispose();
    _spinController.dispose();
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
          _swoopController,
          _rippleController,
          _spinController,
          _floatController,
          _logoController,
          _exitController,
        ]),
        builder: (context, child) {
          final floatOffset = math.sin(_floatController.value * math.pi) * 4.5;
          final yawRotation = _spinController.value * math.pi * 2;
          final rippleValue = _rippleController.value;

          return FadeTransition(
            opacity: _exitFadeAnimation,
            child: Stack(
              children: [
                // 1. Nền chuyển sắc chuẩn Vibe Web SportO (Trắng sáng & Gradient xanh đại dương nhẹ)
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

                // Vầng sáng dịu nhẹ nhàng ở tâm
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.10),
                          AppTheme.secondary.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),

                // Vòng sóng ánh sáng lan tỏa nhẹ khi bóng chạm tâm (Shockwave Ripple dịu mắt)
                if (rippleValue > 0.0 && rippleValue < 1.0)
                  Center(
                    child: Transform.translate(
                      offset: const Offset(0, -32),
                      child: Container(
                        width: 140 * rippleValue,
                        height: 50 * rippleValue,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(
                              alpha: (1.0 - rippleValue) * 0.45,
                            ),
                            width: 1.5 * (1.0 - rippleValue),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2. Khối trung tâm: Quả bóng Pickleball 3D Mini + Logo SVG SportO
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trái bóng Pickleball 3D Mini (Tròn trịa hoàn hảo, không còn gai nhọn)
                      Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: SlideTransition(
                          position: _swoopOffsetAnimation,
                          child: FadeTransition(
                            opacity: _swoopOpacityAnimation,
                            child: Transform.scale(
                              scale: _swoopScaleAnimation.value,
                              child: Pickleball3DWidget(
                                size: 52, // Kích thước mini chuẩn mực, thanh lịch
                                rotationY: yawRotation,
                                rotationX: -0.30,
                                rotationZ: 0.18,
                                primaryColor: const Color(0xFFD8F800),
                                highlightColor: const Color(0xFFF9FFB8),
                                shadowColor: const Color(0xFF7FA800),
                                showGlow: true,
                                showGroundShadow: true,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

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
                                  final t = (_spinController.value * 2 + delay) % 1.0;
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
          );
        },
      ),
    );
  }
}
