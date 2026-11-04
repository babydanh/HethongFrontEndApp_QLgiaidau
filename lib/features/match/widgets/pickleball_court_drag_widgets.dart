import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Key of the painted court (cells, kitchens and net).
const courtSurfaceKey = Key('courtSurface');

/// Resolves a drop to an action, or null when the drop must do nothing.
typedef ResolveCourtDrop =
    CourtDropAction? Function(CourtDragSource source, CourtDropTarget target);

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

/// What a tap (or a screen reader) can do with one player, without dragging:
/// the same drop, resolved and applied through the same callbacks, so
/// permissions and singles rules hold for both. Keys are labels.
Map<String, VoidCallback> courtPlayerActions({
  required AppLocalizations l10n,
  required int team,
  required int playerIndex,
  required ResolveCourtDrop resolve,
  required void Function(CourtDropAction action) onDrop,
}) {
  final swap = resolve(
    CourtDragSource(team: team, playerIndex: playerIndex),
    CourtDropTarget.half(team: team),
  );
  if (swap == null) return const {};
  return {l10n.pickleballCourtActionSwapPlaces: () => onDrop(swap)};
}

/// Green outline drawn over [child] while a drop would do something.
class CourtDropOutline extends StatelessWidget {
  const CourtDropOutline({
    super.key,
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

/// Long-press then drag; the original dims while dragging and the feedback
/// is centred under the finger.
class CourtDraggable extends StatelessWidget {
  const CourtDraggable({
    super.key,
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
      // Empty space inside the child counts, so a roomy child is grabbable
      // anywhere, not only on its text.
      hitTestBehavior: HitTestBehavior.opaque,
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
