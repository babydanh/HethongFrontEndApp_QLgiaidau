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
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top vận động viên',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Mùa giải 2026',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hạng 2
              Expanded(
                child: _PodiumSlot(
                  ranking: rankings[1],
                  rankNumber: '2',
                  tier: TierPalette.matchTier(rankings[1].eloPoints, tiers),
                  podiumHeight: 52,
                  podiumColor: const Color(0xFF94A3B8),
                  avatarBg: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 8),
              // Hạng 1
              Expanded(
                child: _PodiumSlot(
                  ranking: rankings[0],
                  rankNumber: '1',
                  tier: TierPalette.matchTier(rankings[0].eloPoints, tiers),
                  podiumHeight: 82,
                  podiumColor: const Color(0xFFF59E0B),
                  avatarBg: const Color(0xFFF59E0B),
                  isKing: true,
                ),
              ),
              const SizedBox(width: 8),
              // Hạng 3
              Expanded(
                child: _PodiumSlot(
                  ranking: rankings[2],
                  rankNumber: '3',
                  tier: TierPalette.matchTier(rankings[2].eloPoints, tiers),
                  podiumHeight: 44,
                  podiumColor: const Color(0xFFF97316),
                  avatarBg: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final PlayerRanking ranking;
  final String rankNumber;
  final EloTier? tier;
  final double podiumHeight;
  final Color podiumColor;
  final Color avatarBg;
  final bool isKing;

  const _PodiumSlot({
    required this.ranking,
    required this.rankNumber,
    required this.tier,
    required this.podiumHeight,
    required this.podiumColor,
    required this.avatarBg,
    this.isKing = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isKing)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 24),
          )
        else
          const SizedBox(height: 28),
        Container(
          width: isKing ? 58 : 50,
          height: isKing ? 58 : 50,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: avatarBg.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _initials(ranking.fullName),
              style: TextStyle(
                color: Colors.white,
                fontSize: isKing ? 18 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ranking.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${ranking.eloPoints} ELO',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 8),
        // Khối bục xếp hạng với số
        Container(
          height: podiumHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              rankNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
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
