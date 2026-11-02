import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_palette.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Key of the strip (or column) that holds the net and its icon controls.
const courtNetKey = Key('courtNet');

/// Key of the icon controls inside the net strip.
const courtNetControlsKey = Key('courtNetControls');

/// Thickness of the net strip. Wide enough for a 44dp icon plus the lines.
const courtNetThickness = 64.0;

const _iconButtonSize = 44.0;
const _scoreButtonVisual = 32.0;
const _scoreButtonHit = 44.0;
const _finishColor = Color(0xFF16A34A);

/// Actions of the ⋯ menu; a null callback hides (or disables) its item.
class CourtMenuActions {
  const CourtMenuActions({
    this.onSwitchEnds,
    this.onUndo,
    this.onRestoreAutomatic,
    this.onToggleAutoSwitch,
    this.autoSwitchEnds = true,
    this.onToggleOverride,
    this.overrideEnabled = false,
    this.onForceWin,
  });

  final VoidCallback? onSwitchEnds;
  final VoidCallback? onUndo;
  final VoidCallback? onRestoreAutomatic;
  final VoidCallback? onToggleAutoSwitch;
  final bool autoSwitchEnds;

  /// Null in Lite: there is no exception there, so the item is not drawn.
  final VoidCallback? onToggleOverride;
  final bool overrideEnabled;

  /// Null when the caller offers no quick-win action.
  final VoidCallback? onForceWin;

  bool get hasAny =>
      onSwitchEnds != null ||
      onUndo != null ||
      onRestoreAutomatic != null ||
      onToggleAutoSwitch != null ||
      onToggleOverride != null ||
      onForceWin != null;
}

/// Icon controls drawn on the net: ⋯, finish set, winner cup, lose serve.
class CourtNetActions {
  const CourtNetActions({
    this.menu = const CourtMenuActions(),
    this.onFinishSet,
    this.finishSetEnabled = true,
    this.onPickWinner,
    this.pickWinnerEnabled = true,
    this.onLoseServe,
  });

  final CourtMenuActions menu;
  final VoidCallback? onFinishSet;
  final bool finishSetEnabled;
  final VoidCallback? onPickWinner;
  final bool pickWinnerEnabled;

  /// Null in rally and Lite: there is no serve turn to lose.
  final VoidCallback? onLoseServe;
}

/// The net: a column between the halves of a horizontal court, a row between
/// the halves of a vertical one. Holds the call text and the icon controls, and
/// never text buttons.
class CourtNetBand extends StatelessWidget {
  const CourtNetBand({
    super.key,
    required this.courtAxis,
    required this.callText,
    required this.actions,
  });

  /// Direction the halves are laid out in (the court's axis).
  final Axis courtAxis;
  final String? callText;
  final CourtNetActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bandAxis = courtAxis == Axis.vertical
        ? Axis.horizontal
        : Axis.vertical;
    final lineSide = const BorderSide(color: courtLineColor, width: 2);
    final children = <Widget>[
      if (actions.menu.hasAny) _MenuButton(actions: actions.menu),
      if (callText != null)
        Semantics(
          label: '${l10n.pickleballCourtCallLabel}: $callText',
          excludeSemantics: true,
          child: _CallText(callText!),
        ),
      if (actions.onFinishSet != null)
        _NetIcon(
          icon: Icons.check_rounded,
          tooltip: l10n.pickleballCourtFinishSet,
          onPressed: actions.finishSetEnabled ? actions.onFinishSet : null,
          background: _finishColor,
          foreground: Colors.white,
        ),
      if (actions.onPickWinner != null)
        _NetIcon(
          icon: Icons.emoji_events_rounded,
          tooltip: l10n.pickleballCourtPickWinner,
          onPressed: actions.pickWinnerEnabled ? actions.onPickWinner : null,
          background: courtBallColor,
          foreground: courtNavy,
        ),
      if (actions.onLoseServe != null)
        _NetIcon(
          icon: Icons.last_page_rounded,
          tooltip: l10n.pickleballCourtLoseServe,
          onPressed: actions.onLoseServe,
          background: courtServingChipColor,
          foreground: courtNavy,
          outline: courtBallColor,
        ),
    ];
    return Container(
      key: courtNetKey,
      width: bandAxis == Axis.vertical ? courtNetThickness : null,
      height: bandAxis == Axis.horizontal ? courtNetThickness : null,
      decoration: BoxDecoration(
        color: courtNetColor,
        border: bandAxis == Axis.vertical
            ? Border.symmetric(vertical: lineSide)
            : Border.symmetric(horizontal: lineSide),
      ),
      alignment: Alignment.center,
      // A short slot scales the controls down instead of overflowing.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Flex(
          key: courtNetControlsKey,
          direction: bandAxis,
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: children,
        ),
      ),
    );
  }
}

