import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service quản lý kết nối WebSocket (socket.io) tới backend.
///
/// Backend: NestJS WebSocketGateway namespace `/notifications`
///   - Auth: JWT token (WsJwtGuard)
///   - Event nhận: `notification:new` (khi có thông báo mới)
///   - Event gửi: `subscribe` (đăng ký nhận thông báo)
class SocketService {
  static const _log = AppLogger('SocketService');
  io.Socket? _socket;
  final TokenManager _tokenManager;

  /// Callback khi có notification realtime mới.
  void Function(Map<String, dynamic> data)? onNotification;

  SocketService({required TokenManager tokenManager})
      : _tokenManager = tokenManager;

  bool get isConnected => _socket?.connected ?? false;

  /// Kết nối tới backend socket.io server.
  Future<void> connect() async {
    if (_socket?.connected == true) return;
    _disconnect();

    try {
      final token = await _tokenManager.getAccessToken();
      if (token == null || token.isEmpty) {
        _log.warning('Không có JWT token — bỏ qua kết nối socket');
        return;
      }

      final rawBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      // Lấy base server URL (bỏ /api/v1, thêm namespace /notifications)
      final serverUrl = rawBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');

      _log.info('Kết nối socket tới $serverUrl/notifications');

      _socket = io.io(
        '$serverUrl/notifications',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .disableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        _log.success('Socket connected');
        // Đăng ký nhận thông báo
        _socket!.emit('subscribe');
      });

      _socket!.on('notification:new', (data) {
        if (data is Map<String, dynamic>) {
          _log.info('Socket notification received: ${data['title']}');
          onNotification?.call(data);
        }
      });

      _socket!.onDisconnect((_) => _log.info('Socket disconnected'));
      _socket!.onError((err) => _log.error('Socket error', err.toString()));

      _socket!.connect();
    } catch (e, stack) {
      _log.error('Lỗi kết nối socket', e, stack);
    }
  }

  /// Ngắt kết nối.
  void disconnect() {
    _disconnect();
  }

  void _disconnect() {
    _socket?.off('notification:new');
    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('error');
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  /// Làm mới kết nối (khi token thay đổi).
  Future<void> reconnect() async {
    _disconnect();
    await connect();
  }
}
