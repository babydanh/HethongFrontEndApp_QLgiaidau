import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';

/// [UserAvatarTap] whose ring follows the user's best public ranking, read
/// from the existing `GET /rankings/user/:userId` summary. While loading, or
/// when the user has no ranking, the ring stays neutral grey.
class RankedUserAvatarTap extends ConsumerWidget {
  final String userId;
  final String name;
  final String? imageUrl;
  final double size;

  const RankedUserAvatarTap({
    super.key,
    required this.userId,
    required this.name,
    this.imageUrl,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankings =
        ref.watch(userRankingsSummaryProvider(userId)).value ??
        const <PlayerRanking>[];
    final best = rankings.isEmpty
        ? null
        : rankings.reduce((a, b) => b.eloPoints > a.eloPoints ? b : a);
    return UserAvatarTap(
      userId: userId,
      name: name,
      imageUrl: imageUrl,
      elo: best?.eloPoints ?? 0,
      tierName: best?.tierName,
      matchesPlayed: best?.matchesPlayed ?? 0,
      size: size,
    );
  }
}
