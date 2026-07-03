/// Model cho lời mời tham gia câu lạc bộ.
class CommunityInviteModel {
  final String id;
  final String communityId;
  final String communityName;
  final String? communityLogoUrl;
  final String? communityBannerUrl;
  final String inviterName;
  final String role;
  final String status; // PENDING, ACCEPTED, DECLINED
  final String createdAt;

  const CommunityInviteModel({
    required this.id,
    required this.communityId,
    required this.communityName,
    this.communityLogoUrl,
    this.communityBannerUrl,
    this.inviterName = '',
    this.role = 'MEMBER',
    this.status = 'PENDING',
    this.createdAt = '',
  });

  factory CommunityInviteModel.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả cấu trúc lồng (community { name, logoUrl }) và phẳng
    String communityName = json['communityName'] ?? '';
    String? communityLogoUrl = json['communityLogoUrl'];
    String? communityBannerUrl = json['communityBannerUrl'];

    if (json['community'] is Map) {
      final c = json['community'] as Map<String, dynamic>;
      communityName = c['name'] ?? communityName;
      communityLogoUrl = c['logoUrl'] ?? communityLogoUrl;
      communityBannerUrl = c['bannerUrl'] ?? communityBannerUrl;
    }

    String inviterName = json['inviterName'] ?? '';
    if (json['inviter'] is Map) {
      inviterName = (json['inviter'] as Map)['fullName'] ?? inviterName;
    }

    return CommunityInviteModel(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? json['community']?['id'] ?? '',
      communityName: communityName,
      communityLogoUrl: communityLogoUrl,
      communityBannerUrl: communityBannerUrl,
      inviterName: inviterName,
      role: json['role'] ?? 'MEMBER',
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
    );
  }

  bool get isPending => status.toUpperCase() == 'PENDING';
}
