import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

/// Thanh hiển thị các bậc ELO (tier) của môn thể thao đang chọn.
/// Mỗi bậc hiển thị: badge chữ (S/A/B±/C±/D±) + tên tier + khoảng ELO.
/// Người dùng cuộn ngang để xem toàn bộ bậc.
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

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tiers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tier = tiers[i];
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
                    gradient: palette.gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      tier.shortLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
                        '${tier.minElo}–${tier.maxElo}',
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
    );
  }
}
