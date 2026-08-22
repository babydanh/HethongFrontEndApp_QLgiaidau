import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_notification_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<ApiNotificationRepository>((
  ref,
) {
  return ApiNotificationRepository(ref.watch(dioClientProvider));
});

/// Provider cho số thông báo chưa đọc.
/// Watch auth để tự fetch lại sau khi đăng nhập — tránh kẹt 0 do lần fetch
/// đầu tiên chạy lúc chưa có token (401 → catch → cache 0 vĩnh viễn).
final unreadCountProvider = FutureProvider<int>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return 0;
  try {
    final repo = ref.watch(notificationRepositoryProvider);
    return await repo.getUnreadCount();
  } catch (e, stack) {
    AppLogger(
      'NotificationProvider',
    ).error('Không lấy được số thông báo chưa đọc', e, stack);
    return 0;
  }
});

/// Provider cho danh sách thông báo (phân trang)
final notificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return (await repo.getMyNotifications(limit: 20)).items;
});

/// Notifier quản lý trạng thái thông báo
class NotificationNotifier extends Notifier<NotificationState> {
  static const _log = AppLogger('NotificationNotifier');

  AppLocalizations get _l10n =>
      lookupAppLocalizations(ref.read(localeProvider));

  @override
  NotificationState build() => const NotificationState();

  /// Load thêm trang
  Future<void> loadPage(int page) async {
    _log.info('Load notifications page: $page');
    if (state.isLoading || (page > 1 && !state.hasMore)) return;
    final repo = ref.read(notificationRepositoryProvider);
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await repo.getMyNotifications(
        cursor: page == 1 ? null : state.nextCursor,
        limit: 20,
      );
      final items = result.items;
      if (page == 1) {
        state = NotificationState(
          notifications: items,
          currentPage: 1,
          hasMore: result.hasMore,
          nextCursor: result.nextCursor,
        );
      } else {
        state = state.copyWith(
          notifications: [...state.notifications, ...items],
          currentPage: page,
          hasMore: result.hasMore,
          nextCursor: result.nextCursor,
          isLoading: false,
        );
      }
    } catch (e, stack) {
      _log.error('Không thể tải thông báo', e, stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: _l10n.notificationLoadError,
      );
    }
  }

  /// Thêm 1 notification mới (từ socket realtime)
  void addNotification(AppNotification notif) {
    state = state.copyWith(notifications: [notif, ...state.notifications]);
  }

  /// Đánh dấu 1 cái đã đọc
  Future<void> markAsRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(id);
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id)
          return AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            redirectUrl: n.redirectUrl,
            isRead: true,
            createdAt: n.createdAt,
          );
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
      notifications: state.notifications
          .map(
            (n) => AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              redirectUrl: n.redirectUrl,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList(),
    );
    ref.invalidate(unreadCountProvider);
  }
}

final notificationStateProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );

class NotificationState {
  final List<AppNotification> notifications;
  final int currentPage;
  final bool hasMore;
  final String? nextCursor;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.nextCursor,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? currentPage,
    bool? hasMore,
    String? nextCursor,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
