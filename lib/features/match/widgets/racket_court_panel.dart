import 'dart:async';

import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/domain/services/rally_serve_rules.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/services/tennis_serve_state.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_racket.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_tennis.dart';
import 'package:app_quanly_giaidau/features/match/utils/racket_court_drag.dart';
import 'package:app_quanly_giaidau/features/match/widgets/racket_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Badminton and tennis scoring on a court: wires the score panel state to
/// [RacketCourtView]. Strict matches only; Lite cards keep the plain panels.
class RacketCourtPanel extends ConsumerStatefulWidget {
  const RacketCourtPanel({
    super.key,
    required this.params,
    this.isReadOnly = false,
  });

  final MatchControlParams params;
  final bool isReadOnly;

  @override
  ConsumerState<RacketCourtPanel> createState() => _RacketCourtPanelState();
}

class _RacketCourtPanelState extends ConsumerState<RacketCourtPanel> {
  /// The referee chose "Choose server" in the menu: the next tap on a player
  /// corrects who serves.
  bool _correcting = false;

  ScorePanelNotifier get _notifier =>
      ref.read(scorePanelNotifierProvider(widget.params).notifier);

  void _score(bool tennis, int team, bool increment) {
    final first = team == 1;
    if (tennis) {
      increment
          ? _notifier.tennisAwardPoint(first)
          : _notifier.tennisRemovePoint(first);
      return;
    }
    increment
        ? _notifier.rallyAddPoint(first)
        : _notifier.rallyRemovePoint(first);
  }

  void _pickServer(int team, int playerIndex) {
    // Stay in the correcting mode when the pick was refused, so the referee
    // can tap another player.
    final changed = _notifier.racketCorrectServer(team, playerIndex);
    if (changed && _correcting) setState(() => _correcting = false);
  }

  /// Tennis doubles tap: picks the server at once while the team has not
  /// chosen, otherwise opens the menu of what the rules still allow.
  Future<void> _tapTennis(int team, int index, String title) async {
    if (_correcting) {
      _pickServer(team, index);
      return;
    }
    final state = ref.read(scorePanelNotifierProvider(widget.params));
    if (state.racketTennisQuickPick(team)) {
      _notifier.racketApplyTennisAction(
        TennisCellAction(
          TennisCellActionKind.pickServer,
          team: team,
          playerIndex: index,
        ),
      );
      return;
    }
    final picked = await showDialog<TennisCellAction>(
      context: context,
      builder: (_) => _TennisMenu(
        title: title,
        actions: state.racketTennisActions(team, index),
      ),
    );
    if (picked != null && mounted) _notifier.racketApplyTennisAction(picked);
  }

  /// "Choose server" of the ⋯ menu: the next tap on a player corrects who serves.
  void _chooseServer() => setState(() => _correcting = true);

  /// Reminder under the chips: why nothing is highlighted, or what to tap.
  String? _banner(
    AppLocalizations l10n,
    ScorePanelState state,
    bool tennis,
    bool doubles,
    RallySetState rally,
  ) {
    if (_correcting) return l10n.racketPickServerHint;
    if (state.tennisDoubles) {
      return switch (state.racketTennisHint) {
        TennisHint.pickServer => l10n.racketTennisHintPickServer,
        TennisHint.swapReceiver => l10n.racketTennisHintSwapReceiver,
        TennisHint.decidingReceiver => l10n.racketTennisHintDeciding,
        null =>
          state.tennisMatchTiebreakDue ? l10n.cbdTennisMatchTiebreak : null,
      };
    }
    if (state.racketCanPickFirstServer) return l10n.racketPickFirstHint;
    // After a minus, doubles may know the serving team but not the player.
    if (state.racketServerTeam == null ||
        (doubles && state.racketServerPlayerIndex(doubles: true) == null)) {
      return l10n.racketServeUnknown;
    }
    if (tennis) {
      return state.tennisMatchTiebreakDue ? l10n.cbdTennisMatchTiebreak : null;
    }
    return switch (rallyServeBanner(
      kind: SportRuleKind.badminton,
      p1: rally.currentP1,
      p2: rally.currentP2,
      gameIndex: state.finishedSets.length,
      bestOf: state.config.bestOf,
      lastWinner: rally.lastWinner,
    )) {
      RallyBreak.none => null,
      RallyBreak.interval60 => l10n.cbdRallyBreak60,
      RallyBreak.interval60ChangeEnds => l10n.cbdRallyBreak60ChangeEnds,
      RallyBreak.betweenGames => l10n.cbdRallyBreakBetweenGames,
      RallyBreak.changeEnds => l10n.cbdRallyChangeEnds,
    };
  }

