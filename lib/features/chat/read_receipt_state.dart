import 'package:app_quanly_giaidau/data/models/chat_models.dart';

class ChatReadReceiptState {
  ChatReadReceiptState({Iterable<ChatParticipant> participants = const []}) {
    replaceParticipants(participants);
  }

  final Map<String, ChatParticipant> _participantsById = {};
  final Map<String, DateTime> _readAtByUserId = {};

  void replaceParticipants(Iterable<ChatParticipant> participants) {
    _participantsById.clear();
    _readAtByUserId.clear();
    for (final participant in participants) {
      final userId = participant.id.trim();
      if (userId.isEmpty) continue;
      _participantsById[userId] = participant;
      final readAt = participant.lastReadAt;
      if (readAt != null) _readAtByUserId[userId] = readAt;
    }
  }

  bool applyRoomReadEvent(Map<String, dynamic> event, {String? roomId}) {
    final eventRoomId = event['roomId']?.toString();
    if (roomId != null &&
        eventRoomId != null &&
        eventRoomId.isNotEmpty &&
        eventRoomId != roomId) {
      return false;
    }

    final userId = event['userId']?.toString().trim();
    final readAt = DateTime.tryParse(
      (event['readAt'] ?? event['lastReadAt'])?.toString() ?? '',
    );
    if (userId == null || userId.isEmpty || readAt == null) return false;

    final previous = _readAtByUserId[userId];
    if (previous != null && readAt.isBefore(previous)) return false;
    _readAtByUserId[userId] = readAt;
    return true;
  }

  List<ChatParticipant> viewersFor(
    ChatMessageModel message, {
    required String? currentUserId,
  }) {
    if (!message.isMine || currentUserId == null || currentUserId.isEmpty) {
      return const [];
    }

    final viewers = <ChatParticipant>[];
    for (final entry in _participantsById.entries) {
      final userId = entry.key;
      if (userId == currentUserId || userId == message.senderId) continue;
      final readAt = _readAtByUserId[userId];
      if (readAt != null && !readAt.isBefore(message.createdAt)) {
        viewers.add(entry.value);
      }
    }
    return viewers;
  }
}
