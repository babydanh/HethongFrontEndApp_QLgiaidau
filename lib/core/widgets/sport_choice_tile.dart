import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import 'app_icons.dart';

/// Canonical sport selector tile used by filters and creation forms.
///
/// Sport keys remain the API values; this widget only owns the visual
/// treatment and resolves the shared SVG/PNG sport assets through
/// [AppSportIcon]. Keeping that mapping at the UI edge prevents each form
/// from drifting to a different Material glyph or spacing.
class SportChoiceTile extends StatelessWidget {
  final String sportKey;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool expanded;
  final double iconSize;
  final bool withTrailingGap;

  const SportChoiceTile({
    super.key,
    required this.sportKey,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expanded = true,
    this.iconSize = 22,
    this.withTrailingGap = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? AppTheme.primary : colors.textSecondary;
    final child = Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.10)
                : colors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSportIcon(
                sportKey: sportKey,
                size: iconSize,
                color: foreground,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!expanded) return child;
    return Expanded(
      child: withTrailingGap
          ? Padding(padding: const EdgeInsets.only(right: 8), child: child)
          : child,
    );
  }
}
