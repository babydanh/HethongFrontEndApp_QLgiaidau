import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

/// Avatar with a neutral ring for unranked users and the shared ELO tier ring.
class RankAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final int elo;
  final String? tierName;
  final int matchesPlayed;
  final double size;
  final double ringWidth;

  const RankAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.elo = 0,
    this.tierName,
    this.matchesPlayed = 0,
    this.size = 32,
    this.ringWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final ranked = matchesPlayed > 0;
    final palette = TierPalette.fromElo(elo < 1000 ? 1000 : elo, tierName);
    final ringColor = ranked ? palette.badgeBg : Colors.blueGrey.shade400;
    final innerSize = size - (ringWidth * 2);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor,
        boxShadow: ranked
            ? [BoxShadow(color: ringColor.withValues(alpha: 0.24), blurRadius: 7)]
            : null,
      ),
      child: ClipOval(
        child: SizedBox(
          width: innerSize,
          height: innerSize,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stack) => _fallback())
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
        style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade600),
      ),
    );
  }
}
