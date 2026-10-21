import 'package:app_quanly_giaidau/core/utils/elo_tier.dart' as tier_utils;
import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';


class RankTierBadge extends StatelessWidget {
  final String? tierName;
  final int? elo;
  final bool showLabel;
  final String? sportName;
  final String? tierSource;
  final bool? tierAvailable;
  const RankTierBadge({
    super.key,
    this.tierName,
    this.elo,
    this.showLabel = false,
    this.sportName,
    this.tierSource,
    this.tierAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final info = tier_utils.resolveDisplayTier(
      tierName: tierName,
      elo: elo ?? 0,
      tierSource: tierSource,
      tierAvailable: tierAvailable,
    );
    final code = info?.shortCode ?? '--';
    final isRanked = info != null;
    if (info == null) return const SizedBox.shrink();

    // Chuẩn web:
    // TS: viền cam đậm #F59E0B / #D97706, nền vàng cam nhạt #FEF3C7, chữ cam đậm #B45309
    // HTB: viền xanh dương #2563EB, nền xanh nhạt #EFF6FF, chữ xanh #1D4ED8
    // Glow shadow lan tỏa xung quanh badge
    final Color borderColor;
    final Color badgeBg;
    final Color textColor;
    final Color glowColor;

    if (code == 'TS') {
      borderColor = const Color(0xFFF59E0B);
      badgeBg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
      glowColor = const Color(0xFFF59E0B).withValues(alpha: 0.35);
    } else if (code == 'HTA') {
      borderColor = const Color(0xFFE11D48);
      badgeBg = const Color(0xFFFFE4E6);
      textColor = const Color(0xFFBE123C);
      glowColor = const Color(0xFFE11D48).withValues(alpha: 0.35);
    } else if (code == 'LTA') {
      borderColor = const Color(0xFFF43F5E);
      badgeBg = const Color(0xFFFFF1F2);
      textColor = const Color(0xFFE11D48);
      glowColor = const Color(0xFFF43F5E).withValues(alpha: 0.3);
    } else if (code == 'HTB') {
      borderColor = const Color(0xFF2563EB);
      badgeBg = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF1D4ED8);
      glowColor = const Color(0xFF2563EB).withValues(alpha: 0.35);
    } else if (code == 'LTB') {
      borderColor = const Color(0xFF3B82F6);
      badgeBg = const Color(0xFFF0F9FF);
      textColor = const Color(0xFF2563EB);
      glowColor = const Color(0xFF3B82F6).withValues(alpha: 0.3);
    } else if (code == 'HTC') {
      borderColor = const Color(0xFF059669);
      badgeBg = const Color(0xFFECFDF5);
      textColor = const Color(0xFF047857);
      glowColor = const Color(0xFF059669).withValues(alpha: 0.35);
    } else if (code == 'LTC') {
      borderColor = const Color(0xFF10B981);
      badgeBg = const Color(0xFFF0FDF4);
      textColor = const Color(0xFF059669);
      glowColor = const Color(0xFF10B981).withValues(alpha: 0.3);
    } else if (code == 'HTD') {
      borderColor = const Color(0xFF475569);
      badgeBg = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF334155);
      glowColor = const Color(0xFF475569).withValues(alpha: 0.3);
    } else if (code == 'LTD') {
      borderColor = const Color(0xFF78716C);
      badgeBg = const Color(0xFFF5F5F4);
      textColor = const Color(0xFF57534E);
      glowColor = const Color(0xFF78716C).withValues(alpha: 0.25);
    } else {
      borderColor = context.colors.border;
      badgeBg = context.colors.bgCard;
      textColor = context.colors.textMuted;
      glowColor = Colors.transparent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
          width: 1.8,
        ),
        boxShadow: isRanked
            ? [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SportIcon(sportName: sportName, size: 22),
          const SizedBox(width: 6),
          Text(
            showLabel && isRanked ? tierName ?? code : code,
            style: TextStyle(
              color: textColor,
              fontSize: showLabel ? 11.5 : 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }


}

class _SportIcon extends StatelessWidget {
  final String? sportName;
  final double size;

  const _SportIcon({required this.sportName, required this.size});

  @override
  Widget build(BuildContext context) {
    final normalized = (sportName ?? '').trim().toLowerCase();
    final key = AppConstants.sportNames.entries
        .where((entry) => entry.value.toLowerCase() == normalized)
        .map((entry) => entry.key)
        .firstWhere((value) => true, orElse: () => normalized);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: SportChoiceTile.buildSportIcon(key, size - 5),
      ),
    );
  }
}
