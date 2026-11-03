import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_palette.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

export 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_controls.dart'
    show courtNetControlsKey, courtNetKey;

/// Tên hiển thị của VĐV ở [index] trong đội; thiếu tên thì dùng "VĐV n".
String courtPlayerDisplayName(
  List<String> players,
  int index,
  AppLocalizations l10n,
) {
  if (index >= 0 && index < players.length) {
    final name = players[index].trim();
    if (name.isNotEmpty) return name;
  }
  return l10n.pickleballCourtPlayerLabel(index + 1);
}

/// Key of the 48dp hit area around the serving ball.
const serveBallHitKey = Key('serveBallHit');

/// Key of the painted court (cells, kitchens and net).
const courtSurfaceKey = Key('courtSurface');

/// Resolves a drop to an action, or null when the drop must do nothing.
typedef _ResolveDrop =
    CourtDropAction? Function(CourtDragSource source, CourtDropTarget target);

/// Sơ đồ sân pickleball: dọc (hai đội trên/dưới) khi [axis] là dọc, ngang 2:1
/// khi [axis] là ngang. Điểm nằm trong dải bếp của mỗi nửa; lưới giữ lời hô và
/// các icon (⋯, chốt set, cúp, mất giao). Kéo thả người và trái bóng bằng nhấn
/// giữ.
///
/// Chỉ vẽ từ [CourtLayout]; luật cú thả nằm ở [resolveCourtDrop], việc áp dụng
/// nằm ở người gọi qua các callback. Callback null = không có quyền/không áp
/// dụng: ẩn nút tương ứng và tắt kéo thả.
class PickleballCourtView extends StatelessWidget {
  const PickleballCourtView({
    super.key,
    required this.layout,
    required this.team1Players,
    required this.team2Players,
    required this.team1Score,
    required this.team2Score,
    this.axis = Axis.horizontal,
    this.isSideOut = false,
    this.isDoubles = true,
    this.receiverCanScore = false,
    this.autoSwitchEnds = true,
    this.overrideEnabled = false,
    this.finishSetEnabled = true,
    this.pickWinnerEnabled = true,
    this.onScoreChange,
    this.onSetServingTeam,
    this.onDrop,
    this.onSwitchEnds,
    this.onUndo,
    this.onRestoreAutomatic,
    this.onToggleAutoSwitch,
    this.onFinishSet,
    this.onPickWinner,
    this.onLoseServe,
    this.onToggleOverride,
    this.onForceWin,
  });

  static const _motion = Duration(milliseconds: 240);

  /// A horizontal court is never shorter than this; a shorter slot scrolls.
  static const _minHorizontalHeight = 120.0;

  /// A vertical court is never shorter than this; a shorter slot scrolls.
  static const _minVerticalHeight = 360.0;

  /// Hướng xếp hai nửa sân: dọc khi cầm dọc, ngang khi cầm ngang.
  final Axis axis;
  final CourtLayout layout;
  final List<String> team1Players;
  final List<String> team2Players;
  final int team1Score;
  final int team2Score;

  /// Side-out: chỉ đội đang giao được cộng điểm và được đổi đội giao.
  final bool isSideOut;

  /// Singles have no left/right swap: those drops do nothing.
  final bool isDoubles;

  /// Side-out but open scoring: the receiving team may score as well.
  final bool receiverCanScore;
  final bool autoSwitchEnds;
  final bool overrideEnabled;

  /// Chốt set bị khoá khi set chưa kết thúc được (vd. 0-0).
  final bool finishSetEnabled;

  /// Cúp bị khoá khi đang lưu kết quả.
  final bool pickWinnerEnabled;

  /// Null thì ẩn nút − và +.
  final void Function(int team, bool increment)? onScoreChange;

  /// Gọi trước [onDrop] khi trái bóng được thả sang đội kia (đổi đội giao).
  /// Null thì không cho thả trái bóng sang đội kia.
  final void Function(int team)? onSetServingTeam;

  /// Null thì tắt kéo thả.
  final void Function(CourtDropAction action)? onDrop;
  final VoidCallback? onSwitchEnds;
  final VoidCallback? onUndo;
  final VoidCallback? onRestoreAutomatic;
  final VoidCallback? onToggleAutoSwitch;
  final VoidCallback? onFinishSet;
  final VoidCallback? onPickWinner;

