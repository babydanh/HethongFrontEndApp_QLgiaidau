import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class FloatingBottomNav extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const activeColor = AppTheme.primary;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF94A3B8);
    final bgColor = isDark
        ? const Color(0xFF0A0A0A).withValues(alpha: 0.98)
        : Colors.white;
    final borderSide = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

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
        label: 'Khám phá',
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
        icon: Icons.menu_rounded,
        activeIcon: Icons.menu_open_rounded,
        label: l10n.menuTitle,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderSide)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (final tab in tabs)
                Expanded(
                  child: _buildNavItem(
                    tab,
                    isSelected: currentIndex == tab.internalIndex,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    onTap: () => tab.internalIndex == _menuIndex
                        ? onMenuTap()
                        : onTabSelected(tab.internalIndex),
                  ),
                ),
            ],
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
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
              child: Icon(
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
