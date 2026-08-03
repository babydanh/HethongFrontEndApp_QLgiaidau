import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

/// Service quản lý kết nối WebSocket (socket.io) tới namespace `/live` phục vụ live scores.
class MatchSocketService {
  static const _log = AppLogger('MatchSocketService');
  io.Socket? _socket;
  final _joinedMatchIds = <String>{};
  final _joinedTournamentIds = <String>{};

  // Stream controllers to broadcast incoming events
  final _scoreUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _matchStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _viewerCountController = StreamController<Map<String, dynamic>>.broadcast();
  final _commentNewController = StreamController<Map<String, dynamic>>.broadcast();
  final _cheerUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _tournamentMatchUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onScoreUpdate => _scoreUpdateController.stream;
  Stream<Map<String, dynamic>> get onMatchStatus => _matchStatusController.stream;
  Stream<Map<String, dynamic>> get onViewerCount => _viewerCountController.stream;
  Stream<Map<String, dynamic>> get onCommentNew => _commentNewController.stream;
  Stream<Map<String, dynamic>> get onCheerUpdate => _cheerUpdateController.stream;
  Stream<Map<String, dynamic>> get onTournamentMatchUpdate => _tournamentMatchUpdateController.stream;

  /// An toàn parse socket payload: accept Map hoặc JSON string.
  /// Log warning nếu format lạ, không throw.
  Map<String, dynamic>? _parsePayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      // Map nhưng không generic – cast an toàn
      try {
        return Map<String, dynamic>.from(data);
      } catch (_) {
        _log.warning('Socket payload là Map không cast được: $data');
        return null;
      }
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        _log.warning('Socket payload là JSON string không decode được: $data');
        return null;
      }
    }
    _log.warning('Socket payload format lạ (type=${data.runtimeType}): $data');
    return null;
  }

  bool get isConnected => _socket?.connected ?? false;

  void connect(String? matchId, {bool joinMatch = true}) {
    if (joinMatch && matchId != null) {
      _joinedMatchIds.add(matchId);
    }
    if (_socket != null) {
      if (_socket!.connected) {
        _joinTrackedRooms();
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
            .setTransports(['websocket', 'polling'])
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setTimeout(8000)
            .disableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        _log.success('Match Socket connected');
        _joinTrackedRooms();
      });

      _socket!.on('score:update', (data) {
        _log.info('Socket match score:update received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _scoreUpdateController.add(parsed);
        }
      });

      _socket!.on('match:status', (data) {
        _log.info('Socket matchStatus received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _matchStatusController.add(parsed);
        }
      });

      _socket!.on('viewer:count', (data) {
        _log.info('Socket viewerCount received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _viewerCountController.add(parsed);
        }
      });

      _socket!.on('comment:new', (data) {
        _log.info('Socket comment:new received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _commentNewController.add(parsed);
        }
      });

      _socket!.on('cheer:update', (data) {
        _log.info('Socket cheer:update received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _cheerUpdateController.add(parsed);
        }
      });

      _socket!.on('match:update', (data) {
        _log.info('Socket tournament match:update received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _tournamentMatchUpdateController.add(parsed);
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
    _joinedMatchIds.remove(matchId);
    if (_socket?.connected == true) {
      _log.info('Leaving match $matchId');
      _socket!.emit('leaveMatch', matchId);
    }
  }

  void joinTournament(String tournamentId) {
    _joinedTournamentIds.add(tournamentId);
    if (_socket?.connected == true) {
      _socket!.emit('joinTournament', tournamentId);
    }
  }

  void leaveTournament(String tournamentId) {
    _joinedTournamentIds.remove(tournamentId);
    if (_socket?.connected == true) {
      _socket!.emit('leaveTournament', tournamentId);
    }
  }

  void disconnect() {
    if (_socket != null) {
      _log.info('Disconnecting match socket');
      _socket!.disconnect();
      _socket!.close();
      _socket = null;
    }
    _joinedMatchIds.clear();
    _joinedTournamentIds.clear();
  }

  void _joinTrackedRooms() {
    final socket = _socket;
    if (socket?.connected != true) return;
    for (final matchId in _joinedMatchIds) {
      socket!.emit('joinMatch', matchId);
    }
    for (final tournamentId in _joinedTournamentIds) {
      socket!.emit('joinTournament', tournamentId);
    }
  }
}