  /// Null ở rally và Lite: không có lượt giao để mất.
  final VoidCallback? onLoseServe;

  /// Null ở Lite: không có ngoại lệ.
  final VoidCallback? onToggleOverride;
  final VoidCallback? onForceWin;

  int _scoreOf(int team) => team == 1 ? team1Score : team2Score;

  CourtDropAction? _resolve(CourtDragSource source, CourtDropTarget target) {
    final action = resolveCourtDrop(source, target, layout.servingTeam);
    if (action is SwapPlaces && !isDoubles) return null;
    if (action is SetServer &&
        action.changesServingTeam &&
        (!isSideOut || onSetServingTeam == null)) {
      return null;
    }
    return action;
  }

  void _handleDrop(CourtDropAction action) {
    if (action is SetServer && action.changesServingTeam) {
      onSetServingTeam?.call(action.team);
    }
    onDrop?.call(action);
  }

  /// The court fills its slot: halves, cells and the net band are all flexible,
  /// so any aspect ratio works and no blank margin is left around it. Only an
  /// unbounded height falls back to a default shape, and a slot below the
  /// minimum height scrolls.
  Size _courtSize(BoxConstraints constraints) {
    final vertical = axis == Axis.vertical;
    final minHeight = vertical ? _minVerticalHeight : _minHorizontalHeight;
    final height = constraints.hasBoundedHeight
        ? math.max(constraints.maxHeight, minHeight)
        : constraints.maxWidth * (vertical ? 1.5 : 0.5);
    return Size(constraints.maxWidth, height);
  }

  String? get _callText {
    final serving = layout.servingScore;
    final receiving = layout.receivingScore;
    if (serving == null || receiving == null) return null;
    final server = layout.callServerNumber;
    return server == null
        ? '$serving-$receiving'
        : '$serving-$receiving-$server';
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _motion;
    final firstTeam = layout.team1First ? 1 : 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _courtSize(constraints);
        final court = SizedBox(
          width: size.width,
          height: size.height,
          child: _CourtSurface(
            axis: axis,
            layout: layout,
            firstTeam: firstTeam,
            secondTeam: 3 - firstTeam,
            team1Players: team1Players,
            team2Players: team2Players,
            scoreOf: _scoreOf,
            lockReceiverPlus: isSideOut && !receiverCanScore,
            onScoreChange: onScoreChange,
            callText: _callText,
            net: CourtNetActions(
              menu: CourtMenuActions(
                onSwitchEnds: onSwitchEnds,
                onUndo: onUndo,
                onRestoreAutomatic: onRestoreAutomatic,
                onToggleAutoSwitch: onToggleAutoSwitch,
                autoSwitchEnds: autoSwitchEnds,
                onToggleOverride: onToggleOverride,
                overrideEnabled: overrideEnabled,
                onForceWin: onForceWin,
              ),
              onFinishSet: onFinishSet,
              finishSetEnabled: finishSetEnabled,
              onPickWinner: onPickWinner,
              pickWinnerEnabled: pickWinnerEnabled,
              onLoseServe: onLoseServe,
            ),
            motion: motion,
            dragEnabled: onDrop != null,
            resolve: _resolve,
            onDrop: _handleDrop,
          ),
        );
        final scrolls =
            constraints.hasBoundedHeight &&
            size.height > constraints.maxHeight + 0.5;
        return Align(
          alignment: Alignment.center,
          child: scrolls ? SingleChildScrollView(child: court) : court,
        );
      },
    );
  }
}

class _CourtSurface extends StatelessWidget {
  const _CourtSurface({
    required this.axis,
    required this.layout,
    required this.firstTeam,
    required this.secondTeam,
    required this.team1Players,
    required this.team2Players,
    required this.scoreOf,
    required this.lockReceiverPlus,
    required this.onScoreChange,
    required this.callText,
    required this.net,
    required this.motion,
    required this.dragEnabled,
    required this.resolve,
    required this.onDrop,
  });

  final Axis axis;
  final CourtLayout layout;
  final int firstTeam;
  final int secondTeam;
  final List<String> team1Players;
  final List<String> team2Players;
  final int Function(int team) scoreOf;
  final bool lockReceiverPlus;
  final void Function(int team, bool increment)? onScoreChange;
  final String? callText;
  final CourtNetActions net;
  final Duration motion;
  final bool dragEnabled;
  final _ResolveDrop resolve;
  final void Function(CourtDropAction action) onDrop;

