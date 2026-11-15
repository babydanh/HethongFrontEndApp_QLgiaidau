/// What the hero chat icon of a tournament shows.
enum TournamentChatState {
  /// Anyone signed in can read and write.
  open,

  /// Read only (tournament finished + 7 days, or cancelled).
  closed,

  /// The organizer removed this user from the room.
  kicked,

  /// Room is gone or unavailable: the icon is hidden.
  purged,
}

/// Reply of `GET /tournaments/:id/chat-room`. The server decides the status
/// and write permission; the client never recomputes them from dates.
class TournamentChatRoom {
  const TournamentChatRoom({
    required this.available,
    this.reason,
    this.roomId,
    this.status,
    this.canWrite = false,
    this.role,
    this.closesAt,
    this.purgeAt,
  });

  final bool available;
  final String? reason;
  final String? roomId;
  final String? status;
  final bool canWrite;
  final String? role;
  final DateTime? closesAt;
  final DateTime? purgeAt;

  bool get isOrganizer => role == 'ORGANIZER';

  TournamentChatState get state {
    if (!available) {
      return reason == 'KICKED'
          ? TournamentChatState.kicked
          : TournamentChatState.purged;
    }
    if (roomId == null || roomId!.isEmpty) return TournamentChatState.purged;
    return status == 'CLOSED'
        ? TournamentChatState.closed
        : TournamentChatState.open;
  }

  factory TournamentChatRoom.fromJson(Map<String, dynamic> json) {
    return TournamentChatRoom(
      available: json['available'] == true,
      reason: json['reason']?.toString(),
      roomId: json['roomId']?.toString(),
      status: json['status']?.toString(),
      canWrite: json['canWrite'] == true,
      role: json['role']?.toString(),
      closesAt: DateTime.tryParse(json['closesAt']?.toString() ?? ''),
      purgeAt: DateTime.tryParse(json['purgeAt']?.toString() ?? ''),
    );
  }
}
