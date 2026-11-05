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

/// Chạy [action] cho từng scope, lỗi từng scope được log và trả null.
Future<List<T?>> _perScope<T>(
  Future<T> Function(String scope) action, {
  required AppLogger log,
  required String failMessage,
}) {
  return Future.wait(
    notificationScopes.map((s) async {
      try {
        return await action(s);
      } catch (e, stack) {
        log.error('$failMessage (scope $s)', e, stack);
        return null;
      }
    }),
  );
}

/// Provider cho số thông báo chưa đọc.
/// Watch auth để tự fetch lại sau khi đăng nhập — tránh kẹt 0 do lần fetch
/// đầu tiên chạy lúc chưa có token (401 → catch → cache 0 vĩnh viễn).
/// Tổng các scope thành công; 0 chỉ khi mọi scope lỗi.
final unreadCountProvider = FutureProvider<int>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return 0;
  final repo = ref.watch(notificationRepositoryProvider);
  final counts = await _perScope(
    (s) => repo.getUnreadCount(scope: s),
    log: const AppLogger('NotificationProvider'),
    failMessage: 'Không lấy được số thông báo chưa đọc',
  );
  return counts.fold<int>(0, (a, b) => a + (b ?? 0));
});

/// Provider cho danh sách thông báo (phân trang). Một scope lỗi vẫn hiện scope
/// còn lại; chỉ ném lỗi khi mọi scope lỗi.
final notificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final pages = await _perScope(
    (s) => repo.getMyNotifications(limit: 20, scope: s),
    log: const AppLogger('NotificationProvider'),
    failMessage: 'Không tải được thông báo',
  );
  if (pages.every((p) => p == null)) {
    throw Exception('Không tải được thông báo ở mọi scope');
  }
  return [for (final p in pages) ...?p?.items]
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
        scopes.map((s) async {
          try {
            return await repo.getMyNotifications(
              cursor: first ? null : state.cursors[s],
              limit: 20,
              scope: s,
            );
          } catch (e, stack) {
            _log.error('Không thể tải thông báo (scope $s)', e, stack);
            return null;
          }
        }),
      );
      if (results.every((r) => r == null)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _l10n.notificationLoadError,
        );
        return;
      }
      final cursors = <String, String?>{};
      for (var i = 0; i < scopes.length; i++) {
        final r = results[i];
        if (r == null) {
          // Scope lỗi giữ cursor cũ (null = chưa tải trang nào) để thử lại.
          cursors[scopes[i]] = first ? null : state.cursors[scopes[i]];
        } else if (r.hasMore && r.nextCursor != null) {
          cursors[scopes[i]] = r.nextCursor;
        }
      }
      final items = [for (final r in results) ...?r?.items];
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
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
    ref.invalidate(unreadCountProvider);
  }

  /// Đánh dấu tất cả đã đọc. Scope nào thành công được đánh dấu cục bộ; nếu có
  /// scope lỗi thì tải lại trang 1 + số chưa đọc để đồng bộ rồi ném lỗi.
  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    final failed = <String>[];
    Object? firstError;
    await Future.wait(
      notificationScopes.map((s) async {
        try {
          await repo.markAllAsRead(scope: s);
        } catch (e, stack) {
          _log.error('Không đánh dấu đã đọc được (scope $s)', e, stack);
          failed.add(s);
          firstError ??= e;
        }
      }),
    );
    // Thông báo không mang scope nên chỉ đánh dấu cục bộ khi mọi scope thành
    // công; còn lại dựng lại từ server bên dưới.
    if (failed.isEmpty) {
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList(),
      );
    }
    ref.invalidate(unreadCountProvider);
    if (failed.isNotEmpty) {
      await loadPage(1);
      throw firstError!;
    }
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
