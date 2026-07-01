import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

/// Một dòng xếp hạng (hạng 4 trở đi). Hiển thị số hạng, avatar chữ, tên,
// tier badge, ELO, W/L và tỉ lệ thắng.
class RankingRow extends StatelessWidget {
  final PlayerRanking ranking;
  final List<EloTier> tiers;
  final bool isMe;
  final bool highlight;
  final VoidCallback? onTap;

  const RankingRow({
    super.key,
    required this.ranking,
    this.tiers = const [],
    this.isMe = false,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wr = ranking.winRate;
    final tier = TierPalette.matchTier(ranking.eloPoints, tiers);
    final palette = TierPalette.from(tier);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlight ? palette.soft.withValues(alpha: 0.5) : colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe
                ? AppTheme.primary
                : highlight
                    ? palette.color
                    : colors.border,
            width: isMe || highlight ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Số hạng
            SizedBox(
              width: 30,
              child: Text(
                '#${ranking.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ranking.rank <= 3
                      ? (ranking.rank == 1
                          ? const Color(0xFFFFD700)
                          : ranking.rank == 2
                              ? const Color(0xFFC0C0C0)
                              : const Color(0xFFCD7F32))
                      : colors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar chữ
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: palette.gradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  _initials(ranking.fullName),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Tên + W/L
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ranking.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Bạn',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Tier badge
                      if (tier != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: palette.soft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tier.shortLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: palette.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'W ${ranking.matchesWon} · L ${ranking.matchesLost}',
                        style: TextStyle(fontSize: 10, color: colors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ELO + winrate
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ranking.eloPoints}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.color,
                  ),
                ),
                Text(
                  '${wr.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: wr >= 60 ? colors.success : colors.textMuted,
                    fontWeight: wr >= 60 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: colors.textMuted),
          ],
        ),
      ),
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
