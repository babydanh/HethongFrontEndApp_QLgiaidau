import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/sport_rank_badge.dart';

/// Bục vinh danh Top 3. Người hạng 1 ở giữa cao nhất, 2 bên trái, 3 bên phải.
class PodiumView extends StatelessWidget {
  final List<PlayerRanking> rankings;
  final List<EloTier> tiers;
  final String? formatLabel;
  final ValueChanged<String>? onTapUser;

  const PodiumView({
    super.key,
    required this.rankings,
    this.tiers = const [],
    this.formatLabel,
    this.onTapUser,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    final p1 = rankings.isNotEmpty ? rankings[0] : null;
    final p2 = rankings.length >= 2 ? rankings[1] : null;
    final p3 = rankings.length >= 3 ? rankings[2] : null;

    final subtitleText = (formatLabel != null && formatLabel!.isNotEmpty)
        ? '$formatLabel • ${l10n.rankingSeason(2026)}'
        : l10n.rankingSeason(2026);

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
                l10n.rankingTop100Athletes,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                subtitleText,
                style: TextStyle(
                  fontSize: 11,
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
                  ranking: p2,
                  rankNumber: '2',
                  tier: p2 != null
                      ? TierPalette.matchTier(p2.eloPoints, tiers)
                      : null,
                  podiumHeight: 52,
                  podiumColor: const Color(0xFF94A3B8),
                  avatarBg: const Color(0xFF94A3B8),
                  formatLabel: formatLabel,
                  onTap: () {
                    if (p2 != null && onTapUser != null) {
                      onTapUser!(p2.userId);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Hạng 1
              Expanded(
                child: _PodiumSlot(
                  ranking: p1,
                  rankNumber: '1',
                  tier: p1 != null
                      ? TierPalette.matchTier(p1.eloPoints, tiers)
                      : null,
                  podiumHeight: 82,
                  podiumColor: const Color(0xFFF59E0B),
                  avatarBg: const Color(0xFFF59E0B),
                  isKing: true,
                  formatLabel: formatLabel,
                  onTap: () {
                    if (p1 != null && onTapUser != null) {
                      onTapUser!(p1.userId);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Hạng 3
              Expanded(
                child: _PodiumSlot(
                  ranking: p3,
                  rankNumber: '3',
                  tier: p3 != null
                      ? TierPalette.matchTier(p3.eloPoints, tiers)
                      : null,
                  podiumHeight: 44,
                  podiumColor: const Color(0xFFF97316),
                  avatarBg: const Color(0xFFF97316),
                  formatLabel: formatLabel,
                  onTap: () {
                    if (p3 != null && onTapUser != null) {
                      onTapUser!(p3.userId);
                    }
                  },
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
  final PlayerRanking? ranking;
  final String rankNumber;
  final EloTier? tier;
  final double podiumHeight;
  final Color podiumColor;
  final Color avatarBg;
  final bool isKing;
  final String? formatLabel;
  final VoidCallback? onTap;

  const _PodiumSlot({
    required this.ranking,
    required this.rankNumber,
    required this.tier,
    required this.podiumHeight,
    required this.podiumColor,
    required this.avatarBg,
    this.isKing = false,
    this.formatLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final name = ranking?.fullName ?? l10n.ranking_unranked;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isKing)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
            )
          else
            const SizedBox(height: 28),
          _buildPodiumAvatar(colors, name),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: ranking != null ? FontWeight.w800 : FontWeight.w600,
              color: ranking != null ? colors.textPrimary : colors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          if (ranking != null)
            SportRankBadge(ranking: ranking!, compact: true),
          const SizedBox(height: 8),
          // Khối bục xếp hạng với số
          Container(
            height: podiumHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: podiumColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: podiumColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                rankNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumAvatar(dynamic colors, String name) {
    final nameParts = name.split('/');
    final isDoublesFormat =
        (formatLabel != null && formatLabel!.toLowerCase().contains('đôi')) ||
        (ranking?.matchType != null &&
            ranking!.matchType!.toLowerCase().contains('double'));
    final size = isKing ? 58.0 : 50.0;
    final subSize = size * 0.75;

    if (isDoublesFormat) {
      final name1 = nameParts.isNotEmpty ? nameParts[0].trim() : '';
      final name2 = nameParts.length >= 2 ? nameParts[1].trim() : '';

      return SizedBox(
        width: size * 1.3,
        height: size,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: (size - subSize) / 2,
              child: Container(
                width: subSize,
                height: subSize,
                decoration: BoxDecoration(
                  color: ranking != null
                      ? const Color(0xFF2563EB)
                      : colors.border.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.bgCard, width: 2),
                ),
                child: Center(
                  child: Text(
                    ranking != null ? _initials(name1) : '?',
                    style: TextStyle(
                      fontSize: isKing ? 13 : 11,
                      fontWeight: FontWeight.w900,
                      color: ranking != null ? Colors.white : colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: subSize * 0.55,
              top: (size - subSize) / 2,
              child: Container(
                width: subSize,
                height: subSize,
                decoration: BoxDecoration(
                  color: ranking != null
                      ? const Color(0xFF10B981)
                      : colors.border.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.bgCard, width: 2),
                ),
                child: Center(
                  child: Text(
                    ranking != null
                        ? (name2.isNotEmpty ? _initials(name2) : '+1')
                        : '?',
                    style: TextStyle(
                      fontSize: isKing ? 13 : 11,
                      fontWeight: FontWeight.w900,
                      color: ranking != null ? Colors.white : colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ranking != null
            ? avatarBg
            : colors.border.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        boxShadow: ranking != null
            ? [
                BoxShadow(
                  color: avatarBg.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          ranking != null ? _initials(name) : '?',
          style: TextStyle(
            color: ranking != null ? Colors.white : colors.textMuted,
            fontSize: isKing ? 18 : 15,
            fontWeight: FontWeight.w900,
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
