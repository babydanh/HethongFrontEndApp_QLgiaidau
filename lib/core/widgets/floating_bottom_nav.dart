import 'package:flutter/material.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        label: 'Trang chủ',
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
        label: 'Giải đấu',
      ),
      _NavTabData(
        internalIndex: 4,
        icon: Icons.leaderboard_outlined,
        activeIcon: Icons.leaderboard_rounded,
        label: 'Xếp hạng',
      ),
      _NavTabData(
        internalIndex: _menuIndex,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Tôi',
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
