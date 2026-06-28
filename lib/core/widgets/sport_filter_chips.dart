import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';

/// Bộ lọc môn thể thao dạng chip ngang, dùng chung cho mọi tab
class SportFilterChips extends StatelessWidget {
  final String selectedSport;
  final ValueChanged<String> onSportChanged;

  const SportFilterChips({
    super.key,
    required this.selectedSport,
    required this.onSportChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(context, 'Tất cả', 'all', Icons.grid_view_rounded),
          const SizedBox(width: 8),
          ...AppConstants.sportNames.entries.map((e) {
            final iconData = AppConstants.sportIcons[e.key];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(context, e.value, e.key, iconData),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, String key, dynamic icon) {
    final isSelected = selectedSport == key;
    return GestureDetector(
      onTap: () => onSportChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : context.colors.bgCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppTheme.primary : context.colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon is IconData)
              Icon(icon, size: 14, color: isSelected ? AppTheme.primary : context.colors.textSecondary)
            else if (icon is String)
              icon.endsWith('.png') || icon.contains('/')
                  ? Image.asset(
                      icon,
                      width: 14,
                      height: 14,
                      color: isSelected ? AppTheme.primary : context.colors.textSecondary,
                    )
                  : Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
