import 'package:app_quanly_giaidau/core/config/app_theme.dart';
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
  final trimmedPhone = phoneNumber.trim();
  if (trimmedPhone.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vui lòng cập nhật số điện thoại trước khi xác minh')),
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
      SnackBar(content: Text('Không thể gửi mã OTP: $e')),
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
                const SnackBar(content: Text('Vui lòng nhập mã OTP')),
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
                  const SnackBar(content: Text('Đã xác minh số điện thoại thành công')),
                );
              }
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Xác minh thất bại: $e')),
              );
            } finally {
              if (ctx.mounted) setState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            backgroundColor: context.colors.bgCard,
            title: const Text('Xác minh số điện thoại'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã OTP 6 chữ số đã được gửi tới $trimmedPhone. Nhập mã để hoàn tất xác minh.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpCtrl,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Mã OTP',
                    hintText: 'Nhập mã 6 chữ số',
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : submitOtp,
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Xác minh'),
              ),
            ],
          );
        },
      );
    },
  );

  otpCtrl.dispose();
}
