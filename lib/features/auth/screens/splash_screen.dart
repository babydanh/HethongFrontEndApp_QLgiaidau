import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Khởi tạo auth và chuyển trang
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _initAuth();
      }
    });
  }

  Future<void> _initAuth() async {
    await ref.read(authProvider.notifier).init();

    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      final route = switch (auth.role) {
        UserRole.admin => '/admin/tournament/${auth.tournamentId}',
        UserRole.referee => '/referee',
        UserRole.viewer => '/viewer',
        _ => '/home',
      };
      context.go(route);
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo / Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: context.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Name
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          context.primaryGradient.createShader(bounds),
                      child: const Text(
                        'QUẢN LÝ\nGIẢI ĐẤU',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'Tổ chức giải đấu chuyên nghiệp',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.textSecondary.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
