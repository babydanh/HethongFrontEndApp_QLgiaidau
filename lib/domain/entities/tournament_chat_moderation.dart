/// Mute lengths the server accepts (`POST /chat/rooms/:id/mutes`), in minutes.
const List<int> kChatMuteMinutes = [15, 60, 1440];

/// Largest slow-mode gap a moderator may set, in seconds.
const int kChatSlowModeMaxSeconds = 60;

DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

/// One row of `GET /chat/rooms/:id/participants` (moderators only).
class ChatRoomMember {
  const ChatRoomMember({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.registration,
    this.online = false,
    this.kicked = false,
    this.mutedUntil,
  });

  final String userId;
  final String? fullName;
  final String? avatarUrl;

  /// `APPROVED` | `PENDING` | `STAFF`.
  final String? registration;
  final bool online;
  final bool kicked;
  final DateTime? mutedUntil;

  bool isMutedAt(DateTime now) =>
      mutedUntil != null && mutedUntil!.isAfter(now);

  factory ChatRoomMember.fromJson(Map<String, dynamic> json) => ChatRoomMember(
    userId: json['userId']?.toString() ?? '',
    fullName: _text(json['fullName']),
    avatarUrl: _text(json['avatarUrl']),
    registration: _text(json['registration']),
    online: json['online'] == true,
    kicked: json['kicked'] == true,
    mutedUntil: _date(json['mutedUntil']),
  );
}

class ChatRoomMemberPage {
  const ChatRoomMemberPage({required this.items, this.nextCursor});

  final List<ChatRoomMember> items;
  final String? nextCursor;
}

/// One row of `GET /chat/rooms/:id/kicks`. Old servers send `createdAt`
/// instead of `kickedAt` and no `kickedByName`.
class ChatRoomKick {
  const ChatRoomKick({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.kickedByName,
    this.kickedAt,
  });

  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final String? kickedByName;
  final DateTime? kickedAt;

  factory ChatRoomKick.fromJson(Map<String, dynamic> json) => ChatRoomKick(
    userId: json['userId']?.toString() ?? '',
    fullName: _text(json['fullName']),
    avatarUrl: _text(json['avatarUrl']),
    kickedByName: _text(json['kickedByName']),
    kickedAt: _date(json['kickedAt'] ?? json['createdAt']),
  );
}
