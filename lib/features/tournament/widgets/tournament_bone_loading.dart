import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:flutter/material.dart';

/// Khung chung cho các skeleton "bone loading" của giải đấu và bảng đấu.
///
/// Đặt trong vùng có chiều cao hữu hạn thì cắt phần thừa (không cuộn, không
/// tràn); đặt trong `ListView`/`Column` (chiều cao vô hạn) thì co theo nội dung.
class _BoneFrame extends StatelessWidget {
  final Widget child;

  const _BoneFrame({required this.child});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return child;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: child,
        );
      },
    ),
  );
}

/// Danh sách hàng (ảnh tròn + hai dòng chữ): người tham gia, sân, địa điểm,
/// nhà tài trợ, hạng mục...
class BoneListLoading extends StatelessWidget {
  final int itemCount;
  final bool leadingAvatar;

  const BoneListLoading({
    super.key,
    this.itemCount = 5,
    this.leadingAvatar = true,
  });

  @override
  Widget build(BuildContext context) => _BoneFrame(
    child: ListPageSkeleton(itemCount: itemCount, leadingAvatar: leadingAvatar),
  );
}

/// Vài khối thẻ cao bằng nhau cho vùng nhỏ nằm trong một thẻ/ô cấu hình.
class BoneBlockLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const BoneBlockLoading({super.key, this.itemCount = 2, this.itemHeight = 56});

  @override
  Widget build(BuildContext context) => _BoneFrame(
    child: SkeletonScope(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < itemCount; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SkeletonBox(height: itemHeight, radius: 12),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Danh sách trận (cùng hình với `MatchRowSkeleton` của thẻ trận thật).
class BoneMatchListLoading extends StatelessWidget {
  final int itemCount;

  const BoneMatchListLoading({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) => _BoneFrame(
    child: SkeletonScope(
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) const MatchRowSkeleton(),
        ],
      ),
    ),
  );
}

/// Bảng xếp hạng/bảng chéo: các hàng có số thứ tự, tên và điểm.
class BoneStandingsLoading extends StatelessWidget {
  final int itemCount;

  const BoneStandingsLoading({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) => _BoneFrame(
    child: SkeletonScope(
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) const LeaderboardRowSkeleton(),
        ],
      ),
    ),
  );
}

/// Trang chi tiết chung (khối đầu trang + vài khối nội dung).
class BoneDetailLoading extends StatelessWidget {
  const BoneDetailLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const _BoneFrame(child: DetailPageSkeleton());
}

/// Bục vinh danh: ba cột, cột giữa cao nhất.
class BonePodiumLoading extends StatelessWidget {
  const BonePodiumLoading({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SkeletonScope(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: SkeletonBox(height: 96, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 128, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 80, radius: 14)),
          ],
        ),
      ),
    ),
  );
}

/// Sơ đồ nhánh đấu: ba cột thẻ trận, cột sau thưa hơn cột trước.
class BoneBracketLoading extends StatelessWidget {
  final double height;

  const BoneBracketLoading({super.key, this.height = 240});

  @override
  Widget build(BuildContext context) => _BoneFrame(
    child: SkeletonScope(
      child: SizedBox(
        height: height,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _BracketColumn(count: 4)),
              SizedBox(width: 24),
              Expanded(child: _BracketColumn(count: 2)),
              SizedBox(width: 24),
              Expanded(child: _BracketColumn(count: 1)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BracketColumn extends StatelessWidget {
  final int count;

  const _BracketColumn({required this.count});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      for (var i = 0; i < count; i++) const SkeletonBox(height: 44, radius: 10),
    ],
  );
}

/// Hàng chip chọn (môn thi đấu...).
class BoneChipsLoading extends StatelessWidget {
  const BoneChipsLoading({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SkeletonScope(
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SkeletonBox(width: 96, height: 36, radius: 18),
            SizedBox(width: 8),
            SkeletonBox(width: 80, height: 36, radius: 18),
            SizedBox(width: 8),
            SkeletonBox(width: 88, height: 36, radius: 18),
          ],
        ),
      ),
    ),
  );
}
