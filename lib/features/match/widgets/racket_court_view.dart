import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/services/racket_court_layout.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/widgets/court_receive_outline.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_drag_widgets.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_palette.dart';
import 'package:app_quanly_giaidau/features/match/widgets/racket_court_bar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

const _surface = Color(0xFFF7F7F9);
const _ink = Color(0xFF1B1B1F);
const _chipColor = Color(0xFFFF7A00);
const _bannerColor = Color(0xFFFFF7D1);

/// Key of the undo button.
const racketUndoKey = Key('racketUndo');

/// Key of the switch-ends button.
const racketEndsKey = Key('racketEnds');

/// Key of the ⋯ button.
const racketMenuKey = Key('racketMenu');

/// Badminton / tennis court: two halves of two cells, the server's GIAO chip,
/// the receiver's dashed outline, and between the halves the call, the scores,
/// undo and switch-ends. Drags and taps reuse the pickleball court rules.
class RacketCourtView extends StatelessWidget {
  const RacketCourtView({
    super.key,
    required this.cells,
    required this.team1Players,
    required this.team2Players,
    required this.team1Name,
    required this.team2Name,
    required this.endsFlipped,
    required this.axis,
    required this.scoreText1,
    required this.scoreText2,
    required this.servingTeam,
    required this.call,
    required this.setText,
    required this.resolve,
    required this.onDrop,
    this.chips = const [],
    this.banner,
    this.canUndo = false,
    this.onScore,
    this.onUndo,
    this.onSwitchEnds,
    this.onMenu,
    this.onPickServer,
  });

  final List<RacketCourtCell> cells;

  /// Full names; empty when the match has no player list (the team name shows).
  final List<String> team1Players;
  final List<String> team2Players;
  final String team1Name;
  final String team2Name;

  /// Team 2 on the first half (left, or top when upright).
  final bool endsFlipped;
  final Axis axis;
  final String scoreText1;
  final String scoreText2;

  /// Team whose score box is highlighted; null when nobody is known to serve.
  final int? servingTeam;
  final String call;
  final String setText;
  final List<String> chips;
  final String? banner;
  final bool canUndo;

  /// Null for a viewer: no score buttons, no drag, no taps.
  final void Function(int team, bool increment)? onScore;
  final VoidCallback? onUndo;
  final VoidCallback? onSwitchEnds;
  final VoidCallback? onMenu;

  /// Non-null only while the first server can still be picked: a tap on a
  /// player chooses who serves first.
  final void Function(int team, int playerIndex)? onPickServer;
  final ResolveCourtDrop resolve;
  final void Function(CourtDropAction action) onDrop;

  bool get _interactive => onScore != null;

