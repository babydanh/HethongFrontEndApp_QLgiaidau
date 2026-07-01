import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';

/// Helper ánh xạ tier (bậc ELO) sang màu sắc & kiểu hiển thị.
///
/// Cấp độ (theo backend, schema `elo_tiers`):
///   Tier S > High/Low A > High/Low B > High/Low C > High/Low D
/// Xem `backend-api_qlgiaidau/docs/database_schema.md`.
class TierPalette {
  final String grade;
  final String label;
  final Color color;
  final Color soft;
  final LinearGradient gradient;

  const TierPalette({
    required this.grade,
    required this.label,
    required this.color,
    required this.soft,
    required this.gradient,
  });

  static const _s = TierPalette(
    grade: 'S',
    label: 'S',
    color: Color(0xFFFF7A00),
    soft: Color(0x33FF7A00),
    gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF7A00)]),
  );
  static const _a = TierPalette(
    grade: 'A',
    label: 'A',
    color: Color(0xFFEF4444),
    soft: Color(0x33EF4444),
    gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEF4444)]),
  );
  static const _b = TierPalette(
    grade: 'B',
    label: 'B',
    color: Color(0xFF3B82F6),
    soft: Color(0x333B82F6),
    gradient: LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)]),
  );
  static const _c = TierPalette(
    grade: 'C',
    label: 'C',
    color: Color(0xFF22C55E),
    soft: Color(0x3322C55E),
    gradient: LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF22C55E)]),
  );
  static const _d = TierPalette(
    grade: 'D',
    label: 'D',
    color: Color(0xFF94A3B8),
    soft: Color(0x3394A3B8),
    gradient: LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)]),
  );

  /// Lấy palette theo tier (nếu null/empty → chưa xếp hạng).
  static TierPalette from(EloTier? tier) {
    if (tier == null) {
      return const TierPalette(
        grade: '',
        label: '?',
        color: Color(0xFF64748B),
        soft: Color(0x3364748B),
        gradient: LinearGradient(colors: [Color(0xFF475569), Color(0xFF334155)]),
      );
    }
    switch (tier.grade) {
      case 'S':
        return _s;
      case 'A':
        return _a;
      case 'B':
        return _b;
      case 'C':
        return _c;
      default:
        return _d;
    }
  }

  /// Tìm tier khớp với điểm ELO của người chơi.
  static EloTier? matchTier(int elo, List<EloTier> tiers) {
    for (final t in tiers) {
      if (elo >= t.minElo && elo <= t.maxElo) return t;
    }
    // Dưới mức thấp nhất → trả tier thấp nhất (nếu có).
    if (tiers.isNotEmpty) return tiers.first;
    return null;
  }
}
