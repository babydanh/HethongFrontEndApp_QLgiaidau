import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ClubMatchSessionIntroCard extends StatelessWidget {
  final AppLocalizations l10n;

  const ClubMatchSessionIntroCard({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(Icons.groups_rounded, color: onPrimary, size: 26),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clubMatchSessionCreateTitle,
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    l10n.clubMatchSessionNoBracketHint,
                    style: TextStyle(
                      color: onPrimary.withValues(alpha: 0.88),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClubMatchSessionModeCard extends StatelessWidget {
  final String value;
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ClubMatchSessionModeCard({
    super.key,
    required this.value,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppTheme.spacingSM),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.info.withValues(alpha: 0.10)
                : context.colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? context.colors.info : context.colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colors.info
                      : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.colors.textSecondary,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? context.colors.info
                    : context.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClubMatchSessionDateChoice extends StatelessWidget {
  final String label;
  final String valueLabel;
  final bool hasValue;
  final IconData icon;
  final VoidCallback onTap;

  const ClubMatchSessionDateChoice({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.hasValue,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingSM,
          ),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.colors.info),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valueLabel,
                      style: TextStyle(
                        color: hasValue
                            ? context.colors.info
                            : context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClubMatchSessionNoBracketHint extends StatelessWidget {
  final AppLocalizations l10n;

  const ClubMatchSessionNoBracketHint({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: context.colors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.colors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: context.colors.info),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Text(
              l10n.clubMatchSessionNoBracketHint,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClubMatchSessionBottomActions extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const ClubMatchSessionBottomActions({
    super.key,
    required this.l10n,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMD,
          AppTheme.spacingSM,
          AppTheme.spacingMD,
          AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSubmitting ? null : onCancel,
                child: Text(l10n.commonCancel),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(l10n.clubMatchSessionCreate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
