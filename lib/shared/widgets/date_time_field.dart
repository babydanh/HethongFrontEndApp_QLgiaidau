import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared date-time field: small label on top, full value (with year) on one
/// line, and an optional error shown right under the field in red.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.buttonKey,
    required this.label,
    required this.placeholder,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final Key buttonKey;
  final String label;

  /// Shown instead of the value while [value] is null.
  final String placeholder;
  final DateTime? value;

  /// Field is disabled while null.
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final error = errorText;
    final hasError = error != null;
    final current = value?.toLocal();
    final accent = hasError ? colors.error : colors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: hasError ? colors.error : colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: buttonKey,
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              alignment: Alignment.centerLeft,
              side: BorderSide(color: hasError ? colors.error : colors.border),
            ),
            icon: Icon(Icons.calendar_today_outlined, size: 17, color: accent),
            label: Text(
              current == null
                  ? placeholder
                  : DateFormat('dd/MM/yyyy · HH:mm').format(current),
              maxLines: 1,
              style: TextStyle(
                color: accent,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error,
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
