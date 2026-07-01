/// Mô tả một bậc ELO (tier) của một môn thể thao (category).
///
/// Phản ánh bảng `elo_tiers` trong database schema:
///   - category_id, name, min_elo, max_elo, icon_url
/// Xem `backend-api_qlgiaidau/docs/database_schema.md` (mục 2. Tầng Ranking).
class EloTier {
  final String id;
  final String categoryId;
  final String name;
  final int minElo;
  final int maxElo;
  final String? iconUrl;

  const EloTier({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.minElo,
    required this.maxElo,
    this.iconUrl,
  });

  factory EloTier.fromJson(Map<String, dynamic> json) {
    return EloTier(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? json['category_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      minElo: ((json['minElo'] ?? json['min_elo'] ?? 0) as num).toInt(),
      maxElo: ((json['maxElo'] ?? json['max_elo'] ?? 0) as num).toInt(),
      iconUrl: json['iconUrl'] as String? ?? json['icon_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'minElo': minElo,
        'maxElo': maxElo,
        if (iconUrl != null) 'iconUrl': iconUrl,
      };

  /// Nhãn ngắn gọn để hiển thị trên badge (VD: "S", "A", "B+", "D-").
  String get shortLabel {
    final lower = name.toLowerCase();
    if (lower.contains('tier s') || lower == 's') return 'S';
    final letter = RegExp(r'tier\s+([a-d])').firstMatch(lower)?.group(1);
    if (letter == null) return name.isEmpty ? '?' : name[0].toUpperCase();
    final prefix = lower.contains('high') ? '+' : (lower.contains('low') ? '-' : '');
    return letter.toUpperCase() + prefix;
  }

  /// Hạng chữ cái thô (S/A/B/C/D) dùng để chọn màu sắc.
  String get grade {
    final lower = name.toLowerCase();
    if (lower.contains('tier s') || lower == 's') return 'S';
    return RegExp(r'tier\s+([a-d])').firstMatch(lower)?.group(1)?.toUpperCase() ?? 'D';
  }

  @override
  String toString() => 'EloTier($name $minElo-$maxElo)';
}
