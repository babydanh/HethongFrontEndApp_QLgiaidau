import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> startEmailVerificationFlow(
  BuildContext context,
  WidgetRef ref,
  String email,
) async {
  final l10n = AppLocalizations.of(context)!;
  final trimmedEmail = email.trim();
  if (trimmedEmail.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.emailVerificationEmailRequired)),
    );
    return;
  }

  final authRepository = ref.read(authRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  try {
    await authRepository.requestEmailVerification();
  } catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.emailVerificationSendFailed(e.toString()))),
    );
    return;
  }

  if (!context.mounted) return;

  final tokenCtrl = TextEditingController();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> submitToken() async {
            final token = tokenCtrl.text.trim();
            if (token.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(l10n.emailVerificationTokenRequired)),
              );
              return;
            }

            setState(() {
              isSubmitting = true;
            });

            try {
              await authRepository.confirmEmailVerification(token: token);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              ref.invalidate(userProfileProvider);
              if (context.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.emailVerificationSuccess)),
                );
              }
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(l10n.emailVerificationFailed(e.toString()))),
              );
            } finally {
              if (ctx.mounted) {
                setState(() {
                  isSubmitting = false;
                });
              }
            }
          }

          return AlertDialog(
            backgroundColor: context.colors.bgCard,
            title: Text(l10n.emailVerificationTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.emailVerificationCodeSent(trimmedEmail),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tokenCtrl,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: l10n.emailVerificationTokenLabel,
                    hintText: l10n.emailVerificationTokenHint,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: Text(l10n.emailVerificationCancel),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : submitToken,
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.emailVerificationConfirm),
              ),
            ],
          );
        },
      );
    },
  );

  tokenCtrl.dispose();
}
