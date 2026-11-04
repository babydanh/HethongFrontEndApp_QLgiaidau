import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_palette.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const _iconButtonSize = 44.0;
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

enum _MenuItem { switchEnds, undo, restore, autoSwitch, override, forceWin }

/// The ⋯ button and its popup menu.
class CourtMenuButton extends StatelessWidget {
  const CourtMenuButton({super.key, required this.actions});

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
