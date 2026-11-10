import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';

/// One scoring step the referee can take back (a point, a lose-serve or a
/// server pick): the points, the serve and the court as they were just before
/// it. Kept in the session only.
class ScoreUndoStep {
  const ScoreUndoStep({
    required this.rally,
    required this.serve,
    required this.court,
    required this.finishedSetCount,
  });

  final RallySetState rally;
  final PickleballServeState serve;
  final CourtState court;

  /// Sets already closed at that moment: a step from an earlier set can no
  /// longer be restored once a game has ended.
  final int finishedSetCount;
}

enum UndoAction { score, court }

/// Most steps kept; the oldest is dropped first.
const int undoStepLimit = 50;

List<ScoreUndoStep> pushUndoStep(List<ScoreUndoStep> stack, ScoreUndoStep step) {
  final next = [...stack, step];
  return next.length > undoStepLimit
      ? next.sublist(next.length - undoStepLimit)
      : next;
}

/// What one press of undo does, null when there is nothing to undo. A court
/// edit made after the newest scoring step goes first (the saved court history
/// grew since then); otherwise the newest scoring step is taken back; with no
/// step left it falls back to the court history.
UndoAction? resolveUndoAction(
  List<ScoreUndoStep> stack, {
  required int courtDepth,
  required int finishedSetCount,
}) {
  final top = stack.isEmpty ? null : stack.last;
  if (top == null || top.finishedSetCount != finishedSetCount) {
    return courtDepth > 0 ? UndoAction.court : null;
  }
  if (courtDepth > top.court.history.length) return UndoAction.court;
  return UndoAction.score;
}
