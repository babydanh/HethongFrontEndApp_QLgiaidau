import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:flutter/material.dart';

/// Skeleton cho các danh sách thẻ của màn quản trị (CLB, giao dịch, khiếu nại,
/// yêu cầu thay đổi, xác minh): [itemCount] thẻ có tiêu đề, hai dòng phụ và một
/// nhãn trạng thái, cùng lề với danh sách thật.
class AdminListSkeleton extends StatelessWidget {
  final int itemCount;

  const AdminListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) => SkeletonScope(
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            const _AdminCardSkeleton(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}

class _AdminCardSkeleton extends StatelessWidget {
  const _AdminCardSkeleton();

  @override
  Widget build(BuildContext context) => const RepaintBoundary(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonCircle(size: 44),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(height: 14),
              SizedBox(height: 8),
              SkeletonLine(width: 180, height: 10),
              SizedBox(height: 8),
              SkeletonLine(width: 120, height: 10),
            ],
          ),
        ),
        SizedBox(width: 12),
        SkeletonBox(width: 56, height: 22, radius: 11),
      ],
    ),
  );
}
