import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

class StatusBadge extends StatelessWidget {
  final String statusKey;

  const StatusBadge({super.key, required this.statusKey});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusName = StatusHelper.getTournamentStatusLabel(
      statusKey,
      l10n: l10n,
    );
    final normalized = StatusHelper.normalizeTournamentStatus(statusKey);
    final bgColor = StatusHelper.getTournamentStatusColor(statusKey, context);
    final isLive = normalized == AppConstants.statusInProgress;
    final isCompleted = normalized == AppConstants.statusCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (isCompleted) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 10,
              color: Colors.white,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            isLive ? l10n.matchTableLive : statusName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}