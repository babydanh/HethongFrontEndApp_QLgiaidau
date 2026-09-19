import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Thanh Navigation Bar lơ lửng (Floating Pill) chuẩn phong cách hiện đại theo đúng logic 5 Tab sẵn có của App:
/// 1. Trang chủ (Index 0)
/// 2. Khám phá (Index 3)
/// 3. GIẢI ĐẤU (Index 1) - Nút tròn Cúp vàng nhô cao ở chính giữa ("nhô nhô" nổi bật)
/// 4. Bảng xếp hạng (Index 4)
/// 5. Cá nhân (Index 2 - onProfileTap)
///
/// Thiết kế:
/// - Thanh bar lơ lửng cách đáy màn hình với bóng đổ đa tầng sang trọng
/// - Vạch gạch chân năng động (Sliding Indicator) màu vàng thể thao trượt theo tab active
/// - Nút Giải đấu trung tâm nhô cao với viền trắng cắt góc sắc nét
/// - Hiệu ứng nảy "nhô nhô" micro-bounce mượt mà khi chạm
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

  /// Ánh xạ từ currentIndex của App sang vị trí cột (0, 1, 2, 3, 4)
  int _getSlotIndex(int index) {
    return switch (index) {
      0 => 0, // Trang chủ
      3 => 1, // Khám phá / CLB
      1 => 2, // Giải đấu (Nút giữa nhô cao)
      4 => 3, // Bảng xếp hạng
      profileIndex => 4, // Cá nhân
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotIndex = _getSlotIndex(currentIndex);
    final isTournamentSelected = currentIndex == 1;

    final bgColor = isDark
        ? const Color(0xFF131B2A).withValues(alpha: 0.96)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.85);

    final inactiveColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);
    final activeColor = isDark
        ? Colors.white
        : const Color(0xFF1E293B);

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth - 32.0; // Margin 16px mỗi bên
          final slotWidth = barWidth / 5.0;
          final indicatorLeft = (slotIndex * slotWidth) + (slotWidth - 22.0) / 2.0;

          return Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            height: 66,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Khối thanh nav lơ lửng (Floating Pill Background)
                Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(33),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.07),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // 2. Vạch gạch chân năng động trượt ngang (Sliding Indicator)
                // (Chỉ hiện khi chọn các tab ngoài, khi chọn tab Giải đấu thì nút giữa tự tỏa sáng nhô cao)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  bottom: 8.0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isTournamentSelected ? 0.0 : 1.0,
                    child: Container(
                      width: 22.0,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC700), // Vàng thể thao chuẩn mẫu ảnh
                        borderRadius: BorderRadius.circular(2.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC700).withValues(alpha: 0.55),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Hàng 5 Tab điều hướng theo đúng logic sẵn có
                SizedBox(
                  height: 66,
                  child: Row(
                    children: [
                      // Vị trí 0: Trang chủ (Index 0)
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

                      // Vị trí 1: Khám phá / CLB (Index 3)
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.explore_outlined,
                          activeIcon: Icons.explore_rounded,
                          isSelected: slotIndex == 1,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          onTap: () => onTabSelected(3),
                        ),
                      ),

                      // Vị trí 2: GIẢI ĐẤU (Index 1) - NÚT TRÒN CÚP VÀNG NHÔ CAO Ở CHÍNH GIỮA
                      SizedBox(
                        width: slotWidth,
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -14), // Nhô cao lên trên thanh bar
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                onTabSelected(1);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedScale(
                                scale: isTournamentSelected ? 1.14 : 1.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFD600), // Vàng sáng rực rỡ
                                        Color(0xFFFFB300), // Vàng cam thể thao
                                      ],
                                    ),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF131B2A) : Colors.white,
                                      width: 3.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFC700).withValues(
                                          alpha: isTournamentSelected ? 0.65 : 0.40,
                                        ),
                                        blurRadius: isTournamentSelected ? 18 : 12,
                                        spreadRadius: isTournamentSelected ? 2 : 1,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.emoji_events_rounded, // Biểu tượng Cúp giải đấu vàng
                                      color: Color(0xFF1E293B),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Vị trí 3: Bảng xếp hạng (Index 4)
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.leaderboard_outlined,
                          activeIcon: Icons.leaderboard_rounded,
                          isSelected: slotIndex == 3,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          onTap: () => onTabSelected(4),
                        ),
                      ),

                      // Vị trí 4: Cá nhân (Index 2)
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          isSelected: slotIndex == 4,
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
          );
        },
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
          scale: isSelected ? 1.15 : 1.0, // Hiệu ứng nảy nhô nhô nhẹ khi chọn
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}