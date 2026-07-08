import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

class StatusBadge extends StatelessWidget {
  final String statusKey;

  const StatusBadge({
    super.key,
    required this.statusKey,
  });

  @override
  Widget build(BuildContext context) {
    final statusName = StatusHelper.getTournamentStatusLabel(statusKey);
    final bgColor = StatusHelper.getTournamentStatusColor(statusKey, context);
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
