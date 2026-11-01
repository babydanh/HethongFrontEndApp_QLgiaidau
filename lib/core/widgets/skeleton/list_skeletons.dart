import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:flutter/material.dart';

class TournamentListItemSkeleton extends StatelessWidget {
  const TournamentListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SkeletonBox(width: 72, height: 72, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(height: 14),
                SizedBox(height: 8),
                SkeletonLine(width: 140, height: 10),
                SizedBox(height: 8),
                SkeletonLine(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class LeaderboardRowSkeleton extends StatelessWidget {
  const LeaderboardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SkeletonLine(width: 24, height: 14),
          SizedBox(width: 12),
          SkeletonCircle(size: 40),
          SizedBox(width: 12),
          Expanded(child: SkeletonLine(height: 14)),
          SizedBox(width: 12),
          SkeletonLine(width: 48, height: 14),
        ],
      ),
    ),
  );
}

class SocialPostSkeleton extends StatelessWidget {
  const SocialPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonCircle(size: 36),
              SizedBox(width: 10),
              Expanded(child: SkeletonLine(width: 140, height: 12)),
            ],
          ),
          SizedBox(height: 12),
          SkeletonLine(height: 12),
          SizedBox(height: 8),
          SkeletonLine(width: 200, height: 12),
          SizedBox(height: 12),
          SkeletonBox(height: 140, radius: 14),
        ],
      ),
    ),
  );
}

class MatchRowSkeleton extends StatelessWidget {
  const MatchRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SkeletonBox(height: 88, radius: 14),
    ),
  );
}

/// Danh sách chung cho màn nào chưa có skeleton riêng: [itemCount] hàng, mỗi
/// hàng có (tuỳ chọn) ảnh tròn và hai dòng chữ. Không cuộn (`shrinkWrap`), nên
/// đặt trong khung có chiều cao hoặc `Column`.
class ListPageSkeleton extends StatelessWidget {
  final int itemCount;
  final bool leadingAvatar;

  const ListPageSkeleton({
    super.key,
    this.itemCount = 6,
    this.leadingAvatar = true,
  });

  @override
  Widget build(BuildContext context) => SkeletonScope(
    child: Column(
      children: [
        for (var i = 0; i < itemCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (leadingAvatar) ...[
                  const SkeletonCircle(size: 44),
                  const SizedBox(width: 12),
                ],
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(height: 14),
                      SizedBox(height: 8),
                      SkeletonLine(width: 140, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Trang chi tiết chung: khối đầu trang, vài dòng mô tả và hai khối nội dung.
class DetailPageSkeleton extends StatelessWidget {
  const DetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 160, radius: 16),
          SizedBox(height: 16),
          SkeletonLine(height: 18),
          SizedBox(height: 10),
          SkeletonLine(width: 220, height: 12),
          SizedBox(height: 20),
          SkeletonBox(height: 96, radius: 14),
          SizedBox(height: 12),
          SkeletonBox(height: 96, radius: 14),
        ],
      ),
    ),
  );
}
