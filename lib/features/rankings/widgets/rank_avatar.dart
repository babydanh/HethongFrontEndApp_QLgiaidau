import 'package:app_quanly_giaidau/core/utils/elo_tier.dart';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

/// Avatar with a neutral ring for unranked users and the shared ELO tier ring.
class RankAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final int elo;
  final String? tierName;
  final String? tierSource;
  final bool? tierAvailable;
  final int matchesPlayed;
  final double size;
  final double ringWidth;

  const RankAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.elo = 0,
    this.tierName,
    this.tierSource,
    this.tierAvailable,
    this.matchesPlayed = 0,
    this.size = 32,
    this.ringWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final tier = resolveDisplayTier(
      tierName: tierName,
      elo: elo,
      tierSource: tierSource,
      tierAvailable: tierAvailable,
    );
    final ranked =
        tier != null &&
        (elo > 0 || matchesPlayed > 0 || tierName?.isNotEmpty == true);
    final palette = TierPalette.fromRank(elo, tierName, tierSource);
    final ringColor = ranked ? palette.ring : TierPalette.unrankedRing;
    final innerSize = size - (ringWidth * 2);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor,
        // Glow như web (`0 0 16px -2px <màu>60` ở avatar 48px), co theo kích thước.
        boxShadow: ranked
            ? [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0x60 / 0xFF),
                  blurRadius: size / 3,
                  spreadRadius: -size / 24,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: SizedBox(
          width: innerSize,
          height: innerSize,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.blueGrey.shade50,
      alignment: Alignment.center,
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey.shade600,
        ),
      ),
    );
  }
}
