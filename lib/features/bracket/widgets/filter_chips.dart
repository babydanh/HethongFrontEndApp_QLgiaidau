import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// A pill-style round filter button for bracket views.
/// Styled with borderRadius: 20, padding: 8,16, fontSize: 12, fontWeight: w600.
/// Selected state: primary bg + white text, unselected: bgSurface + textSecondary.
class RoundFilterPill extends StatelessWidget {
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  const RoundFilterPill({
    super.key,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : colors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : colors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A unified filter chip widget for bracket filtering.
/// Kept for backward compatibility but delegates to [RoundFilterChip].
@Deprecated('Use RoundFilterPill instead')
class BracketFilterChip extends StatelessWidget {
  final bool isSelected;
  final String label;
  final ValueChanged<bool> onSelected;

  const BracketFilterChip({
    super.key,
    required this.isSelected,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : colors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: BorderSide(color: isSelected ? Colors.transparent : colors.border),
      ),
      showCheckmark: false,
    );
  }
}
