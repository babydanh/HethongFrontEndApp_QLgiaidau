import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider cho SocketService (kết nối WebSocket realtime).
final socketServiceProvider = Provider<SocketService>((ref) {
  final tokenManager = ref.read(tokenManagerProvider);
  return SocketService(tokenManager: tokenManager);
});
