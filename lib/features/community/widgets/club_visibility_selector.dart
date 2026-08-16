import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

/// Chế độ hiển thị CLB — radio cards giống web (SettingsTab.tsx):
/// PUBLIC / RESTRICTED / PRIVATE kèm icon và mô tả ngắn.
class ClubVisibilitySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ClubVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    (
      code: 'PUBLIC',
      label: 'Công khai',
      description: 'Mọi người đều tìm thấy và xem được thông tin.',
      icon: Icons.public_rounded,
    ),
    (
      code: 'RESTRICTED',
      label: 'Hạn chế',
      description: 'Tìm thấy CLB nhưng nội dung chỉ dành cho thành viên.',
      icon: Icons.shield_outlined,
    ),
    (
      code: 'PRIVATE',
      label: 'Riêng tư',
      description: 'Ẩn khỏi tìm kiếm, chỉ tham gia qua đường link mời.',
      icon: Icons.lock_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: _options.map((option) {
        final selected = value == option.code;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onChanged(option.code),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppTheme.primary : colors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : option.icon,
                    color: selected ? AppTheme.primary : colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppTheme.primary : colors.textPrimary,
                          ),
                        ),
                        Text(
                          option.description,
                          style: TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
