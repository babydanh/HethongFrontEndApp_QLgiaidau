import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/domain/services/rally_serve_rules.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
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
    _notifier.racketCorrectServer(team, playerIndex);
    if (_correcting) setState(() => _correcting = false);
  }

  Future<void> _openMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final choose = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.sports_tennis_rounded),
          title: Text(l10n.racketPickServer),
          onTap: () => Navigator.pop(sheet, true),
        ),
      ),
    );
    if (choose == true && mounted) setState(() => _correcting = true);
  }

  /// Reminder under the chips: why nothing is highlighted, or what to tap.
  String? _banner(
    AppLocalizations l10n,
    ScorePanelState state,
    bool tennis,
    RallySetState rally,
  ) {
    if (_correcting) return l10n.racketPickServerHint;
    if (state.racketCanPickFirstServer) return l10n.racketPickFirstHint;
    if (state.racketServerTeam == null) return l10n.racketServeUnknown;
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

    return LayoutBuilder(
      builder: (context, box) => RacketCourtView(
        cells: state.racketCells(doubles: doubles),
        team1Players: players1,
        team2Players: players2,
        team1Name: name1,
        team2Name: name2,
        endsFlipped: state.racketPick.endsFlipped,
        axis: box.maxWidth >= box.maxHeight ? Axis.horizontal : Axis.vertical,
        scoreText1: score1,
        scoreText2: score2,
        servingTeam: server,
        call: call,
        setText: setText,
        chips: _chips(l10n, state, tennis, [name1, name2]),
        banner: _banner(l10n, state, tennis, rally),
        canUndo: state.canRacketUndo,
        onScore: readOnly ? null : (team, inc) => _score(tennis, team, inc),
        onUndo: _notifier.racketUndoStep,
        onSwitchEnds: _notifier.racketSwitchEnds,
        onMenu: _openMenu,
        onPickServer: picking ? _pickServer : null,
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
