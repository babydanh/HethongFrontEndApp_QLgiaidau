class BracketSlotDragData {
  final String matchId;
  final String slot;
  final String? participantId;
  final bool isBye;

  const BracketSlotDragData({
    required this.matchId,
    required this.slot,
    this.participantId,
    this.isBye = false,
  });

  /// Backend only accepts real tournament participant IDs in slot mutations.
  /// Empty/TBD/BYE are presentation placeholders and must not be dragged.
  bool get hasParticipant {
    final value = participantId?.trim();
    if (value == null || value.isEmpty) return false;
    final normalized = value.toUpperCase();
    return normalized != 'BYE' && normalized != 'TBD' && !isBye;
  }

  /// A non-BYE empty slot can receive a MOVE operation.
  bool get canReceiveMove => !hasParticipant && !isBye;

  @override
  bool operator ==(Object other) =>
      other is BracketSlotDragData &&
      other.matchId == matchId &&
      other.slot == slot;

  @override
  int get hashCode => Object.hash(matchId, slot);
}

class BracketSlotDropResult {
  final BracketSlotDragData source;
  final BracketSlotDragData target;

  const BracketSlotDropResult({required this.source, required this.target});
}

typedef BracketSlotDropCallback =
    Future<void> Function(
      BracketSlotDragData source,
      BracketSlotDragData target,
    );
