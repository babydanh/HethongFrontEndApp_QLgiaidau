import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class PickleballLoadingWidget extends StatelessWidget {
  final double size;
  final String? message;
  final Color? textColor;

  const PickleballLoadingWidget({
    super.key,
    this.size = 72,
    this.message,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/pickleball_loading.gif',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor ?? context.colors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
