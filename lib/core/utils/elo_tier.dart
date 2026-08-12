/// Bảng tier ELO dùng chung (đồng bộ chuẩn WEB — `EloTierBadge.tsx`).
///
/// Ngưỡng số: S ≥ 1800, A ≥ 1700, B ≥ 1500, C ≥ 1200, D ≥ 1100 (dưới 1100
/// vẫn hiển thị D, giống WEB "Low Tier D").
/// Ưu tiên `tierName` từ API nếu có (giống WEB: "The API tier wins; numeric
/// thresholds remain a fallback for old records").
library;

/// Nhóm tier hiển thị (5 bậc chuẩn WEB).
enum EloTierRole { s, a, b, c, d }

/// Kết quả resolve tier: nhãn ngắn (S/A/B/C/D) + role để lấy màu từ AppTheme.
class EloTierInfo {
  final String label;
  final EloTierRole role;

  const EloTierInfo({required this.label, required this.role});
}

/// Resolve tier từ ELO + tierName API.
///
/// - `tierName` có giá trị nhận diện được (Tier S / High-Low Tier A/B/C/D)
///   → dùng tierName (dữ liệu cũ không có vẫn fallback ngưỡng số).
/// - Không có tierName → ngưỡng số: 1800/1700/1500/1200/1100.
EloTierInfo resolveEloTier({required int elo, String? tierName}) {
  final name = (tierName ?? '').trim().toLowerCase();

  if (name.isNotEmpty) {
    if (name.contains('tier s')) return _tier('S', EloTierRole.s);
    if (name.contains('tier a')) return _tier('A', EloTierRole.a);
    if (name.contains('tier b')) return _tier('B', EloTierRole.b);
    if (name.contains('tier c')) return _tier('C', EloTierRole.c);
    if (name.contains('tier d')) return _tier('D', EloTierRole.d);
  }

  if (elo >= 1800) return _tier('S', EloTierRole.s);
  if (elo >= 1700) return _tier('A', EloTierRole.a);
  if (elo >= 1500) return _tier('B', EloTierRole.b);
  if (elo >= 1200) return _tier('C', EloTierRole.c);
  return _tier('D', EloTierRole.d);
}

EloTierInfo _tier(String label, EloTierRole role) =>
    EloTierInfo(label: label, role: role);