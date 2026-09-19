import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Thanh Navigation Bar lơ lửng (Floating Pill) chuẩn phong cách hiện đại:
/// - Nổi bồng bềnh cách đáy màn hình với bóng đổ đa tầng sang trọng
/// - Vạch gạch chân năng động (Sliding Indicator) màu vàng thể thao trượt theo tab active
/// - Nút (+) trung tâm nhô cao màu vàng rực rỡ với viền trắng tương phản sắc nét
/// - Popup Action Sheet nhô lên (bouncy spring animation) với các phím tắt: Quét QR, Tạo giải, Tạo CLB
class FloatingBottomNav extends StatefulWidget {
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

  @override
  State<FloatingBottomNav> createState() => _FloatingBottomNavState();
}

class _FloatingBottomNavState extends State<FloatingBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _plusController;
  late Animation<double> _plusRotation;

  @override
  void initState() {
    super.initState();
    _plusController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _plusRotation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _plusController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _plusController.dispose();
    super.dispose();
  }

  /// Ánh xạ từ currentIndex của App sang vị trí cột (0, 1, 3, 4)
  int _getSlotIndex(int index) {
    return switch (index) {
      0 => 0, // Home
      1 || 4 => 1, // Giải đấu (và BXH)
      3 => 3, // Cộng đồng / CLB / Chat
      FloatingBottomNav.profileIndex => 4, // Profile
      _ => 0,
    };
  }

  /// Hiển thị Popup Action Menu nhô nhô lên với animation nảy nhẹ nhàng
  void _showQuickActionSheet() {
    HapticFeedback.mediumImpact();
    _plusController.forward();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isScrollControlled: true,
      builder: (ctx) => _QuickActionPopup(
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    ).whenComplete(() {
      if (mounted) {
        _plusController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotIndex = _getSlotIndex(widget.currentIndex);

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
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  bottom: 8.0,
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

                // 3. Hàng các Icon điều hướng (Row 5 mục)
                SizedBox(
                  height: 66,
                  child: Row(
                    children: [
                      // Vị trí 0: Trang chủ (Home)
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          isSelected: slotIndex == 0,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          onTap: () => widget.onTabSelected(0),
                        ),
                      ),

                      // Vị trí 1: Giải đấu (Tournaments)
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.sports_tennis_outlined,
                          activeIcon: Icons.sports_tennis_rounded,
                          isSelected: slotIndex == 1,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          onTap: () => widget.onTabSelected(1),
                        ),
                      ),

                      // Vị trí 2: NÚT TRUNG TÂM (+) NHÔ CAO MÀU VÀNG
                      SizedBox(
                        width: slotWidth,
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -14), // Nhô cao lên trên thanh bar
                            child: GestureDetector(
                              onTap: _showQuickActionSheet,
                              behavior: HitTestBehavior.opaque,
                              child: RotationTransition(
                                turns: _plusRotation,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFD600), // Vàng sáng
                                        Color(0xFFFFB300), // Vàng cam ấm
                                      ],
                                    ),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF131B2A) : Colors.white,
                                      width: 3.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFC700).withValues(alpha: 0.50),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFF1E293B),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Vị trí 3: Cộng đồng / Tin nhắn (Social & Clubs)
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          activeIcon: Icons.chat_bubble_rounded,
                          isSelected: slotIndex == 3,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          onTap: () => widget.onTabSelected(3),
                        ),
                      ),

                      // Vị trí 4: Cá nhân (Profile)
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          isSelected: slotIndex == 4,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          onTap: widget.onProfileTap,
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
          scale: isSelected ? 1.12 : 1.0,
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

/// Popup Action Menu nhô nhô lên khi nhấn nút (+) trung tâm
class _QuickActionPopup extends StatelessWidget {
  final VoidCallback onDismiss;

  const _QuickActionPopup({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A2234) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.15),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo nhẹ ở đỉnh
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề popup với badge vàng
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC700).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'TẠO MỚI & THAO TÁC',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Tạo giải đấu mới
              _buildActionTile(
                context,
                icon: Icons.emoji_events_rounded,
                iconBgGradient: const LinearGradient(
                  colors: [Color(0xFF1D8EF8), Color(0xFF3AB5F6)],
                ),
                title: 'Tạo giải đấu mới',
                subtitle: 'Thiết lập bảng đấu, thể thức và điều lệ giải',
                onTap: () {
                  onDismiss();
                  context.push('/tournament/create');
                },
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // 2. Quét mã QR check-in
              _buildActionTile(
                context,
                icon: Icons.qr_code_scanner_rounded,
                iconBgGradient: const LinearGradient(
                  colors: [Color(0xFFFFC700), Color(0xFFFF9800)],
                ),
                title: 'Quét mã QR',
                subtitle: 'Check-in nhanh vận động viên & trọng tài',
                onTap: () {
                  onDismiss();
                  context.push('/scan-qr');
                },
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // 3. Tạo câu lạc bộ mới
              _buildActionTile(
                context,
                icon: Icons.groups_rounded,
                iconBgGradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                ),
                title: 'Tạo câu lạc bộ',
                subtitle: 'Xây dựng và gắn kết cộng đồng người chơi',
                onTap: () {
                  onDismiss();
                  context.push('/club/create');
                },
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required LinearGradient iconBgGradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: iconBgGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: iconBgGradient.colors.first.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}