import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// 44 dp tab strip shared by the tournament intro and management hub.
///
/// Rendered only through [TournamentTabBarDelegate], which pins it as a
/// `SliverPersistentHeader`; the strip itself has no app-bar role.
class TournamentTabStrip extends StatelessWidget {
  static const double tabBarHeight = 44.0;

  final TabController tabController;
  final List<Widget> tabHeaders;
  final AppColorsExtension colors;

  const TournamentTabStrip({
    super.key,
    required this.tabController,
    required this.tabHeaders,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: tabBarHeight,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.primary, width: 2.5),
          insets: EdgeInsets.only(bottom: 0),
        ),
        dividerColor: Colors.transparent,
        labelColor: AppTheme.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: tabHeaders,
      ),
    );
  }
}

/// Pinned [SliverPersistentHeaderDelegate] wrapper around [TournamentTabStrip].
class TournamentTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<Widget> tabHeaders;
  final AppColorsExtension colors;

  const TournamentTabBarDelegate({
    required this.tabController,
    required this.tabHeaders,
    required this.colors,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return TournamentTabStrip(
      tabController: tabController,
      tabHeaders: tabHeaders,
      colors: colors,
    );
  }

  @override
  double get maxExtent => TournamentTabStrip.tabBarHeight;

  @override
  double get minExtent => TournamentTabStrip.tabBarHeight;

  @override
  bool shouldRebuild(TournamentTabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController ||
        oldDelegate.tabHeaders != tabHeaders ||
        oldDelegate.colors != colors;
  }
}
