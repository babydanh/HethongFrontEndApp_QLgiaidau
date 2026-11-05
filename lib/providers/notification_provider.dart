import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_notification_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backend tách thông báo thành 2 scope; App phải đọc cả hai.
const notificationScopes = ['player', 'management'];

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
    final counts = await Future.wait(
      notificationScopes.map((s) => repo.getUnreadCount(scope: s)),
    );
    return counts.fold<int>(0, (a, b) => a + b);
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
  final pages = await Future.wait(
    notificationScopes.map((s) => repo.getMyNotifications(limit: 20, scope: s)),
  );
  return [for (final p in pages) ...p.items]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      final first = page == 1;
      // Mỗi scope một cursor; scope đã hết trang thì bỏ qua.
      final scopes = first
          ? notificationScopes
          : notificationScopes.where(state.cursors.containsKey).toList();
      final results = await Future.wait(
        scopes.map(
          (s) => repo.getMyNotifications(
            cursor: first ? null : state.cursors[s],
            limit: 20,
            scope: s,
          ),
        ),
      );
      final cursors = <String, String?>{};
      for (var i = 0; i < scopes.length; i++) {
        if (results[i].hasMore && results[i].nextCursor != null) {
          cursors[scopes[i]] = results[i].nextCursor;
        }
      }
      final items = [for (final r in results) ...r.items];
      final merged = [if (!first) ...state.notifications, ...items]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = NotificationState(
        notifications: merged,
        currentPage: page,
        hasMore: cursors.isNotEmpty,
        cursors: cursors,
      );
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
    await Future.wait(
      notificationScopes.map((s) => repo.markAllAsRead(scope: s)),
    );
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
  /// Cursor trang kế của từng scope còn dữ liệu (scope hết trang thì vắng).
  final Map<String, String?> cursors;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.cursors = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? currentPage,
    bool? hasMore,
    Map<String, String?>? cursors,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      cursors: cursors ?? this.cursors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
