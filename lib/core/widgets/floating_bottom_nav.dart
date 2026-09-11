import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/core/utils/rank_tier_colors.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';



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
    final l10n = AppLocalizations.of(context)!;
    final isLoggedIn = ref.watch(authProvider).isAuthenticated;
    final userProfileAsync = ref.watch(userProfileProvider);
    final avatarUrl = userProfileAsync.asData?.value.avatarUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankings = ref.watch(userRankingsProvider).asData?.value ?? const [];
    final playedRankings = rankings.where((r) => r.matchesPlayed > 0).toList()
      ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));
    final bestRanking = playedRankings.isEmpty ? null : playedRankings.first;
    final tierColor = RankTierColors.isRanked(bestRanking?.tierName, matchesPlayed: bestRanking?.matchesPlayed)
        ? RankTierColors.fromTierName(bestRanking?.tierName)
        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0));
    final colors = context.colors;
    const activeColor = AppTheme.primary;
    final inactiveColor = isDark ? colors.textMuted : const Color(0xFF94A3B8);
    final borderSide = colors.border;
    final navBgColor = colors.bgCard;

    return Container(
      decoration: BoxDecoration(
        color: navBgColor,
        border: Border(
          top: BorderSide(color: borderSide, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.explore_outlined, Icons.explore_rounded, l10n.navExplore, activeColor, inactiveColor),
              _buildNavItem(1, Icons.emoji_events_outlined, Icons.emoji_events_rounded, l10n.navTournaments, activeColor, inactiveColor),
              _buildCenterAvatarItem(isLoggedIn, avatarUrl, tierColor, isDark),
              _buildNavItem(3, Icons.people_outline_rounded, Icons.people_rounded, l10n.navClubs, activeColor, inactiveColor),
              _buildNavItem(4, Icons.leaderboard_outlined, Icons.leaderboard_rounded, l10n.navRankings, activeColor, inactiveColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAvatarItem(bool isLoggedIn, String? avatarUrl, Color tierColor, bool isDark) {
    final isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: onProfileTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.08 : 1.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : tierColor,
                    width: 2,
                  ),
                ),
                child: _buildAvatarContent(isLoggedIn, avatarUrl, isSelected),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tôi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : (isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF94A3B8)),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 2),
              height: 2.5,
              width: isSelected ? 16 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, Color activeColor, Color inactiveColor) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        padding: const EdgeInsets.only(top: 6),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 2),
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
          errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, color: isActive ? Colors.white : Colors.grey, size: 24),
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
