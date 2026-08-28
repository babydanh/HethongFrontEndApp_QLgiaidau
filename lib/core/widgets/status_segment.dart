import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Segment tabs cho trạng thái, thiết kế phẳng tràn viền theo SportO Vibe
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
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgDark,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: items.map((item) {
          final isActive = selected == item.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.key),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                          color: isActive
                              ? AppTheme.webPrimary
                              : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      bottom: 0,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: AppTheme.webPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
