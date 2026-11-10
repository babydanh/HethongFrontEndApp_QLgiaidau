import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';

/// How long a dragged row must stay on an edge before the page turns.
const Duration bracketEdgeHold = Duration(milliseconds: 450);

const double _edgeWidth = 36;

/// While a participant is being dragged ([enabled]), the left and right edges
/// of [child] turn the page: holding the dragged row there for
/// [bracketEdgeHold] calls [onPrev] / [onNext] (null = no page that way) and
/// repeats at the same pace until the row leaves the edge or is dropped.
/// Dropping on an edge changes nothing (the drop is swallowed).
class BracketEdgePager extends StatefulWidget {
  const BracketEdgePager({
    super.key,
    required this.child,
    required this.enabled,
    this.onPrev,
    this.onNext,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  State<BracketEdgePager> createState() => _BracketEdgePagerState();
}

class _BracketEdgePagerState extends State<BracketEdgePager> {
  Timer? _timer;

  // The edge the dragged row is on: true = next (right), false = prev (left).
  bool? _edgeIsNext;

  void _enter(bool next) {
    _timer?.cancel();
    setState(() => _edgeIsNext = next);
    // Read the callbacks when the timer fires: the page may have changed.
    _timer = Timer.periodic(
      bracketEdgeHold,
      (_) => (next ? widget.onNext : widget.onPrev)?.call(),
    );
  }

  void _leave() {
    _timer?.cancel();
    _timer = null;
    if (mounted && _edgeIsNext != null) setState(() => _edgeIsNext = null);
  }

  @override
  void didUpdateWidget(BracketEdgePager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _leave();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _zone({required bool next}) {
    final turns = (next ? widget.onNext : widget.onPrev) != null;
    final lit = turns && _edgeIsNext == next;
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120);
    return Positioned(
      left: next ? null : 0,
      right: next ? 0 : null,
      top: 0,
      bottom: 0,
      width: _edgeWidth,
      child: DragTarget<BracketSlotDragData>(
        key: ValueKey('bracket-edge-${next ? 'next' : 'prev'}'),
        // Accepting without an onAccept swallows a drop on the edge: a reject
        // would pass the drop to the slot lying under the zone.
        onWillAcceptWithDetails: (_) {
          if (turns) _enter(next);
          return true;
        },
        // A drop is not a leave for an accepting target: stop turning here too.
        onAcceptWithDetails: (_) => _leave(),
        onLeave: (_) => _leave(),
        builder: (context, candidates, rejected) => IgnorePointer(
          child: AnimatedOpacity(
            opacity: lit ? 1 : 0,
            duration: fade,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: next ? Alignment.centerRight : Alignment.centerLeft,
                  end: next ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.35),
                    AppTheme.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      children: [widget.child, _zone(next: false), _zone(next: true)],
    );
  }
}