  @override
  Widget build(BuildContext context) {
    final first = endsFlipped ? 2 : 1;
    final second = 3 - first;
    final upright = axis == Axis.vertical;
    final halfA = _RacketHalf(view: this, team: first, isFirst: true);
    final halfB = _RacketHalf(view: this, team: second, isFirst: false);
    final middle = _Middle(view: this, first: first, second: second);
    return ColoredBox(
      color: _surface,
      child: Column(
        children: [
          if (chips.isNotEmpty || banner != null)
            _InfoRow(chips: chips, banner: banner),
          Expanded(
            child: upright
                ? Column(
                    children: [
                      Expanded(flex: 5, child: halfA),
                      SizedBox(height: 168, child: middle),
                      Expanded(flex: 5, child: halfB),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 10, child: halfA),
                      Expanded(flex: 9, child: middle),
                      Expanded(flex: 10, child: halfB),
                    ],
                  ),
          ),
          RacketScoreBar(firstTeam: first, onScore: onScore),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.chips, required this.banner});

  final List<String> chips;
  final String? banner;

  @override
  Widget build(BuildContext context) {
    final banner = this.banner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final text in chips)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _chipColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (banner != null)
          ColoredBox(
            color: _bannerColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                banner,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Call, the two scores, undo and switch-ends, and the set line.
class _Middle extends StatelessWidget {
  const _Middle({
    required this.view,
    required this.first,
    required this.second,
  });

  final RacketCourtView view;
  final int first;
  final int second;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String text(int team) => team == 1 ? view.scoreText1 : view.scoreText2;
    final undo = view.onUndo;
    final canUndo = view.canUndo && undo != null;
    final ends = view.onSwitchEnds;
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Semantics(
                  label: l10n.pickleballCourtCallLabel,
                  child: Text(
                    view.call,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    _ScoreBox(
                      text: text(first),
                      team: first,
                      serving: view.servingTeam == first,
                    ),
                    _ScoreBox(
                      text: text(second),
                      team: second,
                      serving: view.servingTeam == second,
                    ),
                  ],
                ),
                if (view._interactive)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10,
                    children: [
                      _RoundButton(
                        key: racketUndoKey,
                        icon: Icons.undo_rounded,
                        tooltip: l10n.pickleballCourtUndo,
                        onPressed: canUndo ? undo : null,
                      ),
                      if (ends != null)
                        _RoundButton(
                          key: racketEndsKey,
                          icon: Icons.swap_horiz_rounded,
                          tooltip: l10n.pickleballCourtActionSwitchEnds,
                          onPressed: ends,
                        ),
                      if (view.onMenu != null)
                        _RoundButton(
                          key: racketMenuKey,
                          icon: Icons.more_horiz_rounded,
                          tooltip: l10n.pickleballCourtMenu,
                          onPressed: view.onMenu,
                        ),
                    ],
                  ),
                Text(
                  view.setText,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
    required this.text,
    required this.team,
    required this.serving,
  });

  final String text;
  final int team;
  final bool serving;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: serving ? courtServingChipColor : Colors.transparent,
        border: Border.all(
          color: serving ? courtBallColor : Colors.transparent,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: courtPaletteOf(team).accent,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          color: courtNavy,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// One half: two cells. A drop on the free area of the half, or on a cell of
/// the other team's half, goes through [RacketCourtView.resolve].
class _RacketHalf extends StatefulWidget {
  const _RacketHalf({
    required this.view,
    required this.team,
    required this.isFirst,
  });

  final RacketCourtView view;
  final int team;
  final bool isFirst;

  @override
  State<_RacketHalf> createState() => _RacketHalfState();
}

class _RacketHalfState extends State<_RacketHalf> {
  /// A drag that would switch ends is hovering over a player of this half.
  bool _switchHover = false;

  void _setSwitchHover(bool value) {
    if (_switchHover == value || !mounted) return;
    setState(() => _switchHover = value);
  }

  RacketCourtView get _view => widget.view;
  int get _team => widget.team;
  CourtDropTarget get _halfTarget => CourtDropTarget.half(team: _team);

  /// Each team faces the net, so its right court is the bottom cell of the
  /// first half and the top cell of the second half when sideways; upright,
  /// the first half has its right cell on the screen's left.
  List<bool> get _rightOrder {
    final rightFirst = _view.axis == Axis.vertical
        ? widget.isFirst
        : !widget.isFirst;
    return rightFirst ? const [true, false] : const [false, true];
  }

  String? _nameOf(AppLocalizations l10n, int? index) {
    if (index == null) return null;
    final players = _team == 1 ? _view.team1Players : _view.team2Players;
    if (players.isEmpty) return _team == 1 ? _view.team1Name : _view.team2Name;
    if (index < players.length && players[index].trim().isNotEmpty) {
      return abbreviateName(players[index]);
    }
    return l10n.pickleballCourtPlayerLabel(index + 1);
  }

  /// What a tap (or a screen reader) offers for one player: the same drops.
  Map<String, VoidCallback> _actions(AppLocalizations l10n, int index) {
    final out = <String, VoidCallback>{};
    void add(String label, CourtDragSource source, CourtDropTarget target) {
      final action = _view.resolve(source, target);
      if (action != null) out[label] = () => _view.onDrop(action);
    }

    add(
      l10n.pickleballCourtActionSwapPlaces,
      CourtDragSource(
        kind: CourtDragKind.player,
        team: _team,
        playerIndex: index,
      ),
      _halfTarget,
    );
    for (final c in _view.cells) {
      if (c.role != CourtCellRole.server || c.playerIndex == null) continue;
      if (c.team == _team && c.playerIndex == index) continue;
      add(
        l10n.pickleballCourtActionServeHere,
        CourtDragSource(
          kind: CourtDragKind.ball,
          team: c.team,
          playerIndex: c.playerIndex!,
        ),
        CourtDropTarget.player(team: _team, playerIndex: index),
      );
    }
    return out;
  }

  Widget _cell(RacketCourtCell cell) {
    final l10n = AppLocalizations.of(context)!;
    final index = cell.playerIndex;
    final name = _nameOf(l10n, index);
    final interactive = _view._interactive;
    final pick = _view.onPickServer;
    final actions = index == null || !interactive
        ? const <String, VoidCallback>{}
        : _actions(l10n, index);
    final tile = _RacketCellTile(
      cell: cell,
      name: name,
      dragEnabled: interactive,
      actions: actions,
      onPick: pick == null || index == null ? null : () => pick(_team, index),
    );
    if (!interactive || index == null) return Expanded(child: tile);
    final target = CourtDropTarget.player(team: _team, playerIndex: index);
    return Expanded(
      child: DragTarget<CourtDragSource>(
        // Always accept so a drop on a player never falls through to the half.
        onWillAcceptWithDetails: (_) => true,
        onMove: (d) =>
            _setSwitchHover(_view.resolve(d.data, target) is SwitchEnds),
        onLeave: (_) => _setSwitchHover(false),
        onAcceptWithDetails: (d) {
          _setSwitchHover(false);
          final action = _view.resolve(d.data, target);
          if (action != null) _view.onDrop(action);
        },
        builder: (context, candidates, _) {
          final source = candidates.isEmpty ? null : candidates.first;
          final action = source == null ? null : _view.resolve(source, target);
          return CourtDropOutline(
            active: action != null && action is! SwitchEnds,
            radius: 0,
            child: tile,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upright = _view.axis == Axis.vertical;
    final byRight = {
      for (final c in _view.cells.where((c) => c.team == _team))
        c.rightCourt: c,
    };
    final order = _rightOrder;
    final body = Flex(
      direction: upright ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cell(byRight[order[0]]!),
        upright
            ? const SizedBox(width: 2, child: ColoredBox(color: _ink))
            : const SizedBox(height: 2, child: ColoredBox(color: _ink)),
        _cell(byRight[order[1]]!),
      ],
    );
    if (!_view._interactive) return body;
    return DragTarget<CourtDragSource>(
      onWillAcceptWithDetails: (d) =>
          _view.resolve(d.data, _halfTarget) != null,
      onAcceptWithDetails: (d) {
        final action = _view.resolve(d.data, _halfTarget);
        if (action != null) _view.onDrop(action);
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

class _RacketCellTile extends StatelessWidget {
  const _RacketCellTile({
    required this.cell,
    required this.name,
    required this.dragEnabled,
    required this.actions,
    required this.onPick,
  });

  final RacketCourtCell cell;
  final String? name;
  final bool dragEnabled;
  final Map<String, VoidCallback> actions;

  /// Choose this player as the first server (only before the first point).
  final VoidCallback? onPick;

  Future<void> _showActions(BuildContext context, String title) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(title),
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
    final palette = courtPaletteOf(cell.team);
    final sideLabel = cell.rightCourt
        ? l10n.pickleballCourtRightCell
        : l10n.pickleballCourtLeftCell;
    final name = this.name;
    final index = cell.playerIndex;
    if (name == null || index == null) {
      return Semantics(
        label: sideLabel,
        child: ColoredBox(
          color: palette.court.withValues(alpha: 0.4),
          child: const SizedBox.expand(),
        ),
      );
    }
    final isServer = cell.role == CourtCellRole.server;
    final isReceiver = cell.role == CourtCellRole.receiver;
    final person = _Person(name: name);
    final VoidCallback? tap =
        onPick ?? (actions.isEmpty ? null : () => _showActions(context, name));
    return Semantics(
      excludeSemantics: true,
      label:
          '$sideLabel: $name'
          '${isServer ? ', ${l10n.pickleballCourtServeTag}' : ''}'
          '${isReceiver ? ', ${l10n.racketReceive}' : ''}',
      customSemanticsActions: {
        for (final e in actions.entries)
          CustomSemanticsAction(label: e.key): e.value,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: CustomPaint(
          foregroundPainter: isReceiver ? const CourtReceiveOutline() : null,
          child: ColoredBox(
            color: palette.court,
            child: Stack(
              alignment: Alignment.center,
              children: [
                dragEnabled
                    ? CourtDraggable(
                        source: CourtDragSource(
                          kind: CourtDragKind.player,
                          team: cell.team,
                          playerIndex: index,
                        ),
                        feedback: person,
                        child: SizedBox.expand(child: Center(child: person)),
                      )
                    : person,
                Positioned(
                  top: 2,
                  left: 6,
                  child: isServer
                      ? _ServeTag(
                          team: cell.team,
                          playerIndex: index,
                          dragEnabled: dragEnabled,
                        )
                      : isReceiver
                      ? CourtCellTag(text: l10n.racketReceive)
                      : const SizedBox.shrink(),
                ),
                Positioned(
                  right: 8,
                  bottom: 3,
                  child: Text(
                    sideLabel,
                    style: const TextStyle(
                      color: Color(0x8C12306B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE9EEF7),
            child: Icon(Icons.person_rounded, color: courtNavy, size: 20),
          ),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: courtNavy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "GIAO" chip of the server's cell: long-press and drag it to hand the serve
/// to another player.
class _ServeTag extends StatelessWidget {
  const _ServeTag({
    required this.team,
    required this.playerIndex,
    required this.dragEnabled,
  });

  final int team;
  final int playerIndex;
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pill = CourtCellTag(
      text: '● ${l10n.pickleballCourtServeTag}',
      ball: true,
    );
    final hit = ColoredBox(
      key: serveBallHitKey,
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
        child: Align(alignment: Alignment.topLeft, child: pill),
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
              feedbackSize: const Size(96, 36),
              child: hit,
            )
          : hit,
    );
  }
}
