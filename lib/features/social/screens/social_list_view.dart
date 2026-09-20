import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/social/models/activity_feed_item.dart';
import 'package:app_quanly_giaidau/features/social/providers/social_provider.dart';
import 'package:app_quanly_giaidau/features/social/screens/activity_feed_detail_screen.dart';
import 'package:app_quanly_giaidau/features/social/widgets/activity_feed_card.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_date_selector.dart';

class SocialListView extends ConsumerWidget {
  final double topPadding;

  const SocialListView({super.key, this.topPadding = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(socialFilterProvider);
    final feed = ref.watch(activityFeedProvider);
    final activities = _filterActivities(feed.value ?? const [], filter);
    final grouped = <String, List<ActivityFeedItem>>{};
    for (final item in activities) {
      grouped
          .putIfAbsent(
            item.startTime.isEmpty ? '--:--' : item.startTime,
            () => [],
          )
          .add(item);
    }
    final times = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () => ref.read(activityFeedProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPadding)),
          const SliverToBoxAdapter(child: SocialDateSelector()),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          if (feed.isLoading && feed.value == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (feed.hasError && activities.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildError(
                context,
                feed.error,
                () => ref.read(activityFeedProvider.notifier).refresh(),
              ),
            )
          else if (activities.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty(context, filter.selectedDayOfMonth, isDark),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final time = times[index];
                final items = grouped[time]!;
                final collapsed = filter.collapsedTimeSlots.contains(time);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeSlotHeader(
                      timeSlot: time,
                      count: items.length,
                      isCollapsed: collapsed,
                      isDark: isDark,
                      onToggle: () => ref
                          .read(socialFilterProvider.notifier)
                          .toggleTimeSlotCollapse(time),
                    ),
                    if (!collapsed)
                      ...items.map(
                        (item) => ActivityFeedCard(
                          item: item,
                          onTap: () => _openActivity(context, item, ref),
                          onJoin: item.isJoined
                              ? null
                              : () async {
                                  await _join(context, ref, item);
                                },
                          onLeave: item.isJoined
                              ? () async {
                                  await _leave(context, ref, item);
                                }
                              : null,
                        ),
                      ),
                  ],
                );
              }, childCount: times.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  List<ActivityFeedItem> _filterActivities(
    List<ActivityFeedItem> items,
    SocialFilterState filter,
  ) {
    final sport = _normalize(filter.selectedSport);
    final query = filter.searchQuery.trim().toLowerCase();
    return items
        .where((item) {
          if (sport != 'all' &&
              !_normalize(item.sport).contains(sport) &&
              !sport.contains(_normalize(item.sport))) {
            return false;
          }
          if (query.isNotEmpty &&
              !'${item.title} ${item.hostName} ${item.location} ${item.sport}'
                  .toLowerCase()
                  .contains(query)) {
            return false;
          }
          return item.playDate.isEmpty ||
              item.playDate == filter.selectedDateKey;
        })
        .toList(growable: false);
  }

  String _normalize(String value) => value.trim().toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
    '',
  );

  Widget _buildEmpty(BuildContext context, int day, bool isDark) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.event_busy_rounded,
          size: 42,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(height: 12),
        Text(
          'Không có hoạt động ngày $day',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Thử chọn ngày khác hoặc bộ môn khác',
          style: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ),
      ],
    ),
  );

  Widget _buildError(BuildContext context, Object? _, VoidCallback onRetry) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.grey),
              const SizedBox(height: 10),
              const Text(
                'Không thể tải bảng tin lúc này',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      );

  Widget _buildTimeSlotHeader({
    required String timeSlot,
    required int count,
    required bool isCollapsed,
    required bool isDark,
    required VoidCallback onToggle,
  }) => InkWell(
    onTap: onToggle,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$timeSlot  |  $count hoạt động',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Icon(
            isCollapsed
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_up_rounded,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ],
      ),
    ),
  );

  Future<bool> _join(
    BuildContext context,
    WidgetRef ref,
    ActivityFeedItem item,
  ) async {
    try {
      await ref.read(activityFeedProvider.notifier).join(item);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã tham gia hoạt động')));
      }
      return true;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tham gia: $error')));
      }
      return false;
    }
  }

  Future<bool> _leave(
    BuildContext context,
    WidgetRef ref,
    ActivityFeedItem item,
  ) async {
    try {
      await ref.read(activityFeedProvider.notifier).leave(item);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã rút khỏi hoạt động')));
      }
      return true;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể rút slot: $error')));
      }
      return false;
    }
  }

  void _openActivity(
    BuildContext context,
    ActivityFeedItem item,
    WidgetRef ref,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityFeedDetailScreen(
          item: item,
          onJoin: () async {
            if (await _join(context, ref, item) && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          onLeave: () async {
            if (await _leave(context, ref, item) && context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
