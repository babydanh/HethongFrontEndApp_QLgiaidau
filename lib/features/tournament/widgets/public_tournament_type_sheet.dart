import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/organizer_verification_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point used by general settings/profile/dashboard actions.
///
/// Public quick tournaments are the only tournament type available outside a
/// Club. Club tournaments must be created from the Club detail/management
/// screen, where the Club id is part of the creation context.
void showPublicTournamentTypeSheet(BuildContext context) {
  context.push('/tournaments/create');
}

/// Shows the permission explanation for users who cannot organize a public
/// tournament yet. This dialog intentionally has no Club-creation fallback.
void showOrganizerRequiredDialog(
  BuildContext context, {
  VoidCallback? onCancel,
}) {
  final colors = context.colors;
  final l10n = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.organizer_reqTitle,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        l10n.organizer_reqDesc,
        style: TextStyle(
          fontSize: 13,
          color: colors.textSecondary,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            onCancel?.call();
          },
          child: Text(
            l10n.commonCancel,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(dialogCtx);
            OrganizerVerificationSheet.show(context);
          },
          icon: const Icon(Icons.verified_user_outlined, size: 17),
          label: Text(l10n.organizer_applyNow),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    ),
  );
}
