/// Pure drop rules for the draggable pickleball court: no Flutter, no network.
/// Same rules as the Web `resolveCourtDrop`, agreed on one point: with no
/// serving team there is no ball, so a ball drop does nothing in both apps.
library;

/// What is being dragged: a player chip or the serving ball.
enum CourtDragKind { player, ball }

/// The dragged item. [team] is 1 or 2, [playerIndex] is 0 or 1. For a ball it
/// is the player currently holding it.
class CourtDragSource {
  const CourtDragSource({
    required this.kind,
    required this.team,
    required this.playerIndex,
  });

  final CourtDragKind kind;
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

/// Make [playerIndex] of [team] the server; [changesServingTeam] means the
/// drop hands the serve to the other team (side-out).
class SetServer extends CourtDropAction {
  const SetServer({
    required this.team,
    required this.playerIndex,
    required this.changesServingTeam,
  });

  final int team;
  final int playerIndex;
  final bool changesServingTeam;
}

/// Returns the action for dropping [source] on [target], or null when the
/// drop must do nothing. [servingTeam] is the team currently serving.
CourtDropAction? resolveCourtDrop(
  CourtDragSource source,
  CourtDropTarget target,
  int? servingTeam,
) {
  return switch (source.kind) {
    CourtDragKind.player => _resolvePlayerDrop(source, target),
    CourtDragKind.ball => _resolveBallDrop(source, target, servingTeam),
  };
}

CourtDropAction? _resolvePlayerDrop(
  CourtDragSource source,
  CourtDropTarget target,
) {
  if (target.team != source.team) return const SwitchEnds();
  if (target.playerIndex == source.playerIndex) return null;
  return SwapPlaces(source.team);
}

CourtDropAction? _resolveBallDrop(
  CourtDragSource source,
  CourtDropTarget target,
  int? servingTeam,
) {
  final playerIndex = target.playerIndex;
  if (playerIndex == null || servingTeam == null) return null;
  if (target.team == source.team && playerIndex == source.playerIndex) {
    return null;
  }
  return SetServer(
    team: target.team,
    playerIndex: playerIndex,
    changesServingTeam: target.team != servingTeam,
  );
}
