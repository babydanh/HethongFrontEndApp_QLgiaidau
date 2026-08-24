import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';
import 'package:flutter/material.dart';

class SportRankBadge extends StatelessWidget {
  final PlayerRanking ranking;
  final bool compact;
  final bool dark;

  const SportRankBadge({
    super.key,
    required this.ranking,
    this.compact = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final tier = TierPalette.fromElo(ranking.eloPoints, ranking.tierName);
    final sport = _sportVisual(ranking.categoryName);
    final label = _tierLabel(ranking.tierName, tier);
    final iconSize = compact ? 14.0 : 16.0;
    final horizontal = compact ? 7.0 : 9.0;
    final vertical = compact ? 4.0 : 5.0;
    final textColor = dark ? Colors.white : tier.color;
    final background = dark
        ? Colors.white.withValues(alpha: 0.12)
        : tier.soft.withValues(alpha: 0.72);
    final border = dark
        ? Colors.white.withValues(alpha: 0.25)
        : tier.border.withValues(alpha: 0.9);

    return Semantics(
      label: '${sport.label} $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(compact ? 9 : 11),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 22 : 26,
              height: compact ? 22 : 26,
              decoration: BoxDecoration(
                color: sport.color.withValues(alpha: dark ? 0.32 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(sport.icon, size: iconSize, color: sport.color),
            ),
            SizedBox(width: compact ? 5 : 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _tierLabel(String rawTier, TierPalette tier) {
    final name = rawTier.trim().toLowerCase();
    if (name.contains('pro')) return 'PRO';
    if (name.contains('advanced')) return 'ADV';
    if (name.contains('intermediate')) return 'INT';
    if (name.contains('beginner')) return 'BEG';
    return tier.label;
  }

  static _SportVisual _sportVisual(String? rawName) {
    final name = (rawName ?? '').trim().toLowerCase();
    if (name.contains('football') ||
        name.contains('soccer') ||
        name.contains('bóng đá')) {
      return const _SportVisual(
        label: 'Football',
        icon: Icons.sports_soccer_rounded,
        color: Color(0xFF0F766E),
      );
    }
    if (name.contains('badminton') || name.contains('cầu lông')) {
      return const _SportVisual(
        label: 'Badminton',
        icon: Icons.sports_tennis_rounded,
        color: Color(0xFF2563EB),
      );
    }
    if (name.contains('table tennis') ||
        name.contains('ping') ||
        name.contains('bóng bàn')) {
      return const _SportVisual(
        label: 'Table tennis',
        icon: Icons.sports_tennis_rounded,
        color: Color(0xFFE11D48),
      );
    }
    if (name.contains('pickleball')) {
      return const _SportVisual(
        label: 'Pickleball',
        icon: Icons.sports_tennis_rounded,
        color: Color(0xFF059669),
      );
    }
    if (name.contains('tennis') || name.contains('quần vợt')) {
      return const _SportVisual(
        label: 'Tennis',
        icon: Icons.sports_tennis_rounded,
        color: Color(0xFFD97706),
      );
    }
    return const _SportVisual(
      label: 'Sport',
      icon: Icons.sports_rounded,
      color: Color(0xFF64748B),
    );
  }
}

class _SportVisual {
  final String label;
  final IconData icon;
  final Color color;

  const _SportVisual({
    required this.label,
    required this.icon,
    required this.color,
  });
}
