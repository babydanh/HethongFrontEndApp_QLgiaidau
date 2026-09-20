import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/public_tournament_type_sheet.dart';

/// Thanh Navigation Bar lơ lửng căn sát trái + Khối Tiện ích đứng riêng bên phải:
/// - Bên trái: 4 tab điều hướng chính (Trang chủ 0, Giải đấu 1, Khám phá 3, Cá nhân 2)
///   Chiều cao 50px, rộng 252px, bo tròn 25px, vạch xanh Sport Blue trượt ngang.
/// - Bên phải: Thanh tiện ích đứng riêng biệt (chiều cao 50px, rộng 50px, bo tròn 25px)
///   với icon mũi tên lên xuống màu xám đồng bộ (Icons.unfold_more_rounded).
///   Khi nhấn: Bung mở Popup Menu tiện ích (Popover) ngay tại vị trí nút với hiệu ứng
///   spring-bounce chuẩn skills.md (Tạo giải, Tạo CLB, Lên đầu trang, Làm mới...).
class FloatingBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;
  final VoidCallback? onUtilityTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onProfileTap,
    this.onUtilityTap,
  });

  static const int profileIndex = 2;

  @override
  State<FloatingBottomNav> createState() => _FloatingBottomNavState();
}

class _FloatingBottomNavState extends State<FloatingBottomNav> {
  bool _isUtilityPressed = false;
  bool _isPopoverOpen = false;

  /// Ánh xạ từ currentIndex của App sang 4 vị trí slot (0, 1, 2, 3)
  int _getSlotIndex(int index) {
    return switch (index) {
      0 => 0, // Trang chủ
      1 || 4 => 1, // Giải đấu (và BXH)
      3 => 2, // Khám phá / CLB
      FloatingBottomNav.profileIndex => 3, // Cá nhân
      _ => 0,
    };
  }

  void _handleUtilityTap(BuildContext context) {
    HapticFeedback.selectionClick();
    if (widget.onUtilityTap != null) {
      widget.onUtilityTap!();
      return;
    }
    _showAnchorPopover(context);
  }

  /// Hiển thị Popup menu tiện ích bung nở ngay tại vị trí nút bên phải
  void _showAnchorPopover(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeAreaBottom = media.padding.bottom;
    final double popupBottom = 14.0 + safeAreaBottom + 58.0; // Ngay trên đỉnh nút tiện ích
    const double popupRight = 16.0;

    setState(() => _isPopoverOpen = true);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Utilities',
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        return Stack(
          children: [
            Positioned(
              right: popupRight,
              bottom: popupBottom,
              child: Material(
                type: MaterialType.transparency,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.70, end: 1.0).animate(curved),
                  alignment: Alignment.bottomRight, // Bung nở từ góc phải nút tiện ích
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
                    child: _QuickUtilityPopoverCard(
                      isDark: isDark,
                      onActionSelected: (actionType) {
                        Navigator.of(ctx).pop();
                        _executeUtilityAction(context, actionType);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) setState(() => _isPopoverOpen = false);
    });
  }

  void _executeUtilityAction(BuildContext context, _UtilityActionType type) {
    switch (type) {
      case _UtilityActionType.createTournament:
        showPublicTournamentTypeSheet(context);
        break;
      case _UtilityActionType.createClub:
        context.push('/club/create');
        break;
      case _UtilityActionType.exploreTournaments:
        widget.onTabSelected(1);
        break;
      case _UtilityActionType.scrollToTop:
        final primary = PrimaryScrollController.maybeOf(context);
        if (primary != null && primary.hasClients) {
          primary.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
        break;
      case _UtilityActionType.refresh:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotIndex = _getSlotIndex(widget.currentIndex);

    // Màu sắc chuẩn Design Tokens Vibe Web SportO
    const activeColor = AppTheme.primary; // Xanh Sport Blue #1D8EF8
    final inactiveColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8); // Xám đồng bộ chuẩn

    final bgColor = isDark
        ? const Color(0xFF131B2A).withValues(alpha: 0.96)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.90);

    // Kích thước thanh nav chính căn sát trái
    const double barWidth = 252.0;
    const double barHeight = 50.0;
    const double slotWidth = barWidth / 4.0;
    final double indicatorLeft =
        (slotIndex * slotWidth) + (slotWidth - 22.0) / 2.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ─── 1. Khối thanh điều hướng 4 tab chính bên trái ───
            SizedBox(
              width: barWidth,
              height: barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Khối thanh nav lơ lửng phẳng phiu, bo tròn đều
                  Container(
                    width: barWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppTheme.primary.withValues(
                            alpha: isDark ? 0.08 : 0.05,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  // Vạch gạch chân năng động màu Xanh Sport Blue (#1D8EF8)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: indicatorLeft,
                    bottom: 6.0,
                    child: Container(
                      width: 22.0,
                      height: 3.2,
                      decoration: BoxDecoration(
                        color: activeColor,
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

                  // Hàng 4 Icon điều hướng phẳng phiu
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
                            onTap: () => widget.onTabSelected(0),
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
                            onTap: () => widget.onTabSelected(1),
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
                            onTap: () => widget.onTabSelected(3),
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
                            onTap: widget.onProfileTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── 2. Khối Nav Tiện ích đứng riêng biệt bên phải ───
            _buildUtilityNav(
              context,
              isDark: isDark,
              bgColor: bgColor,
              borderColor: borderColor,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityNav(
    BuildContext context, {
    required bool isDark,
    required Color bgColor,
    required Color borderColor,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    // Icon xám cùng tông với các icon khác (khi mở popover thì active màu Sport Blue)
    final iconColor = _isPopoverOpen ? activeColor : inactiveColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isUtilityPressed = true),
      onTapUp: (_) => setState(() => _isUtilityPressed = false),
      onTapCancel: () => setState(() => _isUtilityPressed = false),
      onTap: () => _handleUtilityTap(context),
      child: AnimatedScale(
        scale: _isUtilityPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 50.0,
          height: 50.0,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _isPopoverOpen ? activeColor.withValues(alpha: 0.5) : borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              if (_isPopoverOpen)
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: AnimatedRotation(
              turns: _isPopoverOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                Icons.unfold_more_rounded,
                color: iconColor, // Màu xám đồng nhất
                size: 24,
              ),
            ),
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

enum _UtilityActionType {
  createTournament,
  createClub,
  exploreTournaments,
  scrollToTop,
  refresh,
}

/// Khối Card Popover Tiện ích nổi bật, hiển thị danh sách thao tác nhanh
class _QuickUtilityPopoverCard extends StatelessWidget {
  final bool isDark;
  final ValueChanged<_UtilityActionType> onActionSelected;

  const _QuickUtilityPopoverCard({
    required this.isDark,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.98)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);

    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.10 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildItem(
            title: 'Tạo giải đấu',
            onTap: () => onActionSelected(_UtilityActionType.createTournament),
          ),
          _buildItem(
            title: 'Tạo câu lạc bộ',
            onTap: () => onActionSelected(_UtilityActionType.createClub),
          ),
          _buildItem(
            title: 'Tìm giải đấu & CLB',
            onTap: () => onActionSelected(_UtilityActionType.exploreTournaments),
          ),
          _buildItem(
            title: 'Lên đầu trang',
            onTap: () => onActionSelected(_UtilityActionType.scrollToTop),
          ),
          _buildItem(
            title: 'Làm mới dữ liệu',
            onTap: () => onActionSelected(_UtilityActionType.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}