import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

/// Thanh hiển thị các bậc ELO (tier) của môn thể thao đang chọn.
/// Mỗi bậc hiển thị: badge chữ đầy đủ (TIER S / HIGH TIER A...) + dải ELO.
/// Modal hiển thị theo đúng thứ tự & màu sắc của Web frontend (S -> A -> B -> C -> D).
class TierLegendView extends StatelessWidget {
  final List<EloTier> tiers;
  final int? highlightElo;

  const TierLegendView({
    super.key,
    required this.tiers,
    this.highlightElo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (tiers.isEmpty) return const SizedBox.shrink();

    // Sắp xếp các tier từ cao nhất (Tier S: 1800+) xuống thấp nhất (Low Tier D: 0-1099) giống hệt Web
    final sortedTiers = List<EloTier>.from(tiers)
      ..sort((a, b) => b.minElo.compareTo(a.minElo));

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hệ thống phân hạng ELO',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Điểm ELO tích lũy sau mỗi trận đấu chính thức sẽ xếp người chơi vào các Tier trình độ tương ứng. Chi tiết dải điểm:',
                          style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        ...sortedTiers.map((t) {
                          final palette = TierPalette.from(t);
                          final eloRangeText = (t.maxElo > 5000 || t.minElo >= 1800)
                              ? '${t.minElo}+ ELO'
                              : '${t.minElo} - ${t.maxElo} ELO';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: palette.soft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: palette.border, width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: palette.badgeBg,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    palette.fullLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  eloRangeText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: palette.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 20),
              itemCount: sortedTiers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final tier = sortedTiers[i];
                final palette = TierPalette.from(tier);
                final isMine = highlightElo != null &&
                    highlightElo! >= tier.minElo &&
                    highlightElo! <= tier.maxElo;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMine ? palette.soft : colors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMine ? palette.color : colors.border,
                      width: isMine ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: palette.badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            palette.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 96),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tier.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isMine ? palette.color : colors.textPrimary,
                              ),
                            ),
                            Text(
                              '${tier.minElo}–${tier.maxElo > 5000 ? '${tier.minElo}+' : tier.maxElo}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
