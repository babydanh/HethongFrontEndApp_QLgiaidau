import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_notification_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<ApiNotificationRepository>((ref) {
  return ApiNotificationRepository(ref.watch(dioClientProvider));
});

/// Provider cho số thông báo chưa đọc
final unreadCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

/// Provider cho danh sách thông báo (phân trang)
final notificationsProvider = FutureProvider.family<List<AppNotification>, int>((ref, page) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getMyNotifications(page: page, limit: 20);
});

/// Notifier quản lý trạng thái thông báo
class NotificationNotifier extends Notifier<NotificationState> {
  static const _log = AppLogger('NotificationNotifier');

  @override
  NotificationState build() => const NotificationState();

  /// Load thêm trang
  Future<void> loadPage(int page) async {
    _log.info('Load notifications page: $page');
    final repo = ref.read(notificationRepositoryProvider);
    final items = await repo.getMyNotifications(page: page, limit: 20);
    if (page == 1) {
      state = NotificationState(notifications: items, currentPage: 1, hasMore: items.length >= 20);
    } else {
      state = state.copyWith(
        notifications: [...state.notifications, ...items],
        currentPage: page,
        hasMore: items.length >= 20,
      );
    }
  }

  /// Thêm 1 notification mới (từ socket realtime)
  void addNotification(AppNotification notif) {
    state = state.copyWith(
      notifications: [notif, ...state.notifications],
    );
  }

  /// Đánh dấu 1 cái đã đọc
  Future<void> markAsRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(id);
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) return AppNotification(id: n.id, type: n.type, title: n.title, body: n.body, redirectUrl: n.redirectUrl, isRead: true, createdAt: n.createdAt);
        return n;
      }).toList(),
    );
    ref.invalidate(unreadCountProvider);
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead();
    state = state.copyWith(
      notifications: state.notifications.map((n) => AppNotification(id: n.id, type: n.type, title: n.title, body: n.body, redirectUrl: n.redirectUrl, isRead: true, createdAt: n.createdAt)).toList(),
    );
    ref.invalidate(unreadCountProvider);
  }
}

final notificationStateProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

class NotificationState {
  final List<AppNotification> notifications;
  final int currentPage;
  final bool hasMore;

  const NotificationState({
    this.notifications = const [],
    this.currentPage = 0,
    this.hasMore = true,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? currentPage,
    bool? hasMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
