import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gửi OTP tới số điện thoại rồi mở dialog nhập mã xác nhận.
/// POST /auth/verify-phone/request → POST /auth/verify-phone/confirm
Future<void> startPhoneVerificationFlow(
  BuildContext context,
  WidgetRef ref,
  String phoneNumber,
) async {
  final l10n = AppLocalizations.of(context)!;
  final trimmedPhone = phoneNumber.trim();
  if (trimmedPhone.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.phoneVerificationPhoneRequired)),
    );
    return;
  }

  final authRepository = ref.read(authRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  try {
    await authRepository.requestPhoneVerification(phoneNumber: trimmedPhone);
  } catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.phoneVerificationSendFailed(e.toString()))),
    );
    return;
  }

  if (!context.mounted) return;

  final otpCtrl = TextEditingController();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> submitOtp() async {
            final code = otpCtrl.text.trim();
            if (code.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(l10n.phoneVerificationOtpRequired)),
              );
              return;
            }

            setState(() => isSubmitting = true);

            try {
              await authRepository.confirmPhoneVerification(code: code);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              ref.invalidate(userProfileProvider);
              if (context.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.phoneVerificationSuccess)),
                );
              }
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(l10n.phoneVerificationFailed(e.toString()))),
              );
            } finally {
              if (ctx.mounted) setState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            backgroundColor: context.colors.bgCard,
            title: Text(l10n.phoneVerificationTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.phoneVerificationCodeSent(trimmedPhone),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpCtrl,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n.phoneVerificationOtpLabel,
                    hintText: l10n.phoneVerificationOtpHint,
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: Text(l10n.phoneVerificationCancel),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : submitOtp,
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.phoneVerificationConfirm),
              ),
            ],
          );
        },
      );
    },
  );

  otpCtrl.dispose();
}
