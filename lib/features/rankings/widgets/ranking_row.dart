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

    // Fixed color for avatar initial based on rank or name
    final List<Color> avatarColors = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFFA855F7), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF97316), // Orange
      const Color(0xFF3B82F6), // Blue
    ];
    final avatarColor = avatarColors[ranking.rank % avatarColors.length];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E40AF) : colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? const Color(0xFF1E40AF) : colors.border.withValues(alpha: 0.8),
            width: isMe ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Số hạng
            SizedBox(
              width: 32,
              child: Text(
                '${ranking.rank}',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isMe ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Avatar tròn chữ cái
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withValues(alpha: 0.2) : avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(ranking.fullName),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Tên + Tỉnh thành & Winrate
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
                            fontWeight: FontWeight.w800,
                            color: isMe ? Colors.white : colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Bạn',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Việt Nam · ${wr.toStringAsFixed(0)}% thắng',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white.withValues(alpha: 0.8) : colors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // ELO Score
            Text(
              '${ranking.eloPoints}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isMe ? Colors.white : const Color(0xFF1E40AF),
              ),
            ),
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
