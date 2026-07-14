import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> startEmailVerificationFlow(
  BuildContext context,
  WidgetRef ref,
  String email,
) async {
  final trimmedEmail = email.trim();
  if (trimmedEmail.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không tìm thấy email để xác minh')),
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
      SnackBar(content: Text('Không thể gửi mã xác minh: $e')),
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
                const SnackBar(content: Text('Vui lòng nhập mã xác minh')),
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
                  const SnackBar(content: Text('Đã xác minh email thành công')),
                );
              }
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Xác minh thất bại: $e')),
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
            title: const Text('Xác minh email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã xác minh đã được gửi đến $trimmedEmail. Nhập mã để hoàn tất.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tokenCtrl,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Mã xác minh',
                    hintText: 'Nhập mã từ email',
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
                onPressed: isSubmitting ? null : submitToken,
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

  tokenCtrl.dispose();
}