  Widget _half(int team, {required bool isFirst}) => Expanded(
    child: _CourtHalf(
      axis: axis,
      team: team,
      isFirst: isFirst,
      layout: layout,
      players: team == 1 ? team1Players : team2Players,
      score: scoreOf(team),
      plusEnabled: !lockReceiverPlus || layout.servingTeam == team,
      onScoreChange: onScoreChange,
      motion: motion,
      dragEnabled: dragEnabled,
      resolve: resolve,
      onDrop: onDrop,
    ),
  );

  /// Screen-reader replacement for dragging a player across the net. One
  /// action for the whole court, not one per player.
  Map<CustomSemanticsAction, VoidCallback> _switchEndsAction(
    AppLocalizations l10n,
  ) {
    if (!dragEnabled) return const {};
    final action = resolve(
      CourtDragSource(
        kind: CourtDragKind.player,
        team: firstTeam,
        playerIndex: 0,
      ),
      CourtDropTarget.half(team: secondTeam),
    );
    if (action == null) return const {};
    return {
      CustomSemanticsAction(label: l10n.pickleballCourtActionSwitchEnds): () =>
          onDrop(action),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.pickleballCourtLabel,
      customSemanticsActions: _switchEndsAction(l10n),
      child: Container(
        key: courtSurfaceKey,
        decoration: BoxDecoration(
          color: courtColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: courtLineColor, width: courtLineWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: Flex(
          direction: axis,
          children: [
            _half(firstTeam, isFirst: true),
            CourtNetBand(courtAxis: axis, callText: callText, actions: net),
            _half(secondTeam, isFirst: false),
          ],
        ),
      ),
    );
  }
}

/// One half of the court. Cells face the net. Horizontal court: on the left
/// half the left cell is on top, on the right half the right cell is on top.
/// Vertical court: the top half faces down (its right cell is on the screen's
/// left), the bottom half faces up (its right cell is on the screen's right).
class _CourtHalf extends StatefulWidget {
  const _CourtHalf({
    required this.axis,
    required this.team,
    required this.isFirst,
    required this.layout,
    required this.players,
    required this.score,
    required this.plusEnabled,
    required this.onScoreChange,
    required this.motion,
    required this.dragEnabled,
    required this.resolve,
    required this.onDrop,
  });

  final Axis axis;
  final int team;

  /// Left half (horizontal court) or top half (vertical court).
  final bool isFirst;
  final CourtLayout layout;
  final List<String> players;
  final int score;
  final bool plusEnabled;
  final void Function(int team, bool increment)? onScoreChange;
  final Duration motion;
  final bool dragEnabled;
  final _ResolveDrop resolve;
  final void Function(CourtDropAction action) onDrop;

  @override
  State<_CourtHalf> createState() => _CourtHalfState();
}

class _CourtHalfState extends State<_CourtHalf> {
  /// A drag that would switch ends is hovering over a player of this half.
  bool _switchHover = false;

  void _setSwitchHover(bool value) {
    if (_switchHover == value || !mounted) return;
    setState(() => _switchHover = value);
  }

  CourtDropTarget get _halfTarget => CourtDropTarget.half(team: widget.team);

  /// Screen-reader replacement for dragging: the same drops, resolved and
  /// applied through the same callbacks, so permissions, singles and rally
  /// rules hold for both.
  Map<CustomSemanticsAction, VoidCallback> _semanticActions(
    int playerIndex,
    AppLocalizations l10n,
  ) {
    if (!widget.dragEnabled) return const {};
    final layout = widget.layout;
    final actions = <CustomSemanticsAction, VoidCallback>{};
    void add(String label, CourtDragSource source, CourtDropTarget target) {
      final action = widget.resolve(source, target);
      if (action == null) return;
      actions[CustomSemanticsAction(label: label)] = () =>
          widget.onDrop(action);
    }

    final self = CourtDragSource(
      kind: CourtDragKind.player,
      team: widget.team,
      playerIndex: playerIndex,
    );
    add(
      l10n.pickleballCourtActionSwapPlaces,
      self,
      CourtDropTarget.half(team: widget.team),
    );
    final servingTeam = layout.servingTeam;
    final server = layout.serverPlayerIndex;
    if (servingTeam != null && server != null) {
      add(
        l10n.pickleballCourtActionServeHere,
        CourtDragSource(
          kind: CourtDragKind.ball,
          team: servingTeam,
          playerIndex: server,
        ),
        CourtDropTarget.player(team: widget.team, playerIndex: playerIndex),
      );
    }
    return actions;
  }

