import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/vnsport_header.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginLoadingScreen extends ConsumerStatefulWidget {
  const LoginLoadingScreen({super.key});

  @override
  ConsumerState<LoginLoadingScreen> createState() => _LoginLoadingScreenState();
}

class _LoginLoadingScreenState extends ConsumerState<LoginLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Chờ 2.2 giây để người dùng trải nghiệm hiệu ứng chào mừng trước khi thu nhỏ thành header trang chủ
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final userProfileAsync = ref.watch(userProfileProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: Stack(
        children: [
          // Header siêu to chiếm 68% chiều cao màn hình dùng Hero tag để khi chuyển sang trang chủ sẽ thu nhỏ mượt mà
          Hero(
            tag: "vnsport_header_bg",
            child: CustomPaint(
              size: Size(double.infinity, size.height * 0.68),
              painter: VnsportHeaderPainter(
                isLoggedIn: true,
                colors: colors,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo VNSPORT siêu to dùng Hero tag
                  Hero(
                    tag: "vnsport_logo",
                    child: SizedBox(
                      height: 95,
                      child: SvgPicture.asset(
                        "assets/images/vndcsport.svg",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Dòng chào mừng với hiệu ứng mượt mà
                  userProfileAsync.when(
                    data: (profile) {
                      final name = profile.fullName ?? "Người dùng";
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "CHÀO MỪNG QUAY TRỞ LẠI",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                    error: (context, error) => Text(
                      "Đăng nhập thành công!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(),
                  ),
                  
                  const SizedBox(height: 48),
                  // Spinner hiệu ứng mờ sang trọng
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
