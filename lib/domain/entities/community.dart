/// Entity cho câu lạc bộ / cộng đồng
class Community {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? locationAddress;
  final String? provinceCode;
  final int memberCount;
  final int? maxMembers;
  final List<String> sports; // tên môn thể thao
  final String status; // ACTIVE, PENDING
  final String joinMode; // OPEN, APPROVAL, INVITE_ONLY
  final String createdAt;

  const Community({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.locationAddress,
    this.provinceCode,
    this.memberCount = 0,
    this.maxMembers,
    this.sports = const [],
    this.status = 'ACTIVE',
    this.joinMode = 'OPEN',
    this.createdAt = '',
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    // Xử lý sports từ communitySports nếu có
    List<String> parsedSports = [];
    if (json['communitySports'] != null && json['communitySports'] is List) {
      parsedSports = (json['communitySports'] as List).map((e) {
        if (e is Map) return e['category']?['name']?.toString() ?? e['categoryId']?.toString() ?? '';
        return e.toString();
      }).toList();
    }

    // Xử lý member count
    int memberCount = 0;
    if (json['_count'] != null) {
      memberCount = (json['_count'] as Map)['members'] ?? 0;
    } else if (json['memberCount'] != null) {
      memberCount = json['memberCount'];
    } else if (json['members'] != null && json['members'] is List) {
      memberCount = (json['members'] as List).length;
    }

    return Community(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logoUrl'] ?? json['logo_url'],
      bannerUrl: json['bannerUrl'] ?? json['banner_url'],
      locationAddress: json['locationAddress'] ?? json['location_address'],
      provinceCode: json['provinceCode'] ?? json['province_code'],
      memberCount: memberCount,
      maxMembers: json['maxMembers'],
      sports: parsedSports,
      status: json['status'] ?? 'ACTIVE',
      joinMode: json['joinMode'] ?? 'OPEN',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
