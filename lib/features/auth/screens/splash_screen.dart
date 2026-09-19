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
  // 1. Quả bóng bay chéo lướt nhẹ từ góc trên xuống (Swoop In)
  late AnimationController _swoopController;
  late Animation<Offset> _swoopOffsetAnimation;
  late Animation<double> _swoopScaleAnimation;
  late Animation<double> _swoopOpacityAnimation;

  // 2. Vòng xoay 3D Pickleball loading liên tục quanh trục nghiêng
  late AnimationController _spinController;

  // 3. Nhịp thở lơ lửng nhẹ nhàng (Floating)
  late AnimationController _floatController;

  // 4. Logo SportO mini xuất hiện mượt mà
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  // 5. Chuyển cảnh êm ái vào Home
  late AnimationController _exitController;
  late Animation<double> _exitFadeAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Bay chéo xuống tâm
    _swoopController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );

    _swoopOffsetAnimation = Tween<Offset>(
      begin: const Offset(1.3, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swoopController,
      curve: Curves.easeOutBack,
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
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    ));

    // 2. Xoay 3D liên tục
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    // 3. Lơ lửng nhịp thở
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    // 4. Logo SportO mini trượt lên
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    // 5. Thoát màn hình
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeOut,
    ));

    _swoopController.forward();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _logoController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
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
          _spinController,
          _floatController,
          _logoController,
          _exitController,
        ]),
        builder: (context, child) {
          final floatOffset = math.sin(_floatController.value * math.pi) * 5.0;
          final yawRotation = _spinController.value * math.pi * 2;

          return FadeTransition(
            opacity: _exitFadeAnimation,
            child: Stack(
              children: [
                // 1. Nền chuyển sắc phong cách Web SportO (Clean White & Ocean Blue Wave)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE8F3FF), // Xanh dương nhẹ ở đỉnh như banner Web
                          Color(0xFFF7FAFD),
                          Colors.white,      // Trắng sáng hiện đại
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Vầng sáng xanh thể thao mềm mại ở phía sau (Radial Glow)
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.12),
                          AppTheme.secondary.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // 2. Khối trung tâm: Quả bóng Pickleball 3D Mini + Logo SVG SportO
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trái bóng Pickleball 3D kích thước mini tinh tế
                      Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: SlideTransition(
                          position: _swoopOffsetAnimation,
                          child: FadeTransition(
                            opacity: _swoopOpacityAnimation,
                            child: Transform.scale(
                              scale: _swoopScaleAnimation.value,
                              child: Pickleball3DWidget(
                                size: 54, // Kích thước mini hài hòa, tinh tế
                                rotationY: yawRotation,
                                rotationX: -0.30,
                                rotationZ: 0.18,
                                primaryColor: const Color(0xFFD8F800),
                                highlightColor: const Color(0xFFF9FFB8),
                                shadowColor: const Color(0xFF6B8F00),
                                showGlow: true,
                                showGroundShadow: true,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Logo chính thức SportO "Chơi cùng nhau" SVG kích thước mini
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

                              const SizedBox(height: 18),

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
                                    width: 5.5 * dotScale,
                                    height: 5.5 * dotScale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primary.withValues(
                                        alpha: dotOpacity.clamp(0.2, 1.0),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withValues(alpha: 0.35),
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
