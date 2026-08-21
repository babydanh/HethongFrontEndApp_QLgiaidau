import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/push_notification_service.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';

/// Widget quản lý lifecycle kết nối WebSocket và FCM Push Notification dựa trên trạng thái đăng nhập.
///
/// - Khi user đăng nhập → kết nối socket + đăng ký FCM Push Notification
/// - Khi user đăng xuất → ngắt kết nối socket + hủy token FCM
/// - Khi nhận `notification:new` từ socket → cập nhật NotificationNotifier
class SocketObserver extends ConsumerStatefulWidget {
  final Widget child;

  const SocketObserver({super.key, required this.child});

  @override
  ConsumerState<SocketObserver> createState() => _SocketObserverState();
}

class _SocketObserverState extends ConsumerState<SocketObserver> with WidgetsBindingObserver {
  static const _log = AppLogger('SocketObserver');
  bool _recoveringAfterResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSocket();
      _syncPushNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi app resume, kiểm tra lại kết nối socket
    if (state == AppLifecycleState.resumed) {
      _syncSocket();
      unawaited(_recoverDataAfterResume());
    }
  }

  Future<void> _recoverDataAfterResume() async {
    if (_recoveringAfterResume || !mounted) return;
    _recoveringAfterResume = true;
    try {
      // Give the OS a moment to restore Wi-Fi/mobile data before refetching.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || !ref.read(authProvider).isAuthenticated) return;

      // These providers are shared by profile, home and the management area.
      // Invalidating them reconnects the current screens without restarting app.
      ref.invalidate(userProfileProvider);
      ref.invalidate(unreadCountProvider);
      // Notification state is kept in a Notifier and therefore survives
      // backgrounding. Reload page 1 so notifications created while the app
      // was paused (or while the socket was reconnecting) are not missed.
      unawaited(ref.read(notificationStateProvider.notifier).loadPage(1));
      ref.invalidate(myTournamentWorkspaceProvider);
      ref.invalidate(tournamentsProvider);
    } finally {
      _recoveringAfterResume = false;
    }
  }

  void _syncSocket() {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    final socketService = ref.read(socketServiceProvider);

    if (isAuthenticated) {
      _connectSocket(socketService);
    } else {
      socketService.disconnect();
    }
  }

  void _syncPushNotifications() {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    final dioClient = ref.read(dioClientProvider);

    if (isAuthenticated) {
      PushNotificationService.instance.initialize(dioClient: dioClient);
    }
  }

  void _connectSocket(dynamic socketService) {
    // Đăng ký callback xử lý notification realtime
    socketService.onNotification = (Map<String, dynamic> data) {
      _log.info('Received realtime notification: ${data['title']}');
      try {
        final notif = AppNotification.fromJson(data);
        // Thêm vào đầu danh sách notification
        ref.read(notificationStateProvider.notifier).addNotification(notif);
        // The socket payload is intentionally only an optimistic update. A
        // short refetch reconciles it with the persisted notification record
        // and also covers a notification emitted while reconnecting.
        unawaited(ref.read(notificationStateProvider.notifier).loadPage(1));
        // Refresh unread count
        ref.invalidate(unreadCountProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notif.title),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: notif.routeTarget != null
                  ? SnackBarAction(
                      label: AppLocalizations.of(context)?.coreView ?? 'View',
                      onPressed: () {
                        context.push(notif.routeTarget!);
                      },
                    )
                  : null,
            ),
          );
        }
      } catch (e, stack) {
        _log.error('Lỗi parse notification từ socket', e, stack);
      }
    };

    socketService.connect();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe auth state để connect/disconnect socket và FCM
    ref.listen<bool>(
      authProvider.select((s) => s.isAuthenticated),
      (prev, next) {
        final socketService = ref.read(socketServiceProvider);
        final dioClient = ref.read(dioClientProvider);

        if (next == true && prev != true) {
          _connectSocket(socketService);
          PushNotificationService.instance.initialize(dioClient: dioClient);
        } else if (next == false && prev != false) {
          socketService.disconnect();
          PushNotificationService.instance.unregisterToken(dioClient: dioClient);
        }
      },
    );

    return widget.child;
  }
}
