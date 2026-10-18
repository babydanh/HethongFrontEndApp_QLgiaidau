import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/core/services/socket_room_ref_counter.dart';

/// Service quản lý kết nối WebSocket (socket.io) tới namespace `/live` phục vụ live scores.
class MatchSocketService {
  static const _log = AppLogger('MatchSocketService');
  io.Socket? _socket;
  final _matchRooms = SocketRoomRefCounter();
  final _tournamentRooms = SocketRoomRefCounter();
  final _clubSessionRooms = SocketRoomRefCounter();
  final _clubCommunityRooms = SocketRoomRefCounter();
  final TokenManager? _tokenManager;
  Future<void>? _connectionInFlight;
  int _connectionGeneration = 0;

  MatchSocketService({TokenManager? tokenManager})
    : _tokenManager = tokenManager;

  // Stream controllers to broadcast incoming events
  final _scoreUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _matchStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _viewerCountController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _commentNewController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _cheerUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _tournamentMatchUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _registrationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _scoreboardVisibilityController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _overlayVisibilityController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onScoreUpdate =>
      _scoreUpdateController.stream;
  Stream<Map<String, dynamic>> get onMatchStatus =>
      _matchStatusController.stream;
  Stream<Map<String, dynamic>> get onViewerCount =>
      _viewerCountController.stream;
  Stream<Map<String, dynamic>> get onCommentNew => _commentNewController.stream;
  Stream<Map<String, dynamic>> get onCheerUpdate =>
      _cheerUpdateController.stream;
  Stream<Map<String, dynamic>> get onTournamentMatchUpdate =>
      _tournamentMatchUpdateController.stream;
  Stream<Map<String, dynamic>> get onRegistrationUpdate =>
      _registrationUpdateController.stream;

  Stream<Map<String, dynamic>> get onScoreboardVisibility =>
      _scoreboardVisibilityController.stream;

  Stream<Map<String, dynamic>> get onOverlayVisibility =>
      _overlayVisibilityController.stream;

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

  Future<void> connect(String? matchId, {bool joinMatch = true}) async {
    if (joinMatch && matchId != null) {
      _matchRooms.retain(matchId);
    }
    final connectionInFlight = _connectionInFlight;
    if (connectionInFlight != null) {
      await connectionInFlight;
      return;
    }
    if (_socket != null) {
      if (_socket!.connected) {
        _joinTrackedRooms();
      } else {
        _log.info('Socket exists but disconnected. Reconnecting...');
        try {
          _socket!.connect();
        } catch (e, stack) {
          _log.error('Lỗi kết nối lại match socket', e, stack);
        }
      }
      return;
    }

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
      var rawBaseUrl =
          dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      // Trên Android emulator, localhost trỏ vào chính emulator, không tới host.
      // Giống dio_client: đổi localhost/127.0.0.1 -> 10.0.2.2, nếu không socket
      // /live không kết nối được -> lượt xem (viewer count) không bao giờ lên.
      if (!kIsWeb && Platform.isAndroid) {
        if (rawBaseUrl.contains('localhost')) {
          rawBaseUrl = rawBaseUrl.replaceAll('localhost', '10.0.2.2');
        } else if (rawBaseUrl.contains('127.0.0.1')) {
          rawBaseUrl = rawBaseUrl.replaceAll('127.0.0.1', '10.0.2.2');
        }
      }
      final serverUrl = rawBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
      _log.info('Connecting to match socket at $serverUrl/live');

      final token = await _tokenManager?.getAccessToken();
      if (generation != _connectionGeneration) return;
      _socket = io.io(
        '$serverUrl/live',
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableReconnection()
            // Mobile networks can disappear for minutes. Keep the socket
            // recoverable while the screen remains open.
            .setReconnectionAttempts(20)
            .setReconnectionDelay(1000)
            .setTimeout(8000)
            .setAuth({
              if (token != null && token.isNotEmpty)
                'token': token.startsWith('Bearer ') ? token : 'Bearer $token',
            })
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

      _socket!.on('registration:update', (data) {
        _log.info('Socket tournament registration:update received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _registrationUpdateController.add(parsed);
        }
      });
      _socket!.on('scoreboard:visibility', (data) {
        _log.info('Socket scoreboard:visibility received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _scoreboardVisibilityController.add(parsed);
        }
      });
      _socket!.on('overlay:visibility', (data) {
        _log.info('Socket overlay:visibility received');
        final parsed = _parsePayload(data);
        if (parsed != null) {
          _overlayVisibilityController.add(parsed);
        }
      });

      _socket!.onDisconnect((_) => _log.info('Match Socket disconnected'));
      _socket!.onError(
        (err) => _log.error('Match Socket error', err.toString()),
      );

      _socket!.connect();
    } catch (e, stack) {
      _log.error('Lỗi kết nối match socket', e, stack);
    }
  }

