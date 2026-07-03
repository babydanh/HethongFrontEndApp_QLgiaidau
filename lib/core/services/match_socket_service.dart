import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

/// Service quản lý kết nối WebSocket (socket.io) tới namespace `/live` phục vụ live scores.
class MatchSocketService {
  static const _log = AppLogger('MatchSocketService');
  io.Socket? _socket;

  // Stream controllers to broadcast incoming events
  final _scoreUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _matchStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _viewerCountController = StreamController<Map<String, dynamic>>.broadcast();
  final _commentNewController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onScoreUpdate => _scoreUpdateController.stream;
  Stream<Map<String, dynamic>> get onMatchStatus => _matchStatusController.stream;
  Stream<Map<String, dynamic>> get onViewerCount => _viewerCountController.stream;
  Stream<Map<String, dynamic>> get onCommentNew => _commentNewController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String matchId) {
    if (_socket != null) {
      if (_socket!.connected) {
        _log.info('Socket already connected. Emitting joinMatch for $matchId');
        _socket!.emit('joinMatch', matchId);
      } else {
        _log.info('Socket exists but disconnected. Reconnecting...');
        _socket!.connect();
      }
      return;
    }

    try {
      final rawBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      final serverUrl = rawBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
      _log.info('Connecting to match socket at $serverUrl/live');

      _socket = io.io(
        '$serverUrl/live',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        _log.success('Match Socket connected. Joining match $matchId');
        _socket!.emit('joinMatch', matchId);
      });

      _socket!.on('score:update', (data) {
        _log.info('Socket match score:update received');
        if (data is Map<String, dynamic>) {
          _scoreUpdateController.add(data);
        }
      });

      _socket!.on('match:status', (data) {
        _log.info('Socket matchStatus received');
        if (data is Map<String, dynamic>) {
          _matchStatusController.add(data);
        }
      });

      _socket!.on('viewer:count', (data) {
        _log.info('Socket viewerCount received: $data');
        if (data is Map<String, dynamic>) {
          _viewerCountController.add(data);
        }
      });

      _socket!.on('comment:new', (data) {
        _log.info('Socket comment:new received');
        if (data is Map<String, dynamic>) {
          _commentNewController.add(data);
        }
      });

      _socket!.onDisconnect((_) => _log.info('Match Socket disconnected'));
      _socket!.onError((err) => _log.error('Match Socket error', err.toString()));

      _socket!.connect();
    } catch (e, stack) {
      _log.error('Lỗi kết nối match socket', e, stack);
    }
  }

  void leave(String matchId) {
    if (_socket?.connected == true) {
      _log.info('Leaving match $matchId');
      _socket!.emit('leaveMatch', matchId);
    }
  }

  void disconnect() {
    if (_socket != null) {
      _log.info('Disconnecting match socket');
      _socket!.disconnect();
      _socket!.close();
      _socket = null;
    }
  }
}
