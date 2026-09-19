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

    // Timeline chuẩn xác (2800ms):
    // 0.00 - 0.18 (0 - 500ms)  : Sân rộng (Hình 1) xuất hiện êm ái
    // 0.15 - 0.55 (420 - 1540ms): Quả bóng pickleball vàng bay chậm từ vợt ra chính giữa sân (KHÔNG XOAY)
    // 0.55 - 0.80 (1540 - 2240ms): Sân rộng thu hẹp lại thành model Hình 2 (sân vuông compact)
    // 0.80 - 0.90 (2240 - 2520ms): Giữ Model Hình 2 bồng bềnh nhẹ tại chỗ
    // 0.90 - 1.00 (2520 - 2800ms): Chuyển cảnh êm ái sang Trang chủ (/home)
    _animController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    _animController.forward();

    // Nạp dữ liệu Auth song song
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
          // --- 1. SÂN RỘNG HÌNH 1 XUẤT HIỆN ---
          final introFade = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
            ).value,
          );
          final introScale = Tween<double>(begin: 0.88, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.0, 0.20, curve: Curves.easeOutCubic),
            ).value,
          );

          // --- 2. BÓNG PICKLEBALL BAY CHẬM RA GIỮA (0.15 -> 0.55) ---
          final ballT = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.15, 0.55, curve: Curves.easeInOutCubic),
            ).value,
          );

          // --- 3. SÂN THU HẸP LẠI THÀNH MODEL HÌNH 2 (0.55 -> 0.80) ---
          final shrinkProgress = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.55, 0.80, curve: Curves.easeInOutCubic),
            ).value,
          );

          // Kích thước thu hẹp từ sân rộng 225px xuống 140px (sân vuông compact)
          final courtSize = 225.0 - (shrinkProgress * 85.0);

          // Morph mờ dần từ Hình 1 sang Hình 2
          final morph = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.55, 0.78, curve: Curves.easeInOut),
            ).value,
          );

          // Bồng bềnh nhẹ nhàng tại chỗ khi đã thành hình 2 (không xoay!)
          final floatOffset = math.sin(_animController.value * math.pi * 3) * 3.5;

          // --- 4. LOGO SPORTO SVG MINI (0.30 -> 0.60) ---
          final logoFade = Tween<double>(begin: 0.0, end: 1.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.30, 0.58, curve: Curves.easeOut),
            ).value,
          );
          final logoSlide = Tween<Offset>(
            begin: const Offset(0.0, 0.35),
            end: Offset.zero,
          ).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.30, 0.58, curve: Curves.easeOutCubic),
            ).value,
          );

          // --- 5. CHUYỂN TIẾP VÀO MÀN HÌNH CHÍNH (0.90 -> 1.0) ---
          final exitFade = Tween<double>(begin: 1.0, end: 0.0).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
            ).value,
          );
          final exitScale = Tween<double>(begin: 1.0, end: 1.06).transform(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0.90, 1.0, curve: Curves.easeInOutCubic),
            ).value,
          );

          // ==========================================================
          // TÍNH TOÁN VỊ TRÍ QUẢ BÓNG BAY CHẬM RA GIỮA (TRÊN KHUNG SÂN)
          // ==========================================================
          // Tọa độ tương đối từ vị trí Vợt (Hình 1) ra đến vị trí Tâm (Hình 2)
          // Điểm xuất phát (vợt góc trên-trái): x = 0.30, y = 0.30
          // Điểm đích (giữa sân): x = 0.52, y = 0.43
          final ballRelX = 0.30 + (0.22 * ballT);
          // Quỹ đạo cong hình vòng cung parabol vồng lên rồi rơi chậm xuống
          final ballArc = math.sin(ballT * math.pi) * 0.14;
          final ballRelY = (0.30 + (0.13 * ballT)) - ballArc;

          final ballPixelX = courtSize * ballRelX;
          final ballPixelY = courtSize * ballRelY;

          // Độ mờ của quả bóng đang bay (mờ dần khi đã vào vị trí và Hình 2 hiện rõ)
          final flyingBallOpacity = (ballT > 0.0 && morph < 0.95)
              ? (1.0 - (morph * 1.1)).clamp(0.0, 1.0)
              : 0.0;

          return Opacity(
            opacity: exitFade.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: exitScale,
              child: Stack(
                children: [
                  // 1. Nền chuyển sắc chuẩn Vibe Web SportO (Trắng sáng & Xanh thể thao dịu mát)
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

                  // Vầng hào quang trung tâm mềm mại
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

                  // 2. KHỐI TRUNG TÂM: SÂN THU HẸP + BÓNG BAY RA GIỮA (KHÔNG XOAY)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: Offset(0, floatOffset - 8),
                          child: Transform.scale(
                            scale: introScale,
                            child: Container(
                              width: courtSize,
                              height: courtSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.16 + (shrinkProgress * 0.08),
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
                                  // --- HÌNH 1: SÂN RỘNG ĐÁNH BÓNG (THU HẸP DẦN) ---
                                  if (morph < 1.0)
                                    Opacity(
                                      opacity: ((1.0 - morph) * introFade).clamp(0.0, 1.0),
                                      child: Image.asset(
                                        'assets/images/pickleball_court_3d_match.png',
                                        fit: BoxFit.contain,
                                        width: courtSize,
                                        height: courtSize,
                                      ),
                                    ),

                                  // --- HÌNH 2: MODEL SÂN THU HẸP VUÔNG COMPACT ---
                                  if (morph > 0.0)
                                    Opacity(
                                      opacity: morph.clamp(0.0, 1.0),
                                      child: Image.asset(
                                        'assets/images/pickleball_court_3d_icon.png',
                                        fit: BoxFit.contain,
                                        width: courtSize,
                                        height: courtSize,
                                      ),
                                    ),

                                  // --- QUẢ BÓNG PICKLEBALL BAY CHẬM RA GIỮA SÂN ---
                                  if (flyingBallOpacity > 0.01)
                                    Positioned(
                                      left: ballPixelX - 9,
                                      top: ballPixelY - 9,
                                      child: Opacity(
                                        opacity: flyingBallOpacity,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Vệt sáng vàng neon lướt theo bóng
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    const Color(0xFFFFEB3B).withValues(alpha: 0.65),
                                                    const Color(0xFFFFC107).withValues(alpha: 0.20),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Quả bóng pickleball vàng 3D
                                            Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const RadialGradient(
                                                  center: Alignment(-0.35, -0.35),
                                                  radius: 0.85,
                                                  colors: [
                                                    Color(0xFFFFFF9D), // Điểm phản quang
                                                    Color(0xFFFFEA00), // Vàng neon pickleball
                                                    Color(0xFFFF9800), // Đổ bóng quả bóng
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.25),
                                                    blurRadius: 4,
                                                    offset: const Offset(1, 2),
                                                  ),
                                                ],
                                              ),
                                              // Các chấm tròn đặc trưng bóng pickleball
                                              child: CustomPaint(
                                                painter: _PickleballHolesPainter(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // 3. LOGO CHÍNH THỨC SPORTO "CHƠI CÙNG NHAU" SVG MINI
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

/// Vẽ các chấm tròn nhỏ của quả bóng Pickleball
class _PickleballHolesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF37474F).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;

    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c + const Offset(-2.0, -1.5), 0.9, paint);
    canvas.drawCircle(c + const Offset(2.0, -1.8), 0.9, paint);
    canvas.drawCircle(c + const Offset(-0.3, 2.2), 0.9, paint);
    canvas.drawCircle(c + const Offset(2.5, 1.4), 0.8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
