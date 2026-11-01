import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:flutter/material.dart';

/// Hàng chờ của [SocialSessionCard]: ảnh tròn, tiêu đề, dòng phụ, nhãn và cột
/// giờ ở bên phải, cùng khoảng đệm với thẻ thật.
class SocialSessionCardSkeleton extends StatelessWidget {
  const SocialSessionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SkeletonCircle(size: 44),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(height: 14),
                SizedBox(height: 6),
                SkeletonLine(width: 150, height: 11),
                SizedBox(height: 8),
                Row(
                  children: [
                    SkeletonBox(width: 56, height: 18, radius: 6),
                    SizedBox(width: 8),
                    SkeletonBox(width: 72, height: 18, radius: 6),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLine(width: 44, height: 14),
              SizedBox(height: 6),
              SkeletonLine(width: 32, height: 10),
            ],
          ),
        ],
      ),
    ),
  );
}