  List<String> _chips(
    AppLocalizations l10n,
    ScorePanelState state,
    bool tennis,
    List<String> names,
  ) {
    final config = state.config;
    if (!tennis) {
      final r = state.rally ?? const RallySetState();
      if (rallyGoldenPoint(
        p1: r.currentP1,
        p2: r.currentP2,
        cap: config.maxPoints,
      )) {
        return [l10n.racketGoldenPoint(config.maxPoints)];
      }
      final team = rallySetPointTeam(
        p1: r.currentP1,
        p2: r.currentP2,
        target: config.pointsPerSet,
        winByTwo: config.mustWinByTwo,
        cap: config.maxPoints,
      );
      return [if (team != 0) l10n.racketGamePoint(names[team - 1])];
    }
    final t = state.tennis ?? const TennisGameState();
    if (state.tennisInTiebreak) {
      return [l10n.racketTiebreakServe(state.tennisPlan.tiebreakTarget)];
    }
    final a = t.team1GamePoints;
    final b = t.team2GamePoints;
    if (a < 3 || b < 3) return const [];
    if (config.noAd) return a == b ? [l10n.racketDecidingPoint] : const [];
    if (a == b) return [l10n.tennisDeuce];
    return [l10n.racketAdvantage(names[a > b ? 0 : 1])];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(scorePanelNotifierProvider(widget.params));
    final match = ref.watch(singleMatchProvider(widget.params)).value;
    final tennis = state.config.kind == SportRuleKind.tennis;
    final players1 = match == null
        ? const <String>[]
        : [for (final p in matchSidePlayers(match, 1)) p.fullName];
    final players2 = match == null
        ? const <String>[]
        : [for (final p in matchSidePlayers(match, 2)) p.fullName];
    final name1 =
        (match == null ? null : matchSideTeamName(match, 1)) ??
        l10n.pickleballTeam1;
    final name2 =
        (match == null ? null : matchSideTeamName(match, 2)) ??
        l10n.pickleballTeam2;
    final doubles = players1.length >= 2 || players2.length >= 2;
    final rally = state.rally ?? const RallySetState();
    final t = state.tennis ?? const TennisGameState();
    final inTiebreak = state.tennisInTiebreak;
    final score1 = tennis
        ? formatTennisPoint(t.team1GamePoints, t.team2GamePoints, inTiebreak)
        : '${rally.currentP1}';
    final score2 = tennis
        ? formatTennisPoint(t.team2GamePoints, t.team1GamePoints, inTiebreak)
        : '${rally.currentP2}';
    final server = state.racketServerTeam;
    final call = server == 2 ? '$score2-$score1' : '$score1-$score2';
    final last = state.finishedSets.isEmpty ? null : state.finishedSets.last;
    final live = last == null || last.isFinished ? null : last;
    final setText = tennis
        ? '${l10n.racketGames(live?.score1 ?? 0, live?.score2 ?? 0)}'
              ' · ${state.team1SetWins}-${state.team2SetWins}'
        : l10n.racketGames(state.team1SetWins, state.team2SetWins);
    final finished = state.isMatchComplete;
    final readOnly = widget.isReadOnly || finished;
    final picking =
        !readOnly && (_correcting || state.racketCanPickFirstServer);
    final tennisDoubles = !readOnly && doubles && state.tennisDoubles;
    String title(int team, int i) {
      final players = team == 1 ? players1 : players2;
      return i < players.length && players[i].trim().isNotEmpty
          ? players[i]
          : (team == 1 ? name1 : name2);
    }

    return LayoutBuilder(
      builder: (context, box) => RacketCourtView(
        cells: state.racketCells(doubles: doubles),
        team1Players: players1,
        team2Players: players2,
        team1Name: name1,
        team2Name: name2,
        endsFlipped: state.racketEndsFlipped,
        axis: box.maxWidth >= box.maxHeight ? Axis.horizontal : Axis.vertical,
        scoreText1: score1,
        scoreText2: score2,
        servingTeam: server,
        call: call,
        setText: setText,
        chips: _chips(l10n, state, tennis, [name1, name2]),
        banner: _banner(l10n, state, tennis, doubles, rally),
        canUndo: state.canRacketUndo,
        onScore: readOnly ? null : (team, inc) => _score(tennis, team, inc),
        onUndo: _notifier.racketUndoStep,
        onSwitchEnds: _notifier.racketSwitchEnds,
        onMenu: _chooseServer,
        sportIcon: tennis ? 'tennis' : 'badminton',
        onPickServer: tennisDoubles
            ? (team, i) => unawaited(_tapTennis(team, i, title(team, i)))
            : picking
            ? _pickServer
            : null,
        resolve: (source, target) => racketResolveDrop(
          source: source,
          target: target,
          servingTeam: server,
          isDoubles: doubles,
          isTennis: tennis,
          finished: finished,
        ),
        onDrop: _notifier.racketApplyDrop,
      ),
    );
  }
}

/// Tennis doubles menu for one player: the actions the rules allow now, with
/// a short note when the team is locked and only corrections remain.
class _TennisMenu extends StatelessWidget {
  const _TennisMenu({required this.title, required this.actions});

  final String title;
  final List<TennisCellAction> actions;

  String _label(
    AppLocalizations l10n,
    TennisCellActionKind kind,
  ) => switch (kind) {
    TennisCellActionKind.pickServer => l10n.racketTennisActionServe,
    TennisCellActionKind.correctServer => l10n.racketTennisActionCorrectServer,
    TennisCellActionKind.pickReceiveRight =>
      l10n.racketTennisActionSwapReceiver,
    TennisCellActionKind.fixReceiver => l10n.racketTennisActionFixReceiver,
    TennisCellActionKind.decidingReceiver => l10n.racketTennisActionDeciding,
    TennisCellActionKind.switchEnds => l10n.pickleballCourtActionSwitchEnds,
  };

  String? _note(AppLocalizations l10n, TennisCellActionKind kind) =>
      switch (kind) {
        TennisCellActionKind.correctServer => l10n.racketTennisNoteServeLocked,
        TennisCellActionKind.fixReceiver => l10n.racketTennisNoteReceiveLocked,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notes = [for (final a in actions) ?_note(l10n, a.kind)];
    return AlertDialog(
      scrollable: true,
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          for (final action in actions)
            FilledButton(
              onPressed: () => Navigator.pop(context, action),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(
                _label(l10n, action.kind),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          for (final note in notes)
            Text(note, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
