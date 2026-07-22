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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(context, 'Tất cả', 'all'),
          const SizedBox(width: 8),
          ...AppConstants.sportNames.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(context, e.value, e.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, String key) {
    final isSelected = selectedSport == key;
    return GestureDetector(
      onTap: () => onSportChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : context.colors.bgCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppTheme.primary : context.colors.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
