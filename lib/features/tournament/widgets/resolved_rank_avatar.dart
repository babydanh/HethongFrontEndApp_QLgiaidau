import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/rankings/utils/best_ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';

/// Avatar of a person with the ELO tier ring.
///
/// Uses the [elo] / [tierName] carried by the caller's data when present;
/// otherwise reads the user's best public ranking from
/// `GET /rankings/user/:userId` (cached per user). Without a [userId] and
/// without data the ring stays neutral grey.
///
/// [openProfile] wraps it in [UserAvatarTap]; leave it off where the
/// surrounding row already owns the tap or a drag gesture.
class ResolvedRankAvatar extends StatelessWidget {
  const ResolvedRankAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.imageUrl,
    this.elo,
    this.tierName,
    this.size = 32,
    this.ringWidth = 2,
    this.openProfile = false,
    this.minTouchTarget = 44,
  });

  final String? userId;
  final String name;
  final String? imageUrl;
  final int? elo;
  final String? tierName;
  final double size;
  final double ringWidth;
  final bool openProfile;
  final double minTouchTarget;

  @override
  Widget build(BuildContext context) {
    final id = userId?.trim() ?? '';
    final known = (elo ?? 0) > 0 || (tierName?.isNotEmpty ?? false);
    // Only a lookup needs the provider scope; data-backed rings render as is.
    if (known || id.isEmpty) return _avatar(id, elo ?? 0, tierName, 0);
    return Consumer(
      builder: (context, ref, _) {
        final best = bestRankingOf(
          ref.watch(userRankingsSummaryProvider(id)).value ??
              const <PlayerRanking>[],
        );
        return _avatar(
          id,
          best?.eloPoints ?? 0,
          best?.tierName,
          best?.matchesPlayed ?? 0,
        );
      },
    );
  }

  Widget _avatar(String id, int elo, String? tierName, int matchesPlayed) {
    if (openProfile && id.isNotEmpty) {
      return UserAvatarTap(
        userId: id,
        name: name,
        imageUrl: imageUrl,
        elo: elo,
        tierName: tierName,
        matchesPlayed: matchesPlayed,
        size: size,
        ringWidth: ringWidth,
        minTouchTarget: minTouchTarget,
      );
    }
    return RankAvatar(
      imageUrl: imageUrl,
      name: name,
      elo: elo,
      tierName: tierName,
      matchesPlayed: matchesPlayed,
      size: size,
      ringWidth: ringWidth,
    );
  }
}
