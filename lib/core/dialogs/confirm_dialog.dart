import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Xác nhận',
  String cancelText = 'Hủy',
  Color? confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor ?? context.colors.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}
