/// Entity cho câu lạc bộ / cộng đồng
class Community {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? locationAddress;
  final String? provinceCode;
  final String? districtCode;
  final String? wardCode;
  final String? ownerId;
  final String? myRole;
  final int memberCount;
  final int tournamentCount;
  final int? maxMembers;
  final List<String> sports; // tên môn thể thao
  final String? rules; // Nội quy CLB
  final List<String> joinQuestions; // Câu hỏi khi tham gia
  final Map<String, String> socialLinks; // facebook / zalo / website
  final String status; // ACTIVE, PENDING
  final String joinMode; // OPEN, APPROVAL, INVITE_ONLY
  final String visibility; // PUBLIC, PRIVATE, HIDDEN
  final String createdAt;

  const Community({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.locationAddress,
    this.provinceCode,
    this.districtCode,
    this.wardCode,
    this.ownerId,
    this.myRole,
    this.memberCount = 0,
    this.tournamentCount = 0,
    this.maxMembers,
    this.sports = const [],
    this.rules,
    this.joinQuestions = const [],
    this.socialLinks = const {},
    this.status = 'ACTIVE',
    this.joinMode = 'OPEN',
    this.visibility = 'PUBLIC',
    this.createdAt = '',
  });

  factory Community.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> json = (rawJson['community'] is Map<String, dynamic>)
        ? (rawJson['community'] as Map<String, dynamic>)
        : rawJson;

    // 1. Môn thể thao — backend trả `categories` (List<Category>); fallback `sports`, `communitySports`
    final List<String> parsedSports = [];
    for (final src in [json['categories'], json['sports'], json['communitySports']]) {
      if (src is! List) continue;
      for (final e in src) {
        String sName = '';
        if (e is Map) {
          if (e['category'] is Map) {
            sName = e['category']['name']?.toString() ?? e['category']['slug']?.toString() ?? '';
          } else {
            sName = e['name']?.toString() ?? e['id']?.toString() ?? '';
          }
        } else {
          sName = e.toString();
        }
        sName = sName.trim();
        if (sName.isNotEmpty && !parsedSports.contains(sName)) {
          parsedSports.add(sName);
        }
      }
    }
    if (parsedSports.isEmpty && json['communitySports'] is List) {
      for (final e in json['communitySports'] as List) {
        if (e is Map && e['category'] is Map) {
          final n = e['category']['name']?.toString() ?? '';
          if (n.isNotEmpty) parsedSports.add(n);
        }
      }
    }

    // 2. Số lượng thành viên — ưu tiên `_count.members`, fallback `memberCount`
    final countObj = json['_count'] ?? rawJson['_count'];
    int memberCount = countObj is Map ? int.tryParse(countObj['members']?.toString() ?? '') ?? 0 : 0;
    if (memberCount == 0) {
      final mc = json['memberCount'] ?? rawJson['memberCount'];
      memberCount = int.tryParse(mc?.toString() ?? '') ?? 0;
    }

    // 3. Số giải đấu — từ `_count.tournaments`, fallback `tournamentCount`
    int tournamentCount = countObj is Map ? int.tryParse(countObj['tournaments']?.toString() ?? '') ?? 0 : 0;
    if (tournamentCount == 0) {
      final tc = json['tournamentCount'] ?? rawJson['tournamentCount'];
      tournamentCount = int.tryParse(tc?.toString() ?? '') ?? 0;
    }

    // 4. Vai trò & Owner ID
    final ownerId = json['creatorId'] ?? json['ownerId'] ?? rawJson['ownerId'];
    
    // 5. Vai trò user hiện tại — từ member row (rawJson['role']) hoặc community object
    String? myRole = rawJson['role'] ?? rawJson['myRole'] ?? json['myRole'] ?? json['role'];
    if (myRole != null) {
      myRole = myRole.toString().toUpperCase();
    }

    if (myRole == 'OWNER' || myRole == 'OWNER_ROLE' || myRole == 'LEADER' || myRole == 'CREATOR' || myRole == 'HOST') {
      myRole = 'OWNER';
    }

    // 6. Câu hỏi khi tham gia — backend jsonb string[] (khớp WEB types/community.ts)
    List<String> joinQuestions = [];
    final jq = json['joinQuestions'] ?? rawJson['joinQuestions'];
    if (jq is List) {
      joinQuestions = jq.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }

    // 7. Liên kết mạng xã hội — backend jsonb {facebook, zalo, website}
    Map<String, String> socialLinks = {};
    final sl = json['socialLinks'] ?? rawJson['socialLinks'];
    if (sl is Map) {
      socialLinks = sl.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }

    return Community(
      id: json['id']?.toString() ?? rawJson['id']?.toString() ?? '',
      name: json['name']?.toString() ?? rawJson['name']?.toString() ?? '',
      description: json['description'] ?? rawJson['description'],
      logoUrl: json['logoUrl'] ?? json['logo_url'] ?? rawJson['logoUrl'],
      bannerUrl: json['bannerUrl'] ?? json['banner_url'] ?? rawJson['bannerUrl'],
      locationAddress: json['locationAddress'] ?? json['location_address'] ?? rawJson['locationAddress'],
      provinceCode: json['provinceCode'] ?? json['province_code'] ?? rawJson['provinceCode'],
      districtCode: json['districtCode'] ?? rawJson['districtCode'],
      wardCode: json['wardCode'] ?? rawJson['wardCode'],
      ownerId: ownerId?.toString(),
      myRole: myRole,
      memberCount: memberCount,
      tournamentCount: tournamentCount,
      maxMembers: json['maxMembers'] ?? rawJson['maxMembers'],
      sports: parsedSports,
      status: json['status']?.toString() ?? rawJson['status']?.toString() ?? 'ACTIVE',
      joinMode: json['joinMode']?.toString() ?? rawJson['joinMode']?.toString() ?? 'OPEN',
      visibility: json['visibility']?.toString() ?? rawJson['visibility']?.toString() ?? 'PUBLIC',
      rules: json['rules'] ?? rawJson['rules'],
      joinQuestions: joinQuestions,
      socialLinks: socialLinks,
      createdAt: json['createdAt']?.toString() ?? rawJson['createdAt']?.toString() ?? '',
    );
  }
}
