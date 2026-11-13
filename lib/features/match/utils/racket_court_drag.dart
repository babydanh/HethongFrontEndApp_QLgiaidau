/// Drop rules for the badminton and tennis court: the pickleball rules
/// ([resolveCourtDrop]) minus the drops those sports do not allow.
library;

import 'court_drag.dart';

/// Returns the action for dropping [source] on [target], or null when the drop
/// must do nothing.
///
/// Blocked on top of [resolveCourtDrop]: any drop once the match is
/// [finished]; swapping cells in singles; swapping the serving pair in tennis
/// doubles (the serve order is fixed, only the receiving pair may swap).
CourtDropAction? racketResolveDrop({
  required CourtDragSource source,
  required CourtDropTarget target,
  required int? servingTeam,
  required bool isDoubles,
  required bool isTennis,
  required bool finished,
}) {
  if (finished) return null;
  final action = resolveCourtDrop(source, target, servingTeam);
  if (action is! SwapPlaces) return action;
  if (!isDoubles) return null;
  if (isTennis && action.team == servingTeam) return null;
  return action;
}
