import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/utils/best_ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';

/// Player avatar with the ELO tier ring, like the profile tab.
///
/// Uses [eloPoints]/[tierName] from the caller's data when present; otherwise
/// a player with an account reads the best rank from
/// `GET /rankings/user/:userId` (cached per user, same rule as the profile
/// tab). A guest (no [userId], no rank data) keeps [fallback]. Only the lookup
/// branch needs a `ProviderScope`.
class ParticipantRankAvatar extends StatelessWidget {
  final String? userId;
  final String name;
  final String? imageUrl;
  final int? eloPoints;
  final String? tierName;

  /// Outer diameter, ring included (same footprint as the plain avatar).
  final double size;
  final Widget fallback;

  const ParticipantRankAvatar({
    super.key,
    required this.userId,
    required this.name,
    required this.size,
    required this.fallback,
    this.imageUrl,
    this.eloPoints,
    this.tierName,
  });

  @override
  Widget build(BuildContext context) {
    final elo = eloPoints ?? 0;
    final tier = tierName?.trim() ?? '';
    if (elo > 0 || tier.isNotEmpty) {
      return _ring(elo: elo, tierName: tier.isEmpty ? null : tier);
    }
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return fallback;
    return Consumer(
      builder: (context, ref, _) {
        final best = bestRankingOf(
          ref.watch(userRankingsSummaryProvider(id)).value ??
              const <PlayerRanking>[],
        );
        return _ring(
          elo: best?.eloPoints ?? 0,
          tierName: best?.tierName,
          tierSource: best?.tierSource,
          tierAvailable: best?.tierAvailable,
          matchesPlayed: best?.matchesPlayed ?? 0,
        );
      },
    );
  }

  Widget _ring({
    required int elo,
    String? tierName,
    String? tierSource,
    bool? tierAvailable,
    int matchesPlayed = 0,
  }) => RankAvatar(
    imageUrl: imageUrl,
    name: name,
    elo: elo,
    tierName: tierName,
    tierSource: tierSource,
    tierAvailable: tierAvailable,
    matchesPlayed: matchesPlayed,
    size: size,
    // Thinner ring on the tiny bracket avatars so the photo stays readable.
    ringWidth: size < 20 ? 1.5 : 2,
    // Without a photo [fallback] is the caller's initials circle: keep it
    // inside the ring so cards still show e.g. "ND" on the name colour.
    placeholder: (imageUrl?.isNotEmpty ?? false) ? null : fallback,
  );
}
