import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

class UserClubRankInfo {
  final PlayerRanking? ranking;
  final int matchesPlayed;
  final int matchesWon;
  final int eloPoints;
  final String tierName;
  final String categoryName;
  final int streakCount;
  final String streakType; // 'WIN' | 'LOSS'

  const UserClubRankInfo({
    this.ranking,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.eloPoints = 1000,
    this.tierName = 'Low Tier D',
    this.categoryName = 'Pickleball',
    this.streakCount = 0,
    this.streakType = 'WIN',
  });
}

/// Provider lấy thông tin ELO và thông số thi đấu của User trong một CLB cụ thể
final userClubRankProvider = FutureProvider.family<UserClubRankInfo, ({String userId, String communityId})>((ref, arg) async {
  final dio = ref.read(dioClientProvider).dio;
  try {
    // 1. Lấy thông tin user rankings
    final rankRes = await dio.get('/rankings/user/');
    final rankData = rankRes.data is Map ? (rankRes.data['data'] ?? rankRes.data) : null;
    final commRanks = rankData is Map ? (rankData['communityRanks'] as List<dynamic>? ?? const []) : const [];
    
    // Tìm rank của community này
    final found = commRanks.whereType<Map<String, dynamic>>().firstWhere(
      (r) => r['communityId']?.toString() == arg.communityId,
      orElse: () => <String, dynamic>{},
    );

    // 2. Lấy thông tin môn chính của CLB nếu có
    String catName = 'Pickleball';
    try {
      final clubRes = await dio.get('/communities/');
      final clubData = clubRes.data is Map ? (clubRes.data['data'] ?? clubRes.data) : null;
      if (clubData is Map && clubData['categories'] is List && (clubData['categories'] as List).isNotEmpty) {
        catName = clubData['categories'][0]['name']?.toString() ?? 'Pickleball';
      }
    } catch (_) {}

    if (found.isNotEmpty) {
      final pr = PlayerRanking.fromJson(found);
      final streakCount = pr.winStreak > 0 ? pr.winStreak : pr.currentStreakCount;
      final streakType = pr.currentStreakType ?? 'WIN';
      return UserClubRankInfo(
        ranking: pr,
        matchesPlayed: pr.matchesPlayed,
        matchesWon: pr.matchesWon,
        eloPoints: pr.eloPoints > 0 ? pr.eloPoints : 1000,
        tierName: pr.tierName.isNotEmpty ? pr.tierName : 'Low Tier D',
        categoryName: pr.categoryName ?? catName,
        streakCount: streakCount,
        streakType: streakType,
      );
    }

    return UserClubRankInfo(
      categoryName: catName,
    );
  } catch (e) {
    return const UserClubRankInfo();
  }
});
