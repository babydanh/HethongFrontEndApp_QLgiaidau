import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Neutral pill shown instead of LIVE for a match the organizer forgot to end
/// (`MatchModel.isStaleLive`, flagged by the Backend).
class StaleLiveBadge extends StatelessWidget {
  const StaleLiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        AppLocalizations.of(context)!.matchStaleLiveStatus,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Organizer-only reminder to finish or cancel a stale live match. Reuses the
/// existing end/abandon actions; adds no button of its own.
class StaleLiveReminder extends StatelessWidget {
  const StaleLiveReminder({super.key, required this.match, this.now});

  final MatchModel match;

  /// Clock override for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (!match.isStaleLive) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final color = context.colors.warning;
    final last = match.lastActivityAt;
    final hours = last == null
        ? null
        : (now ?? DateTime.now()).difference(last).inHours;
    final text = hours == null
        ? l10n.matchStaleLiveReminderNoHours
        : l10n.matchStaleLiveReminder(hours < 0 ? 0 : hours);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
