import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/widgets/morphing_nav_loader_transition.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    debugPrint('>>> [SplashScreen] Mounted - Starting 5-ball morphing animation <<<');
    // Reset cờ để mỗi lần splash chạy đều hiển thị đầy đủ hiệu ứng biến hình
    MorphingNavLoaderOverlay.hasCompletedInitialLoad = false;
    _preWarmAuth();
  }

  Future<void> _preWarmAuth() async {
    try {
      await ref.read(authProvider.notifier).init().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[SplashScreen] Auth init timed out, proceeding');
        },
      );
    } catch (e, stack) {
      debugPrint('[SplashScreen] Error during auth init: $e\n$stack');
    }
  }

  void _onAnimationCompleted() {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MorphingNavLoaderOverlay(
        onCompleted: _onAnimationCompleted,
      ),
    );
  }
}

