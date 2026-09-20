import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/club_network_image.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/public_tournament_type_sheet.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

/// Thanh Navigation Bar lơ lửng căn sát trái + Khối Tiện ích đứng riêng bên phải:
/// - Bên trái: 4 tab điều hướng chính (Trang chủ 0, Giải đấu 1, Khám phá 3, Tin nhắn 2)
///   Active Indicator dẹp phong cách web hover nhạt với bo tròn mượt mà, icon active tông màu chủ đạo.
/// - Bên phải: Thanh tiện ích đứng riêng biệt.
///   Khi bung mở popover:
///     + Header là Hồ sơ cá nhân (Avatar, Tên, nút xem trang cá nhân).
///     + Phía dưới là các trang điều hướng mở rộng (Bảng xếp hạng, Giải đấu của tôi, v.v.) và thao tác nhanh.
///     + Hiệu ứng hover viền/nền full màu thanh nhạt tinh tế theo vibe web.
class FloatingBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onProfileTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onUtilityTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onProfileTap,
    this.onChatTap,
    this.onUtilityTap,
  });

  static const int chatIndex = 2; // Hộp thư / Chat
  static const int profileIndex = 2; // backward compatibility

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
      1 => 1, // Giải đấu
      3 => 2, // Khám phá / CLB
      2 => 3, // Chat / Hộp thư
      _ => -1, // Nếu ở 4 (BXH) hoặc màn hình phụ, không active 4 slot chính
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
    final double popupBottom = 12.0 + safeAreaBottom + 48.0; // Ngay trên đỉnh nút tiện ích
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
                      activeNavIndex: widget.currentIndex,
                      onNavigate: (index) {
                        Navigator.of(ctx).pop();
                        widget.onTabSelected(index);
                      },
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
      case _UtilityActionType.profile:
        context.push('/profile');
        break;
      case _UtilityActionType.rankings:
        widget.onTabSelected(4);
        break;
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

    // Tone màu chuẩn vibe Web SportO:
    // Nền hover/active 1 cục màu xanh nhạt nguyên khối tinh tế (không viền đậm)
    final activeFillColor = isDark
        ? AppTheme.primary.withValues(alpha: 0.22)
        : const Color(0xFFEFF6FF); // Xanh nhạt tinh tế kiểu web (blue-50/blue-100)

    // Icon khi active: màu xanh Sport Blue đặc trưng của web
    final activeIconColor = AppTheme.primary;

    final inactiveColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B); // Xám đồng bộ chuẩn

    final bgColor = isDark
        ? const Color(0xFF131B2A).withValues(alpha: 0.96)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.90);

    // Kích thước thanh nav chính dẹt và gọn theo vibe web
    const double barWidth = 252.0;
    const double barHeight = 44.0;
    const double slotWidth = barWidth / 4.0;

    // Kích thước vạch indicator dẹt kiểu web hover full lọt lòng slot (1 khối nhạt, không viền)
    const double indicatorHorizontalPadding = 4.0;
    const double indicatorVerticalPadding = 4.0;
    const double indicatorWidth = slotWidth - (indicatorHorizontalPadding * 2);
    const double indicatorHeight = barHeight - (indicatorVerticalPadding * 2);

    final bool hasSelectedSlot = slotIndex >= 0 && slotIndex < 4;
    final double indicatorLeft = hasSelectedSlot
        ? (slotIndex * slotWidth) + indicatorHorizontalPadding
        : indicatorHorizontalPadding;
    const double indicatorTop = indicatorVerticalPadding;

    // Kiểm tra xem tiện ích có đang chứa mục được chọn không (ví dụ BXH: tab 4)
    final bool isUtilityActive = widget.currentIndex == 4 || _isPopoverOpen;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
                      borderRadius: BorderRadius.circular(barHeight / 2),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 14,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.08 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  // Thanh Indicator hover full 1 cục màu nhạt (không viền đậm) trượt mượt mà
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    left: indicatorLeft,
                    top: indicatorTop,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: hasSelectedSlot ? 1.0 : 0.0,
                      child: Container(
                        width: indicatorWidth,
                        height: indicatorHeight,
                        decoration: BoxDecoration(
                          color: activeFillColor,
                          borderRadius: BorderRadius.circular(indicatorHeight / 2),
                          // Không viền đậm, 1 khối màu nhạt mềm mại
                        ),
                      ),
                    ),
                  ),

                  // Hàng 4 Icon điều hướng (nằm trên indicator để nhận tap mượt mà)
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
                            isSelected: hasSelectedSlot && slotIndex == 0,
                            activeColor: activeIconColor,
                            inactiveColor: inactiveColor,
                            onTap: () => widget.onTabSelected(0),
                          ),
                        ),

                        // Tab 2: Giải đấu (Index 1)
                        Expanded(
                          child: _buildNavItem(
                            icon: Icons.emoji_events_outlined,
                            activeIcon: Icons.emoji_events_rounded,
                            isSelected: hasSelectedSlot && slotIndex == 1,
                            activeColor: activeIconColor,
                            inactiveColor: inactiveColor,
                            onTap: () => widget.onTabSelected(1),
                          ),
                        ),

                        // Tab 3: Khám phá / CLB (Index 3)
                        Expanded(
                          child: _buildNavItem(
                            icon: Icons.explore_outlined,
                            activeIcon: Icons.explore_rounded,
                            isSelected: hasSelectedSlot && slotIndex == 2,
                            activeColor: activeIconColor,
                            inactiveColor: inactiveColor,
                            onTap: () => widget.onTabSelected(3),
                          ),
                        ),

                        // Tab 4: Chat / Hộp thư (Index 2)
                        Expanded(
                          child: _buildNavItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            activeIcon: Icons.chat_bubble_rounded,
                            isSelected: hasSelectedSlot && slotIndex == 3,
                            activeColor: activeIconColor,
                            inactiveColor: inactiveColor,
                            onTap: () {
                              if (widget.onChatTap != null) {
                                widget.onChatTap!();
                              } else {
                                widget.onTabSelected(2);
                              }
                            },
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
              bgColor: isUtilityActive ? activeFillColor : bgColor,
              borderColor: borderColor,
              activeColor: activeIconColor,
              inactiveColor: inactiveColor,
              isActive: isUtilityActive,
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
    required bool isActive,
  }) {
    // Icon khi active là màu đen (dark: trắng), bình thường là xám
    final iconColor = isActive ? activeColor : inactiveColor;

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
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 14,
                spreadRadius: 0.5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: AnimatedRotation(
              turns: _isPopoverOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                isActive ? Icons.widgets_rounded : Icons.unfold_more_rounded,
                color: iconColor,
                size: 20,
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
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 21,
          ),
        ),
      ),
    );
  }
}

