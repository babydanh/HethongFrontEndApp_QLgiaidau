import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class SocialPrivacySheet extends StatelessWidget {
  const SocialPrivacySheet({super.key, required this.selectedPrivacy});

  final String selectedPrivacy;

  static Future<String?> show(BuildContext context, String selectedPrivacy) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialPrivacySheet(selectedPrivacy: selectedPrivacy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const options = ['Công khai', 'Nội bộ CLB'];
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
                  'Quyền riêng tư',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const Divider(),
              for (final privacy in options)
                ListTile(
                  title: Text(
                    privacy,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selectedPrivacy == privacy
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedPrivacy == privacy
                          ? AppTheme.primary
                          : colors.textPrimary,
                    ),
                  ),
                  trailing: selectedPrivacy == privacy
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, privacy),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
