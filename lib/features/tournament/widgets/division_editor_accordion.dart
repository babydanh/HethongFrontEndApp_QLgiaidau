import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:flutter/material.dart';

/// One accordion row of the division editor (design `.li` + `.go`): a header
/// with a one-line [summary] and, when [expanded], the [child] body on a soft
/// grey band. A row without [child] is an action row (play icon box instead of
/// the chevron).
///
/// The parent keeps the single open id, so opening one row closes the rest.
class DivisionEditorAccordionSection extends StatelessWidget {
  const DivisionEditorAccordionSection({
    super.key,
    required this.id,
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    this.locked = false,
    this.child,
  });

  /// Suffix of the header key: `division-editor-section-<id>`.
  final String id;
  final String title;
  final String summary;
  final bool expanded;
  final VoidCallback onToggle;

  /// Shows a lock icon: the structure inside can no longer change.
  final bool locked;

  /// Body shown when [expanded]; null makes this an action row.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    final body = child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishRow(
          key: ValueKey('division-editor-section-$id'),
          title: title,
          subtitle: summary.isEmpty ? null : summary,
          onTap: onToggle,
          trailing: [
            if (locked)
              Icon(Icons.lock_outline_rounded, size: 16, color: colors.faint),
            if (body == null)
              const LavishIconBox(
                child: Icon(Icons.play_arrow_rounded, size: 18),
              )
            else
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
                color: colors.faint,
              ),
          ],
        ),
        if (body != null && expanded)
          // Material so ListTile children paint their ink on the band colour.
          Material(
            color: colors.dark ? colors.rowLine : const Color(0xFFF9FAFB),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.rowLine)),
              ),
              child: body,
            ),
          ),
      ],
    );
  }
}
