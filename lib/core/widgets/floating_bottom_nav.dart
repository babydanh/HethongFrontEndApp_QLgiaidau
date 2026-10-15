import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/utils/best_ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';

class FloatingBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMenuTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onMenuTap,
  });

  static const int _menuIndex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    // Chỉ nghe hồ sơ khi đã đăng nhập: khách không phát sinh request /me.
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    final profile = isAuthenticated
        ? ref.watch(userProfileProvider.select((p) => p.asData?.value))
        : null;
    // Hạng nổi bật để tô viền avatar; chỉ nghe khi đã đăng nhập.
    final ranking = isAuthenticated
        ? ref.watch(
            userRankingsProvider.select(
              (r) => bestRankingOf(r.asData?.value ?? const <PlayerRanking>[]),
            ),
          )
        : null;
    final avatarUrl = profile?.avatarUrl;
    final fullName = profile?.fullName;
    final avatar = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? _NavAvatar(
            url: avatarUrl,
            name: (fullName != null && fullName.isNotEmpty)
                ? fullName
                : 'SportO',
            ranking: ranking,
          )
        : null;

    const activeColor = AppTheme.primary;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : const Color(0xFF64748B);
    final barColor = isDark ? context.colors.bgDark : Colors.white;
    final dividerColor = isDark
        ? context.colors.border
        : const Color(0xFFE2E8F0);

    final tabs = <_NavTabData>[
      _NavTabData(
        internalIndex: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.navHome,
      ),
      _NavTabData(
        internalIndex: 3,
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: l10n.navExplore,
      ),
      _NavTabData(
        internalIndex: 1,
        icon: Icons.emoji_events_outlined,
        activeIcon: Icons.emoji_events_rounded,
        label: l10n.navTournaments,
      ),
      _NavTabData(
        internalIndex: 4,
        icon: Icons.leaderboard_outlined,
        activeIcon: Icons.leaderboard_rounded,
        label: l10n.navRankings,
      ),
      _NavTabData(
        internalIndex: _menuIndex,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: l10n.navProfile,
      ),
    ];

    return ColoredBox(
      color: barColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: dividerColor, width: 1)),
            ),
            child: Row(
              children: [
                for (final tab in tabs)
                  Expanded(
                    child: _buildNavItem(
                      tab,
                      isSelected: currentIndex == tab.internalIndex,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      avatar: tab.internalIndex == _menuIndex ? avatar : null,
                      onTap: () => tab.internalIndex == _menuIndex
                          ? onMenuTap()
                          : onTabSelected(tab.internalIndex),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    _NavTabData tab, {
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
    _NavAvatar? avatar,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 26,
                  decoration: isSelected
                      ? BoxDecoration(
                          color: activeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                        )
                      : null,
                  child: avatar != null
                      ? _AvatarBadge(avatar: avatar)
                      : Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          color: isSelected ? activeColor : inactiveColor,
                          size: 22,
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dữ liệu avatar của người dùng hiện tại trên thanh điều hướng.
class _NavAvatar {
  final String url;
  final String name;
  final PlayerRanking? ranking;

  const _NavAvatar({required this.url, required this.name, this.ranking});
}

/// Avatar tròn 26px; viền và glow theo hạng ELO giống web (`RankAvatar.tsx`).
class _AvatarBadge extends StatelessWidget {
  final _NavAvatar avatar;

  const _AvatarBadge({required this.avatar});

  @override
  Widget build(BuildContext context) {
    final ranking = avatar.ranking;
    return Center(
      child: RankAvatar(
        imageUrl: avatar.url,
        name: avatar.name,
        elo: ranking?.eloPoints ?? 0,
        tierName: ranking?.tierName,
        matchesPlayed: ranking?.matchesPlayed ?? 0,
        size: 26,
        ringWidth: 2,
      ),
    );
  }
}

class _NavTabData {
  final int internalIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavTabData({
    required this.internalIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
