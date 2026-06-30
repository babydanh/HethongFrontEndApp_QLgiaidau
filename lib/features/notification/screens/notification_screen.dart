import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final stateNotif = ref.read(notificationStateProvider);
      if (stateNotif.hasMore && !_isLoadingMore) {
        _isLoadingMore = true;
        ref.read(notificationStateProvider.notifier).loadPage(stateNotif.currentPage + 1).then((_) {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateNotif = ref.watch(notificationStateProvider);
    final unreadAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thông báo',
          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          if (stateNotif.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => ref.read(notificationStateProvider.notifier).markAllAsRead(),
              child: const Text('Đọc tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: stateNotif.notifications.isEmpty && stateNotif.currentPage == 0
          ? _buildLoading()
          : stateNotif.notifications.isEmpty
              ? _buildEmpty()
              : _buildList(stateNotif.notifications),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: context.colors.textMuted),
          const SizedBox(height: 16),
          Text('Chưa có thông báo nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 8),
          Text('Các thông báo về giải đấu, trận đấu sẽ hiển thị tại đây', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildList(List<AppNotification> notifications) {
    // Nhóm theo ngày
    final grouped = <String, List<AppNotification>>{};
    final now = DateTime.now();
    for (final n in notifications) {
      String key;
      final diff = now.difference(n.createdAt);
      if (diff.inDays == 0) key = 'Hôm nay';
      else if (diff.inDays == 1) key = 'Hôm qua';
      else if (diff.inDays < 7) key = 'Tuần này';
      else key = '${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}';
      grouped.putIfAbsent(key, () => []).add(n);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationStateProvider.notifier).loadPage(1),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: grouped.entries.length + 1,
        itemBuilder: (context, index) {
          if (index >= grouped.entries.length) {
            return _isLoadingMore
                ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : const SizedBox.shrink();
          }
          final entry = grouped.entries.elementAt(index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(entry.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.colors.textSecondary, letterSpacing: 0.5)),
              ),
              ...entry.value.map((n) => _buildNotificationCard(n)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif) {
    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          ref.read(notificationStateProvider.notifier).markAsRead(notif.id);
        }
        // Deep link nếu có
        if (notif.redirectUrl != null && notif.redirectUrl!.isNotEmpty) {
          context.go(notif.redirectUrl!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: notif.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notif.icon, color: notif.color, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title, style: TextStyle(
                          fontSize: 14, fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                          color: context.colors.textPrimary,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2979FF)),
                        ),
                    ],
                  ),
                  if (notif.body != null && notif.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(notif.body!, style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text(notif.timeAgo, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
