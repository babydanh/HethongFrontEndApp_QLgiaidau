import 'package:flutter/material.dart';

/// Shared tier palette used by profile cards and the center navigation avatar.
class RankTierColors {
  static Color fromTierName(String? tierName) {
    final name = (tierName ?? '').toUpperCase();
    if (name.contains('TIER S') || name == 'S' || name.contains('TIERS')) return const Color(0xFFFCD34D);
    if (name.contains('HIGH TIER A') || name.contains('RANK A')) return const Color(0xFFFCA5A5);
    if (name.contains('LOW TIER A')) return const Color(0xFFFECACA);
    if (name.contains('HIGH TIER B') || name.contains('RANK B')) return const Color(0xFF93C5FD);
    if (name.contains('LOW TIER B')) return const Color(0xFFBFDBFE);
    if (name.contains('HIGH TIER C') || name.contains('RANK C')) return const Color(0xFF6EE7B7);
    if (name.contains('LOW TIER C')) return const Color(0xFFA7F3D0);
    if (name.contains('HIGH TIER D') || name.contains('RANK D')) return const Color(0xFFCBD5E1);
    if (name.contains('LOW TIER D')) return const Color(0xFFD1D1D1);
    return const Color(0xFFCBD5E1);
  }

  static bool isRanked(String? tierName, {int? matchesPlayed}) {
    final name = (tierName ?? '').toUpperCase();
    return (matchesPlayed ?? 0) > 0 && !name.contains('CHƯA') && !name.contains('UNRANKED');
  }
}
