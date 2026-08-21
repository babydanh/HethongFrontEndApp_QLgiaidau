import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final options = [
      (
        code: 'PUBLIC',
        label: l10n.createClub_visibilityPublic,
        description: l10n.createClub_visibilityPublicDescription,
        icon: Icons.public_rounded,
      ),
      (
        code: 'RESTRICTED',
        label: l10n.createClub_visibilityRestricted,
        description: l10n.createClub_visibilityRestrictedDescription,
        icon: Icons.shield_outlined,
      ),
      (
        code: 'PRIVATE',
        label: l10n.createClub_visibilityPrivate,
        description: l10n.createClub_visibilityPrivateDescription,
        icon: Icons.lock_rounded,
      ),
    ];
    return Column(
      children: options.map((option) {
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
