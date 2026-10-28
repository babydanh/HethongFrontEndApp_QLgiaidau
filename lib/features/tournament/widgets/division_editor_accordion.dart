import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

/// One accordion row of the division editor: a header with a one-line
/// [summary] and, when [expanded], the [child] body. A row without [child]
/// is an action row (shows a play icon instead of the chevron).
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
    final colors = context.colors;
    final body = child;
    // Material (not a decorated box) so ListTile children can paint ink.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: ValueKey('division-editor-section-$id'),
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                          ),
                          if (summary.isNotEmpty)
                            Text(
                              summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (locked)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    Icon(
                      body == null
                          ? Icons.play_circle_outline_rounded
                          : expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (body != null && expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: body,
              ),
          ],
        ),
      ),
    );
  }
}
