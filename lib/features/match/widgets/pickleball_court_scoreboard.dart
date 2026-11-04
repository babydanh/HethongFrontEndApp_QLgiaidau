import 'dart:async';
import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_drag_widgets.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_palette.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Scoreboard look of the referee's phone held sideways: light surface, black
// ink, every cell orange except the server's, which is blue.
const _surface = Color(0xFFF7F7F9);
const _ink = Color(0xFF1B1B1F);
const _endColor = Color(0xFFE5262C);
const _tagColor = Color(0xFFE9EDF3);
const _controlSize = 44.0;

/// Below this width the top and bottom rows shrink instead of overflowing.
const _minBarWidth = 600.0;

/// Below this height the middle column shrinks instead of overflowing.
const _minMiddleHeight = 244.0;

final _cellColor = courtTeam1.court;
final _servingCellColor = courtTeam2.court;

/// The horizontal court drawn as a scoreboard: END and ⋯ on top, a 3-column
/// court (left half, call and scores, right half) and a bar with the clock and
/// the plus/minus buttons of each team. Every action is a callback of the
/// court view: null hides the matching control.
class CourtScoreboard extends StatelessWidget {
  const CourtScoreboard({
    super.key,
    required this.layout,
    required this.team1Players,
    required this.team2Players,
    required this.scoreOf,
    required this.lockReceiverPlus,
    required this.onScoreChange,
    required this.callText,
    required this.net,
    required this.onSwitchEnds,
    required this.overrideEnabled,
    required this.startedAt,
    required this.setNumber,
    required this.motion,
    required this.dragEnabled,
    required this.resolve,
    required this.onDrop,
  });

  final CourtLayout layout;
  final List<String> team1Players;
  final List<String> team2Players;
  final int Function(int team) scoreOf;
  final bool lockReceiverPlus;
  final void Function(int team, bool increment)? onScoreChange;
  final String? callText;
  final CourtNetActions net;
  final VoidCallback? onSwitchEnds;
  final bool overrideEnabled;
  final DateTime? startedAt;
  final int? setNumber;
  final Duration motion;
  final bool dragEnabled;
  final ResolveCourtDrop resolve;
  final void Function(CourtDropAction action) onDrop;

  int get _leftTeam => layout.team1First ? 1 : 2;

  @override
  Widget build(BuildContext context) {
    final left = _leftTeam;
    final right = 3 - left;
    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          _TopRow(net: net, overrideEnabled: overrideEnabled),
          Expanded(
            child: _CourtBlock(
              scoreboard: this,
              leftTeam: left,
              rightTeam: right,
            ),
          ),
          _BottomBar(
            leftTeam: left,
            rightTeam: right,
            scoreOf: scoreOf,
            lockReceiverPlus: lockReceiverPlus,
            servingTeam: layout.servingTeam,
            onScoreChange: onScoreChange,
            onLoseServe: net.onLoseServe,
            startedAt: startedAt,
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.net, required this.overrideEnabled});

  final CourtNetActions net;
  final bool overrideEnabled;

  Future<void> _showEndDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final finish = net.onFinishSet;
    final pick = net.onPickWinner;
    Widget option(
      BuildContext dialog, {
      required IconData icon,
      required String label,
      required Color background,
      required Color foreground,
      required VoidCallback? action,
    }) {
      return FilledButton.icon(
        onPressed: action == null
            ? null
            : () {
                Navigator.pop(dialog);
                action();
              },
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(52),
        ),
      );
    }

    return showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(l10n.pickleballCourtEnd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            if (finish != null)
              option(
                dialog,
                icon: Icons.check_rounded,
                label: l10n.pickleballCourtFinishSet,
                background: context.colors.success,
                foreground: Colors.white,
                action: net.finishSetEnabled ? finish : null,
              ),
            if (pick != null)
              option(
                dialog,
                icon: Icons.emoji_events_rounded,
                label: l10n.pickleballCourtPickWinner,
                background: courtBallColor,
                foreground: courtNavy,
                action: net.pickWinnerEnabled ? pick : null,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEnd = net.onFinishSet != null || net.onPickWinner != null;
    final items = <Widget>[
      if (overrideEnabled) _OverridePill(label: l10n.matchOverrideLabel),
      if (canEnd)
        FilledButton(
          onPressed: () => unawaited(_showEndDialog(context)),
          style: FilledButton.styleFrom(
            backgroundColor: _endColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(128, _controlSize),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          child: Text(l10n.pickleballCourtEnd.toUpperCase()),
        ),
      if (net.menu.hasAny) CourtMenuButton(actions: net.menu),
    ];
    if (items.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 56,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: items,
          ),
        ),
      ),
    );
  }
}

