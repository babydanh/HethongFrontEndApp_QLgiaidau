part of '../screens/club_detail_screen.dart';

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AppColorsExtension colors;
  final ValueChanged<String>? onMoreSelected;

  static const double _tabBarHeight = 44.0;

  _TabBarDelegate({
    required this.tabController,
    required this.colors,
    this.onMoreSelected,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      // color: colors.bgCard,
      height: _tabBarHeight,
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AnimatedBuilder(
          animation: tabController,
          builder: (context, _) {
            final activeIndex = tabController.index;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabItem(
                  index: 0,
                  label: l10n.clubDetailFeedTab,
                  isActive: activeIndex == 0,
                  colors: colors,
                ),
                const SizedBox(width: 14),
                _buildTabItem(
                  index: 1,
                  label: 'Thi đấu',
                  isActive: activeIndex == 1,
                  colors: colors,
                ),
                const SizedBox(width: 14),
                _buildTabItem(
                  index: 2,
                  label: l10n.club_tabMembers,
                  isActive: activeIndex == 2,
                  colors: colors,
                ),
                const SizedBox(width: 14),
                _buildMoreTabButton(context, colors, l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required bool isActive,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: () => tabController.animateTo(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: _tabBarHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? AppTheme.primary : const Color(0xFF64748B),
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: 2.5,
              width: 24.0,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreTabButton(
    BuildContext context,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      height: _tabBarHeight,
      child: PopupMenuButton<String>(
        tooltip: 'Xem thêm',
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        onSelected: onMoreSelected,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Xem thêm',
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 1),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'tourneys',
            height: 40,
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.club_tabTournaments,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'gallery',
            height: 40,
            child: Row(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: Color(0xFF0EA5E9),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.club_tabGallery,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => _tabBarHeight;

  @override
  double get minExtent => _tabBarHeight;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController ||
        oldDelegate.colors != colors;
  }
}

/// Chỉ khởi tạo tab nặng khi tab đó thực sự được chọn.
///
/// `TabBarView` vẫn cần một child cho từng trang để giữ layout, nhưng các
/// widget bên trong (socket, timer, ranking request) không nên chạy ngay khi
/// người dùng chỉ đang xem Bảng tin.
