import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_undo.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:flutter_test/flutter_test.dart';

ScoreUndoStep _step(int p1, {int courtDepth = 0, int sets = 0}) => ScoreUndoStep(
  rally: RallySetState(currentP1: p1),
  serve: const PickleballServeState(),
  court: CourtState(history: List.filled(courtDepth, const CourtState())),
  finishedSetCount: sets,
);

void main() {
  group('TC-UNDO-APP-01 undo order', () {
    test('nothing to undo with no step and no court history', () {
      expect(
        resolveUndoAction(const [], courtDepth: 0, finishedSetCount: 0),
        isNull,
      );
    });

    test('a reload (no step, saved court history) still undoes the court', () {
      expect(
        resolveUndoAction(const [], courtDepth: 3, finishedSetCount: 0),
        UndoAction.court,
      );
    });

    test('steps are taken back one by one, newest first, as often as needed', () {
      var stack = [_step(0), _step(1), _step(2)];
      final seen = <int>[];
      while (resolveUndoAction(stack, courtDepth: 0, finishedSetCount: 0) ==
          UndoAction.score) {
        seen.add(stack.last.rally.currentP1);
        stack = stack.sublist(0, stack.length - 1);
      }
      expect(seen, [2, 1, 0]);
    });

    test('a court edit made after the last scoring step goes first', () {
      final stack = [_step(1, courtDepth: 2)];
      expect(
        resolveUndoAction(stack, courtDepth: 3, finishedSetCount: 0),
        UndoAction.court,
      );
      expect(
        resolveUndoAction(stack, courtDepth: 2, finishedSetCount: 0),
        UndoAction.score,
      );
    });

    test('a step from before a finished game is not restored', () {
      final stack = [_step(4, sets: 0)];
      expect(
        resolveUndoAction(stack, courtDepth: 0, finishedSetCount: 1),
        isNull,
      );
    });

    test('the stack is capped, oldest dropped', () {
      var stack = <ScoreUndoStep>[];
      for (var n = 0; n < undoStepLimit + 10; n++) {
        stack = pushUndoStep(stack, _step(n));
      }
      expect(stack.length, undoStepLimit);
      expect(stack.first.rally.currentP1, 10);
      expect(stack.last.rally.currentP1, undoStepLimit + 9);
    });
  });
}
