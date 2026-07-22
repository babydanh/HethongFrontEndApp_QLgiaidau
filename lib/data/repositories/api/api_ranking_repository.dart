import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/utils/ranking_query_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/repositories/ranking_repository.dart';

class ApiRankingRepository implements IRankingRepository {
  static const _log = AppLogger('ApiRankingRepo');
  final DioClient _dioClient;

  ApiRankingRepository(this._dioClient);

  @override
  Future<List<PlayerRanking>> getRankings({
    int? page,
    int? limit,
    String? categoryId,
    String? matchType,
    String? genderRestriction,
    String? provinceCode,
  }) async {
    _log.info('Tải bảng xếp hạng: page=$page, limit=$limit, categoryId=$categoryId');
    try {
      final queryParams = buildRankingQueryParams(
        categoryId: categoryId,
        matchType: matchType,
        genderRestriction: genderRestriction,
        provinceCode: provinceCode,
        page: page ?? 1,
        limit: limit ?? 100,
      );

      final response = await _dioClient.dio.get(
        '/rankings',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final List<dynamic> dataList = raw is Map<String, dynamic>
            ? (raw['data'] as List<dynamic>? ?? [])
            : (raw as List<dynamic>? ?? []);
        final rankings = dataList
            .map((json) => PlayerRanking.fromJson(json as Map<String, dynamic>))
            .toList();
        // Backend trả theo offset phân trang và sắp xếp desc(eloPoints),
        // nên vị trí hạng = offset + index + 1.
        final offset = ((page ?? 1) - 1) * (limit ?? 50);
        final enriched = <PlayerRanking>[];
        for (var i = 0; i < rankings.length; i++) {
          enriched.add(rankings[i].copyWith(rank: offset + i + 1));
        }
        return enriched;
      }

      throw Exception('Không thể tải bảng xếp hạng');
    } catch (e, stack) {
      _log.error('Lỗi tải bảng xếp hạng', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<EloTier>> getEloTiers(String categoryId) async {
    _log.info('Tải danh sách bậc ELO: categoryId=$categoryId');
    try {
      final response = await _dioClient.dio.get(
        '/categories/$categoryId/elo-tiers',
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        // Endpoint có thể trả mảng trực tiếp hoặc bọc trong { data: [...] }
        final List<dynamic> list = raw is Map<String, dynamic>
            ? (raw['data'] as List<dynamic>? ?? [])
            : (raw as List<dynamic>? ?? []);
        final tiers = list
            .map((json) => EloTier.fromJson(json as Map<String, dynamic>))
            .toList();
        // Sắp xếp tăng dần theo minElo để hiển thị legend đúng thứ tự.
        tiers.sort((a, b) => a.minElo.compareTo(b.minElo));
        return tiers;
      }

      throw Exception('Không thể tải danh sách bậc ELO');
    } catch (e, stack) {
      _log.error('Lỗi tải danh sách bậc ELO', e, stack);
      rethrow;
    }
  }

  @override
  Future<UserRankResponse> getUserRank(
    String userId,
    String categoryId,
  ) async {
    _log.info('Tải rank của user: $userId trong category: $categoryId');
    try {
      final response = await _dioClient.dio.get(
        '/rankings/user/$userId',
        queryParameters: categoryId.isNotEmpty ? {'categoryId': categoryId} : null,
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw['data'] as Map<String, dynamic>? ?? raw as Map<String, dynamic>?;
        // API trả về { publicRanks: [...], communityRanks: [...] }
        // Tìm rank trong publicRanks theo categoryId
        if (data != null) {
          final publicRanks = data['publicRanks'] as List<dynamic>? ?? [];
          for (final r in publicRanks) {
            final rank = PlayerRanking.fromJson(r as Map<String, dynamic>);
            if (rank.categoryId == categoryId || categoryId.isEmpty) {
              return UserRankResponse(eloPoints: rank.eloPoints, tierName: rank.tierName, categoryId: rank.categoryId);
            }
          }
          return UserRankResponse(eloPoints: 1000, tierName: 'Chưa xếp hạng', categoryId: categoryId);
        }
      }

      throw Exception('Không thể tải thông tin xếp hạng của người dùng');
    } catch (e, stack) {
      _log.error('Lỗi tải user rank', e, stack);
      rethrow;
    }
  }
}
