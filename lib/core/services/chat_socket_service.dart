import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService {
  static const _log = AppLogger('ChatSocketService');
  final TokenManager tokenManager;
  io.Socket? _socket;
  String? _currentRoomId;

  bool get isConnected => _socket?.connected ?? false;

  void Function(Map<String, dynamic>)? onMessage;
  void Function(Map<String, dynamic>)? onTyping;
  void Function(Map<String, dynamic>)? onReaction;
  void Function(Map<String, dynamic>)? onPollVoted;
  void Function(Map<String, dynamic>)? onRevoked;
  void Function(Map<String, dynamic>)? onPinned;
  void Function(Map<String, dynamic>)? onUserStatus;
  void Function(Map<String, dynamic>)? onRoomRead;
  void Function(Map<String, dynamic>)? onRoomActivity;
  void Function(bool)? onConnection;

  ChatSocketService(this.tokenManager);

  Future<void> connect(String roomId) async {
    _currentRoomId = roomId;

    final token = await tokenManager.getAccessToken();
    if (token == null || token.isEmpty) {
      _log.warning('Không có JWT token — không thể kết nối chat socket');
      return;
    }

    var rawBaseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (!kIsWeb && Platform.isAndroid) {
      if (rawBaseUrl.contains('localhost')) {
        rawBaseUrl = rawBaseUrl.replaceAll('localhost', '10.0.2.2');
      } else if (rawBaseUrl.contains('127.0.0.1')) {
        rawBaseUrl = rawBaseUrl.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }

    final serverUrl = rawBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    _log.info(
      'Connecting to chat socket at $serverUrl/chat for roomId: $roomId',
    );

    _socket?.disconnect();
    _socket?.close();

    _socket = io.io(
      '$serverUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setTimeout(10000)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _log.success('Chat Socket connected');
      onConnection?.call(true);
      if (_currentRoomId != null && _currentRoomId!.isNotEmpty) {
        _log.info('Joining chat room: $_currentRoomId');
        _socket!.emit('joinChatRoom', _currentRoomId);
      }
    });

    _socket!.onDisconnect((_) {
      _log.info('Chat Socket disconnected');
      onConnection?.call(false);
    });

    _socket!.onConnectError((err) {
      _log.error('Chat Socket connect error', err.toString());
      onConnection?.call(false);
    });

    _socket!.onError((err) {
      _log.error('Chat Socket error', err.toString());
    });

    _socket!.on('chat:error', (data) {
      _log.error('Server chat:error received', data.toString());
    });

    _socket!.on('chat:message', (data) {
      _log.info('Received chat:message event');
      final map = _asMap(data);
      if (map.isNotEmpty) onMessage?.call(map);
    });

    _socket!.on('chat:club:message', (data) {
      _log.info('Received chat:club:message event');
      final map = _asMap(data);
      if (map.isNotEmpty) onMessage?.call(map);
    });

    _socket!.on('chat:typing', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onTyping?.call(map);
    });

    _socket!.on('chat:message:reaction', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onReaction?.call(map);
    });

    _socket!.on('chat:poll:voted', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onPollVoted?.call(map);
    });

    _socket!.on('chat:message:revoked', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onRevoked?.call(map);
    });

    _socket!.on('chat:message:pinned', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onPinned?.call(map);
    });

    _socket!.on('chat:user:status', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onUserStatus?.call(map);
    });

    _socket!.on('chat:room:read', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onRoomRead?.call(map);
    });

    _socket!.on('chat:room:created', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onRoomActivity?.call(map);
    });

    _socket!.on('chat:room:updated', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) onRoomActivity?.call(map);
    });

    _socket!.connect();
  }

  void checkOnlineUsers(
    List<String> userIds,
    void Function(Map<String, dynamic>) callback,
  ) {
    if (isConnected && userIds.isNotEmpty) {
      _socket!.emitWithAck(
        'checkOnlineUsers',
        userIds,
        ack: (data) {
          final map = _asMap(data);
          callback(map);
        },
      );
    }
  }

  void send(String roomId, String content) {
    if (isConnected) {
      _socket!.emit('sendMessage', {'roomId': roomId, 'content': content});
    }
  }

  void typing(String roomId, bool isTyping) {
    if (isConnected) {
      _socket!.emit('typing', {'roomId': roomId, 'isTyping': isTyping});
    }
  }

  void disconnect([String roomId = '']) {
    if (_socket?.connected == true && roomId.isNotEmpty) {
      _socket!.emit('leaveChatRoom', roomId);
    }
    _currentRoomId = null;
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  void dispose() => disconnect();

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }
}
