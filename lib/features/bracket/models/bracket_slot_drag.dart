class BracketSlotDragData {
  final String matchId;
  final String slot;
  final String? participantId;
  final bool isBye;

  /// The slot's match is live or finished (BYE matches excepted): locked in the
  /// app, which skips the backend's identity-swap path on finished matches.
  final bool isLocked;

  /// Display name carried by a holding-tray chip (slots read it from the match).
  final String? label;

  const BracketSlotDragData({
    required this.matchId,
    required this.slot,
    this.participantId,
    this.isBye = false,
    this.isLocked = false,
    this.label,
  });

  /// A participant parked in the holding tray: it belongs to no match slot.
  const BracketSlotDragData.tray({
    required String this.participantId,
    required String this.label,
  }) : matchId = '',
       slot = '',
       isBye = false,
       isLocked = false;

  bool get isFromTray => matchId.isEmpty;

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

typedef BracketSlotUnassignCallback =
    Future<void> Function(BracketSlotDragData slot);

/// Backend operation for dropping [source] on [target], or null when the drop
/// is a no-op (same slot, nothing to move, BYE target).
Map<String, String>? bracketSlotOperation(
  BracketSlotDragData source,
  BracketSlotDragData target,
) {
  if (!source.hasParticipant || target.isBye || source == target) return null;
  if (source.isLocked || target.isLocked) return null;
  if (source.isFromTray) {
    return {
      'operation': target.hasParticipant ? 'REPLACE' : 'ASSIGN',
      'matchId': target.matchId,
      'slot': target.slot,
      'participantId': source.participantId!,
    };
  }
  return {
    'operation': target.hasParticipant ? 'SWAP' : 'MOVE',
    'fromMatchId': source.matchId,
    'fromSlot': source.slot,
    'toMatchId': target.matchId,
    'toSlot': target.slot,
  };
}

Map<String, String> bracketUnassignOperation(BracketSlotDragData slot) => {
  'operation': 'UNASSIGN',
  'matchId': slot.matchId,
  'slot': slot.slot,
};
