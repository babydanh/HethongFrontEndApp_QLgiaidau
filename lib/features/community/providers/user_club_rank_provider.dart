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

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Chuẩn hoá response GET /rankings/user/:userId cho popup thành viên CLB.
/// Endpoint đã trả đúng ranking của user được yêu cầu, nên chỉ cần lọc thêm
/// communityId; tuyệt đối không dùng ranking của tài khoản đang đăng nhập.
UserClubRankInfo userClubRankInfoFromResponse(
  dynamic responseData, {
  required String communityId,
}) {
  final envelope = _asMap(responseData);
  final payload = _asMap(envelope?['data']) ?? envelope;
  final rawRanks = payload?['communityRanks'];
  if (rawRanks is! List) return const UserClubRankInfo();

  final ranks = rawRanks
      .map(_asMap)
      .whereType<Map<String, dynamic>>()
      .where(
        (rank) => rank['communityId']?.toString().trim() == communityId.trim(),
      )
      .toList();
  if (ranks.isEmpty) return const UserClubRankInfo();

  // Một CLB có thể có nhiều dòng theo môn/loại trận. Popup chỉ có một thẻ
  // tổng quan, vì vậy ưu tiên dòng đã thi đấu nhiều nhất, rồi đến ELO cao hơn.
  ranks.sort((a, b) {
    final matches = _asInt(
      b['matchesPlayed'] ?? b['totalMatches'],
    ).compareTo(_asInt(a['matchesPlayed'] ?? a['totalMatches']));
    if (matches != 0) return matches;
    return _asInt(
      b['eloPoints'] ?? b['elo_points'],
    ).compareTo(_asInt(a['eloPoints'] ?? a['elo_points']));
  });

  final ranking = PlayerRanking.fromJson(ranks.first);
  final streakCount = ranking.winStreak > 0
      ? ranking.winStreak
      : ranking.currentStreakCount;
  return UserClubRankInfo(
    ranking: ranking,
    matchesPlayed: ranking.matchesPlayed,
    matchesWon: ranking.matchesWon,
    eloPoints: ranking.eloPoints > 0 ? ranking.eloPoints : 1000,
    tierName: ranking.tierName.isNotEmpty ? ranking.tierName : 'Low Tier D',
    categoryName: ranking.categoryName ?? 'Pickleball',
    streakCount: streakCount,
    streakType: ranking.currentStreakType ?? 'WIN',
  );
}

/// Provider lấy thông tin ELO và thông số thi đấu của User trong một CLB cụ thể
final userClubRankProvider =
    FutureProvider.family<
      UserClubRankInfo,
      ({String userId, String communityId})
    >((ref, arg) async {
      final userId = arg.userId.trim();
      final communityId = arg.communityId.trim();
      if (userId.isEmpty || communityId.isEmpty) {
        return const UserClubRankInfo();
      }

      try {
        final dio = ref.read(dioClientProvider).dio;
        final rankRes = await dio.get('/rankings/user/$userId');
        return userClubRankInfoFromResponse(
          rankRes.data,
          communityId: communityId,
        );
      } catch (_) {
        return const UserClubRankInfo();
      }
    });
