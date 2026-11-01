import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:flutter/material.dart';

/// Bọc skeleton cao hơn khung chứa: cắt phần thừa thay vì báo overflow, không
/// cuộn được (chỉ để giữ chỗ trong lúc tải).
class ScrollFreeSkeleton extends StatelessWidget {
  final Widget child;

  const ScrollFreeSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: child,
  );
}

/// Một khối chữ nhật giữ chỗ cho thẻ/vùng nhỏ đang tải.
class BlockSkeleton extends StatelessWidget {
  final double height;
  final double radius;

  const BlockSkeleton({super.key, required this.height, this.radius = 14});

  @override
  Widget build(BuildContext context) =>
      SkeletonScope(child: SkeletonBox(height: height, radius: radius));
}

/// Một hàng cài đặt/tile: dòng tiêu đề, dòng phụ và công tắc.
class RowTileSkeleton extends StatelessWidget {
  const RowTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(height: 14),
                SizedBox(height: 8),
                SkeletonLine(width: 160, height: 10),
              ],
            ),
          ),
          SizedBox(width: 16),
          SkeletonBox(width: 44, height: 24, radius: 12),
        ],
      ),
    ),
  );
}

/// Tin nhắn chat: bong bóng đến (trái, có avatar) xen bong bóng đi (phải).
class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _Bubble(mine: false, width: 200),
          SizedBox(height: 14),
          _Bubble(mine: false, width: 140),
          SizedBox(height: 14),
          _Bubble(mine: true, width: 180),
          SizedBox(height: 14),
          _Bubble(mine: false, width: 230),
          SizedBox(height: 14),
          _Bubble(mine: true, width: 120),
        ],
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  final bool mine;
  final double width;

  const _Bubble({required this.mine, required this.width});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
    children: [
      if (!mine) ...[const SkeletonCircle(size: 32), const SizedBox(width: 8)],
      SkeletonBox(width: width, height: 40, radius: 16),
    ],
  );
}

/// Biểu mẫu cài đặt: ảnh đại diện tròn rồi vài ô nhập.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: SkeletonCircle(size: 88)),
          SizedBox(height: 24),
          SkeletonLine(width: 90, height: 11),
          SizedBox(height: 8),
          SkeletonBox(height: 48, radius: 12),
          SizedBox(height: 18),
          SkeletonLine(width: 110, height: 11),
          SizedBox(height: 8),
          SkeletonBox(height: 48, radius: 12),
          SizedBox(height: 18),
          SkeletonLine(width: 70, height: 11),
          SizedBox(height: 8),
          SkeletonBox(height: 48, radius: 12),
        ],
      ),
    ),
  );
}

/// Hồ sơ người dùng rút gọn (bottom sheet): ảnh tròn, tên, dòng phụ, ba ô số.
class ProfileSummarySkeleton extends StatelessWidget {
  const ProfileSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          SkeletonCircle(size: 80),
          SizedBox(height: 14),
          SkeletonLine(width: 160, height: 18),
          SizedBox(height: 10),
          SkeletonLine(width: 110, height: 12),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 64, radius: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 64, radius: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 64, radius: 12)),
            ],
          ),
        ],
      ),
    ),
  );
}
