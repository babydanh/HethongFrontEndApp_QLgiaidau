import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/providers/social_provider.dart';

class SocialDateSelector extends ConsumerWidget {
  const SocialDateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(socialFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final dates = List.generate(
      30,
      (index) => DateTime(today.year, today.month, today.day + index),
    );

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = dates[index];
          final dateKey = DateFormat('yyyy-MM-dd').format(item);
          final isSelected = filterState.selectedDateKey == dateKey;
          final weekLabels = const ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

          return GestureDetector(
            onTap: () {
              ref.read(socialFilterProvider.notifier).setDateKey(dateKey);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.secondary.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    index == 0 ? 'HN' : weekLabels[item.weekday % 7],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
