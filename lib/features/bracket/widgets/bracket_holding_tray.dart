import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Temporary holding area for the bracket editor: drop a slot here to free it,
/// then long-press a chip to place that participant into another slot.
class BracketHoldingTray extends StatelessWidget {
  final List<BracketSlotDragData> participants;
  final Future<void> Function(BracketSlotDragData source) onSlotDropped;

  const BracketHoldingTray({
    super.key,
    required this.participants,
    required this.onSlotDropped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return DragTarget<BracketSlotDragData>(
      onWillAcceptWithDetails: (details) =>
          !details.data.isFromTray &&
          details.data.hasParticipant &&
          !details.data.isLocked,
      onAcceptWithDetails: (details) => onSlotDropped(details.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hovering ? colors.bgElevated : colors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hovering ? colors.info : colors.border,
              width: hovering ? 1.5 : 1,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 16, color: colors.textMuted),
              Text(
                l10n.bracketTrayTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              if (participants.isEmpty)
                Text(
                  l10n.bracketTrayEmpty,
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                )
              else
                for (final participant in participants)
                  _TrayChip(participant: participant),
            ],
          ),
        );
      },
    );
  }
}

class _TrayChip extends StatelessWidget {
  final BracketSlotDragData participant;

  const _TrayChip({required this.participant});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = participant.label ?? '';
    Widget chip({double opacity = 1}) => Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.chipBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.textPrimary),
        ),
      ),
    );

    return LongPressDraggable<BracketSlotDragData>(
      key: ValueKey('bracket-tray-chip-${participant.participantId}'),
      data: participant,
      feedback: Material(color: Colors.transparent, child: chip()),
      childWhenDragging: chip(opacity: 0.35),
      child: chip(),
    );
  }
}
