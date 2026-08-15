import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService {
  final TokenManager tokenManager;
  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;
  void Function(Map<String, dynamic>)? onMessage;
  void Function(Map<String, dynamic>)? onTyping;
  void Function(bool)? onConnection;

  ChatSocketService(this.tokenManager);

  Future<void> connect(String roomId) async {
    final token = await tokenManager.getAccessToken();
    if (token == null || token.isEmpty) return;
    final base = (dotenv.env['API_BASE_URL'] ?? '').replaceAll(RegExp(r'/api/v1/?$'), '');
    _socket?.disconnect();
    _socket = io.io('$base/chat', io.OptionBuilder().setTransports(['websocket', 'polling']).setExtraHeaders({'Authorization': 'Bearer $token'}).enableReconnection().build());
    _socket!.onConnect((_) { onConnection?.call(true); _socket!.emit('joinChatRoom', roomId); });
    _socket!.onDisconnect((_) => onConnection?.call(false));
    _socket!.on('chat:club:message', (data) { final map = _asMap(data); if (map.isNotEmpty) onMessage?.call(map); });
    _socket!.on('chat:typing', (data) { final map = _asMap(data); if (map.isNotEmpty) onTyping?.call(map); });
    _socket!.connect();
  }

  void send(String roomId, String content) { if (isConnected) _socket!.emit('sendMessage', {'roomId': roomId, 'content': content}); }
  void typing(String roomId, bool isTyping) { if (isConnected) _socket!.emit('typing', {'roomId': roomId, 'isTyping': isTyping}); }
  void disconnect(String roomId) { if (_socket?.connected == true) _socket!.emit('leaveChatRoom', roomId); _socket?.disconnect(); _socket?.close(); _socket = null; }
  Map<String, dynamic> _asMap(Object? value) => value is Map ? value.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};
}
