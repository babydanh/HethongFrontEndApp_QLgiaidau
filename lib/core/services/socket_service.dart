import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;
  int _reconnectAttempt = 0;

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
    _disconnect();

    try {
      final token = await _tokenManager.getAccessToken();
      if (token == null || token.isEmpty) {
        _log.warning('Không có JWT token — bỏ qua kết nối socket');
        return;
      }

      var rawBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      // Trên Android emulator, localhost trỏ vào chính emulator, không tới host
      if (!kIsWeb && Platform.isAndroid) {
        if (rawBaseUrl.contains('localhost')) {
          rawBaseUrl = rawBaseUrl.replaceAll('localhost', '10.0.2.2');
        } else if (rawBaseUrl.contains('127.0.0.1')) {
          rawBaseUrl = rawBaseUrl.replaceAll('127.0.0.1', '10.0.2.2');
        }
      }
      // Lấy base server URL (bỏ /api/v1, thêm namespace /notifications)
      final serverUrl = rawBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');

      _log.info('Kết nối socket tới $serverUrl/notifications');

      _socket = io.io(
        '$serverUrl/notifications',
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setTimeout(8000)
            .disableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        _reconnectAttempt = 0;
        _log.success('Socket connected');
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
    _reconnectTimer?.cancel();
    _disconnect();
  }

  void _disconnect() {
    try {
      _socket?.off('notification:new');
      _socket?.off('connect');
      _socket?.off('disconnect');
      _socket?.off('error');
      _socket?.off('connect_error');
      _socket?.disconnect();
      _socket?.close();
    } catch (e) {
      _log.warning('Lỗi khi disconnect socket (bỏ qua): $e');
    } finally {
      _socket = null;
    }
  }

  /// Làm mới kết nối (khi token thay đổi).
  Future<void> reconnect() async {
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    _disconnect();
    await connect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _reconnectTimer?.isActive == true) return;
    if (_reconnectAttempt >= 5) {
      _log.warning('Đã đạt giới hạn số lần reconnect socket (5 lần). Tạm dừng reconnect.');
      return;
    }
    final attempt = _reconnectAttempt.clamp(0, 4).toInt();
    final seconds = (2 << attempt).clamp(2, 30).toInt();
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () async {
      _reconnectTimer = null;
      await connect();
    });
  }
}