  /// Theo dõi một trận sau khi socket đã được khởi tạo.
  ///
  /// Tách khỏi [connect] để các màn hình danh sách có thể đăng ký nhiều
  /// phòng trận mà không tạo ra nhiều lần kết nối cạnh tranh nhau.
  void join(String matchId) {
    final normalizedMatchId = matchId.trim();
    if (normalizedMatchId.isEmpty) return;
    _matchRooms.retain(normalizedMatchId);
    if (_socket?.connected == true) {
      _socket!.emit('joinMatch', normalizedMatchId);
    }
  }

  void leave(String matchId) {
    if (_matchRooms.release(matchId) && _socket?.connected == true) {
      _log.info('Leaving match $matchId');
      _socket!.emit('leaveMatch', matchId);
    }
    _releaseIdleConnection();
  }

  void joinTournament(String tournamentId) {
    _tournamentRooms.retain(tournamentId);
    if (_socket?.connected == true) {
      _socket!.emit('joinTournament', tournamentId);
    }
  }

  void leaveTournament(String tournamentId) {
    if (_tournamentRooms.release(tournamentId) && _socket?.connected == true) {
      _socket!.emit('leaveTournament', tournamentId);
    }
    _releaseIdleConnection();
  }

  void joinClubMatchSession(String sessionId) {
    _clubSessionRooms.retain(sessionId);
    if (_socket?.connected == true) {
      _socket!.emit('joinClubMatchSession', sessionId);
    }
  }

  void leaveClubMatchSession(String sessionId) {
    if (_clubSessionRooms.release(sessionId) && _socket?.connected == true) {
      _socket!.emit('leaveClubMatchSession', sessionId);
    }
    _releaseIdleConnection();
  }

  void joinClubCommunity(String communityId) {
    final normalizedCommunityId = communityId.trim();
    if (normalizedCommunityId.isEmpty) return;
    _clubCommunityRooms.retain(normalizedCommunityId);
    if (_socket?.connected == true) {
      _socket!.emit('joinClubCommunity', normalizedCommunityId);
    }
  }

  void leaveClubCommunity(String communityId) {
    final normalizedCommunityId = communityId.trim();
    if (normalizedCommunityId.isEmpty) return;
    if (_clubCommunityRooms.release(normalizedCommunityId) &&
        _socket?.connected == true) {
      _socket!.emit('leaveClubCommunity', normalizedCommunityId);
    }
    _releaseIdleConnection();
  }

  void disconnect() {
    _connectionGeneration++;
    _connectionInFlight = null;
    if (_socket != null) {
      _log.info('Disconnecting match socket');
      _socket!.disconnect();
      _socket = null;
    }
    _matchRooms.clear();
    _tournamentRooms.clear();
    _clubSessionRooms.clear();
    _clubCommunityRooms.clear();
  }

  /// Ngắt socket khi không còn phòng nào được giữ.
  ///
  /// Backend ngắt client không ở phòng nào sau 30 giây (`live-score.gateway.ts`,
  /// `client.disconnect(true)`). Lần ngắt đó đóng cả kết nối engine.io dùng chung,
  /// nên socket_io_client ném `WebSocketConnectionClosed` mà app không bắt được.
  /// Không còn phòng thì không có lý do giữ socket.
  void _releaseIdleConnection() {
    if (_connectionInFlight != null || _socket == null) return;
    if (!_matchRooms.isEmpty ||
        !_tournamentRooms.isEmpty ||
        !_clubSessionRooms.isEmpty ||
        !_clubCommunityRooms.isEmpty) {
      return;
    }
    disconnect();
  }

  void _joinTrackedRooms() {
    final socket = _socket;
    if (socket?.connected != true) return;
    for (final matchId in _matchRooms.ids) {
      socket!.emit('joinMatch', matchId);
    }
    for (final tournamentId in _tournamentRooms.ids) {
      socket!.emit('joinTournament', tournamentId);
    }
    for (final sessionId in _clubSessionRooms.ids) {
      socket!.emit('joinClubMatchSession', sessionId);
    }
    for (final communityId in _clubCommunityRooms.ids) {
      socket!.emit('joinClubCommunity', communityId);
    }
  }
}