enum _UtilityActionType {
  profile,
  rankings,
  createTournament,
  createClub,
  exploreTournaments,
  scrollToTop,
  refresh,
}

/// Khối Card Popover Tiện ích nổi bật:
/// - Header: Hồ sơ cá nhân (Avatar, Tên người dùng, Link xem trang cá nhân)
/// - Thân: Các trang điều hướng bổ sung & Thao tác tiện ích, hover phong cách web full màu nhạt
class _QuickUtilityPopoverCard extends ConsumerWidget {
  final bool isDark;
  final int activeNavIndex;
  final ValueChanged<int> onNavigate;
  final ValueChanged<_UtilityActionType> onActionSelected;

  const _QuickUtilityPopoverCard({
    required this.isDark,
    required this.activeNavIndex,
    required this.onNavigate,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.98)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);

    final userAsync = ref.watch(userProfileProvider);
    final userProfile = userAsync.asData?.value;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
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
          // ─── 1. Header Hồ sơ cá nhân ───
          _buildProfileHeader(context, userProfile),

          // Đường ngăn cách mảnh nhẹ
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
          ),

          const SizedBox(height: 4),

          // ─── 2. Danh sách trang điều hướng & Tiện ích nhanh ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tab Bảng xếp hạng (Nav mở rộng quan trọng: tab 4)
                _buildItem(
                  icon: Icons.leaderboard_rounded,
                  title: 'Bảng xếp hạng',
                  isSelected: activeNavIndex == 4,
                  onTap: () => onActionSelected(_UtilityActionType.rankings),
                ),
                _buildItem(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Tạo giải đấu',
                  onTap: () => onActionSelected(_UtilityActionType.createTournament),
                ),
                _buildItem(
                  icon: Icons.shield_outlined,
                  title: 'Tạo câu lạc bộ',
                  onTap: () => onActionSelected(_UtilityActionType.createClub),
                ),
                _buildItem(
                  icon: Icons.search_rounded,
                  title: 'Tìm giải & CLB',
                  isSelected: activeNavIndex == 1,
                  onTap: () => onActionSelected(_UtilityActionType.exploreTournaments),
                ),
                Divider(
                  height: 9,
                  thickness: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                ),
                _buildItem(
                  icon: Icons.arrow_upward_rounded,
                  title: 'Lên đầu trang',
                  onTap: () => onActionSelected(_UtilityActionType.scrollToTop),
                ),
                _buildItem(
                  icon: Icons.refresh_rounded,
                  title: 'Làm mới dữ liệu',
                  onTap: () => onActionSelected(_UtilityActionType.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  /// Khối Header Hồ sơ trên cùng của Menu Tiện ích
  Widget _buildProfileHeader(BuildContext context, dynamic profile) {
    final avatarUrl = profile?.avatarUrl as String?;
    final fullName = (profile?.fullName as String?)?.trim();
    final displayName = (fullName != null && fullName.isNotEmpty) ? fullName : 'Tài khoản của tôi';
    final role = (profile?.role as String?)?.toUpperCase() ?? 'THÀNH VIÊN';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onActionSelected(_UtilityActionType.profile);
        },
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              // Avatar tròn
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? ClubNetworkImage(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarFallback(),
                        )
                      : _buildAvatarFallback(),
                ),
              ),
              const SizedBox(width: 10),

              // Tên & Nhãn vai trò
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Row(
                      children: [
                        Text(
                          role == 'ORGANIZER' ? 'Ban tổ chức' : (role == 'ADMIN' ? 'Quản trị viên' : 'Hồ sơ cá nhân'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mũi tên dẫn sang profile
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: 20,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final itemTextColor = isSelected
        ? AppTheme.primary
        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B));
    final itemIconColor = isSelected
        ? AppTheme.primary
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final itemBgColor = isSelected
        ? (isDark
            ? AppTheme.primary.withValues(alpha: 0.18)
            : AppTheme.primary.withValues(alpha: 0.10))
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppTheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
        splashColor: AppTheme.primary.withValues(alpha: 0.12),
        highlightColor: AppTheme.primary.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            color: itemBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: itemIconColor,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: itemTextColor,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}