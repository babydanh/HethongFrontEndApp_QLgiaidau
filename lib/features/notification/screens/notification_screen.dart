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
  void initState() { super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(notificationStateProvider.notifier).loadPage(1));
  }
  @override
  void dispose() { _scrollController.removeListener(_onScroll); _scrollController.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final s = ref.read(notificationStateProvider);
      if (s.hasMore && !_isLoadingMore) {
        _isLoadingMore = true;
        ref.read(notificationStateProvider.notifier).loadPage(s.currentPage + 1).then((_) {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateNotif = ref.watch(notificationStateProvider);
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(backgroundColor: colors.bgDark, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary), onPressed: () => context.pop()),
        title: Text('Thông báo', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [if (stateNotif.notifications.any((n) => !n.isRead))
          TextButton(onPressed: () => ref.read(notificationStateProvider.notifier).markAllAsRead(),
            child: const Text('Đọc tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))],
      ),
      body: stateNotif.notifications.isEmpty && stateNotif.currentPage == 0
          ? const Center(child: CircularProgressIndicator())
          : stateNotif.notifications.isEmpty ? _buildEmpty(colors) : _buildList(stateNotif.notifications, colors),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
    children: [Icon(Icons.notifications_none_rounded, size: 64, color: colors.textMuted),
      const SizedBox(height: 16), Text('Chưa có thông báo nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      const SizedBox(height: 8), Text('Các thông báo sẽ hiển thị tại đây', style: TextStyle(fontSize: 13, color: colors.textSecondary))]));

  Widget _buildList(List<AppNotification> notifications, AppColorsExtension colors) {
    final grouped = <String, List<AppNotification>>{};
    final now = DateTime.now();
    for (final n in notifications) {
      final diff = now.difference(n.createdAt);
      final key = diff.inDays == 0 ? 'Hôm nay' : diff.inDays == 1 ? 'Hôm qua' : diff.inDays < 7 ? 'Tuần này' : '${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}';
      grouped.putIfAbsent(key, () => []).add(n);
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(notificationStateProvider.notifier).loadPage(1),
      child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: grouped.entries.length + 1,
        itemBuilder: (context, index) {
          if (index >= grouped.entries.length) {
            return _isLoadingMore
                ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : const SizedBox.shrink();
          }
          final entry = grouped.entries.elementAt(index);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(entry.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.textSecondary))),
            ...entry.value.map((n) => _buildCard(n, colors)),
          ]);
        },
      ),
    );
  }

  Widget _buildCard(AppNotification notif, AppColorsExtension colors) => GestureDetector(
    onTap: () {
      if (!notif.isRead) ref.read(notificationStateProvider.notifier).markAsRead(notif.id);
      if (notif.redirectUrl != null && notif.redirectUrl!.isNotEmpty) context.go(notif.redirectUrl!);
    },
    child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: notif.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(notif.icon, color: notif.color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(notif.title, style: TextStyle(fontSize: 14, fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700, color: colors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (!notif.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2979FF))),
          ]),
          if (notif.body != null && notif.body!.isNotEmpty) ...[const SizedBox(height: 4),
            Text(notif.body!, style: TextStyle(fontSize: 12, color: colors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)],
          const SizedBox(height: 4), Text(notif.timeAgo, style: TextStyle(fontSize: 11, color: colors.textMuted)),
        ])),
      ]),
    ),
  );
}
