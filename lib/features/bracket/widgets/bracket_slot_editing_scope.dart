import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_holding_tray.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Owns the drag-and-drop editing state of a bracket diagram: the holding tray
/// contents and the slot mutations sent to the backend. When [enabled] is false
/// (viewers) it offers no tray and no drop handler.
class BracketSlotEditingScope extends ConsumerStatefulWidget {
  final bool enabled;
  final String tournamentId;
  final String? divisionId;
  final bool Function()? isLite;

  /// Called after the backend accepted a change so the host can refetch.
  final VoidCallback onApplied;
  final Widget Function(
    BuildContext context,
    Widget? tray,
    BracketSlotDropCallback? onSlotDrop,
  )
  builder;

  const BracketSlotEditingScope({
    super.key,
    required this.enabled,
    required this.tournamentId,
    this.divisionId,
    this.isLite,
    required this.onApplied,
    required this.builder,
  });

  @override
  ConsumerState<BracketSlotEditingScope> createState() =>
      _BracketSlotEditingScopeState();
}

class _BracketSlotEditingScopeState
    extends ConsumerState<BracketSlotEditingScope> {
  List<BracketSlotDragData> _tray = const [];
  bool _busy = false;

  @override
  void didUpdateWidget(BracketSlotEditingScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Held participants belong to one division; never carry them to another.
    final scopeChanged =
        oldWidget.tournamentId != widget.tournamentId ||
        oldWidget.divisionId != widget.divisionId;
    if (scopeChanged && _tray.isNotEmpty) _tray = const [];
  }

  /// Sends one operation at a time. Returns true only when the backend
  /// accepted it; failures are shown to the user instead of escaping.
  Future<bool> _send(Map<String, String> operation) async {
    if (_busy) return false;
    _busy = true;
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .updateBracketSlots(
            widget.tournamentId,
            divisionId: widget.divisionId,
            operations: [operation],
            isLite: widget.isLite?.call() ?? false,
          );
      return true;
    } on Exception catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.singleElimUpdateError(error.toString()))),
        );
      }
      return false;
    } finally {
      _busy = false;
    }
  }

  BracketSlotDragData _asTrayChip(BracketSlotDragData slot) {
    final id = slot.participantId!;
    final label = slot.label?.trim();
    return BracketSlotDragData.tray(
      participantId: id,
      label: label == null || label.isEmpty ? id : label,
    );
  }

  List<BracketSlotDragData> _trayWith(BracketSlotDragData chip) => [
    for (final existing in _tray)
      if (existing.participantId != chip.participantId) existing,
    chip,
  ];

  Future<void> _handleSlotDrop(
    BracketSlotDragData source,
    BracketSlotDragData target,
  ) async {
    final operation = bracketSlotOperation(source, target);
    if (operation == null) return;
    if (!await _send(operation) || !mounted) return;
    if (source.isFromTray) {
      // REPLACE pushes the previous occupant out of the slot into the tray.
      setState(() {
        _tray = [
          for (final chip in _tray)
            if (chip.participantId != source.participantId) chip,
          if (target.hasParticipant) _asTrayChip(target),
        ];
      });
    }
    widget.onApplied();
  }

  Future<void> _handleTrayDrop(BracketSlotDragData slot) async {
    if (!await _send(bracketUnassignOperation(slot)) || !mounted) return;
    setState(() => _tray = _trayWith(_asTrayChip(slot)));
    widget.onApplied();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.builder(context, null, null);
    return widget.builder(
      context,
      BracketHoldingTray(
        key: const Key('bracket-holding-tray'),
        participants: _tray,
        onSlotDropped: _handleTrayDrop,
      ),
      _handleSlotDrop,
    );
  }
}