class _CallText extends StatelessWidget {
  const _CallText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // The call shrinks itself to the net's thickness, so a long call never
    // forces the icons beside it to shrink.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: courtNetThickness - 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: courtNavy,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round icon on the net; 44dp so it stays a comfortable touch target.
class _NetIcon extends StatelessWidget {
  const _NetIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.outline,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _iconButtonSize,
        height: _iconButtonSize,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        fixedSize: const Size.square(_iconButtonSize),
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.35),
        disabledForegroundColor: foreground.withValues(alpha: 0.4),
        shape: CircleBorder(
          side: outline == null
              ? BorderSide.none
              : BorderSide(color: outline!, width: 2),
        ),
        elevation: enabled ? 2 : 0,
        shadowColor: Colors.black54,
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

enum _MenuItem { switchEnds, undo, restore, autoSwitch, override, forceWin }

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.actions});

  final CourtMenuActions actions;

  PopupMenuItem<_MenuItem> _item(
    _MenuItem value,
    IconData icon,
    String label, {
    required bool enabled,
    bool? checked,
    Color? color,
  }) {
    return PopupMenuItem<_MenuItem>(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: color)),
          ),
          if (checked ?? false)
            const Icon(Icons.check_rounded, size: 18, color: _finishColor),
        ],
      ),
    );
  }

  void _run(_MenuItem item) {
    switch (item) {
      case _MenuItem.switchEnds:
        actions.onSwitchEnds?.call();
      case _MenuItem.undo:
        actions.onUndo?.call();
      case _MenuItem.restore:
        actions.onRestoreAutomatic?.call();
      case _MenuItem.autoSwitch:
        actions.onToggleAutoSwitch?.call();
      case _MenuItem.override:
        actions.onToggleOverride?.call();
      case _MenuItem.forceWin:
        actions.onForceWin?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_MenuItem>(
      tooltip: l10n.pickleballCourtMenu,
      padding: EdgeInsets.zero,
      onSelected: _run,
      itemBuilder: (_) => [
        _item(
          _MenuItem.switchEnds,
          Icons.swap_vert_rounded,
          l10n.pickleballCourtActionSwitchEnds,
          enabled: actions.onSwitchEnds != null,
        ),
        _item(
          _MenuItem.undo,
          Icons.undo_rounded,
          l10n.pickleballCourtUndo,
          enabled: actions.onUndo != null,
        ),
        _item(
          _MenuItem.restore,
          Icons.restart_alt_rounded,
          l10n.pickleballCourtRestoreAutomatic,
          enabled: actions.onRestoreAutomatic != null,
        ),
        _item(
          _MenuItem.autoSwitch,
          Icons.swap_horiz_rounded,
          l10n.pickleballCourtAutoSwitch,
          enabled: actions.onToggleAutoSwitch != null,
          checked: actions.autoSwitchEnds,
        ),
        if (actions.onToggleOverride != null)
          _item(
            _MenuItem.override,
            Icons.rule_rounded,
            l10n.matchOverrideLabel,
            enabled: true,
            checked: actions.overrideEnabled,
          ),
        if (actions.onForceWin != null)
          _item(
            _MenuItem.forceWin,
            Icons.flag_rounded,
            l10n.matchForceWin,
            enabled: true,
            color: context.colors.error,
          ),
      ],
      child: Container(
        width: _iconButtonSize,
        height: _iconButtonSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(Icons.more_horiz_rounded, color: courtNavy),
      ),
    );
  }
}

/// `−`, the score and `+` of one team, inside its kitchen strip. A horizontal
/// court stacks them (plus on top); a vertical court lines them up.
class CourtKitchenScore extends StatelessWidget {
  const CourtKitchenScore({
    super.key,
    required this.courtAxis,
    required this.team,
    required this.accent,
    required this.score,
    required this.isServing,
    required this.plusEnabled,
    required this.onScoreChange,
    required this.motion,
  });

  final Axis courtAxis;
  final int team;

  /// Color of the plus button: the team's color.
  final Color accent;
  final int score;
  final bool isServing;
  final bool plusEnabled;

  /// Null hides both buttons (read-only).
  final void Function(int team, bool increment)? onScoreChange;
  final Duration motion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final change = onScoreChange;
    final minus = change == null
        ? null
        : _ScoreButton(
            icon: Icons.remove_rounded,
            tooltip: l10n.pickleballCourtRemovePoint(team),
            onPressed: score > 0 ? () => change(team, false) : null,
          );
    final plus = change == null
        ? null
        : _ScoreButton(
            icon: Icons.add_rounded,
            tooltip: l10n.pickleballCourtAddPoint(team),
            filled: true,
            accent: accent,
            onPressed: plusEnabled ? () => change(team, true) : null,
          );
    final number = _ScoreNumber(
      score: score,
      isServing: isServing,
      motion: motion,
    );
    final vertical = courtAxis == Axis.vertical;
    // Vertical court: − score + along the strip. Horizontal: + score − stacked.
    final items = vertical ? [?minus, number, ?plus] : [?plus, number, ?minus];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Flex(
        direction: vertical ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: items,
      ),
    );
  }
}

class _ScoreNumber extends StatelessWidget {
  const _ScoreNumber({
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
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isServing ? courtServingChipColor : null,
        borderRadius: BorderRadius.circular(10),
        border: isServing ? Border.all(color: courtBallColor, width: 2) : null,
      ),
      child: AnimatedSwitcher(
        duration: motion,
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Text(
          '$score',
          key: ValueKey<int>(score),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: courtNavy,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Round 32dp button inside a 44dp hit area: small drawing, comfortable touch.
class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
    this.accent,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = filled ? Colors.white : courtNavy;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _scoreButtonHit,
        height: _scoreButtonHit,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size.square(_scoreButtonHit),
      ),
      icon: Container(
        width: _scoreButtonVisual,
        height: _scoreButtonVisual,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? (accent ?? AppTheme.primary).withValues(
                  alpha: enabled ? 1 : 0.3,
                )
              : Colors.white.withValues(alpha: enabled ? 1 : 0.5),
          border: filled
              ? null
              : Border.all(color: courtNavy.withValues(alpha: 0.2)),
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
