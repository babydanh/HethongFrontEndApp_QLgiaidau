import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/chat_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider cho SocketService (kết nối WebSocket realtime).
final socketServiceProvider = Provider<SocketService>((ref) {
  final tokenManager = ref.read(tokenManagerProvider);
  return SocketService(tokenManager: tokenManager);
});

/// Provider cho MatchSocketService (kết nối WebSocket /live realtime).
final matchSocketServiceProvider = Provider<MatchSocketService>((ref) {
  final service = MatchSocketService(tokenManager: ref.read(tokenManagerProvider));
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});




/// Builds the per-screen chat socket. A provider so tests can swap in a fake
/// that never opens a network connection.
final chatSocketFactoryProvider =
    Provider<ChatSocketService Function(TokenManager)>(
      (ref) => ChatSocketService.new,
    );
