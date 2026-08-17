/// Đơn vị hành chính Việt Nam theo API v2 (tỉnh/thành, phường/xã).
/// GET /regions/provinces, /regions/wards
class Region {
  final String code;
  final String name;
  final String? fullName;

  const Region({required this.code, required this.name, this.fullName});

  factory Region.fromJson(Map<String, dynamic> json) => Region(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        fullName: json['fullName']?.toString(),
      );
}
