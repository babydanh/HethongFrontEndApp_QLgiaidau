import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

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
    final isRanked =
        code != '--' && (tierName?.trim().isNotEmpty == true || (elo ?? 0) > 0);
    final palette = TierPalette.fromElo(elo ?? 0, tierName);
    final accent = isRanked ? palette.badgeBg : context.colors.border;
    final textColor = isRanked ? palette.border : context.colors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.bgDark,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: isRanked ? 0.9 : 0.5),
        ),
        boxShadow: isRanked
            ? [BoxShadow(color: accent.withValues(alpha: 0.32), blurRadius: 7)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SportIcon(sportName: sportName, size: 20),
          const SizedBox(width: 5),
          Text(
            showLabel && isRanked ? tierName ?? code : code,
            style: TextStyle(
              color: textColor,
              fontSize: showLabel ? 10 : 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SportIcon extends StatelessWidget {
  final String? sportName;
  final double size;

  const _SportIcon({required this.sportName, required this.size});

  @override
  Widget build(BuildContext context) {
    final normalized = (sportName ?? '').trim().toLowerCase();
    final key = AppConstants.sportNames.entries
        .where((entry) => entry.value.toLowerCase() == normalized)
        .map((entry) => entry.key)
        .firstWhere((value) => true, orElse: () => normalized);
    final visual = AppConstants.sportIcons[key] ?? '🏅';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: visual.startsWith('assets/')
          ? Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(visual, fit: BoxFit.contain),
            )
          : Text(visual, style: TextStyle(fontSize: size * 0.62, height: 1)),
    );
  }
}
