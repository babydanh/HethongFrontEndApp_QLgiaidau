import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/pickleball_court_3d_animated.dart';
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

    // Chuyển màn hình ngay lập tức sang /home để màn loading MorphingNavLoader thực hiện
    _navTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
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
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

          // Vầng hào quang xanh Sport Blue rất nhẹ ở trung tâm
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // LOGO CHÍNH THỨC SPORTO NGUYÊN BẢN (KHÔNG SÂN CŨ, KHÔNG CHỮ THỪA)
          Center(
            child: SvgPicture.asset(
              'assets/images/sporto_v1.svg',
              width: 230,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Image.asset(
                'assets/images/sporto_v1.png',
                width: 230,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
