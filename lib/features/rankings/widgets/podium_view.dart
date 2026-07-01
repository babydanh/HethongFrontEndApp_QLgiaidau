import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

/// Bục vinh danh Top 3. Người hạng 1 ở giữa cao nhất, 2 bên trái, 3 bên phải.
class PodiumView extends StatelessWidget {
  final List<PlayerRanking> rankings;
  final List<EloTier> tiers;

  const PodiumView({super.key, required this.rankings, this.tiers = const []});

  @override
  Widget build(BuildContext context) {
    if (rankings.length < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hạng 2
          Expanded(
            child: _PodiumSlot(
              ranking: rankings[1],
              medal: '🥈',
              tier: TierPalette.matchTier(rankings[1].eloPoints, tiers),
              height: 116,
              medalColor: const Color(0xFFC0C0C0),
            ),
          ),
          const SizedBox(width: 10),
          // Hạng 1
          Expanded(
            child: _PodiumSlot(
              ranking: rankings[0],
              medal: '👑',
              tier: TierPalette.matchTier(rankings[0].eloPoints, tiers),
              height: 150,
              medalColor: const Color(0xFFFFD700),
              isKing: true,
            ),
          ),
          const SizedBox(width: 10),
          // Hạng 3
          Expanded(
            child: _PodiumSlot(
              ranking: rankings[2],
              medal: '🥉',
              tier: TierPalette.matchTier(rankings[2].eloPoints, tiers),
              height: 100,
              medalColor: const Color(0xFFCD7F32),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final PlayerRanking ranking;
  final String medal;
  final EloTier? tier;
  final double height;
  final Color medalColor;
  final bool isKing;

  const _PodiumSlot({
    required this.ranking,
    required this.medal,
    required this.tier,
    required this.height,
    required this.medalColor,
    this.isKing = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = TierPalette.from(tier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medal, style: TextStyle(fontSize: isKing ? 26 : 20)),
        const SizedBox(height: 4),
        Container(
          width: isKing ? 64 : 50,
          height: isKing ? 64 : 50,
          decoration: BoxDecoration(
            gradient: palette.gradient,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
            boxShadow: [
              BoxShadow(
                color: palette.color.withValues(alpha: isKing ? 0.45 : 0.25),
                blurRadius: isKing ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _initials(ranking.fullName),
              style: TextStyle(
                color: Colors.white,
                fontSize: isKing ? 20 : 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ranking.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isKing ? 13 : 11,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${ranking.eloPoints}',
              style: TextStyle(
                fontSize: isKing ? 14 : 12,
                fontWeight: FontWeight.w800,
                color: palette.color,
              ),
            ),
            if (tier != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: palette.soft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tier!.shortLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: palette.color,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Đế bục
        Container(
          height: height * 0.32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.35),
                medalColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              top: BorderSide(color: medalColor.withValues(alpha: 0.6), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) {
      return '${p[p.length - 2][0]}${p[p.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
