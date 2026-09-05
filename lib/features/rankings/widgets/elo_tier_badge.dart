import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/core/utils/elo_tier.dart';

/// Widget hiển thị huy hiệu ELO Tier chuẩn SportO (đồng bộ 100% với EloTierBadge.tsx trên Web).
/// - Có icon môn thể thao (Pickleball, Tennis, Badminton, Football...).
/// - Có màu sắc nền, viền và glow effect chuẩn theo từng tier.
/// - Hiển thị mã ngắn (LTD, HTD, LTC, HTC, LTB, HTB, LTA, HTA, TS) hoặc tên đầy đủ.
class EloTierBadge extends StatelessWidget {
  final int elo;
  final String? tierName;
  final String? categoryName;
  final bool showFullName;
  final double scale;

  const EloTierBadge({
    super.key,
    required this.elo,
    this.tierName,
    this.categoryName,
    this.showFullName = false,
    this.scale = 1.0,
  });

  Widget _buildSportIcon(String? sport, double sizePx) {
    final s = (sport ?? '').toLowerCase().trim();
    if (s.contains('tennis') || s.contains('quần vợt')) {
      return SvgPicture.asset(
        'assets/icons/tennis.svg',
        width: sizePx,
        height: sizePx,
      );
    }
    if (s.contains('badminton') || s.contains('cầu lông')) {
      return SvgPicture.asset(
        'assets/icons/badminton.svg',
        width: sizePx,
        height: sizePx,
      );
    }
    if (s.contains('football') || s.contains('bóng đá') || s.contains('soccer')) {
      return SvgPicture.asset(
        'assets/icons/football.svg',
        width: sizePx,
        height: sizePx,
      );
    }
    if (s.contains('ping') || s.contains('bóng bàn') || s.contains('table tennis')) {
      return SvgPicture.asset(
        'assets/icons/ping-pong.svg',
        width: sizePx,
        height: sizePx,
      );
    }

    // Default fallback: Pickleball paddle image
    return Image.asset(
      'assets/icons/pickleball.png',
      width: sizePx,
      height: sizePx,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.sports_tennis_rounded,
        size: sizePx,
        color: const Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = resolveEloTier(elo: elo, tierName: tierName);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scale,
        vertical: 3 * scale,
      ),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: info.borderColor,
          width: 1.5 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F0F172A),
            blurRadius: 4 * scale,
            offset: Offset(0, 1.5 * scale),
          ),
          BoxShadow(
            color: info.glowColor,
            blurRadius: 8 * scale,
            spreadRadius: 0.5 * scale,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSportIcon(categoryName, 15 * scale),
          SizedBox(width: 4.5 * scale),
          Text(
            showFullName ? info.fullName : info.shortCode,
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w900,
              color: info.textColor,
              letterSpacing: -0.2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
