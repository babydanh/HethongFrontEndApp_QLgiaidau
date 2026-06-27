import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';

class FloatingBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider).isAuthenticated;
    final userProfileAsync = ref.watch(userProfileProvider);
    final avatarUrl = userProfileAsync.asData?.value.avatarUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double navBarHeight = 66.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 60) / 5;

    const activeColor = Color(0xFF2979FF);
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF94A3B8);
    final bgColor = isDark ? const Color(0xFF0A0A0A).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92);
    final borderSide = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // ─── Main bar ───
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: screenWidth,
              height: navBarHeight + bottomPadding,
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: borderSide)),
              ),
              padding: EdgeInsets.only(bottom: bottomPadding + 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.explore_outlined, Icons.explore_rounded, "Khám phá", activeColor, inactiveColor),
                  _buildNavItem(1, Icons.emoji_events_outlined, Icons.emoji_events_rounded, "Giải đấu", activeColor, inactiveColor),
                  const SizedBox(width: 52),
                  _buildNavItem(3, Icons.people_outline_rounded, Icons.people_rounded, "CLB", activeColor, inactiveColor),
                  _buildNavItem(4, Icons.leaderboard_outlined, Icons.leaderboard_rounded, "Xếp hạng", activeColor, inactiveColor),
                ],
              ),
            ),
          ),
        ),

        // ─── Profile Avatar (center) ───
        Positioned(
          top: -bottomPadding - 28,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              onTabSelected(2);
              onProfileTap();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: currentIndex == 2
                        ? const LinearGradient(colors: [Color(0xFF2979FF), Color(0xFF4D88FF)])
                        : null,
                    color: currentIndex == 2 ? null : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                    border: Border.all(
                      color: currentIndex == 2
                          ? const Color(0xFF2979FF)
                          : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0)),
                      width: currentIndex == 2 ? 0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentIndex == 2
                            ? const Color(0xFF2979FF).withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.06),
                        blurRadius: currentIndex == 2 ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _buildAvatarContent(isLoggedIn, avatarUrl, currentIndex == 2),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: currentIndex == 2 ? 14 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, Color activeColor, Color inactiveColor) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.1 : 1.0,
              child: Container(
                width: 32,
                height: 24,
                decoration: isSelected
                    ? BoxDecoration(
                        color: activeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 3),
              height: 2.5,
              width: isSelected ? 16 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isSelected
                    ? [BoxShadow(color: activeColor.withValues(alpha: 0.4), blurRadius: 3)]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(bool isLoggedIn, String? avatarUrl, bool isActive) {
    if (!isLoggedIn) {
      return Icon(Icons.person_rounded, color: isActive ? Colors.white : Colors.grey, size: 24);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: isActive ? Colors.white : Colors.grey, size: 24),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
        ),
      );
    }
    return Icon(Icons.person_rounded, color: isActive ? Colors.white : Colors.grey, size: 24);
  }
}
