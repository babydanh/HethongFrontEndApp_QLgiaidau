import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class SocialCancelSessionDialog extends StatelessWidget {
  const SocialCancelSessionDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => const SocialCancelSessionDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      title: Text(
        'Xác nhận hủy kèo',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
      content: Text(
        'Bạn có chắc muốn hủy buổi Social này không?',
        style: TextStyle(fontSize: 14, color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Không', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hủy kèo'),
        ),
      ],
    );
  }
}
