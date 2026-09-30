/// Payload carried when a match is dragged from the pool onto a court.
///
/// Mirrors `BracketSlotDragData`: the label travels with the payload so the
/// drag feedback can render without holding on to the originating widget.
class CourtMatchDragData {
  const CourtMatchDragData({required this.matchId, required this.matchLabel});

  final String matchId;
  final String matchLabel;

  @override
  bool operator ==(Object other) =>
      other is CourtMatchDragData && other.matchId == matchId;

  @override
  int get hashCode => matchId.hashCode;
}

/// A court of the tournament, flattened out of its venue so it can be a drop
/// target on its own.
class TournamentCourtRef {
  const TournamentCourtRef({
    required this.id,
    required this.name,
    required this.venueName,
    this.address = '',
  });

  final String id;
  final String name;
  final String venueName;

  /// Venue address. Sent along with the court so a match scheduled here also
  /// carries a usable address on its card.
  final String address;

  @override
  bool operator ==(Object other) =>
      other is TournamentCourtRef && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
