import 'package:app_quanly_giaidau/core/services/chat_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'dispose gỡ mọi callback để socket đóng sau đó không gọi ngược vào màn đã hủy',
    () {
      final service = ChatSocketService(TokenManager());
      service
        ..onConnection = (_) {}
        ..onMessage = (_) {}
        ..onTyping = (_) {}
        ..onReaction = (_) {}
        ..onPollVoted = (_) {}
        ..onRevoked = (_) {}
        ..onPinned = (_) {}
        ..onUserStatus = (_) {}
        ..onRoomRead = (_) {}
        ..onRoomActivity = (_) {};

      service.dispose();

      expect(service.onConnection, isNull);
      expect(service.onMessage, isNull);
      expect(service.onTyping, isNull);
      expect(service.onReaction, isNull);
      expect(service.onPollVoted, isNull);
      expect(service.onRevoked, isNull);
      expect(service.onPinned, isNull);
      expect(service.onUserStatus, isNull);
      expect(service.onRoomRead, isNull);
      expect(service.onRoomActivity, isNull);
    },
  );
}
