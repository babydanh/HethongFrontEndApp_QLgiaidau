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
                        const SizedBox(width: 8),
                        Text(
                          'Điểm ELO tích lũy sau mỗi trận đấu chính thức sẽ xếp người chơi vào các Tier trình độ tương ứng. Chi tiết dải điểm:',
                          style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        ...tiers.map((t) {
                          final palette = TierPalette.from(t);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: palette.soft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.color.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: palette.gradient,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.shortLabel,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: palette.color),
                                  ),
                                ),
                                Text(
                                  '${t.minElo} - ${t.maxElo > 5000 ? '${t.minElo}+' : t.maxElo} ELO',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: colors.textPrimary),
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
              itemCount: tiers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
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
          ),
        ],
      ),
    );
  }
}
