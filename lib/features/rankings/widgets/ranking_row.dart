import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

/// Một dòng xếp hạng (hạng 4 trở đi). Hiển thị số hạng, avatar chữ, tên,
// tier badge, ELO, W/L và tỉ lệ thắng.
class RankingRow extends StatelessWidget {
  final PlayerRanking ranking;
  final List<EloTier> tiers;
  final bool isMe;
  final bool highlight;
  final String? formatLabel;
  final VoidCallback? onTap;

  const RankingRow({
    super.key,
    required this.ranking,
    this.tiers = const [],
    this.isMe = false,
    this.highlight = false,
    this.formatLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wr = ranking.winRate;
    final bool isTop10 = ranking.rank >= 4 && ranking.rank <= 10;

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
          color: isMe
              ? const Color(0xFF1E40AF)
              : (isTop10 ? colors.bgCard : colors.bgCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? const Color(0xFF1E40AF)
                : (isTop10
                    ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                    : colors.border.withValues(alpha: 0.8)),
            width: isMe || isTop10 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isTop10
                  ? const Color(0xFF2563EB).withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Số hạng
            Container(
              width: 34,
              height: 28,
              alignment: Alignment.center,
              decoration: isTop10
                  ? BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Text(
                '#${ranking.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTop10 ? 13 : 13,
                  fontWeight: FontWeight.w900,
                  color: isMe
                      ? Colors.white
                      : (isTop10 ? const Color(0xFF2563EB) : colors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar (Single or Stacked Dual for Doubles)
            _buildAvatarWidget(context, colors, avatarColor),
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
                      if (formatLabel != null && formatLabel!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFF0284C7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            formatLabel!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isMe ? Colors.white : const Color(0xFF0284C7),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
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
              '${ranking.eloPoints} ELO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isMe ? Colors.white : const Color(0xFF1E40AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(BuildContext context, dynamic colors, Color avatarColor) {
    final nameParts = ranking.fullName.split('/');
    final isDoublesTeam = nameParts.length >= 2;

    if (isDoublesTeam) {
      final name1 = nameParts[0].trim();
      final name2 = nameParts[1].trim();
      return SizedBox(
        width: 54,
        height: 40,
        child: Stack(
          children: [
            // Player 1 Avatar
            Positioned(
              left: 0,
              top: 2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: isMe ? const Color(0xFF1E40AF) : colors.bgCard, width: 2),
                ),
                child: Center(
                  child: Text(
                    _initials(name1),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
            ),
            // Player 2 Avatar (Overlapping)
            Positioned(
              left: 18,
              top: 2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: isMe ? const Color(0xFF1E40AF) : colors.bgCard, width: 2),
                ),
                child: Center(
                  child: Text(
                    _initials(name2),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