  Widget _cell(CourtCell cell) {
    final playerIndex = widget.layout.slotsOf(widget.team).playerIn(cell);
    final l10n = AppLocalizations.of(context)!;
    final layout = widget.layout;
    final isServing =
        layout.servingTeam == widget.team &&
        layout.serverPlayerIndex != null &&
        playerIndex == layout.serverPlayerIndex;
    final tile = _CourtCellTile(
      cell: cell,
      team: widget.team,
      playerIndex: playerIndex,
      playerName: playerIndex == null
          ? null
          : courtPlayerDisplayName(widget.players, playerIndex, l10n),
      isServing: isServing,
      dragEnabled: widget.dragEnabled,
      motion: widget.motion,
      semanticActions: playerIndex == null
          ? const {}
          : _semanticActions(playerIndex, l10n),
    );
    // Empty cells fall through to the half-level target.
    if (!widget.dragEnabled || playerIndex == null) {
      return Expanded(child: tile);
    }
    final target = CourtDropTarget.player(
      team: widget.team,
      playerIndex: playerIndex,
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
          final highlight = action != null && action is! SwitchEnds;
          return _DropOutline(active: highlight, radius: 6, child: tile);
        },
      ),
    );
  }

  /// Order of the two cells inside the half, in reading order of the cell box.
  List<CourtCell> get _cellOrder {
    final rightFirst = widget.axis == Axis.vertical
        ? widget.isFirst
        : !widget.isFirst;
    return rightFirst
        ? const [CourtCell.right, CourtCell.left]
        : const [CourtCell.left, CourtCell.right];
  }

  @override
  Widget build(BuildContext context) {
    final vertical = widget.axis == Axis.vertical;
    final cells = _cellOrder;
    final palette = courtPaletteOf(widget.team);
    final divider = vertical
        ? Container(width: courtLineWidth, color: courtLineColor)
        : Container(height: courtLineWidth, color: courtLineColor);
    final cellsBox = Expanded(
      flex: vertical ? 70 : 62,
      child: ColoredBox(
        color: palette.court,
        child: Flex(
          direction: vertical ? Axis.horizontal : Axis.vertical,
          children: [_cell(cells[0]), divider, _cell(cells[1])],
        ),
      ),
    );
    final scoreStrip = CourtKitchenScore(
      courtAxis: widget.axis,
      team: widget.team,
      accent: palette.accent,
      score: widget.score,
      isServing: widget.layout.servingTeam == widget.team,
      plusEnabled: widget.plusEnabled,
      onScoreChange: widget.onScoreChange,
      motion: widget.motion,
    );
    // The kitchen touches the net: it is the second child of the first half
    // and the first child of the second half.
    final lineAtNet = BorderSide(color: courtLineColor, width: courtLineWidth);
    final kitchen = Expanded(
      flex: vertical ? 30 : 38,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.kitchen,
          border: vertical
              ? Border(
                  top: widget.isFirst ? lineAtNet : BorderSide.none,
                  bottom: widget.isFirst ? BorderSide.none : lineAtNet,
                )
              : Border(
                  left: widget.isFirst ? lineAtNet : BorderSide.none,
                  right: widget.isFirst ? BorderSide.none : lineAtNet,
                ),
        ),
        child: scoreStrip,
      ),
    );
    final body = Flex(
      direction: widget.axis,
      children: widget.isFirst ? [cellsBox, kitchen] : [kitchen, cellsBox],
    );
    if (!widget.dragEnabled) return body;

    return DragTarget<CourtDragSource>(
      onWillAcceptWithDetails: (details) =>
          widget.resolve(details.data, _halfTarget) != null,
      onAcceptWithDetails: (details) {
        final action = widget.resolve(details.data, _halfTarget);
        if (action != null) widget.onDrop(action);
      },
      builder: (context, candidates, _) => _DropOutline(
        active: candidates.isNotEmpty || _switchHover,
        radius: 0,
        thick: true,
        child: body,
      ),
    );
  }
}

/// Green outline drawn over [child] while a drop would do something.
class _DropOutline extends StatelessWidget {
  const _DropOutline({
    required this.active,
    required this.radius,
    required this.child,
    this.thick = false,
  });

