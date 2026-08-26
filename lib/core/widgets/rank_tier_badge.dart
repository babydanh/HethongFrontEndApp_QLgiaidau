import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/rank_tier_colors.dart';

String getShortTierCode(String? tierName, int? elo) {
  final name = (tierName ?? '').trim();
  final upper = name.toUpperCase();

  if (upper.contains('TIER S') || upper == 'S' || upper.contains('TIERS')) {
    return 'TS';
  }
  if (upper.contains('HIGH TIER A') || upper == 'HTA') return 'HTA';
  if (upper.contains('LOW TIER A') || upper == 'LTA') return 'LTA';
  if (upper.contains('HIGH TIER B') || upper == 'HTB') return 'HTB';
  if (upper.contains('LOW TIER B') || upper == 'LTB') return 'LTB';
  if (upper.contains('HIGH TIER C') || upper == 'HTC') return 'HTC';
  if (upper.contains('LOW TIER C') || upper == 'LTC') return 'LTC';
  if (upper.contains('HIGH TIER D') || upper == 'HTD') return 'HTD';
  if (upper.contains('LOW TIER D') || upper == 'LTD') return 'LTD';

  if (elo != null) {
    if (elo >= 1800) return 'TS';
    if (elo >= 1700) return 'HTA';
    if (elo >= 1600) return 'LTA';
    if (elo >= 1500) return 'HTB';
    if (elo >= 1400) return 'LTB';
    if (elo >= 1300) return 'HTC';
    if (elo >= 1200) return 'LTC';
    if (elo >= 1100) return 'HTD';
    return 'LTD';
  }

  return '--';
}

class RankTierBadge extends StatelessWidget {
  final String? tierName;
  final int? elo;
  final bool showLabel;
  final String? sportName;

  const RankTierBadge({
    super.key,
    this.tierName,
    this.elo,
    this.showLabel = false,
    this.sportName,
  });

  @override
  Widget build(BuildContext context) {
    final code = getShortTierCode(tierName, elo);
    final isRanked = code != '--' && RankTierColors.isRanked(tierName);
    final color = isRanked
        ? RankTierColors.fromTierName(tierName)
        : const Color(0xFF94A3B8);
    final sportIcon = _sportIcon(sportName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sportIcon.startsWith('assets/'))
            Image.asset(sportIcon, width: 15, height: 15)
          else
            Text(sportIcon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            code,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          if (showLabel && isRanked) ...[
            const SizedBox(width: 4),
            Text(
              tierName ?? '',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _sportIcon(String? name) {
    final normalized = (name ?? '').trim().toLowerCase();
    final key = AppConstants.sportNames.entries
        .where((entry) => entry.value.toLowerCase() == normalized)
        .map((entry) => entry.key)
        .firstWhere((value) => true, orElse: () => normalized);
    return AppConstants.sportIcons[key] ?? '🏅';
  }
}
