import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// A tappable setting row used by the Social session form.
class SocialSettingTile extends StatelessWidget {
  const SocialSettingTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.valueColor,
    this.verticalPadding = 8,
    this.errorText,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback onTap;
  final double verticalPadding;

  /// When set, the row turns red and the message is shown under it.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final error = errorText;
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Row(
          children: [
            Icon(
              icon,
              color: error == null ? AppTheme.primary : colors.error,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: value == null ? 15 : 14.5,
                  fontWeight: FontWeight.w600,
                  color: error == null ? colors.textPrimary : colors.error,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? colors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
    if (error == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(error, style: TextStyle(fontSize: 12, color: colors.error)),
        ),
      ],
    );
  }
}
