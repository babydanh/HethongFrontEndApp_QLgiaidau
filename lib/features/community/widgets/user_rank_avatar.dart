import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/utils/best_ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';

/// Best public ranking of [userId] (`GET /rankings/user/:userId`, cached per
/// user), or null while loading, when unranked or when there is no user id.
PlayerRanking? watchUserBestRanking(WidgetRef ref, String? userId) {
  final id = userId?.trim() ?? '';
  if (id.isEmpty) return null;
  return bestRankingOf(
    ref.watch(userRankingsSummaryProvider(id)).value ?? const <PlayerRanking>[],
  );
}

/// Non-tappable [RankAvatar] for a person. The ring uses the payload's own
/// [elo]/[tierName] when present, otherwise the user's best public ranking.
/// Use it where the surrounding row already owns the tap gesture; elsewhere
/// prefer `RankedUserAvatarTap`.
class UserRankAvatar extends ConsumerWidget {
  final String? userId;
  final String name;
  final String? imageUrl;
  final int? elo;
  final String? tierName;
  final double size;
  final double ringWidth;

  const UserRankAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.imageUrl,
    this.elo,
    this.tierName,
    this.size = 32,
    this.ringWidth = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasOwnRank = (elo ?? 0) > 0 || (tierName?.trim().isNotEmpty ?? false);
    final best = hasOwnRank ? null : watchUserBestRanking(ref, userId);
    return RankAvatar(
      imageUrl: imageUrl,
      name: name,
      elo: hasOwnRank ? elo ?? 0 : best?.eloPoints ?? 0,
      tierName: hasOwnRank ? tierName : best?.tierName,
      tierSource: best?.tierSource,
      tierAvailable: best?.tierAvailable,
      matchesPlayed: best?.matchesPlayed ?? 0,
      size: size,
      ringWidth: ringWidth,
    );
  }
}
