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
    final videoCardSize = (size.width * 0.58).clamp(180.0, 260.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Nền chuyển sắc chuẩn Vibe SportO (Trắng sáng & Xanh thể thao dịu mát)
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
              width: 320,
              height: 320,
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

          // 2. KHỐI TRUNG TÂM: VIDEO PICKLEBALL + LOGO SPORTO
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Khung video Pickleball bo góc chuẩn nét
                Container(
                  width: videoCardSize,
                  height: videoCardSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.22),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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

                const SizedBox(height: 32),

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
