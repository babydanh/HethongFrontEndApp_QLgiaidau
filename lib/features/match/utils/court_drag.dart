/// Pure drop rules for the draggable pickleball court: no Flutter, no network.
/// Only players are dragged. Who serves is never picked by hand: the score and
/// the serve turns decide it.
library;

/// The dragged player chip. [team] is 1 or 2, [playerIndex] is 0 or 1.
class CourtDragSource {
  const CourtDragSource({required this.team, required this.playerIndex});

  final int team;
  final int playerIndex;
}

/// Where the item is dropped: on a player, or on the free area of a half.
class CourtDropTarget {
  const CourtDropTarget.player({
    required this.team,
    required int this.playerIndex,
  });

  const CourtDropTarget.half({required this.team}) : playerIndex = null;

  final int team;

  /// Null when the target is a half.
  final int? playerIndex;
}

/// Result of a drop, to be applied with the court actions.
sealed class CourtDropAction {
  const CourtDropAction();
}

/// Swap the left and right cells of [team].
class SwapPlaces extends CourtDropAction {
  const SwapPlaces(this.team);

  final int team;
}

/// Switch ends: both teams change halves, partners move along.
class SwitchEnds extends CourtDropAction {
  const SwitchEnds();
}

/// Returns the action for dropping [source] on [target], or null when the
/// drop must do nothing.
CourtDropAction? resolveCourtDrop(
  CourtDragSource source,
  CourtDropTarget target,
) {
  if (target.team != source.team) return const SwitchEnds();
  if (target.playerIndex == source.playerIndex) return null;
  return SwapPlaces(source.team);
}
