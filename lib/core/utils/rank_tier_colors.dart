import 'package:flutter/material.dart';

/// Shared tier palette used by profile cards and the center navigation avatar.
class RankTierColors {
  static Color fromTierName(String? tierName) {
    final name = (tierName ?? '').toUpperCase();
    if (name.contains('TIER S') || name == 'S' || name.contains('TIERS')) return const Color(0xFFF59E0B);
    if (name.contains('HIGH TIER A') || name.contains('RANK A')) return const Color(0xFFEF4444);
    if (name.contains('LOW TIER A')) return const Color(0xFFF87171);
    if (name.contains('HIGH TIER B') || name.contains('RANK B')) return const Color(0xFF3B82F6);
    if (name.contains('LOW TIER B')) return const Color(0xFF60A5FA);
    if (name.contains('HIGH TIER C') || name.contains('RANK C')) return const Color(0xFF10B981);
    if (name.contains('LOW TIER C')) return const Color(0xFF34D399);
    if (name.contains('HIGH TIER D') || name.contains('RANK D')) return const Color(0xFF64748B);
    if (name.contains('LOW TIER D')) return const Color(0xFF94A3B8);
    return const Color(0xFFCBD5E1);
  }

  static bool isRanked(String? tierName, {int? matchesPlayed}) {
    final name = (tierName ?? '').toUpperCase().trim();
    if (name.isEmpty || name.contains('CHƯA') || name.contains('UNRANKED')) {
      return false;
    }
    return true;
  }
}
