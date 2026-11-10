import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';

/// What a playoff board needs to let a manager move participants between
/// slots: the drop handler of `BracketSlotEditingScope` (or a test double),
/// plus the tap-tap flow (the picked source slot and the tap handler).
class BracketEditing {
  const BracketEditing({
    required this.onSlotDrop,
    required this.onSlotTap,
    this.selectedSlot,
  });

  final BracketSlotDropCallback onSlotDrop;
  final ValueChanged<BracketSlotDragData> onSlotTap;
  final BracketSlotDragData? selectedSlot;
}

/// One participant slot of a bracket card. A manager long-presses it and drops
/// it on another slot (SWAP / MOVE), or taps one slot and then another when the
/// target is on another page. Locked, BYE and empty slots cannot be lifted.
class BracketSlotRow extends StatelessWidget {
  const BracketSlotRow({
    super.key,
    required this.data,
    required this.selected,
    required this.onTap,
    required this.onDrop,
    required this.child,
  });

  final BracketSlotDragData data;

  /// This slot is the source picked by the first tap of a tap-tap move.
  final bool selected;
  final ValueChanged<BracketSlotDragData> onTap;
  final BracketSlotDropCallback onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canDrag = data.hasParticipant && !data.isLocked;
    return DragTarget<BracketSlotDragData>(
      key: ValueKey('bracket-slot-${data.matchId}-${data.slot}'),
      onWillAcceptWithDetails: (details) =>
          bracketSlotOperation(details.data, data) != null,
      onAcceptWithDetails: (details) => onDrop(details.data, data),
      builder: (context, candidates, rejected) {
        final highlighted = candidates.isNotEmpty || selected;
        final row = AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: highlighted
                ? AppTheme.primary.withValues(alpha: 0.14)
                : null,
            border: Border.all(
              color: highlighted ? AppTheme.primary : Colors.transparent,
              width: highlighted ? 1.5 : 0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
        return LongPressDraggable<BracketSlotDragData>(
          data: data,
          delay: bracketDragDelay,
          maxSimultaneousDrags: canDrag ? 1 : 0,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary, width: 1.5),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black26),
                ],
              ),
              child: Text(
                data.label ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.38, child: row),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canDrag || data.canReceiveMove ? () => onTap(data) : null,
            child: row,
          ),
        );
      },
    );
  }
}
