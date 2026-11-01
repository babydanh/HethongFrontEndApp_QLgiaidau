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
