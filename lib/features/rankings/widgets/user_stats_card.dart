import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

/// Card "Bạn" hiển thị vị trí + ELO của người dùng hiện tại.
/// Dạng compact 1-line gọn gàng, dán dưới cùng bảng xếp hạng.
class UserStatsCard extends StatelessWidget {
  final PlayerRanking ranking;
  final List<EloTier> tiers;

  const UserStatsCard({
    super.key,
    required this.ranking,
    this.tiers = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final tier = TierPalette.matchTier(ranking.eloPoints, tiers);
    final isUnranked = ranking.rank <= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.info.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.info.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              isUnranked ? '-' : '${ranking.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: colors.info,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar Initials
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.info.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _initials(ranking.fullName),
                style: TextStyle(
                  color: colors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + Badge "BẠN"
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ranking.fullName.isNotEmpty
                            ? ranking.fullName
                            : l10n.rankingYouLabel,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.info,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        l10n.rankingYouLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isUnranked
                      ? l10n.rankingUserStatsUnranked(
                          tier?.name ?? l10n.ranking_unranked,
                        )
                      : l10n.rankingUserStatsRanked(
                          ranking.rank,
                          tier?.name ?? l10n.ranking_ranked,
                        ),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ELO Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${ranking.eloPoints}',
                style: TextStyle(
                  color: colors.info,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'ELO',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
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
