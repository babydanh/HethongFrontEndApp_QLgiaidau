import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Segment tabs cho trạng thái, dùng chung (sắp diễn ra / live / hoàn thành)
class StatusSegment extends StatelessWidget {
  final List<({String key, String label})> items;
  final String selected;
  final ValueChanged<String> onChanged;

  const StatusSegment({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((item) {
          final isActive = selected == item.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(item.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : context.colors.bgCard,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isActive ? AppTheme.primary : context.colors.border,
                  ),
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : context.colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
