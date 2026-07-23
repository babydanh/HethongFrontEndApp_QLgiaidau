import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class DivisionFilterSegment extends StatelessWidget {
  final List<String> divisions;
  final String selectedDivision;
  final ValueChanged<String> onDivisionChanged;

  const DivisionFilterSegment({
    super.key,
    required this.divisions,
    required this.selectedDivision,
    required this.onDivisionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (divisions.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: divisions.map((div) {
            final isSelected = div == selectedDivision;
            return GestureDetector(
              onTap: () => onDivisionChanged(div),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2979FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  div,
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.colors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
