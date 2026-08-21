import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/locale_provider.dart';

/// A self-contained language preference control for the Settings screen.
///
/// The provider owns persistence and application state; this widget only
/// renders the current choice and forwards user selection to the provider.
class LanguageSettingCard extends ConsumerWidget {
  const LanguageSettingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.language_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n!.settingsLanguage,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locale.languageCode == 'en'
                      ? (l10n!.languageEn)
                      : (l10n!.languageVi),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: locale.languageCode,
              dropdownColor: colors.bgCard,
              iconEnabledColor: colors.textSecondary,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              items: [
                DropdownMenuItem(
                  value: 'vi',
                  child: Text(l10n!.languageVi),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n!.languageEn),
                ),
              ],
              onChanged: (languageCode) {
                if (languageCode == null) {
                  return;
                }
                ref.read(localeProvider.notifier).changeLocale(languageCode);
              },
            ),
          ),
        ],
      ),
    );
  }
}
