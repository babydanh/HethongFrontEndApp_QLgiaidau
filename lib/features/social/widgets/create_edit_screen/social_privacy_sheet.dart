import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SocialPrivacySheet extends StatelessWidget {
  const SocialPrivacySheet({
    super.key,
    required this.selectedPrivacy,
    this.allowClubOnly = true,
  });

  final String selectedPrivacy;
  final bool allowClubOnly;

  static Future<String?> show(
    BuildContext context,
    String selectedPrivacy, {
    bool allowClubOnly = true,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialPrivacySheet(
        selectedPrivacy: selectedPrivacy,
        allowClubOnly: allowClubOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final options = <(String, String)>[
      ('PUBLIC', l10n.socialPrivacyPublic),
      if (allowClubOnly) ('CLUB_ONLY', l10n.socialPrivacyClubOnly),
    ];

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
                  l10n.socialPrivacyLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const Divider(),
              for (final (value, label) in options)
                ListTile(
                  selected: selectedPrivacy == value,
                  title: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selectedPrivacy == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedPrivacy == value
                          ? AppTheme.primary
                          : colors.textPrimary,
                    ),
                  ),
                  trailing: selectedPrivacy == value
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
