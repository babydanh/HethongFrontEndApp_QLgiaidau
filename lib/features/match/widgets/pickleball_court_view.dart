import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

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

// Court palette follows the Web mock; it is a fixed "painted court" look and
// does not change with the app theme.
const _courtColor = Color(0xFF8EBDF0);
const _kitchenColor = Color(0xFFB7D4F7);
const _netColor = Color(0xFF94A3B8);
const _navy = Color(0xFF12306B);
const _servingChipColor = Color(0xFFFFF7D1);
const _ballColor = Color(0xFFFACC15);
const _lineColor = Colors.white;
const _lineWidth = 3.0;

/// Key of the 48dp hit area around the serving ball.
const serveBallHitKey = Key('serveBallHit');

/// Resolves a drop to an action, or null when the drop must do nothing.
typedef _ResolveDrop =
    CourtDropAction? Function(CourtDragSource source, CourtDropTarget target);

/// Sơ đồ sân pickleball nằm ngang (2:1): thanh điểm, hai nửa sân ngăn bởi lưới,
/// kéo thả người và trái bóng bằng nhấn giữ, icon hoàn tác / khôi phục.
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
    this.isSideOut = false,
    this.isDoubles = true,
    this.receiverCanScore = false,
    this.autoSwitchEnds = true,
    this.onScoreChange,
    this.onSetServingTeam,
    this.onDrop,
    this.onUndo,
    this.onRestoreAutomatic,
    this.onToggleAutoSwitch,
  });

  static const _pillHeight = 48.0;
  static const _toolsHeight = 48.0;
  static const _gap = 8.0;
  static const _motion = Duration(milliseconds: 240);

  /// Narrowest court drawn at its own size; a smaller slot scales it down.
  static const _minCourtWidth = 240.0;

  /// The block is scaled down to fit a short slot, but never below this
  /// factor (buttons stay >= ~40dp: 44 * 0.92); a shorter slot scrolls instead.
  static const _minScale = 0.92;

  /// Call text (score-score-server) is dropped below this court width.
  static const _callMinWidth = 300.0;

  /// Upper bound of the height the view needs for a court [width] wide
  /// (pills, court and tools), so a parent can reserve room for it.
  static double naturalHeight(double width) =>
      _pillHeight + _gap + width / 2 + _gap + _toolsHeight;

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

  /// Null thì ẩn nút − và +.
  final void Function(int team, bool increment)? onScoreChange;

  /// Gọi trước [onDrop] khi trái bóng được thả sang đội kia (đổi đội giao).
  /// Null thì không cho thả trái bóng sang đội kia.
  final void Function(int team)? onSetServingTeam;

  /// Null thì tắt kéo thả.
  final void Function(CourtDropAction action)? onDrop;
  final VoidCallback? onUndo;
  final VoidCallback? onRestoreAutomatic;
  final VoidCallback? onToggleAutoSwitch;

  bool get _showTools =>
      onUndo != null ||
      onRestoreAutomatic != null ||
      onToggleAutoSwitch != null;

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

  /// Scales the block down to fit, or scrolls it when it is too short.
  static Widget _fitOrScroll({required bool scrolls, required Widget child}) =>
      scrolls
      ? SingleChildScrollView(child: Center(child: child))
      : FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _motion;
    final leftTeam = layout.team1First ? 1 : 2;
    final rightTeam = 3 - leftTeam;

    return LayoutBuilder(
      builder: (context, constraints) {
        // In a short (landscape) slot shrink the court so pills, court and
        // tools fit the height; the court keeps its 2:1 ratio and never goes
        // below [_minCourtWidth]. A slot still too short is scaled down by at
        // most [_minScale]; below that the block scrolls instead.
        final chrome =
            _pillHeight + _gap + (_showTools ? _gap + _toolsHeight : 0);
        final fitWidth = constraints.hasBoundedHeight
            ? math.max(_minCourtWidth, (constraints.maxHeight - chrome) * 2)
            : double.infinity;
        final width = math.min(constraints.maxWidth, fitWidth);
        final scrolls =
            constraints.hasBoundedHeight &&
            constraints.maxHeight < (chrome + _minCourtWidth / 2) * _minScale;
        return Align(
          alignment: Alignment.topCenter,
          child: _fitOrScroll(
            scrolls: scrolls,
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ScoreBar(
                    leftTeam: leftTeam,
                    rightTeam: rightTeam,
                    scoreOf: _scoreOf,
                    layout: layout,
                    showCall: width >= _callMinWidth,
                    lockReceiverPlus: isSideOut && !receiverCanScore,
                    onScoreChange: onScoreChange,
                  ),
                  const SizedBox(height: _gap),
                  AspectRatio(
                    aspectRatio: 2,
                    child: _CourtSurface(
                      layout: layout,
                      leftTeam: leftTeam,
                      rightTeam: rightTeam,
                      team1Players: team1Players,
                      team2Players: team2Players,
                      motion: motion,
                      dragEnabled: onDrop != null,
                      resolve: _resolve,
                      onDrop: _handleDrop,
                    ),
                  ),
                  if (_showTools) ...[
                    const SizedBox(height: _gap),
                    _CourtTools(
                      autoSwitchEnds: autoSwitchEnds,
                      onUndo: onUndo,
                      onRestoreAutomatic: onRestoreAutomatic,
                      onToggleAutoSwitch: onToggleAutoSwitch,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.leftTeam,
    required this.rightTeam,
    required this.scoreOf,
    required this.layout,
    required this.showCall,
    required this.lockReceiverPlus,
    required this.onScoreChange,
  });

  final int leftTeam;
  final int rightTeam;
  final int Function(int team) scoreOf;
  final CourtLayout layout;
  final bool showCall;

  /// Plus is disabled for the team that is not serving.
  final bool lockReceiverPlus;
  final void Function(int team, bool increment)? onScoreChange;

  Widget _pill(int team) => _ScorePill(
    team: team,
    score: scoreOf(team),
    isServing: layout.servingTeam == team,
    plusEnabled: !lockReceiverPlus || layout.servingTeam == team,
    onScoreChange: onScoreChange,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final servingScore = layout.servingScore;
    final receivingScore = layout.receivingScore;
    final call = layout.callServerNumber;
    final callText = !showCall || servingScore == null || receivingScore == null
        ? null
        : call == null
        ? '$servingScore-$receivingScore'
        : '$servingScore-$receivingScore-$call';

    return SizedBox(
      height: PickleballCourtView._pillHeight,
      child: Row(
        children: [
          Expanded(child: _pill(leftTeam)),
          if (callText != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Semantics(
                label: '${l10n.pickleballCourtCallLabel}: $callText',
                excludeSemantics: true,
                child: Text(
                  callText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
          Expanded(child: _pill(rightTeam)),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.team,
    required this.score,
    required this.isServing,
    required this.plusEnabled,
    required this.onScoreChange,
  });

  /// Drawn size of the round buttons; their hit area is larger.
  static const _visualSize = 32.0;

  /// Below this pill width the hit area is 44dp instead of 48dp so the score
  /// still fits (short landscape slot).
  static const _roomyWidth = 130.0;

  final int team;
  final int score;
  final bool isServing;
  final bool plusEnabled;
  final void Function(int team, bool increment)? onScoreChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final change = onScoreChange;

    return Container(
      height: PickleballCourtView._pillHeight,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      // Border painted over the pill so it does not shrink the 48dp hit area.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isServing ? _ballColor : colors.border,
          width: isServing ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hit = constraints.maxWidth >= _roomyWidth ? 48.0 : 44.0;
          return Row(
            children: [
              if (change != null)
                _RoundButton(
                  icon: Icons.remove_rounded,
                  tooltip: l10n.pickleballCourtRemovePoint(team),
                  hitSize: hit,
                  onPressed: score > 0 ? () => change(team, false) : null,
                ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              if (change != null)
                _RoundButton(
                  icon: Icons.add_rounded,
                  tooltip: l10n.pickleballCourtAddPoint(team),
                  hitSize: hit,
                  filled: true,
                  onPressed: plusEnabled ? () => change(team, true) : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Round 32dp button inside a larger hit area, so the drawing stays small but
/// the touch target is not.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.hitSize,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final double hitSize;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    final foreground = filled ? Colors.white : colors.textPrimary;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: hitSize, height: hitSize),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.square(hitSize),
      ),
      icon: Container(
        width: _ScorePill._visualSize,
        height: _ScorePill._visualSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? AppTheme.primary.withValues(alpha: enabled ? 1 : 0.3)
              : null,
          border: filled ? null : Border.all(color: colors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? foreground : foreground.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}

class _CourtTools extends StatelessWidget {
  const _CourtTools({
    required this.autoSwitchEnds,
    required this.onUndo,
    required this.onRestoreAutomatic,
    required this.onToggleAutoSwitch,
  });

  /// 48dp touch target whatever the platform default tap target is.
  static final _toolStyle = IconButton.styleFrom(
    tapTargetSize: MaterialTapTargetSize.padded,
    minimumSize: const Size.square(48),
  );

  final bool autoSwitchEnds;
  final VoidCallback? onUndo;
  final VoidCallback? onRestoreAutomatic;
  final VoidCallback? onToggleAutoSwitch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return SizedBox(
      height: PickleballCourtView._toolsHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: l10n.pickleballCourtUndo,
            onPressed: onUndo,
            style: _toolStyle,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: l10n.pickleballCourtRestoreAutomatic,
            onPressed: onRestoreAutomatic,
            style: _toolStyle,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            tooltip: l10n.pickleballCourtAutoSwitch,
            onPressed: onToggleAutoSwitch,
            isSelected: autoSwitchEnds,
            style: _toolStyle.copyWith(
              foregroundColor: WidgetStatePropertyAll(
                autoSwitchEnds ? AppTheme.primary : colors.textSecondary,
              ),
              backgroundColor: WidgetStatePropertyAll(
                autoSwitchEnds
                    ? AppTheme.primary.withValues(alpha: 0.16)
                    : null,
              ),
            ),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
    );
  }
}

class _CourtSurface extends StatelessWidget {
  const _CourtSurface({
    required this.layout,
    required this.leftTeam,
    required this.rightTeam,
    required this.team1Players,
    required this.team2Players,
    required this.motion,
    required this.dragEnabled,
    required this.resolve,
    required this.onDrop,
  });

  final CourtLayout layout;
  final int leftTeam;
  final int rightTeam;
  final List<String> team1Players;
  final List<String> team2Players;
  final Duration motion;
  final bool dragEnabled;
  final _ResolveDrop resolve;
  final void Function(CourtDropAction action) onDrop;

  Widget _half(int team, {required bool isLeft}) => Expanded(
    child: _CourtHalf(
      team: team,
      isLeft: isLeft,
      layout: layout,
      players: team == 1 ? team1Players : team2Players,
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
        team: leftTeam,
        playerIndex: 0,
      ),
      CourtDropTarget.half(team: rightTeam),
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
      child: _court(),
    );
  }

  Widget _court() {
    return Container(
      decoration: BoxDecoration(
        color: _courtColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _lineColor, width: _lineWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _half(leftTeam, isLeft: true),
          Container(
            width: 14,
            decoration: const BoxDecoration(
              color: _netColor,
              border: Border.symmetric(
                vertical: BorderSide(color: _lineColor, width: 2),
              ),
            ),
          ),
          _half(rightTeam, isLeft: false),
        ],
      ),
    );
  }
}

/// One half of the court. Cells face the net: on the left half the left cell is
/// on top and the right cell below; on the right half the other way round.
class _CourtHalf extends StatefulWidget {
  const _CourtHalf({
    required this.team,
    required this.isLeft,
    required this.layout,
    required this.players,
    required this.motion,
    required this.dragEnabled,
    required this.resolve,
    required this.onDrop,
  });

  final int team;
  final bool isLeft;
  final CourtLayout layout;
  final List<String> players;
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

  @override
  Widget build(BuildContext context) {
    final cells = widget.isLeft
        ? const [CourtCell.left, CourtCell.right]
        : const [CourtCell.right, CourtCell.left];
    final cellsColumn = Expanded(
      flex: 76,
      child: Column(
        children: [
          _cell(cells[0]),
          Container(height: _lineWidth, color: _lineColor),
          _cell(cells[1]),
        ],
      ),
    );
    final kitchen = Expanded(
      flex: 24,
      child: Container(
        decoration: BoxDecoration(
          color: _kitchenColor,
          border: Border(
            left: widget.isLeft
                ? const BorderSide(color: _lineColor, width: _lineWidth)
                : BorderSide.none,
            right: widget.isLeft
                ? BorderSide.none
                : const BorderSide(color: _lineColor, width: _lineWidth),
          ),
        ),
      ),
    );
    final body = Row(
      children: widget.isLeft ? [cellsColumn, kitchen] : [kitchen, cellsColumn],
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
          color: isServing ? _servingChipColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: isServing ? Border.all(color: _ballColor, width: 2) : null,
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
            color: _navy,
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
      color: _ballColor,
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
    child: const Icon(Icons.sports_baseball_rounded, size: 16, color: _navy),
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
