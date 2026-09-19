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

  @override
  void initState() {
    super.initState();

    _initVideo();

    // Nạp dữ liệu Auth song song
    _preWarmAuth();

    // Tự động chuyển màn hình sau 3.2 giây (khớp đúng chu kỳ video 3s)
    _navTimer = Timer(const Duration(milliseconds: 3200), () {
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
    final videoCardSize = (size.width * 0.65).clamp(220.0, 300.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Nền trắng tinh khiết (#FFFFFF) đồng bộ 100% với Web & Video Blender
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),

          // KHỐI TRUNG TÂM: VIDEO BLENDER 3D + LOGO SPORTO
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Khung video hòa tan hoàn toàn vào nền trắng (không viền)
                SizedBox(
                  width: videoCardSize,
                  height: videoCardSize,
                  child: _isVideoInitialized
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _videoController.value.size.width,
                            height: _videoController.value.size.height,
                            child: VideoPlayer(_videoController),
                          ),
                        )
                      : Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 20),

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
