import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Thanh Navigation Bar lơ lửng căn sát trái, mỏng gọn, chuẩn Vibe Web SportO:
/// - 4 tab điều hướng: Trang chủ (0), Giải đấu (1), Khám phá (3), Cá nhân (2)
/// - Căn sang bên trái (Alignment.bottomLeft), kích thước thu gọn thanh lịch
/// - Chiều cao hạ thấp (50px), phẳng phiu, loại bỏ hoàn toàn nút cong lồi ở giữa
/// - Màu sắc chuẩn Vibe Web SportO: Xanh Sport Blue (#1D8EF8) làm chủ đạo cho active & indicator
/// - Vạch gạch chân xanh Sport Blue trượt ngang mượt mà dưới chân icon active
/// - Hiệu ứng nảy micro-bounce êm ái khi chạm
class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onProfileTap,
  });

  static const int profileIndex = 2;

  /// Ánh xạ từ currentIndex của App sang 4 vị trí slot (0, 1, 2, 3)
  int _getSlotIndex(int index) {
    return switch (index) {
      0 => 0, // Trang chủ
      1 || 4 => 1, // Giải đấu (và BXH)
      3 => 2, // Khám phá / CLB
      profileIndex => 3, // Cá nhân
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotIndex = _getSlotIndex(currentIndex);

    // Màu sắc chuẩn Design Tokens Vibe Web SportO
    const activeColor = AppTheme.primary; // Xanh Sport Blue #1D8EF8
    final inactiveColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    final bgColor = isDark
        ? const Color(0xFF131B2A).withValues(alpha: 0.96)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.90);

    // Kích thước thanh nav gọn gàng căn sát trái
    const double barWidth = 252.0;
    const double barHeight = 50.0;
    const double slotWidth = barWidth / 4.0;
    final double indicatorLeft = (slotIndex * slotWidth) + (slotWidth - 22.0) / 2.0;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          margin: const EdgeInsets.only(left: 16, bottom: 14),
          width: barWidth,
          height: barHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Khối thanh nav lơ lửng phẳng phiu, bo tròn đều
              Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),

              // 2. Vạch gạch chân năng động màu Xanh Sport Blue (#1D8EF8) chuẩn Vibe Web
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: indicatorLeft,
                bottom: 6.0,
                child: Container(
                  width: 22.0,
                  height: 3.2,
                  decoration: BoxDecoration(
                    color: activeColor, // Xanh Sport Blue
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.60),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Hàng 4 Icon điều hướng phẳng phiu, đều đặn theo tone Web
              SizedBox(
                width: barWidth,
                height: barHeight,
                child: Row(
                  children: [
                    // Tab 1: Trang chủ (Index 0)
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        isSelected: slotIndex == 0,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onTabSelected(0),
                      ),
                    ),

                    // Tab 2: Giải đấu (Index 1)
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.emoji_events_outlined,
                        activeIcon: Icons.emoji_events_rounded,
                        isSelected: slotIndex == 1,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onTabSelected(1),
                      ),
                    ),

                    // Tab 3: Khám phá / CLB (Index 3)
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.explore_outlined,
                        activeIcon: Icons.explore_rounded,
                        isSelected: slotIndex == 2,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onTabSelected(3),
                      ),
                    ),

                    // Tab 4: Cá nhân (Index 2)
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        isSelected: slotIndex == 3,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: onProfileTap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}