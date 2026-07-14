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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: items.map((item) {
            final isActive = selected == item.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? (isDark ? Colors.white10 : Colors.white) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: isActive && !isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive 
                          ? AppTheme.primary 
                          : (isDark ? Colors.white70 : Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
