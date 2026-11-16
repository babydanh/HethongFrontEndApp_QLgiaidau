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

  /// Not registered yet and registration is open: the icon opens sign-up.
  needsRegistration,

  /// Not registered and registration is closed: the icon only explains.
  registrationClosed,

  /// Registered, waiting for the organizer: can read, cannot write.
  pending,
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
    this.registrationOpen,
    this.registration,
    this.name,
    this.logoUrl,
  });

  final bool available;
  final String? reason;
  final String? roomId;
  final String? status;
  final bool canWrite;
  final String? role;
  final DateTime? closesAt;
  final DateTime? purgeAt;

  /// Only with `reason: NOT_REGISTERED`; null (old server) counts as open.
  final bool? registrationOpen;

  /// `APPROVED` | `PENDING` | `STAFF`; null on an old server.
  final String? registration;

  /// Tournament name and logo for the room header, when the server sends them.
  final String? name;
  final String? logoUrl;

  bool get isOrganizer => role == 'ORGANIZER';

  TournamentChatState get state {
    if (!available) {
      if (reason == 'KICKED') return TournamentChatState.kicked;
      if (reason != 'NOT_REGISTERED') return TournamentChatState.purged;
      return registrationOpen == false
          ? TournamentChatState.registrationClosed
          : TournamentChatState.needsRegistration;
    }
    if (roomId == null || roomId!.isEmpty) return TournamentChatState.purged;
    if (status == 'CLOSED') return TournamentChatState.closed;
    return registration == 'PENDING'
        ? TournamentChatState.pending
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
      registrationOpen: switch (json['registrationOpen']) {
        final bool v => v,
        _ => null,
      },
      registration: json['registration']?.toString(),
      name: json['name']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }
}
