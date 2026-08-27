import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';

void main() {
  test('referee-editable football phases exclude terminal COMPLETED', () {
    expect(footballEditablePhases, isNot(contains('COMPLETED')));
    expect(footballEditablePhases, contains('PENALTY_SHOOTOUT'));
  });

  test('Football completion semantics do not require time or phase', () {
    const state = FootballLiveState(
      team1Goals: 2,
      team2Goals: 1,
      phase: 'FIRST_HALF',
      minute: 0,
      addedMinute: 0,
    );

    expect(state.isMatchComplete, isTrue);
    expect(state.winnerTeam, 1);
  });

  test('ScorePanelState preserves server terminal signal independently', () {
    const config = SportConfig(
      kind: SportRuleKind.football,
      scoringModel: SportScoringModel.rallyPointSet,
      bestOf: 1,
      setsToWin: 1,
      pointsPerSet: 0,
      mustWinByTwo: false,
      maxPoints: 0,
      tiebreakAt: 0,
    );
    const state = ScorePanelState(config: config);
    final terminal = state.copyWith(isServerTerminal: true);

    expect(state.isServerTerminal, isFalse);
    expect(terminal.isServerTerminal, isTrue);
  });

  test('Football panel commits time on change and locks terminal controls', () {
    final panel = File(
      'lib/features/match/widgets/football_score_panel.dart',
    ).readAsStringSync();

    expect(panel, contains('final isLocked'));
    expect(panel, contains('state.isServerTerminal'));
    expect(panel, contains('readOnly: widget.disabled'));
    expect(panel, contains('final parsed = int.tryParse(value)'));
    expect(panel, contains("? const ['COMPLETED']"));
  });

  test('Football completion aborts when pre-completion score flush fails', () {
    final notifier = File(
      'lib/features/match/notifiers/score_panel_notifier.dart',
    ).readAsStringSync();

    expect(notifier, contains('Future<bool> _flushPendingFootballSync()'));
    expect(
      notifier,
      contains('final flushed = await _flushPendingFootballSync()'),
    );
    expect(notifier, contains('if (!flushed)'));
    expect(notifier, contains('scorePanel_footballSyncError'));
  });
}
