import 'package:app_quanly_giaidau/data/models/chat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-CHAT-UI-M-02 a SYSTEM message is flagged with its event', () {
    final msg = ChatMessageModel.fromJson({
      'id': 's1',
      'roomId': 'r1',
      'type': 'SYSTEM',
      'senderId': null,
      'content': 'An đã tham gia phòng',
      'metadata': {'event': 'JOINED', 'userId': 'u1', 'visibleTo': 'ALL'},
      'createdAt': '2026-11-16T10:00:00.000Z',
    });

    expect(msg.isSystem, isTrue);
    expect(msg.systemEvent, 'JOINED');
    expect(msg.content, 'An đã tham gia phòng');
  });

  test('TC-CHAT-UI-M-02 a plain TEXT message is not a system message', () {
    final msg = ChatMessageModel.fromJson({
      'id': 'm1',
      'roomId': 'r1',
      'type': 'TEXT',
      'senderId': 'u1',
      'content': 'Chào',
      'createdAt': '2026-11-16T10:00:00.000Z',
    });

    expect(msg.isSystem, isFalse);
    expect(msg.systemEvent, isNull);
  });

  test('TC-CHAT-UI-M-02 copyWith keeps the system flag', () {
    final msg = ChatMessageModel.fromJson({
      'id': 's1',
      'type': 'SYSTEM',
      'content': 'x',
      'metadata': {'event': 'KICKED'},
    });

    final copy = msg.copyWith(isPinned: true);

    expect(copy.isSystem, isTrue);
    expect(copy.systemEvent, 'KICKED');
  });
}