  final bool active;
  final double radius;
  final bool thick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: active
            ? Border.all(color: colors.success, width: thick ? 4 : 3)
            : null,
      ),
      child: child,
    );
  }
}

class _CourtCellTile extends StatelessWidget {
  const _CourtCellTile({
    required this.cell,
    required this.team,
    required this.playerIndex,
    required this.playerName,
    required this.isServing,
    required this.dragEnabled,
    required this.motion,
    required this.semanticActions,
  });

  static const _ballSize = 30.0;

  /// Hit area around the ball; the drawing stays [_ballSize].
  static const _ballHitSize = 48.0;

  final CourtCell cell;
  final int team;
  final int? playerIndex;
  final String? playerName;
  final bool isServing;
  final bool dragEnabled;
  final Duration motion;
  final Map<CustomSemanticsAction, VoidCallback> semanticActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cellLabel = cell == CourtCell.right
        ? l10n.pickleballCourtRightCell
        : l10n.pickleballCourtLeftCell;
    final name = playerName;
    final index = playerIndex;
    final semanticsLabel = name == null
        ? cellLabel
        : isServing
        ? '$cellLabel: $name, ${l10n.pickleballServing}'
        : '$cellLabel: $name';
    if (name == null || index == null) {
      return Semantics(label: semanticsLabel, child: const SizedBox.expand());
    }

    final source = CourtDragSource(
      kind: CourtDragKind.player,
      team: team,
      playerIndex: index,
    );
    final shortName = abbreviateName(name);
    final chip = _PlayerChip(
      label: shortName,
      isServing: isServing,
      motion: motion,
    );

    return Semantics(
      label: semanticsLabel,
      customSemanticsActions: semanticActions,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: isServing ? _ballHitSize / 2 : 0,
              right: isServing ? _ballHitSize / 2 : 0,
            ),
            child: dragEnabled
                ? _CourtDraggable(
                    source: source,
                    feedback: _PlayerChip(
                      label: shortName,
                      isServing: isServing,
                      motion: Duration.zero,
                    ),
                    child: chip,
                  )
                : chip,
          ),
          if (isServing)
            Positioned(
              top: 0,
              right: 0,
              child: _ServeBall(
                team: team,
                playerIndex: index,
                dragEnabled: dragEnabled,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.label,
    required this.isServing,
    required this.motion,
  });

  final String label;
  final bool isServing;
  final Duration motion;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: motion,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isServing ? courtServingChipColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: isServing
              ? Border.all(color: courtBallColor, width: 2)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x4412306B),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: courtNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ServeBall extends StatelessWidget {
  const _ServeBall({
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
    final ball = _ballDot(_CourtCellTile._ballSize);
    final source = CourtDragSource(
      kind: CourtDragKind.ball,
      team: team,
      playerIndex: playerIndex,
    );
    final hit = ColoredBox(
      key: serveBallHitKey,
      color: Colors.transparent,
      child: SizedBox.square(
        dimension: _CourtCellTile._ballHitSize,
        child: Center(child: ball),
      ),
    );
    return Semantics(
      label: l10n.pickleballCourtBall,
      excludeSemantics: true,
      child: dragEnabled
          ? _CourtDraggable(
              source: source,
              feedback: ball,
              feedbackSize: const Size.square(_CourtCellTile._ballSize),
              child: hit,
            )
          : hit,
    );
  }

  static Widget _ballDot(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: courtBallColor,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: const Icon(
      Icons.sports_baseball_rounded,
      size: 16,
      color: courtNavy,
    ),
  );
}

/// Long-press then drag; the original dims while dragging and the feedback
/// is centred under the finger.
class _CourtDraggable extends StatelessWidget {
  const _CourtDraggable({
    required this.source,
    required this.feedback,
    required this.child,
    this.feedbackSize = const Size(96, 32),
  });

  static const _longPressDelay = Duration(milliseconds: 250);

  final CourtDragSource source;
  final Widget feedback;
  final Size feedbackSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anchor = Offset(feedbackSize.width / 2, feedbackSize.height / 2);
    return LongPressDraggable<CourtDragSource>(
      data: source,
      delay: _longPressDelay,
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: (_, _, _) => anchor,
      feedback: Material(
        type: MaterialType.transparency,
        child: SizedBox.fromSize(
          size: feedbackSize,
          child: Center(child: feedback),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}
