import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class FormSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? titleAction;

  const FormSection({
    super.key,
    required this.title,
    required this.child,
    this.titleAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              titleAction ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
