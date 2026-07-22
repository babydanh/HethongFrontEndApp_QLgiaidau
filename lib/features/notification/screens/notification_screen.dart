import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});
  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  static const _log = AppLogger('NotificationScreen');
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // Filter mode: false = Tất cả, true = Chưa đọc
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(notificationStateProvider.notifier).loadPage(1));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final s = ref.read(notificationStateProvider);
      if (s.hasMore && !_isLoadingMore) {
        _isLoadingMore = true;
        ref
            .read(notificationStateProvider.notifier)
            .loadPage(s.currentPage + 1)
            .then((_) {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ref.read(notificationStateProvider.notifier).markAllAsRead();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đánh dấu tất cả đã đọc.')),
      );
    }
  }

  Future<void> _handleInviteAction(
      AppNotification notif, bool accept) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final endpoint = accept ? '/notifications/${notif.id}/accept' : '/notifications/${notif.id}/decline';
      await dio.patch(endpoint);
      await ref.read(notificationStateProvider.notifier).markAsRead(notif.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Đã chấp nhận lời mời' : 'Đã từ chối lời mời'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi xử lý lời mời', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Không thể chấp nhận lời mời' : 'Không thể từ chối lời mời'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateNotif = ref.watch(notificationStateProvider);
    final colors = context.colors;

    // Lọc notifications theo chế độ
    final displayedNotifications = _unreadOnly
        ? stateNotif.notifications.where((n) => !n.isRead).toList()
        : stateNotif.notifications;

    final totalUnread = stateNotif.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thông báo',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          // Nút Đánh dấu đã đọc tất cả (luôn hiển thị nếu có unread)
          if (totalUnread > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter bar ──
          _buildFilterBar(colors, totalUnread),
          Expanded(
            child: stateNotif.notifications.isEmpty && stateNotif.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stateNotif.notifications.isEmpty && stateNotif.errorMessage != null
                    ? _buildError(stateNotif.errorMessage!, colors)
                    : stateNotif.notifications.isEmpty
                        ? _buildEmpty(colors)
                        : displayedNotifications.isEmpty
                            ? _buildFilteredEmpty(colors)
                            : _buildList(displayedNotifications, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppColorsExtension colors, int totalUnread) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgDark,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Filter chips
          _FilterSegment(
            label: 'Tất cả',
            isActive: !_unreadOnly,
            colors: colors,
            onTap: () => setState(() => _unreadOnly = false),
          ),
          const SizedBox(width: 8),
          _FilterSegment(
            label: 'Chưa đọc${totalUnread > 0 ? ' ($totalUnread)' : ''}',
            isActive: _unreadOnly,
            colors: colors,
            count: totalUnread,
            onTap: () => setState(() => _unreadOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Chưa có thông báo nào',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Các thông báo sẽ hiển thị tại đây',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      );

  Widget _buildFilteredEmpty(AppColorsExtension colors) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_rounded, size: 48, color: colors.success.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Không có thông báo chưa đọc',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() => _unreadOnly = false),
              child: const Text('Xem tất cả thông báo'),
            ),
          ],
        ),
      );

  Widget _buildError(String message, AppColorsExtension colors) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(notificationStateProvider.notifier).loadPage(1),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );

  Widget _buildList(List<AppNotification> notifications, AppColorsExtension colors) {
    final grouped = <String, List<AppNotification>>{};
    final now = DateTime.now();
    for (final n in notifications) {
      final diff = now.difference(n.createdAt);
      final key = diff.inDays == 0
          ? 'Hôm nay'
          : diff.inDays == 1
              ? 'Hôm qua'
              : diff.inDays < 7
                  ? 'Tuần này'
                  : '${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}';
      grouped.putIfAbsent(key, () => []).add(n);
    }

    // Sort groups by date key
    final orderedKeys = <String>[];
    if (grouped.containsKey('Hôm nay')) orderedKeys.add('Hôm nay');
    if (grouped.containsKey('Hôm qua')) orderedKeys.add('Hôm qua');
    if (grouped.containsKey('Tuần này')) orderedKeys.add('Tuần này');
    for (final k in grouped.keys) {
      if (!orderedKeys.contains(k)) orderedKeys.add(k);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationStateProvider.notifier).loadPage(1),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: orderedKeys.length + 1,
        itemBuilder: (context, index) {
          if (index >= orderedKeys.length) {
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : const SizedBox.shrink();
          }
          final entryKey = orderedKeys[index];
          final items = grouped[entryKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  entryKey,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              ...items.map((n) => _buildCard(n, colors)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(AppNotification notif, AppColorsExtension colors) {
    final isInvite = notif.type == 'TOURNAMENT_REGISTER_PENDING' ||
        notif.type == 'CLUB_INVITE' ||
        notif.type == 'INVITE';

    return GestureDetector(
      onTap: () async {
        if (!notif.isRead) {
          try {
            await ref
                .read(notificationStateProvider.notifier)
                .markAsRead(notif.id);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Không thể cập nhật trạng thái thông báo.')),
              );
            }
          }
        }
        if (!mounted) return;
        if (notif.redirectUrl != null && notif.redirectUrl!.isNotEmpty) {
          context.go(notif.redirectUrl!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notif.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(notif.icon, color: notif.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2979FF),
                              ),
                            ),
                        ],
                      ),
                      if (notif.body != null && notif.body!.isNotEmpty)
                        ...[
                          const SizedBox(height: 4),
                          Text(
                            notif.body!,
                            style: TextStyle(
                                fontSize: 12, color: colors.textSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      const SizedBox(height: 4),
                      Text(
                        notif.timeAgo,
                        style: TextStyle(
                            fontSize: 11, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Inline accept/decline buttons for invites
            if (isInvite) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleInviteAction(notif, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textMuted,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Từ chối',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _handleInviteAction(notif, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Chấp nhận',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Filter Segment Widget ───

class _FilterSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final AppColorsExtension colors;
  final int? count;
  final VoidCallback onTap;

  const _FilterSegment({
    required this.label,
    required this.isActive,
    required this.colors,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2979FF).withValues(alpha: 0.12)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF2979FF).withValues(alpha: 0.4)
                : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              size: 16,
              color: isActive
                  ? const Color(0xFF2979FF)
                  : colors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF2979FF)
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
