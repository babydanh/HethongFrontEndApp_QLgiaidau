/// Đơn vị hành chính Việt Nam theo API v2 (tỉnh/thành, phường/xã).
/// GET /regions/provinces, /regions/wards, /regions/search
class Region {
  final String code;
  final String name;
  final String? fullName;
  final String? provinceCode;

  /// Loại đơn vị khi trả về từ `/regions/search`: `province` hoặc `ward`.
  /// Null khi lấy từ `/regions/provinces` hoặc `/regions/wards`.
  final String? type;

  /// Tên tỉnh chủ quản (chỉ có ở kết quả ward của `/regions/search`).
  final String? provinceName;

  /// Tâm tọa độ (nếu API có trả kèm), dùng để ghim tạm khi chỉ có mã địa phương.
  final double? latitude;
  final double? longitude;

  const Region({
    required this.code,
    required this.name,
    this.fullName,
    this.provinceCode,
    this.type,
    this.provinceName,
    this.latitude,
    this.longitude,
  });

  /// Địa chỉ hiển thị đầy đủ: "Phường X, Tỉnh Y" cho ward, tên tỉnh cho province.
  String get displayAddress {
    final full = fullName?.trim() ?? '';
    if (full.isNotEmpty) return full;
    final province = provinceName?.trim() ?? '';
    if (province.isNotEmpty && province != name.trim()) {
      return '${name.trim()}, $province';
    }
    return name;
  }

  bool get isWard => type == 'ward' || provinceCode != null;

  factory Region.fromJson(Map<String, dynamic> json) => Region(
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    fullName:
        (json['displayAddress'] ?? json['fullName'] ?? json['full_name'])
            ?.toString(),
    provinceCode:
        (json['provinceCode'] ?? json['province_code'])?.toString(),
    type: json['type']?.toString(),
    provinceName:
        (json['provinceName'] ?? json['province_name'])?.toString(),
    latitude: (json['latitude'] as num?)?.toDouble() ??
        (json['centerLat'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble() ??
        (json['centerLng'] as num?)?.toDouble(),
  );
}
