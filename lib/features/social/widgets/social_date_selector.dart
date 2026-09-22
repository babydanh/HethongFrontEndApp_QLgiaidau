import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';

class SocialDateOption {
  final String dayOfWeek;
  final int dayOfMonth;
  final DateTime date;

  const SocialDateOption({
    required this.dayOfWeek,
    required this.dayOfMonth,
    required this.date,
  });
}

class SocialDateSelector extends ConsumerWidget {
  const SocialDateSelector({super.key});

  static const List<String> _dayOfWeekLabels = [
    '',
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  static List<SocialDateOption> get dateOptions {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);
    return List.generate(14, (index) {
      final date =
          DateTime(firstDay.year, firstDay.month, firstDay.day + index);
      return SocialDateOption(
        dayOfWeek: _dayOfWeekLabels[date.weekday],
        dayOfMonth: date.day,
        date: date,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(socialFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = dateOptions;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = options[index];
          final isSelected = filterState.isSameDate(item.date);

          return GestureDetector(
            onTap: () {
              ref
                  .read(socialFilterProvider.notifier)
                  .setSelectedDate(item.date);
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
                    item.dayOfWeek,
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
                    '${item.dayOfMonth}',
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
