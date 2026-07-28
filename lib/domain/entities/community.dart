/// Entity cho câu lạc bộ / cộng đồng
class Community {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? locationAddress;
  final String? provinceCode;
  final String? ownerId;
  final String? myRole;
  final int memberCount;
  final int? maxMembers;
  final List<String> sports; // tên môn thể thao
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
    this.ownerId,
    this.myRole,
    this.memberCount = 0,
    this.maxMembers,
    this.sports = const [],
    this.status = 'ACTIVE',
    this.joinMode = 'OPEN',
    this.visibility = 'PUBLIC',
    this.createdAt = '',
  });

  factory Community.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> json = (rawJson['community'] is Map<String, dynamic>)
        ? (rawJson['community'] as Map<String, dynamic>)
        : rawJson;

    // 1. Xử lý môn thể thao (thu thập từ mọi nguồn sports / communitySports / categories / categoryIds)
    List<String> parsedSports = [];
    final allSources = [
      json['sports'], rawJson['sports'],
      json['communitySports'], rawJson['communitySports'],
      json['categories'], rawJson['categories'],
      json['categoryIds'], rawJson['categoryIds'],
      json['sport'], rawJson['sport'],
      json['category'], rawJson['category'],
    ];

    for (final src in allSources) {
      if (src == null) continue;
      if (src is List) {
        for (final e in src) {
          String sName = '';
          if (e is Map) {
            sName = e['name']?.toString() ?? e['category']?['name']?.toString() ?? e['categoryId']?.toString() ?? e['id']?.toString() ?? '';
          } else {
            sName = e.toString();
          }
          sName = sName.trim();
          if (sName.isNotEmpty && !parsedSports.contains(sName)) {
            parsedSports.add(sName);
          }
        }
      } else {
        String sName = src is Map ? (src['name']?.toString() ?? src['id']?.toString() ?? '') : src.toString();
        sName = sName.trim();
        if (sName.isNotEmpty && !parsedSports.contains(sName)) {
          parsedSports.add(sName);
        }
      }
    }

    // 2. Xử lý số lượng thành viên (memberCount / _count / members)
    int memberCount = 0;
    final countObj = json['_count'] ?? rawJson['_count'];
    if (countObj != null && countObj is Map) {
      final mCount = countObj['members'] ?? countObj['communityMembers'] ?? countObj['Members'] ?? countObj['users'];
      if (mCount != null) {
        memberCount = int.tryParse(mCount.toString()) ?? 0;
      }
    }
    if (memberCount == 0) {
      final mc = json['memberCount'] ?? rawJson['memberCount'] ?? json['membersCount'] ?? rawJson['membersCount'] ?? json['totalMembers'] ?? rawJson['totalMembers'];
      if (mc != null) {
        memberCount = int.tryParse(mc.toString()) ?? 0;
      }
    }
    if (memberCount == 0) {
      final membersList = json['members'] ?? rawJson['members'] ?? json['communityMembers'] ?? rawJson['communityMembers'];
      if (membersList is List) {
        memberCount = membersList.length;
      }
    }

    // 3. Xử lý Vai trò & Owner ID
    final ownerId = json['ownerId'] ?? json['owner_id'] ?? json['createdById'] ?? json['created_by_id'] ?? rawJson['ownerId'] ?? rawJson['createdById'] ?? rawJson['userId'];
    
    // role từ CommunityMember row (rawJson['role']) hoặc từ community object
    String? myRole = rawJson['role'] ?? rawJson['myRole'] ?? rawJson['userRole'] ?? json['myRole'] ?? json['role'] ?? json['userRole'];
    if (myRole != null) {
      myRole = myRole.toString().toUpperCase();
    }

    final bool isOwnerFlag = rawJson['isOwner'] == true || json['isOwner'] == true || rawJson['is_owner'] == true || json['is_owner'] == true;
    if (isOwnerFlag || myRole == 'OWNER' || myRole == 'OWNER_ROLE' || myRole == 'LEADER' || myRole == 'CREATOR' || myRole == 'HOST') {
      myRole = 'OWNER';
    }

    return Community(
      id: json['id']?.toString() ?? rawJson['id']?.toString() ?? '',
      name: json['name']?.toString() ?? rawJson['name']?.toString() ?? '',
      description: json['description'] ?? rawJson['description'],
      logoUrl: json['logoUrl'] ?? json['logo_url'] ?? rawJson['logoUrl'],
      bannerUrl: json['bannerUrl'] ?? json['banner_url'] ?? rawJson['bannerUrl'],
      locationAddress: json['locationAddress'] ?? json['location_address'] ?? rawJson['locationAddress'],
      provinceCode: json['provinceCode'] ?? json['province_code'] ?? rawJson['provinceCode'],
      ownerId: ownerId?.toString(),
      myRole: myRole,
      memberCount: memberCount,
      maxMembers: json['maxMembers'] ?? rawJson['maxMembers'],
      sports: parsedSports,
      status: json['status']?.toString() ?? rawJson['status']?.toString() ?? 'ACTIVE',
      joinMode: json['joinMode']?.toString() ?? rawJson['joinMode']?.toString() ?? 'OPEN',
      visibility: json['visibility']?.toString() ?? rawJson['visibility']?.toString() ?? 'PUBLIC',
      createdAt: json['createdAt']?.toString() ?? rawJson['createdAt']?.toString() ?? '',
    );
  }
}
