import 'package:app_quanly_giaidau/data/models/chat_models.dart';
import 'package:app_quanly_giaidau/features/chat/read_receipt_state.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessageModel _message({
  String senderId = 'me',
  bool isMine = true,
  String createdAt = '2026-08-27T10:00:00.000Z',
}) {
  return ChatMessageModel(
    id: 'message-1',
    roomId: 'room-1',
    senderId: senderId,
    senderName: 'Sender',
    content: 'Hello',
    createdAt: DateTime.parse(createdAt),
    isMine: isMine,
  );
}

void main() {
  group('ChatReadReceiptState', () {
    test('includes a viewer at the exact timestamp boundary', () {
      final state = ChatReadReceiptState(
        participants: [
          ChatParticipant(
            id: 'viewer',
            fullName: 'Viewer',
            lastReadAt: DateTime.parse('2026-08-27T10:00:00.000Z'),
          ),
        ],
      );

      expect(
        state.viewersFor(_message(), currentUserId: 'me').map((p) => p.id),
        ['viewer'],
      );
    });

    test('excludes sender and current user', () {
      final timestamp = DateTime.parse('2026-08-27T10:01:00.000Z');
      final state = ChatReadReceiptState(
        participants: [
          ChatParticipant(id: 'me', fullName: 'Me', lastReadAt: timestamp),
          ChatParticipant(
            id: 'other',
            fullName: 'Other',
            lastReadAt: timestamp,
          ),
        ],
      );

      expect(
        state.viewersFor(_message(), currentUserId: 'me').map((p) => p.id),
        ['other'],
      );
      expect(
        state.viewersFor(
          _message(senderId: 'other', isMine: false),
          currentUserId: 'me',
        ),
        isEmpty,
      );
    });

    test('deduplicates participants by user ID', () {
      final state = ChatReadReceiptState(
        participants: [
          ChatParticipant(
            id: 'viewer',
            fullName: 'Old profile',
            lastReadAt: DateTime.parse('2026-08-27T10:01:00.000Z'),
          ),
          ChatParticipant(
            id: 'viewer',
            fullName: 'Current profile',
            lastReadAt: DateTime.parse('2026-08-27T10:02:00.000Z'),
          ),
        ],
      );

      final viewers = state.viewersFor(_message(), currentUserId: 'me');
      expect(viewers, hasLength(1));
      expect(viewers.single.fullName, 'Current profile');
    });

    test('zero viewers remains the sent state', () {
      final state = ChatReadReceiptState(
        participants: [
          ChatParticipant(
            id: 'viewer',
            fullName: 'Viewer',
            lastReadAt: DateTime.parse('2026-08-27T09:59:59.999Z'),
          ),
        ],
      );

      expect(state.viewersFor(_message(), currentUserId: 'me'), isEmpty);
    });

    test(
      'room read event updates state without accepting stale timestamps',
      () {
        final state = ChatReadReceiptState(
          participants: const [
            ChatParticipant(id: 'viewer', fullName: 'Viewer'),
          ],
        );

        expect(
          state.applyRoomReadEvent({
            'roomId': 'room-1',
            'userId': 'viewer',
            'readAt': '2026-08-27T10:00:00.000Z',
          }, roomId: 'room-1'),
          isTrue,
        );
        expect(state.viewersFor(_message(), currentUserId: 'me'), hasLength(1));
        expect(
          state.applyRoomReadEvent({
            'roomId': 'room-1',
            'userId': 'viewer',
            'readAt': '2026-08-27T09:59:00.000Z',
          }, roomId: 'room-1'),
          isFalse,
        );
        expect(
          state.applyRoomReadEvent({
            'roomId': 'another-room',
            'userId': 'viewer',
            'readAt': '2026-08-27T10:03:00.000Z',
          }, roomId: 'room-1'),
          isFalse,
        );
      },
    );
  });
}
