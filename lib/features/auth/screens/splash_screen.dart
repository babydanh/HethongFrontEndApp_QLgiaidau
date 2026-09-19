import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/features/auth/widgets/pickleball_3d_widget.dart';
import 'package:app_quanly_giaidau/features/auth/widgets/court_laser_3d_painter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // 1. Tia laser vẽ các đường line sân 3D
  late AnimationController _laserController;

  // 2. Trái bóng Pickleball nảy 1 nhịp chuẩn xác vào vạch giao bóng
  late AnimationController _bounceController;
  late Animation<double> _ballYAnimation;
  late Animation<double> _ballScaleAnimation;
  late Animation<double> _ballOpacityAnimation;

  // 3. Sóng chấn động khi bóng tiếp xúc mặt sân
  late AnimationController _impactController;

  // 4. Các đường line sân co tròn (morph) thành vòng hào quang
  late AnimationController _morphController;

  // 5. Quả bóng xoay 3D liên tục
  late AnimationController _spinController;

  // 6. Nhịp thở lơ lửng bồng bềnh
  late AnimationController _floatController;

  // 7. Logo SportO SVG mini hiện ra
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  // 8. Thoát màn hình chuyển vào Trang chủ
  late AnimationController _exitController;
  late Animation<double> _exitFadeAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Tia Laser vẽ sân 3D (850ms)
    _laserController = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );

    // 2. Bóng Pickleball rơi và nảy 1 nhịp (700ms)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Mô phỏng quỹ đạo rơi từ trên cao xuống và nảy 1 nhịp
    _ballYAnimation = TweenSequence<double>([
      // Rơi từ trên cao (-130) xuống chạm sàn (0)
      TweenSequenceItem(
        tween: Tween<double>(begin: -130.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 48,
      ),
      // Nảy lên đỉnh nhịp 1 (-32)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -32.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 26,
      ),
      // Rơi xuống lại sàn (0)
      TweenSequenceItem(
        tween: Tween<double>(begin: -32.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 26,
      ),
    ]).animate(_bounceController);

    _ballScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 48,
      ),
      // Biến dạng nảy nhẹ khi đập sàn (squash & stretch)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        weight: 40,
      ),
    ]).animate(_bounceController);

    _ballOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: const Interval(0.0, 0.3)),
    );

    // 3. Sóng chấn động khi bóng đập sàn (450ms)
    _impactController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    // 4. Các đường line sân co lại thành vòng hào quang (750ms)
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    // 5. Xoay 3D liên tục (Looping Spin)
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();

    // 6. Nhịp thở lơ lửng
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    // 7. Logo SportO mini hiện ra
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // 8. Thoát màn hình chuyển vào Home
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
    );

    // === CHẠY KỊCH BẢN CHUYỂN ĐỘNG THEO DÒNG THỜI GIAN (CINEMATIC TIMELINE) ===
    // 0ms: Tia laser bắt đầu vẽ sân 3D
    _laserController.forward();

    // 550ms: Trái bóng bắt đầu rơi xuống từ trên cao
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        _bounceController.forward();
      }
    });

    // 880ms: Bóng tiếp sàn nhịp đầu tiên -> kích hoạt sóng chấn động mặt sân
    Future.delayed(const Duration(milliseconds: 880), () {
      if (mounted) {
        _impactController.forward();
      }
    });

    // 1250ms: Các đường line sân co tròn (morph) thành vòng hào quang năng lượng
    Future.delayed(const Duration(milliseconds: 1250), () {
      if (mounted) {
        _morphController.forward();
      }
    });

    // 1450ms: Logo chính thức SportO SVG mini trượt lên trong vòng hào quang
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) {
        _logoController.forward();
      }
    });

    // 2400ms: Bắt đầu nạp Auth và chuyển tiếp vào Trang chủ
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
    _laserController.dispose();
    _bounceController.dispose();
    _impactController.dispose();
    _morphController.dispose();
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
          _laserController,
          _bounceController,
          _impactController,
          _morphController,
          _spinController,
          _floatController,
          _logoController,
          _exitController,
        ]),
        builder: (context, child) {
          final floatOffset = math.sin(_floatController.value * math.pi) * 4.5;
          final yawRotation = _spinController.value * math.pi * 2;
          final ballY = _ballYAnimation.value + (_bounceController.isCompleted ? floatOffset : 0.0);

          return FadeTransition(
            opacity: _exitFadeAnimation,
            child: Stack(
              children: [
                // 1. Nền chuyển sắc chuẩn Vibe Web SportO
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE8F3FF), // Sóng xanh thể thao nhẹ ở đỉnh
                          Color(0xFFF7FAFD),
                          Colors.white,
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Vầng hào quang trung tâm (Radial Atmosphere)
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

                // 2. Lớp tia Laser vẽ sân 3D Isometric & Morphing thành vòng hào quang
                Positioned.fill(
                  child: CustomPaint(
                    painter: CourtLaser3DPainter(
                      laserProgress: _laserController.value,
                      morphProgress: _morphController.value,
                      impactProgress: _impactController.value,
                    ),
                  ),
                ),

                // 3. Khối trung tâm: Trái bóng Pickleball 3D nảy & Logo SportO mini
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trái bóng Pickleball 3D nảy xuống ngay tâm vạch giao bóng
                      Transform.translate(
                        offset: Offset(0, ballY - 10),
                        child: FadeTransition(
                          opacity: _ballOpacityAnimation,
                          child: Transform.scale(
                            scale: _ballScaleAnimation.value,
                            child: Pickleball3DWidget(
                              size: 52, // Kích thước mini chuẩn mực, sắc sảo
                              rotationY: yawRotation,
                              rotationX: -0.30,
                              rotationZ: 0.18,
                              primaryColor: const Color(0xFFD8F800),
                              highlightColor: const Color(0xFFF9FFB8),
                              shadowColor: const Color(0xFF6B8F00),
                              showGlow: true,
                              showGroundShadow: _bounceController.value > 0.4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Logo chính thức SportO "Chơi cùng nhau" SVG mini
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

                              // 3 chấm năng lượng mini SportO Blue
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
