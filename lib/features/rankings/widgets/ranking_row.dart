import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

/// 1 dòng xếp hạng (dùng cho rank 4+)
class RankingRow extends StatelessWidget {
  final PlayerRanking ranking;
  final VoidCallback? onTap;

  const RankingRow({
    super.key,
    required this.ranking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final winRate = ranking.winRate;
    final matchesLost = ranking.matchesLost;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 32,
              child: Text(
                '${ranking.rank}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ranking.rank <= 3
                      ? (ranking.rank == 1 ? const Color(0xFFFFD700) : ranking.rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32))
                      : context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _getInitials(ranking.fullName),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thắng ${ranking.matchesWon} · Thua $matchesLost',
                    style: TextStyle(fontSize: 11, color: context.colors.textMuted),
                  ),
                ],
              ),
            ),
            // ELO
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ranking.eloPoints}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${winRate.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, color: winRate >= 60 ? context.colors.success : context.colors.textMuted),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
