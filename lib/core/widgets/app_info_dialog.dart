import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';

class AppInfoDialog extends StatelessWidget {
  final String title;
  final String content;

  const AppInfoDialog({
    super.key,
    required this.title,
    required this.content,
  });

  static void show(BuildContext context, {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AppInfoDialog(title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.bgCard,
      title: Text(title, style: TextStyle(color: context.colors.textPrimary)),
      content: Text(content, style: TextStyle(color: context.colors.textSecondary, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppConstants.textClose, style: const TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}