class _OverridePill extends StatelessWidget {
  const _OverridePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The three columns. Holds the court's semantics, like the portrait court.
class _CourtBlock extends StatelessWidget {
  const _CourtBlock({
    required this.scoreboard,
    required this.leftTeam,
    required this.rightTeam,
  });

  final CourtScoreboard scoreboard;
  final int leftTeam;
  final int rightTeam;

  /// Screen-reader replacement for dragging a player across the net.
  Map<CustomSemanticsAction, VoidCallback> _switchEndsAction(
    AppLocalizations l10n,
  ) {
    if (!scoreboard.dragEnabled) return const {};
    final action = scoreboard.resolve(
      CourtDragSource(
        kind: CourtDragKind.player,
        team: leftTeam,
        playerIndex: 0,
      ),
      CourtDropTarget.half(team: rightTeam),
    );
    if (action == null) return const {};
    return {
      CustomSemanticsAction(label: l10n.pickleballCourtActionSwitchEnds): () =>
          scoreboard.onDrop(action),
    };
  }

  Widget _half(int team, {required bool isLeft}) {
    return _ScoreboardHalf(
      team: team,
      isLeft: isLeft,
      layout: scoreboard.layout,
      players: team == 1 ? scoreboard.team1Players : scoreboard.team2Players,
      dragEnabled: scoreboard.dragEnabled,
      resolve: scoreboard.resolve,
      onDrop: scoreboard.onDrop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.pickleballCourtLabel,
      customSemanticsActions: _switchEndsAction(l10n),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          key: courtSurfaceKey,
          decoration: BoxDecoration(border: Border.all(color: _ink, width: 2)),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(flex: 35, child: _half(leftTeam, isLeft: true)),
              Expanded(
                flex: 30,
                child: _MiddleColumn(
                  scoreboard: scoreboard,
                  leftTeam: leftTeam,
                  rightTeam: rightTeam,
                ),
              ),
              Expanded(flex: 35, child: _half(rightTeam, isLeft: false)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round black control (↕, ⇄): 44dp, a comfortable touch target.
class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _ink,
        shape: const CircleBorder(side: BorderSide(color: Colors.white)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: _controlSize,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

/// One half: two cells and the ↕ button that swaps its players.
class _ScoreboardHalf extends StatefulWidget {
  const _ScoreboardHalf({
    required this.team,
    required this.isLeft,
    required this.layout,
    required this.players,
    required this.dragEnabled,
    required this.resolve,
    required this.onDrop,
  });

  final int team;
  final bool isLeft;
  final CourtLayout layout;
  final List<String> players;
  final bool dragEnabled;
  final ResolveCourtDrop resolve;
  final void Function(CourtDropAction action) onDrop;

  @override
  State<_ScoreboardHalf> createState() => _ScoreboardHalfState();
}

class _ScoreboardHalfState extends State<_ScoreboardHalf> {
  /// A drag that would switch ends is hovering over a player of this half.
  bool _switchHover = false;

  void _setSwitchHover(bool value) {
    if (_switchHover == value || !mounted) return;
    setState(() => _switchHover = value);
  }

  CourtDropTarget get _halfTarget => CourtDropTarget.half(team: widget.team);

  /// Left half: left cell on top. Right half: right cell on top. Both cells
  /// face the net.
  List<CourtCell> get _cellOrder => widget.isLeft
      ? const [CourtCell.left, CourtCell.right]
      : const [CourtCell.right, CourtCell.left];

  Widget _cell(CourtCell cell) {
    final l10n = AppLocalizations.of(context)!;
    final layout = widget.layout;
    final index = layout.slotsOf(widget.team).playerIn(cell);
    final isServing =
        index != null &&
        layout.servingTeam == widget.team &&
        layout.serverPlayerIndex == index;
    final tile = _ScoreboardCell(
      cell: cell,
      team: widget.team,
      playerIndex: index,
      playerName: index == null
          ? null
          : courtPlayerDisplayName(widget.players, index, l10n),
      isServing: isServing,
      serverNumber: layout.callServerNumber,
      dragEnabled: widget.dragEnabled,
      actions: index == null || !widget.dragEnabled
          ? const {}
          : courtPlayerActions(
              l10n: l10n,
              layout: layout,
              team: widget.team,
              playerIndex: index,
              resolve: widget.resolve,
              onDrop: widget.onDrop,
            ),
    );
    if (!widget.dragEnabled || index == null) return Expanded(child: tile);
    final target = CourtDropTarget.player(
      team: widget.team,
      playerIndex: index,
    );
    return Expanded(
      child: DragTarget<CourtDragSource>(
        // Always accept so a drop on a player never falls through to the half
        // (dropping a player on himself must do nothing); resolve decides.
        onWillAcceptWithDetails: (_) => true,
        onMove: (details) =>
            _setSwitchHover(widget.resolve(details.data, target) is SwitchEnds),
        onLeave: (_) => _setSwitchHover(false),
        onAcceptWithDetails: (details) {
          _setSwitchHover(false);
          final action = widget.resolve(details.data, target);
          if (action != null) widget.onDrop(action);
        },
        builder: (context, candidates, _) {
          final source = candidates.isEmpty ? null : candidates.first;
          final action = source == null ? null : widget.resolve(source, target);
          return CourtDropOutline(
            active: action != null && action is! SwitchEnds,
            radius: 0,
            child: tile,
          );
        },
      ),
    );
  }

  Widget? _swapButton(AppLocalizations l10n) {
    if (!widget.dragEnabled) return null;
    final action = widget.resolve(
      CourtDragSource(
        kind: CourtDragKind.player,
        team: widget.team,
        playerIndex: 0,
      ),
      _halfTarget,
    );
    if (action == null) return null;
    return _RoundControl(
      icon: Icons.swap_vert_rounded,
      tooltip: l10n.pickleballCourtActionSwapPlaces,
      onPressed: () => widget.onDrop(action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cells = _cellOrder;
    final swap = _swapButton(l10n);
    final body = Stack(
      children: [
        Column(
          // Stretch so each cell's colour fills the column, not just its label.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cell(cells[0]),
            const SizedBox(height: 2, child: ColoredBox(color: _ink)),
            _cell(cells[1]),
          ],
        ),
        ?(swap == null ? null : Center(child: swap)),
      ],
    );
    if (!widget.dragEnabled) return body;
    return DragTarget<CourtDragSource>(
      onWillAcceptWithDetails: (details) =>
          widget.resolve(details.data, _halfTarget) != null,
      onAcceptWithDetails: (details) {
        final action = widget.resolve(details.data, _halfTarget);
        if (action != null) widget.onDrop(action);
      },
      builder: (context, candidates, _) => CourtDropOutline(
        active: candidates.isNotEmpty || _switchHover,
        radius: 0,
        thick: true,
        child: body,
      ),
    );
  }
}

class _ScoreboardCell extends StatelessWidget {
  const _ScoreboardCell({
    required this.cell,
    required this.team,
    required this.playerIndex,
    required this.playerName,
    required this.isServing,
    required this.serverNumber,
    required this.dragEnabled,
    required this.actions,
  });

  final CourtCell cell;
  final int team;
  final int? playerIndex;
  final String? playerName;
  final bool isServing;
  final int? serverNumber;
  final bool dragEnabled;

  /// What a tap offers (swap, give the serve); empty hides the tap.
  final Map<String, VoidCallback> actions;

  Future<void> _showActions(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final entry in actions.entries)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialog);
                  entry.value();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(entry.key),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cellLabel = cell == CourtCell.right
        ? l10n.pickleballCourtRightCell
        : l10n.pickleballCourtLeftCell;
    final color = isServing ? _servingCellColor : _cellColor;
    final name = playerName;
    final index = playerIndex;
    if (name == null || index == null) {
      return Semantics(
        label: cellLabel,
        child: ColoredBox(color: color, child: const SizedBox.expand()),
      );
    }
    final shortName = abbreviateName(name);
    final person = _PersonLabel(name: shortName);
    final source = CourtDragSource(
      kind: CourtDragKind.player,
      team: team,
      playerIndex: index,
    );
    return Semantics(
      label: isServing
          ? '$cellLabel: $name, ${l10n.pickleballServing}'
          : '$cellLabel: $name',
      customSemanticsActions: {
        for (final entry in actions.entries)
          CustomSemanticsAction(label: entry.key): entry.value,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: actions.isEmpty ? null : () => _showActions(context, name),
        child: ColoredBox(
          color: color,
          child: Stack(
            alignment: Alignment.center,
            children: [
              dragEnabled
                  ? CourtDraggable(
                      source: source,
                      feedback: Material(
                        type: MaterialType.transparency,
                        child: _PersonLabel(name: shortName),
                      ),
                      child: person,
                    )
                  : person,
              if (isServing)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _ServeTag(
                    team: team,
                    playerIndex: index,
                    serverNumber: serverNumber,
                    dragEnabled: dragEnabled,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonLabel extends StatelessWidget {
  const _PersonLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE9EEF7),
            child: Icon(Icons.person_rounded, color: courtNavy),
          ),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "SERVE n" tag of the server's cell. Long-press and drag it to hand the
/// ball to another player, like the ball of the portrait court.
class _ServeTag extends StatelessWidget {
  const _ServeTag({
    required this.team,
    required this.playerIndex,
    required this.serverNumber,
    required this.dragEnabled,
  });

  static const _feedbackSize = Size(144, 36);

  /// Hit area around the tag, like the ball of the portrait court.
  static const _hitSize = 48.0;

  final int team;
  final int playerIndex;
  final int? serverNumber;
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = serverNumber;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _tagColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const Icon(Icons.directions_run_rounded, size: 16, color: _ink),
          Text(
            number == null
                ? l10n.pickleballCourtServeTag
                : '${l10n.pickleballCourtServeTag} $number',
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    final hit = ColoredBox(
      key: serveBallHitKey,
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _hitSize,
          minHeight: _hitSize,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(child: pill),
        ),
      ),
    );
    return Semantics(
      label: l10n.pickleballCourtBall,
      excludeSemantics: true,
      child: dragEnabled
          ? CourtDraggable(
              source: CourtDragSource(
                kind: CourtDragKind.ball,
                team: team,
                playerIndex: playerIndex,
              ),
              feedback: pill,
              feedbackSize: _feedbackSize,
              child: hit,
            )
          : hit,
    );
  }
}

/// Call, the two scores, ⇄ and "pickleball · Set n". Shrinks as a whole when
/// the court is short.
class _MiddleColumn extends StatelessWidget {
  const _MiddleColumn({
    required this.scoreboard,
    required this.leftTeam,
    required this.rightTeam,
  });

  final CourtScoreboard scoreboard;
  final int leftTeam;
  final int rightTeam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final call = scoreboard.callText;
    final setNumber = scoreboard.setNumber;
    final switchEnds = scoreboard.onSwitchEnds;
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            height: math.max(constraints.maxHeight, _minMiddleHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: call == null
                        ? null
                        : '${l10n.pickleballCourtCallLabel}: $call',
                    excludeSemantics: true,
                    child: Text(
                      call ?? '',
                      maxLines: 1,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (team, align) in [
                        (leftTeam, Alignment.centerLeft),
                        (rightTeam, Alignment.centerRight),
                      ])
                        Expanded(
                          child: Align(
                            alignment: align,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _ScoreChip(
                                score: scoreboard.scoreOf(team),
                                isServing:
                                    scoreboard.layout.servingTeam == team,
                                motion: scoreboard.motion,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (switchEnds != null)
                    _RoundControl(
                      icon: Icons.swap_horiz_rounded,
                      tooltip: l10n.pickleballCourtActionSwitchEnds,
                      onPressed: switchEnds,
                    )
                  else
                    const SizedBox(height: _controlSize),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.pickleballCourtSportName,
                        style: const TextStyle(color: _ink, fontSize: 18),
                      ),
                      if (setNumber != null)
                        Text(
                          l10n.pickleballCourtSetNumber(setNumber),
                          style: const TextStyle(
                            color: Color(0xFF7A7F8A),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.score,
    required this.isServing,
    required this.motion,
  });

  final int score;
  final bool isServing;
  final Duration motion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isServing ? courtServingChipColor : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isServing ? courtBallColor : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: AnimatedSwitcher(
        duration: motion,
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Text(
          '$score',
          key: ValueKey<int>(score),
          style: TextStyle(
            color: context.colors.success,
            fontSize: 52,
            height: 1.1,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Clock, then + − of the left team, CHANGE SERVE, − + of the right team.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.leftTeam,
    required this.rightTeam,
    required this.scoreOf,
    required this.lockReceiverPlus,
    required this.servingTeam,
    required this.onScoreChange,
    required this.onLoseServe,
    required this.startedAt,
  });

  final int leftTeam;
  final int rightTeam;
  final int Function(int team) scoreOf;
  final bool lockReceiverPlus;
  final int? servingTeam;
  final void Function(int team, bool increment)? onScoreChange;
  final VoidCallback? onLoseServe;
  final DateTime? startedAt;

  List<Widget> _teamButtons(
    AppLocalizations l10n,
    int team, {
    required bool plusFirst,
  }) {
    final change = onScoreChange;
    if (change == null) return const [];
    final accent = courtPaletteOf(team).accent;
    final plusEnabled = !lockReceiverPlus || servingTeam == team;
    final plus = _BarButton(
      tooltip: l10n.pickleballCourtAddPoint(team),
      color: accent,
      onPressed: plusEnabled ? () => change(team, true) : null,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
    final minus = _BarButton(
      tooltip: l10n.pickleballCourtRemovePoint(team),
      color: Color.lerp(accent, Colors.white, 0.3)!,
      onPressed: scoreOf(team) > 0 ? () => change(team, false) : null,
      child: const Icon(Icons.remove_rounded, color: Colors.white, size: 28),
    );
    return plusFirst ? [plus, minus] : [minus, plus];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loseServe = onLoseServe;
    final controls = <Widget>[
      ..._teamButtons(l10n, leftTeam, plusFirst: true),
      if (loseServe != null)
        _BarButton(
          tooltip: l10n.pickleballCourtChangeServe,
          color: context.colors.success,
          minWidth: 120,
          onPressed: loseServe,
          child: Text(
            l10n.pickleballCourtChangeServe.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ..._teamButtons(l10n, rightTeam, plusFirst: false),
    ];
    final start = startedAt;
    if (controls.isEmpty && start == null) return const SizedBox(height: 8);
    return SizedBox(
      height: 64,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: math.max(constraints.maxWidth, _minBarWidth),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: start == null
                          ? null
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _ElapsedClock(startedAt: start),
                            ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: controls,
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rectangular bar button: 44dp tall, drawn on a [Material] so the ripple shows.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.tooltip,
    required this.color,
    required this.onPressed,
    required this.child,
    this.minWidth = 56,
  });

  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;
  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed == null ? color.withValues(alpha: 0.3) : color,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minWidth,
              minHeight: _controlSize,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Time since the match started, ticking once a second.
class _ElapsedClock extends StatefulWidget {
  const _ElapsedClock({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  String get _text {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final safe = elapsed.isNegative ? Duration.zero : elapsed;
    final minutes = _two(safe.inMinutes % 60);
    final seconds = _two(safe.inSeconds % 60);
    return safe.inHours > 0
        ? '${safe.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        const Icon(Icons.timer_outlined, color: _ink, size: 26),
        Text(
          _text,
          style: const TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
