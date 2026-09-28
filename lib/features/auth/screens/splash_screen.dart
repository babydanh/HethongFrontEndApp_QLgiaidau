import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
  late final Timer _authInitTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Khởi tạo auth và chuyển trang
    _authInitTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _initAuth();
      }
    });
  }

  Future<void> _initAuth() async {
    try {
      await ref
          .read(authProvider.notifier)
          .init()
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () {
              debugPrint(
                '[SplashScreen] Auth init timed out, proceeding to /home',
              );
            },
          );
    } catch (e, stack) {
      debugPrint('[SplashScreen] Error during auth init: $e\n$stack');
    }

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
    _authInitTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF06243B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF06243B),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with tennis court / ball from uploaded mockup (Image 3)
            const _SplashBackgroundBackdrop(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TickerMode(
                        enabled: !reduceMotion,
                        child: AnimatedBuilder(
                          animation: _controller,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Hero(
                                  tag: 'Sporto_logo',
                                  child: SvgPicture.asset(
                                    'assets/images/sporto_v1.svg',
                                    width: 200,
                                    height: 80,
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (context) => Image.asset(
                                      'assets/images/sporto_v1.png',
                                      width: 200,
                                      height: 80,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Center(
                                        child: Text(
                                          'SPORTO',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.primary,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.appTagline,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            blurRadius: 6,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                ),
                              ],
                            ),
                          ),
                          builder: (context, child) {
                            return Opacity(
                              opacity: reduceMotion ? 1 : _fadeAnimation.value,
                              child: Transform.scale(
                                scale: reduceMotion ? 1 : _scaleAnimation.value,
                                child: child,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 36),
                      TickerMode(
                        enabled: !reduceMotion,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackgroundBackdrop extends StatelessWidget {
  const _SplashBackgroundBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          'assets/images/splash_bg.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF145DAD),
                  Color(0xFF66C4E0),
                  Color(0xFF397C8D),
                  Color(0xFF092D45),
                ],
              ),
            ),
          ),
        ),
        // Subtle dark overlay to make SVG logo and text stand out clearly with high contrast
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF06243B).withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.25),
                const Color(0xFF06243B).withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

