/// Model cho thành viên CLB — từ API response
class CommunityMemberModel {
  final String id;
  final String userId;
  final String communityId;
  final String role;
  final String status;
  final String? userFullName;
  final String? userAvatarUrl;
  final String? userEmail;
  final String joinedAt;

  const CommunityMemberModel({
    required this.id,
    required this.userId,
    required this.communityId,
    this.role = 'MEMBER',
    this.status = 'JOINED',
    this.userFullName,
    this.userAvatarUrl,
    this.userEmail,
    this.joinedAt = '',
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    // Xử lý nested member + user từ BE
    final member = json['member'] as Map<String, dynamic>? ?? json;
    final user = json['user'] as Map<String, dynamic>?;

    return CommunityMemberModel(
      id: member['id']?.toString() ?? '',
      userId: member['userId']?.toString() ?? user?['id']?.toString() ?? '',
      communityId: member['communityId']?.toString() ?? '',
      role: member['role']?.toString() ?? 'MEMBER',
      status: member['status']?.toString() ?? 'JOINED',
      userFullName: user?['fullName']?.toString(),
      userAvatarUrl: user?['avatarUrl']?.toString(),
      userEmail: user?['email']?.toString(),
      joinedAt: member['joinedAt']?.toString() ?? '',
    );
  }
}
