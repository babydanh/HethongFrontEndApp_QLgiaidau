import 'package:app_quanly_giaidau/domain/entities/swiss.dart';

sealed class SwissSlotRef {
  const SwissSlotRef();
}

class SwissPairSlot extends SwissSlotRef {
  const SwissPairSlot(this.pairIndex, this.side);

  final int pairIndex;
  final int side;
}

class SwissByeSlot extends SwissSlotRef {
  const SwissByeSlot();
}

class SwissPoolSlot extends SwissSlotRef {
  const SwissPoolSlot();
}

class SwissSitOutSlot extends SwissSlotRef {
  const SwissSitOutSlot();
}

class SwissDraft {
  const SwissDraft({
    required this.pairs,
    required this.byeId,
    required this.sitOutIds,
    required this.poolIds,
  });

  final List<({String? p1, String? p2})> pairs;
  final String? byeId;
  final List<String> sitOutIds;
  final List<String> poolIds;
}

class _DraftLocation {
  const _DraftLocation(this.slot, [this.index = -1]);

  final SwissSlotRef slot;
  final int index;
}

SwissDraft draftFromPreview(SwissPreview preview) {
  final pairs = [
    for (final pair in preview.pairs)
      (p1: pair.participant1Id, p2: pair.participant2Id),
  ];
  final assigned = <String>{};
  for (final pair in pairs) {
    assigned.add(pair.p1);
    assigned.add(pair.p2);
  }
  if (preview.byeParticipantId != null) assigned.add(preview.byeParticipantId!);
  assigned.addAll(preview.sitOutParticipantIds);

  return SwissDraft(
    pairs: pairs,
    byeId: preview.byeParticipantId,
    sitOutIds: [...preview.sitOutParticipantIds],
    poolIds: [
      for (final participant in preview.participants)
        if (assigned.add(participant.id)) participant.id,
    ],
  );
}

SwissDraft moveParticipant(
  SwissDraft draft,
  String participantId,
  SwissSlotRef to,
) {
  final source = _findLocation(draft, participantId);
  if (source == null || !_validTarget(draft, to)) return draft;
  if (_sameSlot(source.slot, to) ||
      (source.slot is SwissPoolSlot && to is SwissPoolSlot) ||
      (source.slot is SwissSitOutSlot && to is SwissSitOutSlot)) {
    return draft;
  }

  final displaced = _targetParticipant(draft, to);
  final pairs = [...draft.pairs];
  final sitOutIds = [...draft.sitOutIds];
  final poolIds = [...draft.poolIds];
  var byeId = draft.byeId;
  switch (source.slot) {
    case SwissPairSlot(:final pairIndex, :final side):
      _setPair(pairs, pairIndex, side, displaced);
    case SwissByeSlot():
      byeId = displaced;
    case SwissPoolSlot():
      poolIds.removeAt(source.index);
    case SwissSitOutSlot():
      sitOutIds.removeAt(source.index);
  }
  switch (to) {
    case SwissPairSlot(:final pairIndex, :final side):
      _setPair(pairs, pairIndex, side, participantId);
    case SwissByeSlot():
      byeId = participantId;
    case SwissPoolSlot():
      poolIds.add(participantId);
    case SwissSitOutSlot():
      sitOutIds.add(participantId);
  }
  if (displaced != null && source.slot is SwissPoolSlot) {
    poolIds.add(displaced);
  } else if (displaced != null && source.slot is SwissSitOutSlot) {
    sitOutIds.add(displaced);
  }

  return SwissDraft(
    pairs: pairs,
    byeId: byeId,
    sitOutIds: sitOutIds,
    poolIds: poolIds,
  );
}

bool isDraftComplete(SwissDraft draft) =>
    draft.poolIds.isEmpty &&
    draft.pairs.every(
      (pair) =>
          (pair.p1 == null && pair.p2 == null) ||
          (pair.p1 != null && pair.p2 != null),
    );

SwissRoundDraftRequest draftToRequest(
  SwissDraft draft, {
  required String divisionId,
  String? stageId,
}) => SwissRoundDraftRequest(
  divisionId: divisionId,
  stageId: stageId,
  pairs: [
    for (final pair in draft.pairs)
      if (pair.p1 != null && pair.p2 != null)
        (participant1Id: pair.p1!, participant2Id: pair.p2!),
  ],
  byeParticipantId: draft.byeId,
  sitOutParticipantIds: [...draft.sitOutIds],
);

_DraftLocation? _findLocation(SwissDraft draft, String participantId) {
  for (var i = 0; i < draft.pairs.length; i++) {
    final pair = draft.pairs[i];
    if (pair.p1 == participantId) return _DraftLocation(SwissPairSlot(i, 1));
    if (pair.p2 == participantId) return _DraftLocation(SwissPairSlot(i, 2));
  }
  if (draft.byeId == participantId) return const _DraftLocation(SwissByeSlot());
  for (var i = 0; i < draft.poolIds.length; i++) {
    if (draft.poolIds[i] == participantId) {
      return _DraftLocation(const SwissPoolSlot(), i);
    }
  }
  for (var i = 0; i < draft.sitOutIds.length; i++) {
    if (draft.sitOutIds[i] == participantId) {
      return _DraftLocation(const SwissSitOutSlot(), i);
    }
  }
  return null;
}

bool _validTarget(SwissDraft draft, SwissSlotRef slot) => switch (slot) {
  SwissPairSlot(:final pairIndex, :final side) =>
    pairIndex >= 0 &&
        pairIndex < draft.pairs.length &&
        (side == 1 || side == 2),
  SwissByeSlot() || SwissPoolSlot() || SwissSitOutSlot() => true,
};

bool _sameSlot(SwissSlotRef first, SwissSlotRef second) =>
    switch ((first, second)) {
      (
        SwissPairSlot(:final pairIndex, :final side),
        SwissPairSlot(pairIndex: final otherIndex, side: final otherSide),
      ) =>
        pairIndex == otherIndex && side == otherSide,
      (SwissByeSlot(), SwissByeSlot()) ||
      (SwissPoolSlot(), SwissPoolSlot()) ||
      (SwissSitOutSlot(), SwissSitOutSlot()) => true,
      _ => false,
    };

String? _targetParticipant(SwissDraft draft, SwissSlotRef slot) =>
    switch (slot) {
      SwissPairSlot(:final pairIndex, :final side) =>
        side == 1 ? draft.pairs[pairIndex].p1 : draft.pairs[pairIndex].p2,
      SwissByeSlot() => draft.byeId,
      SwissPoolSlot() || SwissSitOutSlot() => null,
    };

void _setPair(
  List<({String? p1, String? p2})> pairs,
  int pairIndex,
  int side,
  String? participantId,
) {
  final pair = pairs[pairIndex];
  pairs[pairIndex] = side == 1
      ? (p1: participantId, p2: pair.p2)
      : (p1: pair.p1, p2: participantId);
}

class SwissDraftHistory {
  SwissDraftHistory(SwissDraft initial) : _current = initial;

  SwissDraft _current;
  final List<SwissDraft> _previous = [];

  bool get canUndo => _previous.isNotEmpty;
  SwissDraft get current => _current;

  void push(SwissDraft next) {
    _previous.add(_current);
    _current = next;
  }

  SwissDraft undo() {
    if (_previous.isNotEmpty) _current = _previous.removeLast();
    return _current;
  }

  void reset(SwissDraft to) {
    _previous.clear();
    _current = to;
  }
}
