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
    final isRank4 = ranking.rank == 4;

    if (isRank4) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank 4 Crown Badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '4',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Name + Subtitle + Tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DẪN ĐẦU NHÓM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD97706),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ranking.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatLabel != null && formatLabel!.isNotEmpty
                          ? formatLabel!
                          : 'Vận động viên xuất sắc',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // ELO Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ranking.eloPoints}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const Text(
                    'ELO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E40AF) : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMe
                ? const Color(0xFF1E40AF)
                : colors.border.withValues(alpha: 0.7),
            width: isMe ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Số hạng dạng circle badge xám nhạt
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : colors.border.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${ranking.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isMe ? Colors.white : colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar (Single or Stacked Dual for Doubles)
            _buildAvatarWidget(context, colors, avatarColor),
            const SizedBox(width: 14),
            // Tên VĐV
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isMe ? Colors.white : colors.textPrimary,
                    ),
                  ),
                  if (formatLabel != null && formatLabel!.isNotEmpty)
                    Text(
                      formatLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : colors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            // ELO Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${ranking.eloPoints}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isMe ? Colors.white : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'ELO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isMe ? Colors.white70 : colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(BuildContext context, dynamic colors, Color avatarColor) {
    final nameParts = ranking.fullName.split('/');
    final isDoublesFormat = (formatLabel != null && formatLabel!.toLowerCase().contains('đôi')) ||
        (ranking.matchType != null && ranking.matchType!.toLowerCase().contains('double')) ||
        nameParts.length >= 2;

    if (isDoublesFormat) {
      final name1 = nameParts.isNotEmpty ? nameParts[0].trim() : '';
      final name2 = nameParts.length >= 2 ? nameParts[1].trim() : '';
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
                    name2.isNotEmpty ? _initials(name2) : '+1',
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
