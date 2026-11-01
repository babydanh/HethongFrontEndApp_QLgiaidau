import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:flutter/material.dart';

/// Ô banner nổi bật; `height` là chiều cao ô banner thật để không giật layout.
class HomeBannerSkeleton extends StatelessWidget {
  final double height;

  const HomeBannerSkeleton({super.key, required this.height});

  @override
  Widget build(BuildContext context) => SkeletonScope(
    child: SizedBox(
      height: height,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SkeletonBox(radius: 16),
      ),
    ),
  );
}

/// Thanh 3 tab trạng thái (Trực tiếp / Sắp diễn ra / Đã kết thúc).
class HomeStatusTabsSkeleton extends StatelessWidget {
  const HomeStatusTabsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SkeletonBox(height: 44, radius: 14),
    ),
  );
}

enum SkeletonCardVariant { live, schedule, result }

/// Card một giải kèm các hàng trận; hình dạng theo tab đang chọn.
class TournamentMatchesCardSkeleton extends StatelessWidget {
  final SkeletonCardVariant variant;

  const TournamentMatchesCardSkeleton({
    super.key,
    this.variant = SkeletonCardVariant.schedule,
  });

  @override
  Widget build(BuildContext context) => SkeletonScope(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SkeletonCircle(size: 36),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 160, height: 14),
                      SizedBox(height: 6),
                      SkeletonLine(width: 90, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TournamentMatchRowsSkeleton(variant: variant),
        ],
      ),
    ),
  );
}

/// Chỉ phần hàng trận của card (không có đầu giải), dùng khi card đang tải
/// trang kế.
class TournamentMatchRowsSkeleton extends StatelessWidget {
  final SkeletonCardVariant variant;

  const TournamentMatchRowsSkeleton({
    super.key,
    this.variant = SkeletonCardVariant.schedule,
  });

  @override
  Widget build(BuildContext context) => SkeletonScope(
    child: variant == SkeletonCardVariant.live
        ? SizedBox(
            height: 144,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                SkeletonBox(width: 260, radius: 14),
                SizedBox(width: 12),
                SkeletonBox(width: 260, radius: 14),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  SkeletonBox(
                    height: variant == SkeletonCardVariant.schedule ? 64 : 88,
                    radius: 14,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
  );
}
