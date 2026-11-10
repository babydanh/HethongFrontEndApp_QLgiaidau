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
    this.onDragChanged,
  });

  final BracketSlotDropCallback onSlotDrop;
  final ValueChanged<BracketSlotDragData> onSlotTap;
  final BracketSlotDragData? selectedSlot;

  /// Tells the board when a row is lifted (true) or let go (false), so the
  /// edge pager can wake up. Called more than once per drag; stay idempotent.
  final ValueChanged<bool>? onDragChanged;
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
    this.onDragChanged,
  });

  final BracketSlotDragData data;

  /// This slot is the source picked by the first tap of a tap-tap move.
  final bool selected;
  final ValueChanged<BracketSlotDragData> onTap;
  final BracketSlotDropCallback onDrop;
  final Widget child;
  final ValueChanged<bool>? onDragChanged;

  @override
  Widget build(BuildContext context) {
    final canDrag = data.hasParticipant && !data.isLocked;
    // Reduced motion: jump straight to the end state.
    final still = MediaQuery.disableAnimationsOf(context);
    return DragTarget<BracketSlotDragData>(
      key: ValueKey('bracket-slot-${data.matchId}-${data.slot}'),
      onWillAcceptWithDetails: (details) =>
          bracketSlotOperation(details.data, data) != null,
      onAcceptWithDetails: (details) => onDrop(details.data, data),
      builder: (context, candidates, rejected) {
        final highlighted = candidates.isNotEmpty || selected;
        final row = AnimatedContainer(
          duration: still ? Duration.zero : const Duration(milliseconds: 140),
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
          // A swap or move changes who sits here: the new name fades in.
          child: AnimatedSwitcher(
            duration: still ? Duration.zero : const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            child: KeyedSubtree(
              key: ValueKey(data.participantId),
              child: child,
            ),
          ),
        );
        return LongPressDraggable<BracketSlotDragData>(
          data: data,
          delay: bracketDragDelay,
          maxSimultaneousDrags: canDrag ? 1 : 0,
          onDragStarted: () => onDragChanged?.call(true),
          // onDragEnd is skipped when the row is gone (the page turned), the
          // other two still fire.
          onDragEnd: (_) => onDragChanged?.call(false),
          onDragCompleted: () => onDragChanged?.call(false),
          onDraggableCanceled: (_, _) => onDragChanged?.call(false),
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
