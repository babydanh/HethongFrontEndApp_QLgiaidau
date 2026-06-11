import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppBottomNav extends StatelessWidget {
  final VoidCallback onFabTap;

  const AppBottomNav({super.key, required this.onFabTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: context.colors.bgSurface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      elevation: 10,
      child: const SizedBox(height: 60), // Khoảng trống cho các tab tương lai
    );
  }

  static Widget buildFab(BuildContext context, VoidCallback onTap) {
    return FloatingActionButton.large(
      onPressed: onTap,
      backgroundColor: AppTheme.accent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 36),
      ),
    ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
