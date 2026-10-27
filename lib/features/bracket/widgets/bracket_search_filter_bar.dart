import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// One compact, single-colour bar: search field on the left, filter button on
/// the right. Kept short (~36 dp) so it fits above the bracket diagram.
class BracketSearchFilterBar extends StatelessWidget {
  const BracketSearchFilterBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.hasActiveFilters,
    required this.activeCount,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final String hint;
  final bool hasActiveFilters;
  final int activeCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const radius = BorderRadius.all(Radius.circular(10));
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: radius,
        border: Border.all(
          color: hasActiveFilters ? AppTheme.primary : colors.border,
          width: hasActiveFilters ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('bracket-search-field'),
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 12, color: colors.textMuted),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: colors.textMuted,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      key: const Key('bracket-search-clear'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: onClear,
                    );
                  },
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
          Container(height: 20, width: 1, color: colors.border),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('bracket-filter-button'),
              onTap: onFilterTap,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: hasActiveFilters
                            ? AppTheme.primary
                            : colors.textMuted,
                      ),
                      if (hasActiveFilters) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
