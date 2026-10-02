import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_date_selector.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_nearby_filter.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_session_card.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class SocialListView extends ConsumerStatefulWidget {
  final double topPadding;

  const SocialListView({super.key, this.topPadding = 0});

  @override
  ConsumerState<SocialListView> createState() => _SocialListViewState();
}

class _SocialListViewState extends ConsumerState<SocialListView> {
  @override
  void initState() {
    super.initState();
    // Xin quyền vị trí khi user vào tab Social (đúng lúc cần).
    // Chỉ tự hỏi lần đầu (initial); các lần sau user chủ động qua toggle/banner
    // để tránh nag dialog khi chuyển tab. Đã granted thì refresh im lặng.
    Future.microtask(() {
      final status = ref.read(userLocationProvider).status;
      if (status == UserLocationStatus.initial) {
        ref.read(userLocationProvider.notifier).requestWhenInUse();
      } else if (status == UserLocationStatus.granted) {
        ref.read(userLocationProvider.notifier).refreshSilently();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterState = ref.watch(socialFilterProvider);
    final locationState = ref.watch(userLocationProvider);
    final sessionsAsync = ref.watch(filteredSocialSessionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(socialSessionsProvider.notifier).refresh();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Offset for top header
          SliverToBoxAdapter(child: SizedBox(height: widget.topPadding)),

          // Nearby is future-based and is not constrained by the date picker.
          if (!filterState.nearbyOnly)
            const SliverToBoxAdapter(child: SocialDateSelector()),

          // Toggle "Gần bạn" + chips bán kính + banner quyền vị trí
          const SliverToBoxAdapter(child: SocialNearbyFilter()),

          const SliverToBoxAdapter(child: SizedBox(height: 6)),

          // Content according to AsyncValue
          ...sessionsAsync.when(
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(socialSessionsProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            data: (sessions) {
              if (sessions.isEmpty) {
                final nearbyNotifier = ref.read(
                  socialSessionsProvider.notifier,
                );
                if (filterState.nearbyOnly && nearbyNotifier.hasMoreNearby) {
                  return [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('Chưa có kết quả trong trang này.'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildNearbyPagination(nearbyNotifier),
                    ),
                  ];
                }
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                              filterState.nearbyOnly &&
                                      locationState.hasPosition
                                  ? l10n.socialNearbyNoResults
                                  : 'Không có buổi Social nào trong ngày ${filterState.selectedDate.day}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              filterState.nearbyOnly &&
                                      locationState.hasPosition
                                  ? l10n.socialNearbyExpandRadius
                                  : 'Thử chọn ngày khác hoặc tìm kiếm môn thể thao khác',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              }

              if (filterState.nearbyOnly) {
                return [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SocialSessionCard(
                        session: sessions[index],
                        onTap: () =>
                            _openSessionDetail(context, sessions[index].id),
                      ),
                      childCount: sessions.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildNearbyPagination(
                      ref.read(socialSessionsProvider.notifier),
                    ),
                  ),
                ];
              }

              // Regular list mode keeps the existing time-slot grouping.
              final Map<String, List<SocialSessionModel>> groupedSessions = {};
              for (final session in sessions) {
                groupedSessions
                    .putIfAbsent(session.timeSlot, () => [])
                    .add(session);
              }
              final sortedTimeSlots = groupedSessions.keys.toList()..sort();

              return [
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final timeSlot = sortedTimeSlots[index];
                    final sessionsInSlot = groupedSessions[timeSlot]!;
                    final isCollapsed = filterState.collapsedTimeSlots.contains(
                      timeSlot,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time Slot Group Header
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
                  }, childCount: sortedTimeSlots.length),
                ),
              ];
            },
          ),

          // Bottom spacing for bottom nav
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildNearbyPagination(SocialSessionsNotifier notifier) {
    if (!notifier.hasMoreNearby && notifier.loadMoreError == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Center(
        child: notifier.isLoadingMore
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (notifier.loadMoreError != null)
                    Text(notifier.loadMoreError!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: notifier.loadMoreNearby,
                    child: Text(
                      notifier.loadMoreError == null
                          ? AppLocalizations.of(context)!.socialNearbyLoadMore
                          : AppLocalizations.of(context)!.socialNearbyRetry,
                    ),
                  ),
                ],
              ),
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
