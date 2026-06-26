/// Community ranking model — from API GET /communities/:id/rankings
class CommunityRankingModel {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final int eloPoints;
  final int? rank;

  const CommunityRankingModel({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.eloPoints = 0,
    this.rank,
  });

  factory CommunityRankingModel.fromJson(Map<String, dynamic> json) {
    // Handle { rank: { userId, eloPoints }, user: { fullName, avatarUrl } }
    final rankData = json['rank'] as Map<String, dynamic>? ?? json;
    final userData = json['user'] as Map<String, dynamic>?;

    return CommunityRankingModel(
      userId: rankData['userId']?.toString() ?? userData?['id']?.toString() ?? '',
      fullName: userData?['fullName']?.toString() ?? rankData['fullName']?.toString() ?? 'Người dùng',
      avatarUrl: userData?['avatarUrl']?.toString(),
      eloPoints: int.tryParse(rankData['eloPoints']?.toString() ?? '0') ?? 0,
      rank: json['rank'] is Map ? null : int.tryParse((json['rank'] ?? '').toString()),
    );
  }
}
