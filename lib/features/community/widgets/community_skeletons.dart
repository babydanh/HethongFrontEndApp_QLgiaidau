import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:flutter/material.dart';

/// Khung chờ của bottom sheet cài đặt bảng tin: tiêu đề và vài nhóm
/// nhãn + ô chọn.
class CommunitySettingsSheetSkeleton extends StatelessWidget {
  const CommunitySettingsSheetSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: SkeletonBox(width: 40, height: 4, radius: 2)),
        SizedBox(height: 16),
        SkeletonLine(width: 200, height: 18),
        SizedBox(height: 20),
        _SettingsGroupSkeleton(),
        SizedBox(height: 16),
        _SettingsGroupSkeleton(),
        SizedBox(height: 16),
        _SettingsGroupSkeleton(),
      ],
    ),
  );
}

class _SettingsGroupSkeleton extends StatelessWidget {
  const _SettingsGroupSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SkeletonLine(width: 120, height: 12),
      SizedBox(height: 8),
      SkeletonBox(height: 44, radius: 12),
    ],
  );
}

/// Khung chờ của màn chat CLB: bong bóng lệch trái/phải xen kẽ.
class CommunityChatSkeleton extends StatelessWidget {
  const CommunityChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _ChatBubbleSkeleton(width: 220, mine: false),
          _ChatBubbleSkeleton(width: 160, mine: false),
          _ChatBubbleSkeleton(width: 200, mine: true),
          _ChatBubbleSkeleton(width: 120, mine: true),
          _ChatBubbleSkeleton(width: 240, mine: false),
          _ChatBubbleSkeleton(width: 180, mine: true),
        ],
      ),
    ),
  );
}

class _ChatBubbleSkeleton extends StatelessWidget {
  final double width;
  final bool mine;

  const _ChatBubbleSkeleton({required this.width, required this.mine});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!mine) ...[
          const SkeletonCircle(size: 32),
          const SizedBox(width: 8),
        ],
        Flexible(child: SkeletonBox(width: width, height: 44, radius: 16)),
      ],
    ),
  );
}

/// Khung chờ của form sửa CLB: ảnh bìa, ảnh đại diện và các ô nhập.
class CommunityFormSkeleton extends StatelessWidget {
  const CommunityFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 120, radius: 12),
          SizedBox(height: 16),
          Center(child: SkeletonCircle(size: 88)),
          SizedBox(height: 20),
          SkeletonLine(width: 100, height: 12),
          SizedBox(height: 8),
          SkeletonBox(height: 48, radius: 12),
          SizedBox(height: 16),
          SkeletonLine(width: 100, height: 12),
          SizedBox(height: 8),
          SkeletonBox(height: 96, radius: 12),
          SizedBox(height: 16),
          SkeletonLine(width: 100, height: 12),
          SizedBox(height: 8),
          SkeletonBox(height: 48, radius: 12),
        ],
      ),
    ),
  );
}

/// Khung chờ của bảng tin cộng đồng: hai bài đăng.
class CommunityFeedSkeleton extends StatelessWidget {
  const CommunityFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const Column(children: [SocialPostSkeleton(), SocialPostSkeleton()]);
}

/// Khung chờ của tab thư viện ảnh: lưới ô vuông 2 cột.
class CommunityGallerySkeleton extends StatelessWidget {
  const CommunityGallerySkeleton({super.key});

  @override
  Widget build(BuildContext context) => SkeletonScope(
    child: GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.all(16),
      children: [for (var i = 0; i < 6; i++) const SkeletonBox(radius: 12)],
    ),
  );
}

/// Danh sách hàng chờ cuộn được, dùng cho màn có thân là danh sách dài.
class CommunityListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool leadingAvatar;

  const CommunityListSkeleton({
    super.key,
    this.itemCount = 8,
    this.leadingAvatar = true,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: ListPageSkeleton(itemCount: itemCount, leadingAvatar: leadingAvatar),
  );
}
