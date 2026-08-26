import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider gọi API GET /rankings thật.
/// Mặc định tải Top 100 (limit=100) theo categoryId để hiển thị bảng xếp hạng.
typedef RankingQuery = ({
  String categoryId,
  String matchType,
  String? genderRestriction,
  String? provinceCode,
});

final rankingsProvider =
    FutureProvider.family<List<PlayerRanking>, RankingQuery>((
      ref,
      query,
    ) async {
      final repo = ref.read(rankingRepositoryProvider);
      return repo.getRankings(
        categoryId: query.categoryId,
        matchType: query.matchType,
        genderRestriction: query.genderRestriction,
        provinceCode: query.provinceCode,
        limit: 100,
      );
    });

/// Provider lấy danh sách bậc ELO (tier) của 1 môn thể thao.
/// GET /categories/:id/elo-tiers — dùng cho tier legend + gắn tier cho người dùng.
final footballTeamRankingsProvider =
    FutureProvider.family<List<FootballTeamRanking>, String>((
      ref,
      categoryId,
    ) async {
      if (categoryId.isEmpty) return [];
      final repo = ref.read(rankingRepositoryProvider);
      return repo.getFootballTeamRankings(categoryId: categoryId, limit: 100);
    });

final eloTiersProvider = FutureProvider.family<List<EloTier>, String?>((
  ref,
  categoryId,
) async {
  if (categoryId == null || categoryId.isEmpty) return [];
  final repo = ref.read(rankingRepositoryProvider);
  return repo.getEloTiers(categoryId);
});

/// Provider lấy rank của 1 user trong 1 category
final userRankProvider =
    FutureProvider.family<
      UserRankResponse?,
      ({String userId, String categoryId})
    >((ref, params) async {
      try {
        final repo = ref.read(rankingRepositoryProvider);
        return await repo.getUserRank(params.userId, params.categoryId);
      } catch (e) {
        return null;
      }
    });

/// Provider lấy lịch sử biến động ELO của user.
/// GET /rankings/user/:userId/history
typedef EloHistoryQuery = ({
  String userId,
  String? categoryId,
  String? scope,
  String? communityId,
  String? matchType,
  String? genderRestriction,
  String? partnerId,
  int limit,
  String? cursor,
});

final eloHistoryProvider =
    FutureProvider.family<List<EloHistoryLog>, EloHistoryQuery>((
      ref,
      query,
    ) async {
      try {
        if (query.userId.isEmpty) return [];
        final dio = ref.read(dioProvider);
        final params = <String, dynamic>{
          'limit': query.limit,
          if (query.cursor != null) 'cursor': query.cursor,
        };
        if (query.categoryId != null) params['categoryId'] = query.categoryId;
        if (query.scope != null) params['scope'] = query.scope;
        if (query.communityId != null)
          params['communityId'] = query.communityId;
        if (query.matchType != null) params['matchType'] = query.matchType;
        if (query.genderRestriction != null)
          params['genderRestriction'] = query.genderRestriction;
        if (query.partnerId != null) params['partnerId'] = query.partnerId;

        final response = await dio.get(
          '/rankings/user/${query.userId}/history',
          queryParameters: params,
        );
        final raw = response.data;
        final List<dynamic> list = raw is Map<String, dynamic>
            ? (raw['data'] as List<dynamic>? ?? [])
            : (raw as List<dynamic>? ?? []);
        return list
            .map((e) => EloHistoryLog.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    });

/// Provider lấy tổng hợp ELO của user từ API GET /rankings/user/:userId
/// Dùng repository thay vì raw Dio để có auth interceptor
final userRankingsSummaryProvider =
    FutureProvider.family<List<PlayerRanking>, String>((ref, userId) async {
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
