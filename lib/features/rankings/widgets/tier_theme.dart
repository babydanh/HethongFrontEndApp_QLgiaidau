import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';

/// Helper ánh xạ tier (bậc ELO) sang màu sắc & kiểu hiển thị chuẩn Web.
///
/// Cấp độ (theo backend & web frontend):
///   Tier S > High Tier A > Low Tier A > High Tier B > Low Tier B > High Tier C > Low Tier C > High Tier D > Low Tier D
class TierPalette {
  final String grade;
  final String label;
  final String fullLabel;
  final Color color;
  final Color soft;
  final Color badgeBg;
  final Color border;
  final LinearGradient gradient;

  const TierPalette({
    required this.grade,
    required this.label,
    required this.fullLabel,
    required this.color,
    required this.soft,
    required this.badgeBg,
    required this.border,
    required this.gradient,
  });

  // Palette màu chuẩn 100% khớp giao diện Web
  static const _tierS = TierPalette(
    grade: 'S',
    label: 'S',
    fullLabel: 'TIER S',
    color: Color(0xFF92400E),
    soft: Color(0xFFFEF3C7),
    badgeBg: Color(0xFFD97706),
    border: Color(0xFFFCD34D),
    gradient: LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
  );

  static const _highA = TierPalette(
    grade: 'A',
    label: 'A+',
    fullLabel: 'HIGH TIER A',
    color: Color(0xFF991B1B),
    soft: Color(0xFFF8C4B4),
    badgeBg: Color(0xFFDC2626),
    border: Color(0xFFFCA5A5),
    gradient: LinearGradient(colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)]),
  );

  static const _lowA = TierPalette(
    grade: 'A',
    label: 'A-',
    fullLabel: 'LOW TIER A',
    color: Color(0xFFB91C1C),
    soft: Color(0xFFFBE8E0),
    badgeBg: Color(0xFFEF4444),
    border: Color(0xFFFECACA),
    gradient: LinearGradient(colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)]),
  );

  static const _highB = TierPalette(
    grade: 'B',
    label: 'B+',
    fullLabel: 'HIGH TIER B',
    color: Color(0xFF1E40AF),
    soft: Color(0xFFBFDBFE),
    badgeBg: Color(0xFF2563EB),
    border: Color(0xFF93C5FD),
    gradient: LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)]),
  );

  static const _lowB = TierPalette(
    grade: 'B',
    label: 'B-',
    fullLabel: 'LOW TIER B',
    color: Color(0xFF1D4ED8),
    soft: Color(0xFFEFF6FF),
    badgeBg: Color(0xFF3B82F6),
    border: Color(0xFFBFDBFE),
    gradient: LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)]),
  );

  static const _highC = TierPalette(
    grade: 'C',
    label: 'C+',
    fullLabel: 'HIGH TIER C',
    color: Color(0xFF065F46),
    soft: Color(0xFFA7F3D0),
    badgeBg: Color(0xFF059669),
    border: Color(0xFF6EE7B7),
    gradient: LinearGradient(colors: [Color(0xFF6EE7B7), Color(0xFF10B981)]),
  );

  static const _lowC = TierPalette(
    grade: 'C',
    label: 'C-',
    fullLabel: 'LOW TIER C',
    color: Color(0xFF047857),
    soft: Color(0xFFECFDF5),
    badgeBg: Color(0xFF10B981),
    border: Color(0xFFA7F3D0),
    gradient: LinearGradient(colors: [Color(0xFF6EE7B7), Color(0xFF10B981)]),
  );

  static const _highD = TierPalette(
    grade: 'D',
    label: 'D+',
    fullLabel: 'HIGH TIER D',
    color: Color(0xFF1E293B),
    soft: Color(0xFFE2E8F0),
    badgeBg: Color(0xFF475569),
    border: Color(0xFFCBD5E1),
    gradient: LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFF64748B)]),
  );

  static const _lowD = TierPalette(
    grade: 'D',
    label: 'D-',
    fullLabel: 'LOW TIER D',
    color: Color(0xFF44403C),
    soft: Color(0xFFF5F5F4),
    badgeBg: Color(0xFF78716C),
    border: Color(0xFFD6D3D1),
    gradient: LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFF64748B)]),
  );

  /// Lấy palette theo tier (nếu null/empty → chưa xếp hạng).
  static TierPalette from(EloTier? tier) {
    if (tier == null) {
      return const TierPalette(
        grade: '',
        label: '?',
        fullLabel: 'CHƯA XẾP HẠNG',
        color: Color(0xFF64748B),
        soft: Color(0xFFF1F5F9),
        badgeBg: Color(0xFF64748B),
        border: Color(0xFFCBD5E1),
        gradient: LinearGradient(colors: [Color(0xFF475569), Color(0xFF334155)]),
      );
    }
    final nameLower = tier.name.toLowerCase();
    if (nameLower.contains('tier s') || nameLower == 's' || tier.minElo >= 1800) {
      return _tierS;
    }
    if (nameLower.contains('high tier a') || (nameLower.contains('a') && tier.minElo >= 1700)) {
      return _highA;
    }
    if (nameLower.contains('low tier a') || (nameLower.contains('a') && tier.minElo >= 1600)) {
      return _lowA;
    }
    if (nameLower.contains('high tier b') || (nameLower.contains('b') && tier.minElo >= 1500)) {
      return _highB;
    }
    if (nameLower.contains('low tier b') || (nameLower.contains('b') && tier.minElo >= 1400)) {
      return _lowB;
    }
    if (nameLower.contains('high tier c') || (nameLower.contains('c') && tier.minElo >= 1300)) {
      return _highC;
    }
    if (nameLower.contains('low tier c') || (nameLower.contains('c') && tier.minElo >= 1200)) {
      return _lowC;
    }
    if (nameLower.contains('high tier d') || (nameLower.contains('d') && tier.minElo >= 1100)) {
      return _highD;
    }
    return _lowD;
  }

  /// Tìm tier khớp với điểm ELO của người chơi.
  static EloTier? matchTier(int elo, List<EloTier> tiers) {
    for (final t in tiers) {
      if (elo >= t.minElo && elo <= t.maxElo) return t;
    }
    if (tiers.isNotEmpty) return tiers.first;
    return null;
  }
}
