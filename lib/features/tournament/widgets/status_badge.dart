import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String statusKey;

  const StatusBadge({
    super.key,
    required this.statusKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusName = AppConstants.statusNames[statusKey] ?? statusKey;
    Color bgColor;

    switch (statusKey) {
      case AppConstants.statusCompleted:
        bgColor = colors.textMuted.withValues(alpha: 0.8);
        break;
      case AppConstants.statusRegistration:
        bgColor = const Color(0xFF2563EB); // blue
        break;
      case AppConstants.statusInProgress:
        bgColor = const Color(0xFFEF4444); // red
        break;
      case AppConstants.statusDrawing:
        bgColor = const Color(0xFFF59E0B); // amber
        break;
      default:
        bgColor = colors.info;
        break;
    }

    final isLive = statusKey == AppConstants.statusInProgress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            isLive ? "LIVE" : statusName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
