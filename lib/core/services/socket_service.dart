import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;
  int _reconnectAttempt = 0;
  Future<void>? _connectionInFlight;
  int _connectionGeneration = 0;

  /// Callback khi có notification realtime mới.
  void Function(Map<String, dynamic> data)? onNotification;

  SocketService({required TokenManager tokenManager})
    : _tokenManager = tokenManager;

  bool get isConnected => _socket?.connected ?? false;

  /// Kết nối tới backend socket.io server.
  Future<void> connect() async {
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    if (_socket?.connected == true) return;
    final connectionInFlight = _connectionInFlight;
    if (connectionInFlight != null) {
      await connectionInFlight;
      return;
    }
    _disconnect();

    final connection = _createConnection(_connectionGeneration);
    _connectionInFlight = connection;
    try {
      await connection;
    } finally {
      if (identical(_connectionInFlight, connection)) {
        _connectionInFlight = null;
      }
    }
  }

  Future<void> _createConnection(int generation) async {
    try {
      final token = await _tokenManager.getAccessToken();
      if (generation != _connectionGeneration || _manualDisconnect) return;
      if (token == null || token.isEmpty) {
        _log.warning('Không có JWT token — bỏ qua kết nối socket');
        return;
      }

      const envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
      final rawBaseUrl = envApiBaseUrl.isNotEmpty
          ? envApiBaseUrl
          : (dotenv.env['API_BASE_URL'] ??
                (kIsWeb
                    ? 'https://sporto.asia/api/v1'
                    : 'http://localhost:3000/api/v1'));
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
        _reconnectAttempt = 0;
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

      _socket!.onDisconnect((_) {
        _log.info('Socket disconnected');
        _scheduleReconnect();
      });
      _socket!.onError((err) {
        _log.error('Socket error', err.toString());
        _scheduleReconnect();
      });
      _socket!.on('connect_error', (err) {
        _log.error('Socket connect error', err.toString());
        _scheduleReconnect();
      });

      _socket!.connect();
    } catch (e, stack) {
      _log.error('Lỗi kết nối socket', e, stack);
    }
  }

  /// Ngắt kết nối.
  void disconnect() {
    _manualDisconnect = true;
    _connectionGeneration++;
    _connectionInFlight = null;
    _reconnectTimer?.cancel();
    _disconnect();
  }

  void _disconnect() {
    _socket?.off('notification:new');
    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('error');
    _socket?.off('connect_error');
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  /// Làm mới kết nối (khi token thay đổi).
  Future<void> reconnect() async {
    _manualDisconnect = false;
    _connectionGeneration++;
    _connectionInFlight = null;
    _reconnectTimer?.cancel();
    _disconnect();
    await connect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _reconnectTimer?.isActive == true) return;
    final attempt = _reconnectAttempt.clamp(0, 4).toInt();
    final seconds = (1 << attempt).clamp(1, 30).toInt();
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () async {
      _reconnectTimer = null;
      await connect();
    });
  }
}
