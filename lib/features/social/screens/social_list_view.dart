import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/features/social/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/providers/social_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_date_selector.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_session_card.dart';

class SocialListView extends ConsumerWidget {
  final double topPadding;

  const SocialListView({super.key, this.topPadding = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterState = ref.watch(socialFilterProvider);
    final filteredSessions = ref.watch(filteredSocialSessionsProvider);

    // Group filtered sessions by timeSlot
    final Map<String, List<SocialSessionModel>> groupedSessions = {};
    for (final session in filteredSessions) {
      groupedSessions.putIfAbsent(session.timeSlot, () => []).add(session);
    }
    final sortedTimeSlots = groupedSessions.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async {
        // Re-fetch or reset mock filter
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Offset for top header
          SliverToBoxAdapter(
            child: SizedBox(height: topPadding),
          ),

          // Horizontal Date Selector (IMG1)
          const SliverToBoxAdapter(
            child: SocialDateSelector(),
          ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 6),
              ),

              // Empty State or Grouped Sessions
              if (filteredSessions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.04),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sports_tennis_rounded,
                            size: 32,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không có buổi Social nào trong ngày ${filterState.selectedDayOfMonth}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Thử chọn ngày khác hoặc mở rộng bán kính tìm kiếm',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final timeSlot = sortedTimeSlots[index];
                      final sessionsInSlot = groupedSessions[timeSlot]!;
                      final isCollapsed =
                          filterState.collapsedTimeSlots.contains(timeSlot);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Slot Group Header (e.g. 14:45 | 1 gặp gỡ ∨)
                          _buildTimeSlotHeader(
                            timeSlot: timeSlot,
                            count: sessionsInSlot.length,
                            isCollapsed: isCollapsed,
                            isDark: isDark,
                            onToggle: () {
                              ref
                                  .read(socialFilterProvider.notifier)
                                  .toggleTimeSlotCollapse(timeSlot);
                            },
                          ),

                          // Cards in this slot
                          if (!isCollapsed)
                            ...sessionsInSlot.map(
                              (session) => SocialSessionCard(
                                session: session,
                                onTap: () =>
                                    _openSessionDetail(context, session.id),
                              ),
                            ),
                        ],
                      );
                    },
                    childCount: sortedTimeSlots.length,
                  ),
                ),

              // Bottom spacing for bottom nav
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        );
      }


  Widget _buildTimeSlotHeader({
    required String timeSlot,
    required int count,
    required bool isCollapsed,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : const Color(0xFFF8FAFC),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  timeSlot,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '| $count gặp gỡ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openSessionDetail(BuildContext context, String sessionId) {
    context.push('/social/$sessionId');
  }
}
