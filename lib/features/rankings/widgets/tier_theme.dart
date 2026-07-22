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

  // Palette màu sắc tinh tế cho các Tier (S, A, B, C, D)
  static const _s = TierPalette(
    grade: 'S',
    label: 'S',
    color: Color(0xFFD97706),
    soft: Color(0xFFFEF3C7),
    gradient: LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
  );
  static const _a = TierPalette(
    grade: 'A',
    label: 'A',
    color: Color(0xFFDC2626),
    soft: Color(0xFFFEE2E2),
    gradient: LinearGradient(colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)]),
  );
  static const _b = TierPalette(
    grade: 'B',
    label: 'B',
    color: Color(0xFF2563EB),
    soft: Color(0xFFDBEAFE),
    gradient: LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)]),
  );
  static const _c = TierPalette(
    grade: 'C',
    label: 'C',
    color: Color(0xFF059669),
    soft: Color(0xFFD1FAE5),
    gradient: LinearGradient(colors: [Color(0xFF6EE7B7), Color(0xFF10B981)]),
  );
  static const _d = TierPalette(
    grade: 'D',
    label: 'D',
    color: Color(0xFF475569),
    soft: Color(0xFFF1F5F9),
    gradient: LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFF64748B)]),
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
