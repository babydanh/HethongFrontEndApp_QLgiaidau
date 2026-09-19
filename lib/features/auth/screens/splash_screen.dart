import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/pickleball_court_animation.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isNavigating = false;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // Nạp dữ liệu Auth song song
    _preWarmAuth();

    // Tự động chuyển màn hình mượt mà sau 2.2 giây
    _navTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _preWarmAuth() async {
    try {
      await ref.read(authProvider.notifier).init().timeout(
        const Duration(seconds: 3),
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
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final courtSize = (size.width * 0.55).clamp(180.0, 240.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Nền trắng tinh khiết (#FFFFFF) chuẩn Vibe Web
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),

          // KHỐI TRUNG TÂM: HOẠT HỌA SÂN PICKLEBALL 3D + LOGO SPORTO
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hoạt họa Sân 3D vẽ hoàn toàn bằng code Flutter (nền trong suốt, bóng nảy to/nhỏ đập smash)
                PickleballCourtAnimation(
                  size: courtSize,
                ),

                const SizedBox(height: 24),

                // LOGO CHÍNH THỨC SPORTO "CHƠI CÙNG NHAU" SVG
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 40,
                      child: SvgPicture.asset(
                        'assets/images/sporto_v1_with_text.svg',
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Image.asset(
                          'assets/images/sporto_v1_with_text.png',
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Thanh loading thể thao mảnh đồng màu #1D8EF8
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
