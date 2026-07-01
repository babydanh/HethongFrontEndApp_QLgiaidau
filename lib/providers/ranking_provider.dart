import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider gọi API GET /rankings thật.
/// Mặc định tải Top 100 (limit=100) theo categoryId để hiển thị bảng xếp hạng.
final rankingsProvider = FutureProvider.family<List<PlayerRanking>, String?>((ref, categoryId) async {
  final repo = ref.read(rankingRepositoryProvider);
  return repo.getRankings(categoryId: categoryId, page: 1, limit: 100);
});

/// Provider lấy danh sách bậc ELO (tier) của 1 môn thể thao.
/// GET /categories/:id/elo-tiers — dùng cho tier legend + gắn tier cho người dùng.
final eloTiersProvider = FutureProvider.family<List<EloTier>, String?>((ref, categoryId) async {
  if (categoryId == null || categoryId.isEmpty) return [];
  final repo = ref.read(rankingRepositoryProvider);
  return repo.getEloTiers(categoryId);
});

/// Provider lấy rank của 1 user trong 1 category
final userRankProvider = FutureProvider.family<UserRankResponse?, ({String userId, String categoryId})>(
  (ref, params) async {
    try {
      final repo = ref.read(rankingRepositoryProvider);
      return await repo.getUserRank(params.userId, params.categoryId);
    } catch (e) {
      return null;
    }
  },
);

/// Provider lấy tổng hợp ELO của user từ API GET /rankings/user/:userId
/// Dùng repository thay vì raw Dio để có auth interceptor
final userRankingsSummaryProvider = FutureProvider.family<List<PlayerRanking>, String>((ref, userId) async {
  try {
    if (userId.isEmpty) return [];
    final dio = ref.read(dioProvider);
    final response = await dio.get('/rankings/user/$userId');
    final raw = response.data;
    if (raw is! Map<String, dynamic>) return [];

    final inner = raw['data'] as Map<String, dynamic>? ?? raw;
    final list = inner['publicRanks'] as List<dynamic>? ?? [];
    return list
        .map((e) => PlayerRanking.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});
