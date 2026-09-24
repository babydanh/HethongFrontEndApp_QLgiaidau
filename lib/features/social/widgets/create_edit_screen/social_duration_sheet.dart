import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class SocialDurationSheet extends StatelessWidget {
  const SocialDurationSheet({super.key, required this.selectedHours});

  final double selectedHours;

  static Future<double?> show(BuildContext context, double selectedHours) {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialDurationSheet(selectedHours: selectedHours),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const options = [1.0, 1.5, 2.0, 2.5, 3.0, 4.0];
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Chọn thời lượng kèo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const Divider(),
              for (final hours in options)
                ListTile(
                  title: Text(
                    '${hours == hours.toInt() ? hours.toInt() : hours} giờ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selectedHours == hours
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedHours == hours
                          ? AppTheme.primary
                          : colors.textPrimary,
                    ),
                  ),
                  trailing: selectedHours == hours
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, hours),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
