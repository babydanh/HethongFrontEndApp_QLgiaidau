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

  /// P2C.1/P2C.2 — Tag BQT (text[] từ backend, tối đa 5).
  final List<String> tags;

  /// P2C.3 — Streak tính động từ trận đấu (WIN/LOSS/ELO_UP), không lưu DB.
  final CommunityMemberStreakModel streak;

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
    this.tags = const [],
    this.streak = const CommunityMemberStreakModel(),
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    // Xử lý nested member + user từ BE
    final member = json['member'] as Map<String, dynamic>? ?? json;
    final user = json['user'] as Map<String, dynamic>?;
    final profile = user?['profile'] as Map<String, dynamic>?;

    return CommunityMemberModel(
      id: member['id']?.toString() ?? '',
      userId: member['userId']?.toString() ?? user?['id']?.toString() ?? '',
      communityId: member['communityId']?.toString() ?? '',
      role: member['role']?.toString() ?? 'MEMBER',
      status: member['status']?.toString() ?? 'JOINED',
      userFullName:
          user?['fullName']?.toString() ?? profile?['fullName']?.toString(),
      userAvatarUrl:
          user?['avatarUrl']?.toString() ??
          user?['avatar_url']?.toString() ??
          profile?['avatarUrl']?.toString() ??
          profile?['avatar_url']?.toString(),
      userEmail: user?['email']?.toString(),
      joinedAt: member['joinedAt']?.toString() ?? '',
      tags:
          (member['tags'] as List<dynamic>?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      streak: CommunityMemberStreakModel.fromJson(
        json['streak'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// P2C.3 — Streak tính động: { type: 'WIN'|'LOSS'|'ELO_UP'|null, count, label }.
class CommunityMemberStreakModel {
  final String? type;
  final int count;
  final String? label;

  const CommunityMemberStreakModel({this.type, this.count = 0, this.label});

  factory CommunityMemberStreakModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CommunityMemberStreakModel();
    return CommunityMemberStreakModel(
      type: json['type']?.toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString(),
    );
  }

  /// Chưa có streak đáng hiển thị.
  bool get isEmpty => type == null || type!.isEmpty || count <= 0;

  Map<String, dynamic> toJson() => {
    'type': type,
    'count': count,
    'label': label,
  };
}
