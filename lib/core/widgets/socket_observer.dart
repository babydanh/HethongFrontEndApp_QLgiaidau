import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';

/// Widget quản lý lifecycle kết nối WebSocket dựa trên trạng thái đăng nhập.
///
/// - Khi user đăng nhập → kết nối socket + đăng ký nhận notification realtime
/// - Khi user đăng xuất → ngắt kết nối socket
/// - Khi nhận `notification:new` từ socket → cập nhật NotificationNotifier
class SocketObserver extends ConsumerStatefulWidget {
  final Widget child;

  const SocketObserver({super.key, required this.child});

  @override
  ConsumerState<SocketObserver> createState() => _SocketObserverState();
}

class _SocketObserverState extends ConsumerState<SocketObserver> with WidgetsBindingObserver {
  static const _log = AppLogger('SocketObserver');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSocket());
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

  void _connectSocket(dynamic socketService) {
    // Đăng ký callback xử lý notification realtime
    socketService.onNotification = (Map<String, dynamic> data) {
      _log.info('Received realtime notification: ${data['title']}');
      try {
        final notif = AppNotification.fromJson(data);
        // Thêm vào đầu danh sách notification
        ref.read(notificationStateProvider.notifier).addNotification(notif);
        // Refresh unread count
        ref.invalidate(unreadCountProvider);
      } catch (e, stack) {
        _log.error('Lỗi parse notification từ socket', e, stack);
      }
    };

    socketService.connect();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe auth state để connect/disconnect socket
    ref.listen<bool>(
      authProvider.select((s) => s.isAuthenticated),
      (prev, next) {
        final socketService = ref.read(socketServiceProvider);
        if (next == true && prev != true) {
          _connectSocket(socketService);
        } else if (next == false && prev != false) {
          socketService.disconnect();
        }
      },
    );

    return widget.child;
  }
}
