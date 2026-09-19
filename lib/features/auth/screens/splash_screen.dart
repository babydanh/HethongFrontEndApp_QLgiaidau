import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isNavigating = false;
  Timer? _navTimer;

  // Màu nền đồng bộ chính xác 100% với nền video pickleball 3D
  static const Color _videoBgTop = Color(0xFFD7D5D6);
  static const Color _videoBgBottom = Color(0xFFE0DEDF);

  @override
  void initState() {
    super.initState();

    _initVideo();

    // Nạp dữ liệu Auth song song
    _preWarmAuth();

    // Tự động chuyển màn hình sau 3.5 giây
    _navTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  void _initVideo() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/pickleball_loading.mp4',
    )..initialize().then((_) {
        if (mounted) {
          _videoController.setLooping(true);
          _videoController.setVolume(0.0);
          _videoController.play();
          setState(() {
            _isVideoInitialized = true;
          });
        }
      }).catchError((e) {
        debugPrint('[SplashScreen] Video initialization error: $e');
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
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final videoCardSize = (size.width * 0.72).clamp(240.0, 320.0);

    return Scaffold(
      backgroundColor: _videoBgTop,
      body: Stack(
        children: [
          // 1. Nền chuyển sắc đồng nhất màu với video (xám studio cao cấp)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _videoBgTop,
                    _videoBgBottom,
                    _videoBgTop,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. KHỐI TRUNG TÂM: VIDEO PICKLEBALL + LOGO SPORTO
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Khung video Pickleball hòa tan viền với màu nền
                Container(
                  width: videoCardSize,
                  height: videoCardSize,
                  decoration: BoxDecoration(
                    color: _videoBgTop,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isVideoInitialized
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController.value.size.width,
                            height: _videoController.value.size.height,
                            child: VideoPlayer(_videoController),
                          ),
                        )
                      : Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 28),

                // 3. LOGO CHÍNH THỨC SPORTO "CHƠI CÙNG NHAU" SVG
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 42,
                      child: SvgPicture.asset(
                        'assets/images/sporto_v1_with_text.svg',
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Image.asset(
                          'assets/images/sporto_v1_with_text.png',
                          height: 42,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Thanh loading mảnh phong cách thể thao
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.20),
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
