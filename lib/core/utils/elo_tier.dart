/// Bảng tier ELO dùng chung (đồng bộ 100% chuẩn SportO Web — `rank-style.ts` & `EloTierBadge.tsx`).
///
/// Chuẩn 9 bậc:
/// - Tier S (TS)       : ≥ 1800
/// - High Tier A (HTA) : 1700 - 1799
/// - Low Tier A (LTA)  : 1600 - 1699
/// - High Tier B (HTB) : 1500 - 1599
/// - Low Tier B (LTB)  : 1400 - 1499
/// - High Tier C (HTC) : 1300 - 1399
/// - Low Tier C (LTC)  : 1200 - 1299
/// - High Tier D (HTD) : 1100 - 1199
/// - Low Tier D (LTD)  : 1000 - 1099 (hoặc < 1100, ELO mặc định = 1000)
library;

import 'package:flutter/material.dart';

/// 9 bậc chuẩn SportO
enum EloTierRole {
  s,
  highA,
  lowA,
  highB,
  lowB,
  highC,
  lowC,
  highD,
  lowD,
}

/// Kết quả resolve tier: mã ngắn (TS, HTA, LTD...), tên đầy đủ, màu sắc và role.
class EloTierInfo {
  final String shortCode;
  final String fullName;
  final EloTierRole role;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color glowColor;

  /// Compatibility getter cho code cũ
  String get label => shortCode;

  const EloTierInfo({
    required this.shortCode,
    required this.fullName,
    required this.role,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.glowColor,
  });
}

/// Chuyển đổi tên tier hoặc điểm ELO thành mã viết tắt chuẩn SportO:
/// - Tier S -> TS
/// - High Tier A -> HTA
/// - Low Tier A -> LTA
/// - High Tier B -> HTB
/// - Low Tier B -> LTB
/// - High Tier C -> HTC
/// - Low Tier C -> LTC
/// - High Tier D -> HTD
/// - Low Tier D -> LTD
String getShortTierCode({String? tierName, int? elo}) {
  final name = (tierName ?? '').trim();
  if (name.isNotEmpty) {
    final lower = name.toLowerCase();
    if (lower.contains('tier s') || lower == 's' || lower == 'ts') return 'TS';
    if (lower.contains('high tier a') || lower == 'hta' || lower == 'a+') return 'HTA';
    if (lower.contains('low tier a') || lower == 'lta' || lower == 'a-') return 'LTA';
    if (lower.contains('high tier b') || lower == 'htb' || lower == 'b+') return 'HTB';
    if (lower.contains('low tier b') || lower == 'ltb' || lower == 'b-') return 'LTB';
    if (lower.contains('high tier c') || lower == 'htc' || lower == 'c+') return 'HTC';
    if (lower.contains('low tier c') || lower == 'ltc' || lower == 'c-') return 'LTC';
    if (lower.contains('high tier d') || lower == 'htd' || lower == 'd+') return 'HTD';
    if (lower.contains('low tier d') || lower == 'ltd' || lower == 'd-') return 'LTD';
  }

  if (elo != null) {
    if (elo >= 1800) return 'TS';
    if (elo >= 1700) return 'HTA';
    if (elo >= 1600) return 'LTA';
    if (elo >= 1500) return 'HTB';
    if (elo >= 1400) return 'LTB';
    if (elo >= 1300) return 'HTC';
    if (elo >= 1200) return 'LTC';
    if (elo >= 1100) return 'HTD';
    return 'LTD';
  }

  return 'LTD';
}

/// Resolve tier chuẩn 9 bậc với màu sắc đồng bộ Web
EloTierInfo resolveEloTier({required int elo, String? tierName}) {
  final code = getShortTierCode(tierName: tierName, elo: elo);

  switch (code) {
    case 'TS':
      return const EloTierInfo(
        shortCode: 'TS',
        fullName: 'Tier S',
        role: EloTierRole.s,
        textColor: Color(0xFFF59E0B),
        backgroundColor: Color(0xFFFEF3C7),
        borderColor: Color(0xFFF59E0B),
        glowColor: Color(0x66F59E0B),
      );
    case 'HTA':
      return const EloTierInfo(
        shortCode: 'HTA',
        fullName: 'High Tier A',
        role: EloTierRole.highA,
        textColor: Color(0xFFE11D48),
        backgroundColor: Color(0xFFFFE4E6),
        borderColor: Color(0xFFE11D48),
        glowColor: Color(0x66E11D48),
      );
    case 'LTA':
      return const EloTierInfo(
        shortCode: 'LTA',
        fullName: 'Low Tier A',
        role: EloTierRole.lowA,
        textColor: Color(0xFFF43F5E),
        backgroundColor: Color(0xFFFFF1F2),
        borderColor: Color(0xFFFDA4AF),
        glowColor: Color(0x4DF43F5E),
      );
    case 'HTB':
      return const EloTierInfo(
        shortCode: 'HTB',
        fullName: 'High Tier B',
        role: EloTierRole.highB,
        textColor: Color(0xFF2563EB),
        backgroundColor: Color(0xFFDBEAFE),
        borderColor: Color(0xFF2563EB),
        glowColor: Color(0x662563EB),
      );
    case 'LTB':
      return const EloTierInfo(
        shortCode: 'LTB',
        fullName: 'Low Tier B',
        role: EloTierRole.lowB,
        textColor: Color(0xFF0284C7),
        backgroundColor: Color(0xFFE0F2FE),
        borderColor: Color(0xFF7DD3FC),
        glowColor: Color(0x4D0284C7),
      );
    case 'HTC':
      return const EloTierInfo(
        shortCode: 'HTC',
        fullName: 'High Tier C',
        role: EloTierRole.highC,
        textColor: Color(0xFF059669),
        backgroundColor: Color(0xFFD1FAE5),
        borderColor: Color(0xFF059669),
        glowColor: Color(0x66059669),
      );
    case 'LTC':
      return const EloTierInfo(
        shortCode: 'LTC',
        fullName: 'Low Tier C',
        role: EloTierRole.lowC,
        textColor: Color(0xFF10B981),
        backgroundColor: Color(0xFFECFDF5),
        borderColor: Color(0xFF6EE7B7),
        glowColor: Color(0x4D10B981),
      );
    case 'HTD':
      return const EloTierInfo(
        shortCode: 'HTD',
        fullName: 'High Tier D',
        role: EloTierRole.highD,
        textColor: Color(0xFF334155),
        backgroundColor: Color(0xFFE2E8F0),
        borderColor: Color(0xFF94A3B8),
        glowColor: Color(0x4D64748B),
      );
    case 'LTD':
    default:
      return const EloTierInfo(
        shortCode: 'LTD',
        fullName: 'Low Tier D',
        role: EloTierRole.lowD,
        textColor: Color(0xFF475569),
        backgroundColor: Color(0xFFF1F5F9),
        borderColor: Color(0xFFCBD5E1),
        glowColor: Color(0x3364748B),
      );
  }
}